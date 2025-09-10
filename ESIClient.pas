unit ESIClient;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections, System.Net.HttpClient,
  System.Net.URLClient, System.DateUtils, System.Threading, System.Generics.Defaults,
  System.JSON, System.IOUtils, System.SyncObjs, Math, IdGlobalProtocols, WinApi.Windows,
  CacheHelper, Common, Logger;
type

  TESILogger = procedure(const Msg: string);

  TESIClient = class
    class procedure CheckAndLogRateLimitsAndBackoff(const Headers: TArray<TNameValuePair>; PageNum: Integer);
  public
    constructor Create(aLogger: TLogger);
    destructor Destroy; override;
    procedure ParseMarketOrderPage(const PageJson: string; BuyOrders, SellOrders: TList<TMarketOrderRec>; RegionID: Integer);
    procedure ParallelFetchMarketOrderPages(RegionID, StartPage, EndPage: Integer; var Results: TArray<TPageFetchResult>; MaxThreads: Integer = 8);
    procedure FetchTypeInfo(typeID: Integer; out Rec: TTypesRec);
    procedure FetchMarketOrders(RegionID: Integer; var Results: TArray<TPageFetchResult>; MaxThreads: Integer = 8);
    function FetchMarketOrderPage(RegionID, PageNum: Integer; const ETag: string): TPageFetchResult;
    function ParseTotalPagesFromHeader(const Headers: TNetHeaders): Integer;
    function GetHeader(const Key: string; Headers: TNetHeaders): string;
    // Add more ESI endpoint methods as needed...
  end;

var
  FLogger: TLogger;
  GLowestRateRemain: Integer = MaxInt; // Initialize to high value
  GRateLimitLock: TCriticalSection = nil;

implementation
constructor TESIClient.Create(aLogger: TLogger);
begin
  FLogger := aLogger;
end;
destructor TESIClient.Destroy;
begin
end;
procedure Log(const Msg: string);
begin
  if Assigned(FLogger) then FLogger.Log(Msg);
end;

procedure InitRateLimitControl;
begin
  if GRateLimitLock = nil then
    GRateLimitLock := TCriticalSection.Create;
end;

procedure DoneRateLimitControl;
begin
  FreeAndNil(GRateLimitLock);
end;

function GetLowercaseHeader(AHeaders: TNetHeaders; const Key: string): string;
var
  pair: TNameValuePair;
begin
  for pair in AHeaders do
    if SameText(pair.Name, Key) then
      Exit(pair.Value);
  Result := '';
end;
function ParseUniversalDate(const S: string): TDateTime;
begin
  Result := 0;
  try
    Result := StrInternetToDateTime(S);
  except
    try
      Result := ISO8601ToDate(S);
    except
      on E: Exception do
      begin
        Log('Warning: Failed to parse date string: ' + S + ' Exception: ' + E.Message);
        Result := 0;
      end;
    end;
  end;
end;

function UtcNow: TDateTime;
begin
  Result := TTimeZone.Local.ToUniversalTime(Now);
end;

function TESIClient.GetHeader(const Key: string; Headers: TNetHeaders): string;
var
  pair: TNameValuePair;
begin
  Result := '';
  for pair in Headers do
    if SameText(pair.Name, Key) then
      Exit(pair.Value);
end;


function TESIClient.ParseTotalPagesFromHeader(const Headers: TNetHeaders): Integer;
begin
  Result := StrToIntDef(GetHeader('x-pages', Headers), 1);
end;


function TESIClient.FetchMarketOrderPage(RegionID, PageNum: Integer; const ETag: string): TPageFetchResult;
var
  Client: THTTPClient;
  Response: IHTTPResponse;
begin
  FillChar(Result, SizeOf(Result), 0);
  Client := THTTPClient.Create;
  try
    Client.CustomHeaders['User-Agent'] := USER_AGENT;
    if (PageNum = 1) and (ETag <> '') then
      Client.CustomHeaders['If-None-Match'] := ETag;
    Response := Client.Get(Format('https://esi.evetech.net/latest/markets/%d/orders/?order_type=all&page=%d', [RegionID, PageNum]));
    Result.PageNumber := PageNum;
    Result.PageContent := Response.ContentAsString;
    Result.ETagHeader := GetHeader('etag', Response.Headers);
    Result.ExpiresHeader := GetHeader('expires', Response.Headers);
    Result.LastModifiedHeader := GetHeader('last-modified', Response.Headers);
    Result.Headers := Response.Headers;
    if Response.StatusCode = 200 then
      Result.Success := True
    else if Response.StatusCode = 304 then
      Result.NotModified304 := True;
    Result.ErrorMsg := IntToStr(Response.StatusCode) + ': ' + Response.StatusText;
  finally
    Client.Free;
  end;
