unit RegionManager;

interface

uses
  System.Net.URLClient, System.Net.HttpClient, System.DateUtils, System.Classes, System.Generics.Collections, System.SysUtils, System.Threading,
  System.JSON, System.IOUtils, System.SyncObjs, Math, IdGlobalProtocols,
  Common, EsiClient, Parser, Logger;

type
  TRegionLoadCompleteEvent = procedure of object;
  TMarketRegionOrders = TDictionary<Integer, TDictionary<Integer, TList<TMarketOrderRec>>>;

  TRegionManager = class
  private
    ///////////////////////////////
    /// REGION QUEING VARIABLES ///
    ///////////////////////////////

    FRegionQueue: TQueue<Integer>;
    FQueuedRegionSet: TDictionary<Integer, Boolean>;
    FQueuedRegionCount: Integer;
    FIsRegionLoading: Boolean;
    FOnLoadComplete: TRegionLoadCompleteEvent;
    FLastCacheDir: string;
    FLastLoadedRegion: Integer;
    FLastRegionUpdate: TDictionary<Integer, TDateTime>;
    FParser: TParser;
    FLogger: TLogger;
    FESIClient: TESIClient;
    FUserOnLoadComplete: TRegionLoadCompleteEvent;
    /////////////////////////////
    /// REGION QUEING METHODS ///
    /////////////////////////////

    procedure EnqueueRegion(RegionID: Integer);
    procedure TryStartLoading;
    procedure ProcessNextRegionInQueue;
    procedure RunRegionLoadTask(RegionID: Integer; CacheDir: string);
    procedure FireOnLoadComplete;
    procedure UpdateStatus(const Msg: string);
    function IsRegionLoaded(RegionID: Integer): Boolean;

//    procedure LoadMarketOrdersSingleThreaded(RegionID: Integer; CacheDir: string; BuyOrders: TList<TMarketOrderRec>; SellOrders: TList<TMarketOrderRec>);
    procedure BuildOrderIndexes;
    procedure InitializeGlobalMarketStats;
  public
    UniverseBuyOrders: TDictionary<Int64, TMarketOrderRec>;
    UniverseSellOrders: TDictionary<Int64, TMarketOrderRec>;
    UniverseBuyOrdersByRegion: TDictionary<Integer, TDictionary<Int64, TMarketOrderRec>>;
    UniverseSellOrdersByRegion: TDictionary<Integer, TDictionary<Int64, TMarketOrderRec>>;
    BuyTypeIndex: TDictionary<Integer, TList<TMarketOrderRec>>;
    SellTypeIndex: TDictionary<Integer, TList<TMarketOrderRec>>;
    BuyOrdersByRegionByType:  TDictionary<Integer, TDictionary<Integer, TList<TMarketOrderRec>>>; // region → type → buy orders
    SellOrdersByRegionByType: TDictionary<Integer, TDictionary<Integer, TList<TMarketOrderRec>>>; // region → type → sell orders
    GlobalMarketStats: TDictionary<Integer, TMarketStats>;

    FLoadedRegions: TDictionary<Integer, TRegionInfo>;
    constructor Create(aParser: TParser; aLogger: TLogger);
    destructor Destroy; override;
    procedure UpdateTypesForID(typeID: Integer);
    property OnLoadComplete: TRegionLoadCompleteEvent read FOnLoadComplete write FOnLoadComplete;
    property UserOnLoadComplete: TRegionLoadCompleteEvent read FUserOnLoadComplete write FUserOnLoadComplete;
    function GetJumpRoute(SystemA, SystemB: Integer; MinSecurity, MaxSecurity: Double): TJumpRoute;
    function GetJumpsBetween(SystemA, SystemB: Integer): Integer;
    function GetJumpsBetweenFast(SystemA, SystemB: Integer): Integer;
    function GetAllSystemsInRegion(RegionID: Integer): TArray<Integer>;
    function GetClosestSystemInRegion(StartSystemID, RegionID: Integer; MinSecurity, MaxSecurity: Double): TJumpRoute;
    function GetClosestSystemWithinJumps(StartSystemID, BuySystemID, MaxJumps: Integer; MinSecurity, MaxSecurity: Double): Integer;

    ////////////////////////////
    // DYNAMIC REGION LOADING //
    ////////////////////////////

    procedure EnqueueRegionsForLoad(const RegionIDs: TArray<Integer>; CacheDir: string);
    procedure InternalRegionLoadComplete;
    //procedure QueueRegions(const RegionIDs: TArray<Integer>; CacheDir: string);

    ///////////////////
    // MARKET ORDERS //
    ///////////////////

    function BuyOrdersByRegion: TDictionary<Integer, TDictionary<Int64, TMarketOrderRec>>;
    function BuyOrdersBySystemAndType(SystemID, TypeID: Integer): TList<TMarketOrderRec>;
    function BuyOrdersByStationAndType(StationID, TypeID: Integer): TList<TMarketOrderRec>;
    function SellOrdersByRegion: TDictionary<Integer, TDictionary<Int64, TMarketOrderRec>>;
    function SellOrdersByStationAndType(StationID, TypeID: Integer): TList<TMarketOrderRec>;
    function SellOrdersBySystemAndType(SystemID, TypeID: Integer): TList<TMarketOrderRec>;
    function BuyOrdersByRegionAndType(RegionID, TypeID: Integer): TList<TMarketOrderRec>;
    function SellOrdersByRegionAndType(RegionID, TypeID: Integer): TList<TMarketOrderRec>;
    function MarketGroupBreadcrumb(TypeID: Integer): string;
    function MarketGroups: TDictionary<string, TMarketGroupRec>;

    ////////////////////
    // PARSER REGIONS //
    ////////////////////

    function RegionCount: Integer;
    function RegionIndexToRec(Index: Integer): TRegionsRec;
    function RegionIDToName(RegionID: Integer): string;
    function RegionNameToID(const RegionName: string): Integer;

    ////////////////////
    // PARSER SYSTEMS //
    ////////////////////

    procedure SystemsWithinJumpsOf(StartSystemID, MaxJumps: Integer; out SystemsArr: TArray<Integer>; out DistanceMap: TDictionary<Integer, Integer>);
    function AllSystemIDs: TArray<Integer>;
    function SystemCount: Integer;
    function SystemHasStation(SystemID: Integer): Boolean;
    function SystemIndexToRec(Index: Integer): TSystemsRec;
    function SystemsInRegion(RegionID: Integer): TArray<Integer>;
    function SystemIDExists(SystemID: Integer): Boolean;
    function SystemIDToRegionName(SystemID: Integer): string;
    function SystemIDToName(SystemID: Integer): string;
    function SystemIDToRec(SystemID: Integer): TSystemsRec;
    function SystemIDToRegionID(SystemID: Integer): Integer;
    function SystemNameToID(const SystemName: string): Integer;
    function SystemSecurity(SystemID: Integer): Double;
    function SystemJumps(SystemID: Integer): TArray<Integer>;

    /////////////////////
    // PARSER STATIONS //
    /////////////////////

    function FirstStationInSystem(SystemID: Integer): Integer;
    function StationCount: Integer;
    function StationsInSystem(SystemID: Integer): TList<Int64>;
    function StationIndexToRec(Index: Integer): TStationsRec;
    function StationIDToName(StationID: Int64): string;
    function StationIDToRegionID(StationID: Int64): Integer;
    function StationIDToRegionName(StationID: Int64): string;
    function StationIDToSecurity(StationID: Int64): Double;
    function StationNameToID(const StationName: string): Integer;

    //////////////////
    // TYPE GETTERS //
    //////////////////

    function TypeCount: Integer;
    function TypeIDExists(typeID: Integer): Boolean;
    function TypeIndexToRec(Index: Integer): TTypesRec;
    function TypeIndexToID(Index: Integer): Integer;
    function TypeIDToName(TypeID: Integer): string;
    function TypeIDToDescription(TypeID: Integer): string;
    function TypeIDToMarketGroupID(TypeID: Integer): string;
    function TypeIDToRec(TypeID: Integer): TTypesRec;
    function TypeIDToVolume(TypeID: Integer): Double;
    function TypeNameToID(const TypeName: string): Integer;
    function MarketGroupIDToTypes(const MarketGroupID: string): TArray<TTypesRec>;
    function GetBuyTypeIndex: TDictionary<Integer, TList<TMarketOrderRec>>;
    function GetSellTypeIndex: TDictionary<Integer, TList<TMarketOrderRec>>;
    function TryGetParentToChildren(const MarketGroupID: string; out ChildList: TList<string>): Boolean;
    function TryGetMarketGroup(const MarketGroupID: string; out Group: TMarketGroupRec): Boolean;

  end;
