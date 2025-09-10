unit CacheHelper;

interface

uses
  IdGlobalProtocols, Winapi.Windows, System.DateUtils, System.SysUtils, System.Classes,
  System.JSON, System.IOUtils, System.Generics.Collections;

type
  TMarketOrderPageResult = record
    PageNum: Integer;
    PageContent: string;
  end;
  TMarketOrderPageResults = TArray<TMarketOrderPageResult>;

  TMarketOrderCacheMeta = record
    ETag: string;
    Expires: TDateTime;
    Timestamp: TDateTime;
    Pages: TMarketOrderPageResults;
  end;

  TCacheHelper = class
  public
    class function GetCacheFileName(RegionID: Integer): string;
    class function CacheDir: string;
    class function LoadCache(RegionID: Integer; out CacheMeta: TMarketOrderCacheMeta): Boolean;
    class procedure SaveCache(RegionID: Integer; const CacheMeta: TMarketOrderCacheMeta);
  end;

  // Use your existing universal date parsing function!
  function ParseUniversalDate(const S: string): TDateTime;

implementation

function ParseUniversalDate(const S: string): TDateTime;
begin
  Result := 0;
  try
    Result := StrInternetToDateTime(S); // Your working function, if available!
  except
    try
      Result := ISO8601ToDate(S);
    except
      on E: Exception do
        Result := 0;
    end;
  end;
end;

//---- TCacheHelper implementation ----

class function TCacheHelper.CacheDir: string;
begin
  Result := TPath.Combine('.', 'marketcache');
end;

class function TCacheHelper.GetCacheFileName(RegionID: Integer): string;
begin
  Result := TPath.Combine(CacheDir, Format('market_%d_cache.json', [RegionID]));
end;

class function TCacheHelper.LoadCache(RegionID: Integer; out CacheMeta: TMarketOrderCacheMeta): Boolean;
var
  S: string;
  Root: TJSONObject;
  Arr: TJSONArray;
  i: Integer;
  CacheFile: string;
begin
  Result := False;
  FillChar(CacheMeta, SizeOf(CacheMeta), 0);

  CacheFile := GetCacheFileName(RegionID);
  if not FileExists(CacheFile) then Exit;

  S := TFile.ReadAllText(CacheFile, TEncoding.UTF8);
  Root := TJSONObject.ParseJSONValue(S) as TJSONObject;
  if not Assigned(Root) then Exit;
  try
    CacheMeta.ETag := Root.GetValue<string>('etag', '');
    CacheMeta.Expires := ParseUniversalDate(Root.GetValue<string>('expires', ''));
    CacheMeta.Timestamp := ParseUniversalDate(Root.GetValue<string>('timestamp', ''));
    Arr := Root.GetValue<TJSONArray>('pages');
    if Assigned(Arr) then
    begin
      SetLength(CacheMeta.Pages, Arr.Count);
      for i := 0 to Arr.Count - 1 do
      begin
        with Arr.Items[i] as TJSONObject do
        begin
          CacheMeta.Pages[i].PageNum := GetValue<Integer>('page_num', 0);
          CacheMeta.Pages[i].PageContent := GetValue<string>('result', '');
        end;
      end;
    end
    else
      SetLength(CacheMeta.Pages, 0);
    Result := True;
  finally
    Root.Free;
  end;
end;

class procedure TCacheHelper.SaveCache(RegionID: Integer; const CacheMeta: TMarketOrderCacheMeta);
var
  Root: TJSONObject;
  Arr: TJSONArray;
  i: Integer;
  Dir, CacheFile: string;

  // Helper to convert TDateTime to RFC1123 string (for Expires)
  function DateTimeToRFC1123(DT: TDateTime): string;
  begin
    if DT = 0 then
      Exit('');
    Result := FormatDateTime('ddd, dd mmm yyyy hh:nn:ss', DT, TFormatSettings.Create('en-US')) + ' GMT';
  end;
begin
  Dir := CacheDir;
  if not TDirectory.Exists(Dir) then
    TDirectory.CreateDirectory(Dir);

  CacheFile := GetCacheFileName(RegionID);

  Root := TJSONObject.Create;
  try
    Root.AddPair('etag', CacheMeta.ETag);
    Root.AddPair('expires', DateTimeToRFC1123(CacheMeta.Expires));
    Root.AddPair('timestamp', DateToISO8601(CacheMeta.Timestamp, True));
    Arr := TJSONArray.Create;
    for i := 0 to High(CacheMeta.Pages) do
      Arr.AddElement(
        TJSONObject.Create
          .AddPair('page_num', TJSONNumber.Create(CacheMeta.Pages[i].PageNum))
          .AddPair('result', CacheMeta.Pages[i].PageContent));
    Root.AddPair('pages', Arr);
    TFile.WriteAllText(CacheFile, Root.ToJSON, TEncoding.UTF8);
  finally
    Root.Free;
  end;
end;

end.