end;

class procedure TESIClient.CheckAndLogRateLimitsAndBackoff(const Headers: TArray<TNameValuePair>; PageNum: Integer);
var
  h: Integer;
  RateRemain: Integer;
begin
  RateRemain := -1;
  for h := 0 to High(Headers) do
    if SameText(Headers[h].Name, 'X-ESI-Rate-Limit-Remaining') then
      RateRemain := StrToIntDef(Headers[h].Value, -1);

  if RateRemain >= 0 then
  begin
    GRateLimitLock.Enter;
    try
      if RateRemain < GLowestRateRemain then
        GLowestRateRemain := RateRemain;
    finally
      GRateLimitLock.Leave;
    end;

    if RateRemain < 5 then // If threshold reached
    begin
      Log(Format('WARNING: ESI Rate Limit nearly exhausted (remaining=%d, page=%d). Backing off.', [RateRemain, PageNum]));
      Sleep(3000); // Sleep 3 seconds or more
    end;
  end;
end;


procedure TESIClient.ParallelFetchMarketOrderPages(RegionID, StartPage, EndPage: Integer; var Results: TArray<TPageFetchResult>; MaxThreads: Integer = 8);

  procedure CheckAndLogRateLimits(const Headers: TArray<TNameValuePair>; PageNum: Integer);
  var
    h: Integer;
    LimitRemain, RateRemain, LimitReset, RateReset: Integer;
  begin
    LimitRemain := -1;
    RateRemain := -1;
    LimitReset := -1;
    RateReset := -1;
    for h := 0 to High(Headers) do
    begin
      if SameText(Headers[h].Name, 'X-ESI-Error-Limit-Remain') then
        LimitRemain := StrToIntDef(Headers[h].Value, -1);
      if SameText(Headers[h].Name, 'X-ESI-Error-Limit-Reset') then
        LimitReset := StrToIntDef(Headers[h].Value, -1);
      if SameText(Headers[h].Name, 'X-ESI-Rate-Limit-Remaining') then
        RateRemain := StrToIntDef(Headers[h].Value, -1);
      if SameText(Headers[h].Name, 'X-ESI-Rate-Limit-Reset') then
        RateReset := StrToIntDef(Headers[h].Value, -1);
    end;
    if (LimitRemain >= 0) and (LimitRemain < 10) then
      Log(Format('WARNING: ESI Error Limit nearly exhausted (page %d)!', [PageNum]));
    if (RateRemain >= 0) and (RateRemain < 25) then
      Log(Format('WARNING: ESI Rate Limit nearly exhausted (page %d)!', [PageNum]));
  end;

var
  ResultList: TThreadList<TPageFetchResult>;
  BatchStart, BatchEnd, i: Integer;
  ActiveThreads: TObjectList<TThread>;
begin
  ResultList := TThreadList<TPageFetchResult>.Create;
  try
    BatchStart := StartPage;
    while BatchStart <= EndPage do
    begin
      BatchEnd := Min(BatchStart + MaxThreads - 1, EndPage);
      ActiveThreads := TObjectList<TThread>.Create(True);
      try
        for i := BatchStart to BatchEnd do
        begin
          var ThisPage: Integer := i;
          var Thrd := TThread.CreateAnonymousThread(
            procedure
            var
              Fetched: TPageFetchResult;
            begin
              try
                Fetched := FetchMarketOrderPage(RegionID, ThisPage, '');
                TESIClient.CheckAndLogRateLimitsAndBackoff(Fetched.Headers, ThisPage);
                ResultList.Add(Fetched);
              except
                on E: Exception do
                  Log(Format('Exception in thread for page %d: %s', [ThisPage, E.Message]));
              end;
            end
          );
          Thrd.FreeOnTerminate := False;
          Thrd.Start;
          ActiveThreads.Add(Thrd);
        end;
        for i := 0 to ActiveThreads.Count-1 do
          ActiveThreads[i].WaitFor;
      finally
        ActiveThreads.Free;
      end;
      BatchStart := BatchEnd + 1;
    end;

    // Assemble sorted results
    var Sorted: TList<TPageFetchResult> := ResultList.LockList;
    try
      Sorted.Sort(
        TComparer<TPageFetchResult>.Construct(
          function(const Left, Right: TPageFetchResult): Integer
          begin
            Result := Left.PageNumber - Right.PageNumber;
          end
        )
      );
      SetLength(Results, Sorted.Count);
      for i := 0 to Sorted.Count-1 do
        Results[i] := Sorted[i];
    finally
      ResultList.UnlockList;
    end;
  finally
    ResultList.Free;
  end;