implementation

constructor TRegionManager.Create(aParser: TParser; aLogger: TLogger);
begin
  FLoadedRegions := TDictionary<Integer, TRegionInfo>.Create;
  FLastRegionUpdate := TDictionary<Integer, TDateTime>.Create;
  UniverseBuyOrders := TDictionary<Int64, TMarketOrderRec>.Create;
  UniverseSellOrders := TDictionary<Int64, TMarketOrderRec>.Create;
  FParser := aParser;
  FLogger := aLogger;
  FESIClient := TESIClient.Create(FLogger);
end;
destructor TRegionManager.Destroy;
var
  List: TList<TMarketOrderRec>;
  InnerDict: TDictionary<Int64, TMarketOrderRec>;
begin
   // Clean type index Buy
  if Assigned(BuyTypeIndex) then
  begin
    for List in BuyTypeIndex.Values do
      List.Free;
    BuyTypeIndex.Free;
  end;

  // Clean type index Sell
  if Assigned(SellTypeIndex) then
  begin
    for List in SellTypeIndex.Values do
      List.Free;
    SellTypeIndex.Free;
  end;

  // Clean region-indexed dictionaries for Buy
  if Assigned(UniverseBuyOrdersByRegion) then
  begin
    for InnerDict in UniverseBuyOrdersByRegion.Values do
      InnerDict.Free;
    UniverseBuyOrdersByRegion.Free;
  end;

  // Clean region-indexed dictionaries for Sell
  if Assigned(UniverseSellOrdersByRegion) then
  begin
    for InnerDict in UniverseSellOrdersByRegion.Values do
      InnerDict.Free;
    UniverseSellOrdersByRegion.Free;
  end;

  // Clean flat dictionaries
  if Assigned(UniverseBuyOrders) then
    UniverseBuyOrders.Free;
  if Assigned(UniverseSellOrders) then
    UniverseSellOrders.Free;

  // Clean other lists as needed...
  FLoadedRegions.Free;

  inherited;
end;

function GetLowercaseHeader(AHeaders: TArray<TNameValuePair>; const Key: string): string;
var
  pair: TNameValuePair;
begin
  for pair in AHeaders do
    if SameText(pair.Name, Key) then
      Exit(pair.Value);
  Result := '';
end;


{$REGION 'INDEXING LOGIC'}
procedure BuildRegionOrderIndex(
  const Orders: TDictionary<Int64, TMarketOrderRec>;
  var OrdersByRegion: TDictionary<Integer, TDictionary<Int64, TMarketOrderRec>>
);
var
  Order: TMarketOrderRec;
  RegionDict: TDictionary<Int64, TMarketOrderRec>;
begin
  if Assigned(OrdersByRegion) then OrdersByRegion.Free;
  OrdersByRegion := TDictionary<Integer, TDictionary<Int64, TMarketOrderRec>>.Create;
  for Order in Orders.Values do
  begin
    if not OrdersByRegion.TryGetValue(Order.region_id, RegionDict) then
    begin
      RegionDict := TDictionary<Int64, TMarketOrderRec>.Create;
      OrdersByRegion.Add(Order.region_id, RegionDict);
    end;
    RegionDict.AddOrSetValue(Order.order_id, Order); // AddOrSetValue replaces duplicates
  end;
end;

procedure BuildOrdersByRegionByType(const SourceOrders: TDictionary<Int64, TMarketOrderRec>; var Index: TDictionary<Integer, TDictionary<Integer, TList<TMarketOrderRec>>>);
var
  orderRec: TMarketOrderRec;
  typeDict: TDictionary<Integer, TList<TMarketOrderRec>>;
  orderList: TList<TMarketOrderRec>;
begin
//  if Assigned(Index) then Index.Free; // clean up old index
  if not Assigned(Index) then
    Index := TDictionary<Integer, TDictionary<Integer, TList<TMarketOrderRec>>>.Create;
  for orderRec in SourceOrders.Values do
  begin
    if not Index.TryGetValue(orderRec.region_id, typeDict) then
    begin
      typeDict := TDictionary<Integer, TList<TMarketOrderRec>>.Create;
      Index.Add(orderRec.region_id, typeDict);
    end;
    if not typeDict.TryGetValue(orderRec.type_id, orderList) then
    begin
      orderList := TList<TMarketOrderRec>.Create;
      typeDict.Add(orderRec.type_id, orderList);
    end;
    orderList.Add(orderRec);
  end;
end;

procedure BuildTypeIndex(const Orders: TDictionary<Int64, TMarketOrderRec>; var Index: TDictionary<Integer, TList<TMarketOrderRec>>);
var
  orderRec: TMarketOrderRec;
  list: TList<TMarketOrderRec>;
begin
  if Assigned(Index) then Index.Free;
  Index := TDictionary<Integer, TList<TMarketOrderRec>>.Create;
  for orderRec in Orders.Values do
  begin
    if not Index.TryGetValue(orderRec.type_id, list) then
    begin
      list := TList<TMarketOrderRec>.Create;
      Index.Add(orderRec.type_id, list);
    end;
    list.Add(orderRec);
  end;
end;

procedure BuildRegionOrderIndexByType(
  const Orders: TDictionary<Int64, TMarketOrderRec>;
  var Index: TDictionary<Integer, TDictionary<Integer, TList<TMarketOrderRec>>>
);
var
  orderRec: TMarketOrderRec;
  typeDict: TDictionary<Integer, TList<TMarketOrderRec>>;
  orderList: TList<TMarketOrderRec>;
begin
  if Assigned(Index) then Index.Free;
  Index := TDictionary<Integer, TDictionary<Integer, TList<TMarketOrderRec>>>.Create;
  for orderRec in Orders.Values do
  begin
    if not Index.TryGetValue(orderRec.region_id, typeDict) then
    begin
      typeDict := TDictionary<Integer, TList<TMarketOrderRec>>.Create;
      Index.Add(orderRec.region_id, typeDict);
    end;
    if not typeDict.TryGetValue(orderRec.type_id, orderList) then
    begin
      orderList := TList<TMarketOrderRec>.Create;
      typeDict.Add(orderRec.type_id, orderList);
    end;
    orderList.Add(orderRec);
  end;
end;

procedure TRegionManager.BuildOrderIndexes;
begin
  BuildRegionOrderIndex(UniverseBuyOrders, UniverseBuyOrdersByRegion);
  BuildRegionOrderIndex(UniverseSellOrders, UniverseSellOrdersByRegion);
  BuildTypeIndex(UniverseBuyOrders, BuyTypeIndex);
  BuildTypeIndex(UniverseSellOrders, SellTypeIndex);
  BuildOrdersByRegionByType(UniverseBuyOrders, BuyOrdersByRegionByType);
  BuildOrdersByRegionByType(UniverseSellOrders, SellOrdersByRegionByType);
  InitializeGlobalMarketStats;
// Add any other index-builders as needed
end;

procedure TRegionManager.InitializeGlobalMarketStats;
var
  TypeID: Integer;
  BuyOrders, SellOrders: TList<TMarketOrderRec>;
  Stats: TMarketStats;
  Order: TMarketOrderRec;
  Sum, WeightedSum, Volume: Double;
  Count: Integer;
begin
  if GlobalMarketStats = nil then
    GlobalMarketStats := TDictionary<Integer, TMarketStats>.Create
  else
    GlobalMarketStats.Clear;

  // --- For all types present in BuyTypeIndex and SellTypeIndex ---
  for TypeID in BuyTypeIndex.Keys do
  begin
    FillChar(Stats, SizeOf(Stats), 0);

    // ---------- BUY STATS ----------
    BuyOrders := BuyTypeIndex[TypeID];
    Stats.BuyMin := MaxDouble;
    Stats.BuyMax := -MaxDouble;
    Sum := 0;
    WeightedSum := 0;
    Volume := 0;
    Count := 0;
    if Assigned(BuyOrders) and (BuyOrders.Count > 0) then
    begin
      for Order in BuyOrders do
      begin
        if Order.price < Stats.BuyMin then
          Stats.BuyMin := Order.price;
        if Order.price > Stats.BuyMax then
          Stats.BuyMax := Order.price;
        Sum := Sum + Order.price;
        if Order.volume_remain > 0 then
        begin
          WeightedSum := WeightedSum + (Order.price * Order.volume_remain);
          Volume := Volume + Order.volume_remain;
        end;
        Inc(Count);
      end;
      Stats.BuyAvg := Sum / Count;
      if Volume > 0 then
        Stats.BuyWeighted := WeightedSum / Volume
      else
        Stats.BuyWeighted := Stats.BuyAvg;
    end
    else
    begin
      Stats.BuyMin := 0; Stats.BuyMax := 0; Stats.BuyAvg := 0; Stats.BuyWeighted := 0;
    end;

    // ---------- SELL STATS ----------
    if SellTypeIndex.TryGetValue(TypeID, SellOrders) and Assigned(SellOrders) and (SellOrders.Count > 0) then
    begin
      Stats.SellMin := MaxDouble;
      Stats.SellMax := -MaxDouble;
      Sum := 0;
      WeightedSum := 0;
      Volume := 0;
      Count := 0;
      for Order in SellOrders do
      begin
        if Order.price < Stats.SellMin then
          Stats.SellMin := Order.price;
        if Order.price > Stats.SellMax then
          Stats.SellMax := Order.price;
        Sum := Sum + Order.price;
        if Order.volume_remain > 0 then
        begin
          WeightedSum := WeightedSum + (Order.price * Order.volume_remain);
          Volume := Volume + Order.volume_remain;
        end;
        Inc(Count);
      end;
      Stats.SellAvg := Sum / Count;
      if Volume > 0 then
        Stats.SellWeighted := WeightedSum / Volume
      else
        Stats.SellWeighted := Stats.SellAvg;
    end
    else
    begin
      Stats.SellMin := 0; Stats.SellMax := 0; Stats.SellAvg := 0; Stats.SellWeighted := 0;
    end;

    GlobalMarketStats.AddOrSetValue(TypeID, Stats);
  end;

  // --- For types only in SellTypeIndex (not in BuyTypeIndex) ---
  for TypeID in SellTypeIndex.Keys do
    if not BuyTypeIndex.ContainsKey(TypeID) then
    begin
      FillChar(Stats, SizeOf(Stats), 0);
      if SellTypeIndex.TryGetValue(TypeID, SellOrders) and Assigned(SellOrders) and (SellOrders.Count > 0) then
      begin
        Stats.SellMin := MaxDouble;
        Stats.SellMax := -MaxDouble;
        Sum := 0;
        WeightedSum := 0;
        Volume := 0;
        Count := 0;
        for Order in SellOrders do
        begin
          if Order.price < Stats.SellMin then
            Stats.SellMin := Order.price;
          if Order.price > Stats.SellMax then
            Stats.SellMax := Order.price;
          Sum := Sum + Order.price;
          if Order.volume_remain > 0 then
          begin
            WeightedSum := WeightedSum + (Order.price * Order.volume_remain);
            Volume := Volume + Order.volume_remain;
          end;
          Inc(Count);
        end;
        Stats.SellAvg := Sum / Count;
        if Volume > 0 then
          Stats.SellWeighted := WeightedSum / Volume
        else
          Stats.SellWeighted := Stats.SellAvg;
      end;
      // Buy stats stay zero
      GlobalMarketStats.AddOrSetValue(TypeID, Stats);
    end;
end;



{$ENDREGION}


{$REGION 'REGION QUEUE LOADING'}