end;



procedure TESIClient.FetchMarketOrders(RegionID: Integer; var Results: TArray<TPageFetchResult>; MaxThreads: Integer);
var
  CacheMeta: TMarketOrderCacheMeta;
  NowTime: TDateTime;
  FirstRes: TPageFetchResult;
  TotalPages, i: Integer;
  BatchResults: TArray<TPageFetchResult>;
  NewETag, ExpStr: string;
  NewExpires: TDateTime;

  function FindHeaderValue(const Headers: TArray<TNameValuePair>; const HeaderName: string): string;
  var h: Integer;
  begin
    Result := '';
    for h := 0 to High(Headers) do
      if SameText(Headers[h].Name, HeaderName) then
        Exit(Headers[h].Value);
  end;

  procedure LoadMarketOrderCache;
  var
    ok: Boolean;
    j: Integer;
  begin
    ok := TCacheHelper.LoadCache(RegionID, CacheMeta);
    if not ok then
    begin
      SetLength(Results, 0);
      Exit;
    end;
    SetLength(Results, Length(CacheMeta.Pages));
    for j := 0 to High(CacheMeta.Pages) do
    begin
      Results[j].PageNumber  := CacheMeta.Pages[j].PageNum;
      Results[j].PageContent := CacheMeta.Pages[j].PageContent;
    end;
  end;

  procedure SaveMarketOrderCache(const ETag: string; Expires, Timestamp: TDateTime);
  var
    j: Integer;
  begin
    CacheMeta.ETag      := ETag;
    CacheMeta.Expires   := Expires;
    CacheMeta.Timestamp := Timestamp;
    SetLength(CacheMeta.Pages, Length(Results));
    for j := 0 to High(Results) do
    begin
      CacheMeta.Pages[j].PageNum     := Results[j].PageNumber;
      CacheMeta.Pages[j].PageContent := Results[j].PageContent;
    end;
    TCacheHelper.SaveCache(RegionID, CacheMeta);
  end;

begin
  NowTime := UtcNow;

  // -- Attempt to use valid cache
  LoadMarketOrderCache;
  if (CacheMeta.Expires > 0) and (NowTime < CacheMeta.Expires) or DEBUG then
  begin
    Log('Cache valid (Expires=' + DateTimeToStr(CacheMeta.Expires) + '), using cached results.');
    Exit;
  end;

  // -- Fetch first page conditionally using ETag
  Log('Fetching first page with ETag: ' + CacheMeta.ETag);
  FirstRes := FetchMarketOrderPage(RegionID, 1, CacheMeta.ETag);

  if FirstRes.NotModified304 then
  begin
    Log('First page returned 304 Not Modified, using cached data.');
    LoadMarketOrderCache;
    Exit;
  end;

  // -- Parse total page count, fetch remaining pages in parallel if needed
  TotalPages := ParseTotalPagesFromHeader(FirstRes.Headers);
  Log(Format('First page indicates %d total pages. Launching parallel batch fetch.', [TotalPages]));

  if TotalPages > 1 then
    ParallelFetchMarketOrderPages(RegionID, 2, TotalPages, BatchResults, MaxThreads)
  else
    SetLength(BatchResults, 0);

  // -- Assemble complete result array
  SetLength(Results, 1 + Length(BatchResults));
  Results[0] := FirstRes;
  for i := 0 to High(BatchResults) do
    Results[i+1] := BatchResults[i];

  // -- Extract new ETag/Expires and save all to cache
  NewETag   := FindHeaderValue(FirstRes.Headers, 'etag');
  ExpStr    := FindHeaderValue(FirstRes.Headers, 'expires');
  NewExpires := ParseUniversalDate(ExpStr);

  SaveMarketOrderCache(NewETag, NewExpires, NowTime);

  Log('Market orders fetched and cached. ETag=' + NewETag + ', Expires=' + DateTimeToStr(NewExpires));