procedure TRegionManager.EnqueueRegionsForLoad(const RegionIDs: TArray<Integer>; CacheDir: string);
begin
  if FRegionQueue = nil then
    FRegionQueue := TQueue<Integer>.Create;
  if FQueuedRegionSet = nil then
    FQueuedRegionSet := TDictionary<Integer, Boolean>.Create;
  FQueuedRegionCount := Length(RegionIDs);
  FLastCacheDir := CacheDir;
  for var RegionID in RegionIDs do
    EnqueueRegion(RegionID);
  TryStartLoading;
end;

procedure TRegionManager.EnqueueRegion(RegionID: Integer);
begin
  if IsRegionLoaded(RegionID) then Exit;
  if FQueuedRegionSet.ContainsKey(RegionID) then Exit;
  FRegionQueue.Enqueue(RegionID);
  FQueuedRegionSet.Add(RegionID, True);
  UpdateStatus(Format(' Regions left in queue: %d Queued region %d.', [FRegionQueue.Count, RegionID]));
end;

procedure TRegionManager.TryStartLoading;
begin
  if FIsRegionLoading then Exit;
  ProcessNextRegionInQueue;
end;

procedure TRegionManager.ProcessNextRegionInQueue;
var
  NextRegion: Integer;
begin
  if (FRegionQueue <> nil) and (FRegionQueue.Count > 0) then
  begin
    FIsRegionLoading := True;
    NextRegion := FRegionQueue.Dequeue;
    FQueuedRegionSet.Remove(NextRegion);
    FLastLoadedRegion := NextRegion;
    UpdateStatus(Format(' Regions left in queue: %d Downloading region %d.', [FRegionQueue.Count, NextRegion]));
    FLogger.Progress(FQueuedRegionCount - FRegionQueue.Count, FQueuedRegionCount);
    RunRegionLoadTask(NextRegion, FLastCacheDir);
  end
  else
    FireOnLoadComplete;
end;


procedure TRegionManager.RunRegionLoadTask(RegionID: Integer; CacheDir: string);
begin
  FIsRegionLoading := True;
  TTask.Run(procedure
  var
    PageResults: TArray<TPageFetchResult>;
    LoadedBuyOrders, LoadedSellOrders: TList<TMarketOrderRec>;
    LoadSuccess: Boolean;
    LoadErrorMsg: string;
    RegionInfo: TRegionInfo;
  begin
    LoadSuccess := False;
    try
      // Create working lists local to this thread
      LoadedBuyOrders := TList<TMarketOrderRec>.Create;
      LoadedSellOrders := TList<TMarketOrderRec>.Create;
      // 1. Fetch and cache market order data (using new JSON cache system)
      FESIClient.FetchMarketOrders(RegionID, PageResults, 32);
      // 2. Parse all page JSON results into buy/sell lists
      for var pr in PageResults do
        FESIClient.ParseMarketOrderPage(pr.PageContent, LoadedBuyOrders, LoadedSellOrders, RegionID);
      //FLogger.Log('LoadedSellOrders count: ' + LoadedSellOrders.Count.ToString);
      //FLogger.Log('LoadedBuyOrders count: ' + LoadedBuyOrders.Count.ToString);
      LoadSuccess := True;
    except
      on E: Exception do
        LoadErrorMsg := E.Message;
    end;
    // 3. Merge to master lists and indexes on the main thread for safety
    TThread.Queue(nil, procedure
    var
      TypeDict: TDictionary<Integer, TList<TMarketOrderRec>>;
      typeIDs: TArray<Integer>;
      typeStrArr: TArray<string>;
      typeListStr: string;
      i: Integer;
    begin
      try
        if LoadSuccess then
        begin
          // Merge results: safest to clear and re-add (optional, per your app logic)
          for var order in LoadedBuyOrders do
            UniverseBuyOrders.AddOrSetValue(order.order_id, order);
          for var order in LoadedSellOrders do
            UniverseSellOrders.AddOrSetValue(order.order_id, order);
          // Update metadata
          RegionInfo.RegionID := RegionID;
          RegionInfo.LastLoaded := Now;
          RegionInfo.CacheAge := 0;
          FLoadedRegions.AddOrSetValue(RegionID, RegionInfo);

          BuildOrderIndexes;

          // --- Debug: Log type indexes for this region (SELL) ---
          typeListStr := '';
          if Assigned(SellOrdersByRegionByType) and SellOrdersByRegionByType.TryGetValue(RegionID, TypeDict) then
          begin
            typeIDs := TypeDict.Keys.ToArray;
            SetLength(typeStrArr, Length(typeIDs));
            for i := 0 to High(typeIDs) do
              typeStrArr[i] := typeIDs[i].ToString;
            typeListStr := 'Sell types: ' + String.Join(',', typeStrArr);
          end
          else
            FLogger.Log('Region ' + RegionID.ToString + ' SellOrdersByRegionByType: NO ENTRY');

          // --- Debug: Log type indexes for this region (BUY) ---
          typeListStr := '';
          if Assigned(BuyOrdersByRegionByType) and BuyOrdersByRegionByType.TryGetValue(RegionID, TypeDict) then
          begin
            typeIDs := TypeDict.Keys.ToArray;
            SetLength(typeStrArr, Length(typeIDs));
            for i := 0 to High(typeIDs) do
              typeStrArr[i] := typeIDs[i].ToString;
            typeListStr := 'Buy types: ' + String.Join(',', typeStrArr);
          end
          else
            FLogger.Log('Region ' + RegionID.ToString + ' BuyOrdersByRegionByType: NO ENTRY');

        end
        else
          FLogger.Log('Error loading region ' + RegionID.ToString + ': ' + LoadErrorMsg);
      finally
        LoadedBuyOrders.Free;
        LoadedSellOrders.Free;
        FIsRegionLoading := False;
        InternalRegionLoadComplete;
      end;
    end);
  end);
end;




procedure TRegionManager.FireOnLoadComplete;
begin
  FIsRegionLoading := False;
  UpdateStatus('All requested regions processed.');
  BuildOrderIndexes;
  if Assigned(FOnLoadComplete) then
    TThread.Queue(nil, FOnLoadComplete);
end;

procedure TRegionManager.UpdateStatus(const Msg: string);
begin
  FLogger.Status(Msg);
end;

procedure TRegionManager.InternalRegionLoadComplete;
begin
  // This is only called after one region task finishes (success/fail)
  ProcessNextRegionInQueue;
end;

function TRegionManager.IsRegionLoaded(RegionID: Integer): Boolean;
begin
  Result := (FLoadedRegions <> nil) and FLoadedRegions.ContainsKey(RegionID);
end;

{$ENDREGION}


function TRegionManager.GetJumpsBetween(SystemA, SystemB: Integer): Integer;
var
  Queue: TQueue<Integer>;
  Visited: TDictionary<Integer, Integer>; // systemID -> distance
  Current, Neighbor: Integer;
begin
  Result := -1; // -1 means unreachable or invalid
  if not FParser.FSystemJumps.ContainsKey(SystemA) or
     not FParser.FSystemJumps.ContainsKey(SystemB) then
    Exit;

  if SystemA = SystemB then
  begin
    Result := 0;
    Exit;
  end;

  Queue := TQueue<Integer>.Create;
  Visited := TDictionary<Integer, Integer>.Create;
  try
    Queue.Enqueue(SystemA);
    Visited.Add(SystemA, 0);

    while Queue.Count > 0 do
    begin
      Current := Queue.Dequeue;
      for Neighbor in FParser.FSystemJumps[Current] do
      begin
        if not Visited.ContainsKey(Neighbor) then
        begin
          Visited.Add(Neighbor, Visited[Current] + 1);

          if Neighbor = SystemB then
          begin
            Result := Visited[Neighbor];
            Exit; // Found shortest path
          end;

          Queue.Enqueue(Neighbor);
        end;
      end;
    end;
  finally
    Queue.Free;
    Visited.Free;
  end;
end;

function TRegionManager.GetJumpsBetweenFast(SystemA, SystemB: Integer): Integer;
var
  Inner: TDictionary<Integer, Integer>;
begin
  Result := -1;
  if Assigned(FParser.FAllPairsJumps) then
    if FParser.FAllPairsJumps.TryGetValue(SystemA, Inner) then
      if Inner.TryGetValue(SystemB, Result) then
        Exit;
  // If not found in matrix, optionally fall back to slow BFS (or just return -1)
  Result := GetJumpsBetween(SystemA, SystemB);
end;


function TRegionManager.GetJumpRoute(SystemA, SystemB: Integer; MinSecurity, MaxSecurity: Double): TJumpRoute;
var
  Queue: TQueue<Integer>;
  CameFrom: TDictionary<Integer, Integer>;
  Current, Neighbor: Integer;
  Rec: TSystemsRec;
  Path: TList<Integer>;
  RouteMinSecurity, RouteMaxSecurity: Double;
  Neighbors: TArray<Integer>;
begin
  Result.SystemIDs := [];
  Result.MinSecurity := MaxDouble;
  Result.MaxSecurity := -1.0;

  if (not Self.SystemIDExists(SystemA)) or (not Self.SystemIDExists(SystemB)) then
    Exit;

  // Optional: Remove this block if you want paths between endpoints outside security range,
  // but only allow travel through valid systems
  if (MinSecurity >= 0) and (MaxSecurity >= 0) then
  begin
    if (Self.SystemSecurity(SystemA) < MinSecurity) or (Self.SystemSecurity(SystemA) > MaxSecurity)
      or (Self.SystemSecurity(SystemB) < MinSecurity) or (Self.SystemSecurity(SystemB) > MaxSecurity) then
      Exit;
  end;

  if SystemA = SystemB then
  begin
    Result.SystemIDs := [SystemA];
    Result.MinSecurity := Self.SystemSecurity(SystemA);
    Result.MaxSecurity := Self.SystemSecurity(SystemA);
    Exit;
  end;

  Queue := TQueue<Integer>.Create;
  CameFrom := TDictionary<Integer, Integer>.Create;
  try
    Queue.Enqueue(SystemA);
    CameFrom.Add(SystemA, -1);

    while Queue.Count > 0 do
    begin
      Current := Queue.Dequeue;
      Neighbors := Self.SystemJumps(Current);
      for Neighbor in Neighbors do
      begin
        if not CameFrom.ContainsKey(Neighbor) then
        begin
          if (MinSecurity < 0) or (MaxSecurity < 0)
              or ((Self.SystemSecurity(Neighbor) >= MinSecurity) and (Self.SystemSecurity(Neighbor) <= MaxSecurity)) then
          begin
            CameFrom.Add(Neighbor, Current);
            if Neighbor = SystemB then
            begin
              Path := TList<Integer>.Create;
              var Step := Neighbor;
              while Step <> -1 do
              begin
                Path.Insert(0, Step);
                Step := CameFrom[Step];
              end;
              RouteMinSecurity := MaxDouble;
              RouteMaxSecurity := -1.0;
              for var SysID in Path do
              begin
                Rec := Self.SystemIDToRec(SysID);
                if Rec.security < RouteMinSecurity then
                  RouteMinSecurity := Rec.security;
                if Rec.security > RouteMaxSecurity then
                  RouteMaxSecurity := Rec.security;
              end;
              Result.SystemIDs := Path.ToArray;
              Result.MinSecurity := RouteMinSecurity;
              Result.MaxSecurity := RouteMaxSecurity;
              Path.Free;
              Exit;
            end;
            Queue.Enqueue(Neighbor);
          end;
        end;
      end;
    end;
  finally
    Queue.Free;
    CameFrom.Free;
  end;
end;



procedure TRegionManager.UpdateTypesForID(typeID: Integer);
var
  Rec: TTypesRec;
begin
  FESIClient.FetchTypeInfo(typeID, Rec);
  FParser.FTypes.AddOrSetValue(typeID, Rec);
  FParser.UpdateType(Rec);
end;





function TRegionManager.SellOrdersByRegion: TDictionary<Integer, TDictionary<Int64, TMarketOrderRec>>;
begin
  Result := UniverseSellOrdersByRegion;
end;

function TRegionManager.BuyOrdersByStationAndType(StationID, TypeID: Integer): TList<TMarketOrderRec>;
var
  RegionID: Integer;
  StationBuyOrders: TList<TMarketOrderRec>;
begin
  Result := nil;
  RegionID := StationIDToRegionID(StationID);
  StationBuyOrders := BuyOrdersByRegionAndType(RegionID, TypeID);
  if Assigned(StationBuyOrders) then
  begin
    Result := TList<TMarketOrderRec>.Create;
    for var Order in StationBuyOrders do
      if Order.station_id = StationID then
        Result.Add(Order);
    if Result.Count = 0 then
    begin
      Result.Free;
      Result := nil;
    end;
  end;
end;

function TRegionManager.BuyOrdersByRegionAndType(RegionID, TypeID: Integer): TList<TMarketOrderRec>;
var
  TypeDict: TDictionary<Integer, TList<TMarketOrderRec>>;
begin
  Result := nil;
  if Assigned(BuyOrdersByRegionByType) then
    if BuyOrdersByRegionByType.TryGetValue(RegionID, TypeDict) then
      TypeDict.TryGetValue(TypeID, Result);
end;

function TRegionManager.BuyOrdersBySystemAndType(SystemID, TypeID: Integer): TList<TMarketOrderRec>;
var
  RegionID: Integer;
  OrdersByRegionType: TList<TMarketOrderRec>;
  StationIDs: TList<Int64>;