end;





procedure TESIClient.ParseMarketOrderPage(const PageJson: string; BuyOrders, SellOrders: TList<TMarketOrderRec>; RegionID: Integer);
var
  PageValue: TJSONValue;
  PageArr: TJSONArray;
  j: Integer;
  OrderObj: TJSONObject;
  rec: TMarketOrderRec;
begin
  PageValue := TJSONObject.ParseJSONValue(PageJson);
  try
    if not Assigned(PageValue) then
    begin
      Log('ParseMarketOrderPage: PageValue is nil');
      Exit;
    end;

    if not (PageValue is TJSONArray) then
    begin
      Log('ParseMarketOrderPage: PageJson is not a JSON array');
      Exit;
    end;

    PageArr := TJSONArray(PageValue);
    for j := 0 to PageArr.Count - 1 do
    begin
      if not (PageArr.Items[j] is TJSONObject) then
      begin
        Log(Format('ParseMarketOrderPage: Element %d is not a JSONObject', [j]));
        Continue;
      end;

      OrderObj := PageArr.Items[j] as TJSONObject;
      try
        FillChar(rec, SizeOf(rec), 0); // Defensive: clear record first
        with rec do
        begin
          // Each GetValue should be wrapped to detect missing fields
          order_id      := OrderObj.GetValue<Int64>('order_id', 0);
          type_id       := OrderObj.GetValue<Integer>('type_id', 0);
          is_buy_order  := OrderObj.GetValue<Boolean>('is_buy_order', False);
          station_id    := OrderObj.GetValue<Int64>('location_id', 0);
          system_id     := OrderObj.GetValue<Integer>('system_id', 0);
          region_id     := RegionID;
          price         := OrderObj.GetValue<Double>('price', 0.0);
          volume_remain := OrderObj.GetValue<Integer>('volume_remain', 0);
          volume_total  := OrderObj.GetValue<Integer>('volume_total', 0);
          duration      := OrderObj.GetValue<Integer>('duration', 0);
          issued        := OrderObj.GetValue<string>('issued', '');
          min_volume    := OrderObj.GetValue<Integer>('min_volume', 0);
          range         := OrderObj.GetValue<string>('range', '');
        end;

        if rec.is_buy_order then
          BuyOrders.Add(rec)
        else
          SellOrders.Add(rec);
      except
        on E: Exception do
          Log(Format('ParseMarketOrderPage: Exception processing order %d: %s', [j, E.Message]));
      end;
    end;
  finally
    PageValue.Free;
  end;
end;



procedure TESIClient.FetchTypeInfo(typeID: Integer; out Rec: TTypesRec);
var
  Client: THTTPClient;
  Response: IHTTPResponse;
  JsonObj: TJSONObject;
begin
  Client := THTTPClient.Create;
  try
    Client.CustomHeaders['User-Agent'] := USER_AGENT;
    Response := Client.Get(Format('https://esi.evetech.net/latest/universe/types/%d/', [typeID]));

    if Response.StatusCode = 200 then
    begin
      JsonObj := TJSONObject.ParseJSONValue(Response.ContentAsString) as TJSONObject;
      if Assigned(JsonObj) then
      begin
        // Fill record fields (handle missing values gracefully)
        Rec.typeID        := JsonObj.GetValue<Integer>('type_id');
        Rec.typeName      := JsonObj.GetValue<string>('name', '');
        Rec.lowerTypeName := LowerCase(Rec.typeName);
        Rec.marketGroupID := JsonObj.GetValue<string>('market_group_id', '');
        Rec.volume        := JsonObj.GetValue<Double>('volume', 0);
        Rec.description   := JsonObj.GetValue<string>('description', '');
        Rec.iconID        := JsonObj.GetValue<Int64>('icon_id', 0);
        JsonObj.Free;
      end;
    end;
    // Handle HTTP error cases as needed
  finally
    Client.Free;
  end;
end;


end.