begin
  Result := nil;
  RegionID := SystemIDToRegionID(SystemID);
  OrdersByRegionType := BuyOrdersByRegionAndType(RegionID, TypeID);
  if Assigned(OrdersByRegionType) then
  begin
    Result := TList<TMarketOrderRec>.Create;
    StationIDs := StationsInSystem(SystemID);
    for var Order in OrdersByRegionType do
      if StationIDs.Contains(Order.station_id) then
        Result.Add(Order);
    if Result.Count = 0 then
    begin
      Result.Free;
      Result := nil;
    end;
  end;
end;

function TRegionManager.BuyOrdersByRegion: TDictionary<Integer, TDictionary<Int64, TMarketOrderRec>>;
begin
  Result := UniverseBuyOrdersByRegion;
end;

function TRegionManager.SellOrdersByStationAndType(StationID, TypeID: Integer): TList<TMarketOrderRec>;
var
  RegionID: Integer;
  StationSellOrders: TList<TMarketOrderRec>;
begin
  Result := nil;
  RegionID := StationIDToRegionID(StationID);
  StationSellOrders := SellOrdersByRegionAndType(RegionID, TypeID);
  if Assigned(StationSellOrders) then
  begin
    Result := TList<TMarketOrderRec>.Create;
    for var Order in StationSellOrders do
      if Order.station_id = StationID then
        Result.Add(Order);
    if Result.Count = 0 then
    begin
      Result.Free;
      Result := nil;
    end;
  end;
end;

function TRegionManager.SellOrdersByRegionAndType(RegionID, TypeID: Integer): TList<TMarketOrderRec>;
var
  TypeDict: TDictionary<Integer, TList<TMarketOrderRec>>;
begin
  Result := nil;
  if Assigned(SellOrdersByRegionByType) and
     SellOrdersByRegionByType.TryGetValue(RegionID, TypeDict) then
    TypeDict.TryGetValue(TypeID, Result);
end;


function TRegionManager.SellOrdersBySystemAndType(SystemID, TypeID: Integer): TList<TMarketOrderRec>;
var
  RegionID: Integer;
  OrdersByRegionType: TList<TMarketOrderRec>;
  StationIDs: TList<Int64>;
begin
  Result := nil;
  RegionID := SystemIDToRegionID(SystemID);
  OrdersByRegionType := SellOrdersByRegionAndType(RegionID, TypeID);
  if Assigned(OrdersByRegionType) then
  begin
    Result := TList<TMarketOrderRec>.Create;
    StationIDs := StationsInSystem(SystemID);
    for var Order in OrdersByRegionType do
      if StationIDs.Contains(Order.station_id) then
        Result.Add(Order);
    if Result.Count = 0 then
    begin
      Result.Free;
      Result := nil;
    end;
  end;
end;

function TRegionManager.MarketGroups: TDictionary<string, TMarketGroupRec>;
begin
  Result := FParser.FMarketGroups;
end;

function TRegionManager.TryGetMarketGroup(const MarketGroupID: string; out Group: TMarketGroupRec): Boolean;
begin
  Result := FParser.FMarketGroups.TryGetValue(MarketGroupID, Group);
end;

function TRegionManager.TryGetParentToChildren(const MarketGroupID: string; out ChildList: TList<string>): Boolean;
begin
  Result := FParser.FParentToChildren.TryGetValue(MarketGroupID, ChildList);
end;

function TRegionManager.GetAllSystemsInRegion(RegionID: Integer): TArray<Integer>;
var
  SystemsList: TList<Integer>;
begin
  if (Assigned(FParser.FRegionToSolarSystemIDs)) and
     (FParser.FRegionToSolarSystemIDs.TryGetValue(RegionID, SystemsList)) and
     (SystemsList.Count > 0) then
    Result := SystemsList.ToArray
  else
    Result := [];
end;

function TRegionManager.GetClosestSystemInRegion(StartSystemID, RegionID: Integer; MinSecurity, MaxSecurity: Double): TJumpRoute;
var
  SystemsList: TList<Integer>;
  ClosestSysID: Integer;
  FewestJumps: Integer;
  SysID: Integer;
  CandidateRoute, BestRoute: TJumpRoute;
begin
  ClosestSysID := -1;
  FewestJumps := MaxInt;
  // Initialize BestRoute to empty/default
  BestRoute.SystemIDs := nil;
  BestRoute.DestinationSystemID := -1;
  BestRoute.JumpsFromDest := -1;
  if Assigned(FParser.FRegionToSolarSystemIDs) and
    FParser.FRegionToSolarSystemIDs.TryGetValue(RegionID, SystemsList) and
    (SystemsList.Count > 0) then
  begin
    for SysID in SystemsList do
    begin
      if SysID = StartSystemID then
      begin
        // Same system, always shortest
        BestRoute := GetJumpRoute(StartSystemID, SysID, MinSecurity, MaxSecurity);
        BestRoute.DestinationSystemID := SysID;
        BestRoute.JumpsFromDest := 0; // No jumps needed
        Result := BestRoute;
        Exit;
      end;
      CandidateRoute := GetJumpRoute(StartSystemID, SysID, MinSecurity, MaxSecurity);
      if (Length(CandidateRoute.SystemIDs) > 0) and (Length(CandidateRoute.SystemIDs) < FewestJumps) then
      begin
        ClosestSysID := SysID;
        FewestJumps := Length(CandidateRoute.SystemIDs);
        BestRoute := CandidateRoute;
        BestRoute.DestinationSystemID := SysID;
        // Set jumps from delivery/destination to the ultimate system (here: target system)
        // Assumes you want jumps from ClosestSysID to the final destination (e.g., the buy system)
        // If that's StartSystemID, this will be >0; adjust as needed for your context.
        BestRoute.JumpsFromDest := GetJumpsBetweenFast(SysID, StartSystemID);
      end;
    end;
    // If we found at least one viable route, return it
    if FewestJumps < MaxInt then
    begin
      Result := BestRoute;
      Exit;
    end;
  end;
  // If no system found, return default/empty route with -1
  BestRoute.DestinationSystemID := ClosestSysID;
  BestRoute.JumpsFromDest := -1;
  Result := BestRoute;
end;


function TRegionManager.GetClosestSystemWithinJumps(StartSystemID, BuySystemID, MaxJumps: Integer; MinSecurity, MaxSecurity: Double): Integer;
var
  FewestJumpsFromStart: Integer;
  CandidateSystemID, ClosestSystemID: Integer;
  RouteToBuy, RouteFromStart: TJumpRoute;
begin
  ClosestSystemID := -1;
  FewestJumpsFromStart := MaxInt;

  for CandidateSystemID in AllSystemIDs do
  begin
    // Check if within MaxJumps from buy system
    RouteToBuy := GetJumpRoute(CandidateSystemID, BuySystemID, MinSecurity, MaxSecurity);
    if (Length(RouteToBuy.SystemIDs) - 1 <= MaxJumps) and (Length(RouteToBuy.SystemIDs) > 0) then
    begin
      // Now check distance from start system to candidate
      RouteFromStart := GetJumpRoute(StartSystemID, CandidateSystemID, MinSecurity, MaxSecurity);
      if (Length(RouteFromStart.SystemIDs) > 0) and ((Length(RouteFromStart.SystemIDs) - 1) < FewestJumpsFromStart) then
      begin
        FewestJumpsFromStart := Length(RouteFromStart.SystemIDs) - 1;
        ClosestSystemID := CandidateSystemID;
      end;
    end;
  end;

  Result := ClosestSystemID;
end;



    ////////////////////////
    // PARSER REGION GETS //
    ////////////////////////

function TRegionManager.RegionCount: Integer;
begin
  Result := FParser.FRegions.Count;
end;

function TRegionManager.RegionIndexToRec(Index: Integer): TRegionsRec;
var
  Arr: TArray<TRegionsRec>;
begin
  Arr := FParser.FRegions.Values.ToArray;
  if (Index >= 0) and (Index < Length(Arr)) then
    Result := Arr[Index]
  else
    FillChar(Result, SizeOf(Result), 0);
end;

function TRegionManager.RegionIDToName(RegionID: Integer): string;
var
  RegionRec: TRegionsRec;
begin
  if FParser.FRegions.TryGetValue(RegionID, RegionRec) then
    Result := RegionRec.regionName
  else
    Result := '';
end;

function TRegionManager.RegionNameToID(const RegionName: string): Integer;
var
  Rec: TRegionsRec;
begin
  Result := 0;
  for Rec in FParser.FRegions.Values do
    if SameText(Rec.regionName, RegionName) then
      Exit(Rec.regionID);
end;


    ////////////////////////
    // PARSER SYSTEM GETS //
    ////////////////////////

function TRegionManager.SystemCount: Integer;
begin
  Result := FParser.FSystems.Count;
end;

function TRegionManager.AllSystemIDs: TArray<Integer>;
var
  i: Integer;
begin
  SetLength(Result, SystemCount);
  for i := 0 to SystemCount-1 do
    Result[i] := SystemIndexToRec(i).systemID;
end;

function TRegionManager.FirstStationInSystem(SystemID: Integer): Integer;
begin
  if SystemHasStation(SystemID) then
    Result := StationsInSystem(SystemID)[0] // Return the first station ID
  else
    Result := -1;
end;

function TRegionManager.SystemHasStation(SystemID: Integer): Boolean;
begin
  // Returns true if there is at least one station in the system
  Result := FParser.FSystemToStations.ContainsKey(SystemID) and (FParser.FSystemToStations[SystemID].Count > 0);
end;

function TRegionManager.StationsInSystem(SystemID: Integer): TList<Int64>;
begin
  // Returns a reference to the list of station IDs for the system, or nil if none present
  if FParser.FSystemToStations.ContainsKey(SystemID) then
    Result := FParser.FSystemToStations[SystemID]
  else
    Result := nil;
end;

procedure TRegionManager.SystemsWithinJumpsOf(StartSystemID, MaxJumps: Integer; out SystemsArr: TArray<Integer>; out DistanceMap: TDictionary<Integer, Integer>);
var
  Queue: TQueue<Integer>;
  Visited: TDictionary<Integer, Integer>;
  Current, Neighbor, JumpsHere: Integer;
  NeighborsArr: TArray<Integer>;
  ResultList: TList<Integer>;
begin
  ResultList := TList<Integer>.Create;
  DistanceMap := TDictionary<Integer, Integer>.Create;
  Queue := TQueue<Integer>.Create;
  Visited := TDictionary<Integer, Integer>.Create;
  try
    Queue.Enqueue(StartSystemID);
    Visited.Add(StartSystemID, 0);
    while Queue.Count > 0 do
    begin
      Current := Queue.Dequeue;
      JumpsHere := Visited[Current];
      if JumpsHere > MaxJumps then
        Continue;
      ResultList.Add(Current);
      DistanceMap.AddOrSetValue(Current, JumpsHere);
      if FParser.FSystemJumps.TryGetValue(Current, NeighborsArr) then
      begin
        for Neighbor in NeighborsArr do
        begin
          if not Visited.ContainsKey(Neighbor) then
          begin
            Visited.Add(Neighbor, JumpsHere + 1);
            Queue.Enqueue(Neighbor);
          end;
        end;
      end;
    end;
    SystemsArr := ResultList.ToArray;
  finally
    ResultList.Free;
    Queue.Free;
    Visited.Free;
  end;
end;


function TRegionManager.SystemsInRegion(RegionID: Integer): TArray<Integer>;
var
  SystemsList: TList<Integer>;
begin
  if Assigned(FParser.FRegionToSolarSystemIDs)
    and FParser.FRegionToSolarSystemIDs.TryGetValue(RegionID, SystemsList)
    and (SystemsList.Count > 0) then
    Result := SystemsList.ToArray
  else
    Result := [];
end;

function TRegionManager.SystemIndexToRec(Index: Integer): TSystemsRec;
var
  Arr: TArray<TSystemsRec>;
begin
  Arr := FParser.FSystems.Values.ToArray;
  if (Index >= 0) and (Index < Length(Arr)) then
    Result := Arr[Index]
  else
    FillChar(Result, SizeOf(Result), 0);
end;

function TRegionManager.SystemIDToName(SystemID: Integer): string;
var
  SystemRec: TSystemsRec;
begin
  if FParser.FSystems.TryGetValue(SystemID, SystemRec) then
    Result := SystemRec.systemName
  else
    Result := '';
end;

function TRegionManager.SystemIDToRegionID(SystemID: Integer): Integer;
var
  SystemRec: TSystemsRec;
begin
  if FParser.FSystems.TryGetValue(SystemID, SystemRec) then
    Result := SystemRec.regionID
  else
    Result := 0;
end;

function TRegionManager.SystemIDToRegionName(SystemID: Integer): string;
var
  SystemRec: TSystemsRec;
begin
  if FParser.FSystems.TryGetValue(SystemID, SystemRec) then
    Result := RegionIDToName(SystemRec.regionID)
  else
    Result := '';
end;

function TRegionManager.SystemSecurity(SystemID: Integer): Double;
var
  SystemRec: TSystemsRec;
begin
  if FParser.FSystems.TryGetValue(SystemID, SystemRec) then
    Result := SystemRec.security
  else
    Result := 0.0;
end;

function TRegionManager.SystemIDToRec(SystemID: Integer): TSystemsRec;
begin
  if FParser.FSystems.TryGetValue(SystemID, Result) then
    // Found, return value
  else
    FillChar(Result, SizeOf(Result), 0);
end;

function TRegionManager.SystemNameToID(const SystemName: string): Integer;
var
  Rec: TSystemsRec;
begin
  Result := 0;
  for Rec in FParser.FSystems.Values do
    if SameText(Rec.systemName, SystemName) then
      Exit(Rec.systemID);
end;

function TRegionManager.SystemIDExists(SystemID: Integer): Boolean;
begin
  Result := FParser.FSystems.ContainsKey(SystemID);
end;

function TRegionManager.SystemJumps(SystemID: Integer): TArray<Integer>;
begin
  if not FParser.FSystemJumps.TryGetValue(SystemID, Result) then
    Result := [];
end;

    /////////////////////////
    // PARSER STATION GETS //
    /////////////////////////

function TRegionManager.StationCount: Integer;
begin
  Result := FParser.FStations.Count;
end;

function TRegionManager.StationIndexToRec(Index: Integer): TStationsRec;
var
  Arr: TArray<TStationsRec>;
begin
  Arr := FParser.FStations.Values.ToArray;
  if (Index >= 0) and (Index < Length(Arr)) then
    Result := Arr[Index]
  else
    FillChar(Result, SizeOf(Result), 0);
end;

function TRegionManager.StationIDToName(StationID: Int64): string;
var
  StationRec: TStationsRec;
begin
  if FParser.FStations.TryGetValue(StationID, StationRec) then
    Result := StationRec.stationName
  else if StationID > 1000000000 then
    Result := 'Upwell Citadel'
  else
    Result := 'Unknown Station';
end;


function TRegionManager.StationIDToRegionID(StationID: Int64): Integer;
var
  StationRec: TStationsRec;
begin
  if FParser.FStations.TryGetValue(StationID, StationRec) then
    Result := StationRec.regionID
  else
    Result := 0;
end;

function TRegionManager.StationIDToRegionName(StationID: Int64): string;
var
  StationRec: TStationsRec;
begin
  if FParser.FStations.TryGetValue(StationID, StationRec) then
    Result := RegionIDToName(StationRec.regionID)
  else
    Result := '';
end;

function TRegionManager.StationIDToSecurity(StationID: Int64): Double;
var
  StationRec: TStationsRec;
begin
  if FParser.FStations.TryGetValue(StationID, StationRec) then
    Result := StationRec.security
  else
    Result := 0.0;
end;

function TRegionManager.StationNameToID(const StationName: string): Integer;
var
  Rec: TStationsRec;
begin
  Result := 0;
  for Rec in FParser.FStations.Values do
    if SameText(Rec.stationName, StationName) then
      Exit(Rec.stationID);
end;


    //////////////////////
    // PARSER TYPE GETS //
    //////////////////////

function TRegionManager.MarketGroupBreadcrumb(TypeID: Integer): string;
var
  TypesRec: TTypesRec;
  MgID: string;
  Path: TStringList;
  MgRec: TMarketGroupRec;
  I: Integer;
begin
  Result := '';
  if not FParser.FTypes.TryGetValue(TypeID, TypesRec) then
    Exit;
  MgID := TypesRec.marketGroupID;
  Path := TStringList.Create;
  try
    // Build the parent chain
    while (MgID <> '') and (MgID <> 'None') do
    begin
      if FParser.FMarketGroups.TryGetValue(MgID, MgRec) then
      begin
        Path.Insert(0, MgRec.marketGroupName); // Prepend for correct order
        MgID := MgRec.parentGroupID;
      end
      else
        Break;
    end;
    Result := '';
    for I := 0 to Path.Count-1 do
    begin
      if I > 0 then
        Result := Result + ' / ';
      Result := Result + Path[I];
    end;
  finally
    Path.Free;
  end;
end;

function TRegionManager.TypeIDExists(typeID: Integer): Boolean;
begin
  Result := FParser.FTypes.ContainsKey(typeID);
end;

function TRegionManager.GetBuyTypeIndex: TDictionary<Integer, TList<TMarketOrderRec>>;
begin
  Result := BuyTypeIndex;
end;

function TRegionManager.GetSellTypeIndex: TDictionary<Integer, TList<TMarketOrderRec>>;
begin
  Result := SellTypeIndex;
end;

function TRegionManager.TypeCount: Integer;
begin
  Result := FParser.FTypes.Count;
end;

function TRegionManager.TypeIndexToRec(Index: Integer): TTypesRec;
var
  Arr: TArray<TTypesRec>;
begin
  Arr := FParser.FTypes.Values.ToArray;
  if (Index >= 0) and (Index < Length(Arr)) then
    Result := Arr[Index]
  else
    FillChar(Result, SizeOf(Result), 0);
end;

function TRegionManager.TypeIndexToID(Index: Integer): Integer;
begin
  Result := TypeIndexToRec(Index).typeID;
end;

function TRegionManager.TypeIDToVolume(TypeID: Integer): Double;
var
  rec: TTypesRec;
begin
  // Default to 0 if not found
  if FParser.FTypes.TryGetValue(TypeID, rec) then
    Result := rec.volume
  else
    Result := 0.0;
end;

function TRegionManager.TypeIDToName(TypeID: Integer): string;
var
  rec: TTypesRec;
begin
  // Default to empty string if not found
  if FParser.FTypes.TryGetValue(TypeID, rec) then
    Result := rec.typeName
  else
    Result := '';
end;

function TRegionManager.TypeIDToDescription(TypeID: Integer): string;
var
  rec: TTypesRec;
begin
  // Default to empty string if not found
  if FParser.FTypes.TryGetValue(TypeID, rec) then
    Result := rec.description
  else
    Result := '';
end;

function TRegionManager.TypeIDToMarketGroupID(TypeID: Integer): string;
begin
  Result := TypeIDToRec(TypeID).marketGroupID;
end;

function TRegionManager.TypeIDToRec(TypeID: Integer): TTypesRec;
begin
  if FParser.FTypes.ContainsKey(TypeID) then
    Result := FParser.FTypes.Items[TypeID]
  else
    FillChar(Result, SizeOf(Result), 0);
end;

function TRegionManager.TypeNameToID(const TypeName: string): Integer;
var
  Item: TTypesRec;
begin
  Result := 0;
  for Item in FParser.FTypes.Values do
    if SameText(Item.typeName, TypeName) then
      Exit(Item.typeID);
end;

function TRegionManager.MarketGroupIDToTypes(const MarketGroupID: string): TArray<TTypesRec>;
var
  Item: TTypesRec;
  ResultList: TList<TTypesRec>;
begin
  ResultList := TList<TTypesRec>.Create;
  try
    for Item in FParser.FTypes.Values do
      if Item.marketGroupID = MarketGroupID then
        ResultList.Add(Item);
    Result := ResultList.ToArray;
  finally
    ResultList.Free;
  end;
end;


end.


