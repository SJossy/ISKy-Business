unit OrderAnalyzer;

interface

uses
  Vcl.Graphics, System.Generics.Defaults, Winapi.Windows, System.StrUtils, Threading, System.SysUtils, System.Generics.Collections,
  System.Types, System.Math, Vcl.Grids, System.Classes, System.Diagnostics, System.Variants,
  Common, Logger, Parser, RegionManager;

type
   TEndpointScope = (esStation, esSystem, esRegion);
   TOrderAnalyzer = class
  private
    FParser: TParser;
    FRegionManager: TRegionManager;
    FAvailableISK: Double;
    FMinProfit: Double;
    FMinROI: Double;
    FAccountingLevel: Integer;
    FCargoCapacity: Double;
    FMaxJumps: Integer;
    FMinSec: Double;
    FMaxSec: Double;
    FRequireDirectDelivery: Boolean;
    FSourceRegions: TArray<Integer>;
    FDestRegions: TArray<Integer>;
    FSelectedTypeIDs: TArray<Integer>;
    FStationType: Boolean;
    FAnalyzerResults: TList<TOrderTripResult>;
    FLogger: TLogger;
   // function ArrayContains(const Arr: TArray<Integer>; Value: Integer): Boolean;
  public
    CellColors: array of array of TColor;
    constructor Create(aParser: TParser; aRegionManager: TRegionManager; aLogger: TLogger);
    property AnalyzerResults: TList<TOrderTripResult> read FAnalyzerResults;
    destructor Destroy; override;
    procedure SetAvailableISK(Value: Double);
    procedure SetMinROI(Value: Double);
    procedure SetMinProfit(Value: Double);
    procedure SetCargoCapacity(Value: Double);
    procedure SetMaxJumps(Value: Integer);
    procedure SetAccountingLevel(Value: Integer);
    procedure SetMinSec(Value: Double);
    procedure SetMaxSec(Value: Double);
    procedure SetSourceRegions(const Regions: TArray<Integer>);
    procedure SetDestRegions(const Regions: TArray<Integer>);
    procedure SetSelectedTypeIDs(const TypeIDs: TArray<Integer>);
    procedure SetStationType(Value: Boolean);
    procedure RequireDirect(Value: Boolean);
    procedure OutputResultsToGrid(Grid: TStringGrid; SortCol: Integer);
    procedure FindProfitableTrips(Grid: TStringGrid);
  end;

implementation

constructor TOrderAnalyzer.Create(aParser: TParser; aRegionManager: TRegionManager; aLogger: TLogger);
begin
  FParser := aParser;
  FLogger := aLogger;
  FRegionManager := aRegionManager;
  FAvailableISK := 1.0E12;
  FAccountingLevel := 0;
  FMinProfit := 0;
  FCargoCapacity := 1.0E8;
  FMinROI := 0.25;
  FMaxJumps := 30;
  FMinSec := 0.0;
  FMaxSec := 1.0;
  FSourceRegions := [];
  FDestRegions := [];
  FSelectedTypeIDs := [];
end;
destructor TOrderAnalyzer.Destroy;
begin
  if Assigned(FAnalyzerResults) then
    FAnalyzerResults.Free;
  inherited;
end;

procedure TOrderAnalyzer.SetAvailableISK(Value: Double);                      begin FAvailableISK := Value; end;
procedure TOrderAnalyzer.SetMinProfit(Value: Double);                         begin FMinProfit := Value; end;
procedure TOrderAnalyzer.SetMinROI(Value: Double);                            begin FMinROI := Value; end;
procedure TOrderAnalyzer.SetCargoCapacity(Value: Double);                     begin FCargoCapacity := Value; end;
procedure TOrderAnalyzer.SetMaxJumps(Value: Integer);                         begin FMaxJumps := Value; end;
procedure TOrderAnalyzer.SetAccountingLevel(Value: Integer);                  begin FAccountingLevel := Value; end;
procedure TOrderAnalyzer.SetMinSec(Value: Double);                            begin FMinSec := Value; end;
procedure TOrderAnalyzer.SetMaxSec(Value: Double);                            begin FMaxSec := Value; end;
procedure TOrderAnalyzer.SetSourceRegions(const Regions: TArray<Integer>);    begin FSourceRegions := Regions; end;
procedure TOrderAnalyzer.SetDestRegions(const Regions: TArray<Integer>);      begin FDestRegions := Regions; end;
procedure TOrderAnalyzer.SetSelectedTypeIDs(const TypeIDs: TArray<Integer>);  begin FSelectedTypeIDs := TypeIDs; end;
procedure TOrderAnalyzer.SetStationType(Value: Boolean);                      begin FStationType := Value; end;
procedure TOrderAnalyzer.RequireDirect(Value: Boolean);                       begin FRequireDirectDelivery := Value; end;

function FmtFloat(Value: Double; Decimals: Integer = 0): string;
begin
  Result := FormatFloat('#,##0.' + DupeString('0', Decimals), Value);
end;

function FmtInt(Value: Integer): string;
begin
  Result := FormatFloat('#,##0', Value * 1.0); // force as Double!
end;

function CalcSalesTax(AccountingLevel: Integer): Double;
begin
  Result := 0.075 * (1 - 0.11 * AccountingLevel);
  if Result < 0.036 then
    Result := 0.036;
end;

function CalcWeightedAvgPrice(OrderList: TList<TMarketOrderRec>): Double;
var
  i: Integer;
  WeightedSum, TotalQty: Double;
begin
  WeightedSum := 0;
  TotalQty := 0;
  for i := 0 to OrderList.Count-1 do
  begin
    WeightedSum := WeightedSum + (OrderList[i].price * OrderList[i].volume_remain);
    TotalQty := TotalQty + OrderList[i].volume_remain;
  end;
  if TotalQty > 0 then
    Result := WeightedSum / TotalQty
  else
    Result := 0;
end;

function IntArrayToString(const Arr: TArray<Integer>): string;
var
  SL: TStringList;
  I: Integer;
begin
  SL := TStringList.Create;
  try
    for I in Arr do
      SL.Add(IntToStr(I));
    Result := SL.CommaText;
  finally
    SL.Free;
  end;
end;

procedure TOrderAnalyzer.FindProfitableTrips(Grid: TStringGrid);
var
  TypeID, SourceRegionID, DestRegionID: Integer;
  SellList, BuyList: TList<TMarketOrderRec>;
  SellOrder, BestSellOrder: TMarketOrderRec;
  BuyOrder, BestBuyOrder: TMarketOrderRec;
  ROI, Vol, VolumeM3, MaxVolumeByISK, MaxVolumeByCargo, RealVol, MaxRealVol, SalesTax: Double;
  GrossProfit, SalesTaxCost, NetProfit, SourceSecurity, DestSecurity: Double;
  skipTypeStr, BuyerRange, SourceRegionName, DestRegionName, SourceStationName, DestStationName, DeliveryStationName: string;
  i, NumericBuyRange, DestSystemID, DeliverySystemID, Jumps, BuyOrderJumps: Integer;
  DeliveryStationID: Int64;
  TotalPairs, SkippedPairs, ProfitableCount, SkippedReasonNoOrders, SkippedReasonNoName, SkippedReasonBadStations, SkippedReasonNotProfitable, SkippedReasonBadJumps: Integer;
  SW: TStopWatch;
  SkippedNoNameTypeIDs: TDictionary<Integer, Boolean>;
  SkippedIDsArr: TArray<Integer>;
  SkippedIDStrArr: TArray<string>;
  SourceTypeDict, DestTypeDict: TDictionary<Integer, TList<TMarketOrderRec>>;
  CandidateSystems: TArray<Integer>;
  DistanceMap: TDictionary<Integer, Integer>;
  Route: TJumpRoute;
  MinSourceJumps, BestBuyOrderJumps: Integer;
  OrderResult: TOrderTripResult;
  TotalPrice: Double;
  MinPrice, MaxPrice: Double;

begin
  SW := TStopWatch.StartNew;
  FLogger.Log('--- Indexed Order Analysis Start ---');
  SalesTax := CalcSalesTax(FAccountingLevel);
  if Assigned(FAnalyzerResults) then
    FAnalyzerResults.Free;
  FAnalyzerResults := TList<TOrderTripResult>.Create;
  SkippedNoNameTypeIDs := TDictionary<Integer, Boolean>.Create;
  // Reset stats
  TotalPairs := 0; ProfitableCount := 0;
  SkippedPairs := 0; SkippedReasonNoName := 0; SkippedReasonNoOrders := 0;
  SkippedReasonBadStations := 0; SkippedReasonNotProfitable := 0; SkippedReasonBadJumps := 0;

  for SourceRegionID in FSourceRegions do
  begin
    if FRegionManager.SellOrdersByRegionByType.TryGetValue(SourceRegionID, SourceTypeDict) then
    begin
      for DestRegionID in FDestRegions do
      begin
        if FRegionManager.BuyOrdersByRegionByType.TryGetValue(DestRegionID, DestTypeDict) then
        begin
          for TypeID in SourceTypeDict.Keys do
          begin
            if (Length(FSelectedTypeIDs) > 0) and (TArray.IndexOf<Integer>(FSelectedTypeIDs, TypeID) = -1) then Continue;
            if not DestTypeDict.ContainsKey(TypeID) then Continue;
            Inc(TotalPairs);
            if FRegionManager.TypeIDToName(TypeID) = '' then
              FRegionManager.UpdateTypesForID(TypeID);

            SellList := FRegionManager.SellOrdersByRegionAndType(SourceRegionID, TypeID);
            if (SellList = nil) or (SellList.Count = 0) then
            begin Inc(SkippedPairs); Inc(SkippedReasonNoOrders); Continue; end;
            BuyList := FRegionManager.BuyOrdersByRegionAndType(DestRegionID, TypeID);
            if (BuyList = nil) or (BuyList.Count = 0) then
            begin Inc(SkippedPairs); Inc(SkippedReasonNoOrders); Continue; end;

            if SellList.Count > 0 then
            begin
              MinPrice := SellList[0].price;
              MaxPrice := SellList[0].price;
              TotalPrice := 0;
              for SellOrder in SellList do
              begin
                if SellOrder.price < MinPrice then MinPrice := SellOrder.price;
                if SellOrder.price > MaxPrice then MaxPrice := SellOrder.price;
                TotalPrice := TotalPrice + SellOrder.price;
              end;
              OrderResult.SellMinPrice := MinPrice;
              OrderResult.SellMaxPrice := MaxPrice;
              OrderResult.SellAvgPrice := TotalPrice / SellList.Count;
              OrderResult.SellWeightedAvg := CalcWeightedAvgPrice(SellList);
            end;

            if BuyList.Count > 0 then
            begin
              MinPrice := BuyList[0].price;
              MaxPrice := BuyList[0].price;
              TotalPrice := 0;
              for BuyOrder in BuyList do
              begin
                if BuyOrder.price < MinPrice then MinPrice := BuyOrder.price;
                if BuyOrder.price > MaxPrice then MaxPrice := BuyOrder.price;
                TotalPrice := TotalPrice + BuyOrder.price;
              end;
              OrderResult.BuyMinPrice := MinPrice;
              OrderResult.BuyMaxPrice := MaxPrice;
              OrderResult.BuyAvgPrice := TotalPrice / BuyList.Count;
              OrderResult.BuyWeightedAvg := CalcWeightedAvgPrice(BuyList);
            end;


            BestSellOrder := SellList[0];
            for SellOrder in SellList do
              if SellOrder.price < BestSellOrder.price then BestSellOrder := SellOrder;
            BestBuyOrder := BuyList[0];
            for BuyOrder in BuyList do
              if BuyOrder.price > BestBuyOrder.price then BestBuyOrder := BuyOrder;
            if BestBuyOrder.price <= BestSellOrder.price then
            begin Inc(SkippedPairs); Inc(SkippedReasonNotProfitable); Continue; end;

            SourceSecurity := FRegionManager.StationIDToSecurity(BestSellOrder.station_id);
            if (SourceSecurity < FMinSec) or (SourceSecurity > FMaxSec) then
            begin Inc(SkippedPairs); Inc(SkippedReasonBadStations); Continue; end;

            Vol := Min(BestBuyOrder.volume_remain, BestSellOrder.volume_remain);
            VolumeM3 := FRegionManager.TypeIDToVolume(TypeID); if VolumeM3 <= 0 then VolumeM3 := 1.0;
            MaxVolumeByISK := FAvailableISK / BestSellOrder.price;
            MaxVolumeByCargo := FCargoCapacity / VolumeM3;
            MaxRealVol := Min(MaxVolumeByISK, MaxVolumeByCargo);
            RealVol := Min(Vol, MaxRealVol);
            if RealVol * VolumeM3 > FCargoCapacity then RealVol := FCargoCapacity / VolumeM3;
            if RealVol < 1 then begin Inc(SkippedPairs); Inc(SkippedReasonNotProfitable); Continue; end;

            GrossProfit := (BestBuyOrder.price - BestSellOrder.price) * RealVol;
            SalesTaxCost := BestBuyOrder.price * RealVol * SalesTax;
            NetProfit := GrossProfit - SalesTaxCost;
            if NetProfit < FMinProfit then begin Inc(SkippedPairs); Inc(SkippedReasonNotProfitable); Continue; end;
            ROI := (NetProfit / (BestSellOrder.price * RealVol) * 100);
            if ROI < FMinROI then begin Inc(SkippedPairs); Inc(SkippedReasonNotProfitable); Continue; end;

            SourceRegionName  := FRegionManager.RegionIDToName(SourceRegionID);
            DestRegionName    := FRegionManager.RegionIDToName(DestRegionID);
            SourceStationName := FRegionManager.StationIDToName(BestSellOrder.station_id);
            DestStationName   := FRegionManager.StationIDToName(BestBuyOrder.station_id);
            DestSystemID      := BestBuyOrder.system_id;

            if (SourceStationName = 'Upwell Citadel') or (DestStationName = 'Upwell Citadel') and not FStationType then begin Inc(SkippedPairs); Inc(SkippedReasonBadStations); Continue; end;
            BuyerRange := BestBuyOrder.range;
            DeliveryStationID := -1; DeliverySystemID := -1; BuyOrderJumps := 0; Jumps := -1;

            // --------------- DELIVERY MATCHING BLOCK ---------------
            if FRequireDirectDelivery or (not (SameText(BuyerRange, 'region') or TryStrToInt(BuyerRange, NumericBuyRange))) then
            begin
              // DIRECT STATION DELIVERY
              DestSystemID := BestBuyOrder.system_id;
              Route := FRegionManager.GetJumpRoute(BestSellOrder.system_id, DestSystemID, FMinSec, FMaxSec);
              if (Length(Route.SystemIDs) = 0) or (Length(Route.SystemIDs) - 1 > FMaxJumps) then
              begin Inc(SkippedPairs); Inc(SkippedReasonBadJumps); Continue; end;
              Jumps := Length(Route.SystemIDs) - 1;
              BuyOrderJumps := 0;
              OrderResult.JumpRoute := Route;
            end
            else if SameText(BuyerRange, 'region') then
            begin
              // REGION DELIVERY
              CandidateSystems := FRegionManager.SystemsInRegion(BestBuyOrder.region_id);
              DistanceMap := TDictionary<Integer,Integer>.Create;
              for var sid in CandidateSystems do DistanceMap.AddOrSetValue(sid, 0);
              MinSourceJumps := MaxInt; BestBuyOrderJumps := 0;
              for var SystemID in CandidateSystems do
              begin
                // 1. Station presence check & get first station
                var Stations := FRegionManager.StationsInSystem(SystemID);
                if not Assigned(Stations) or (Stations.Count = 0) then
                  Continue;

                DeliveryStationID := Stations[0];
                DeliveryStationName := FRegionManager.StationIDToName(DeliveryStationID);

                // 2. Skip Upwell Citadel unless FStationType is true:
                if (DeliveryStationName = 'Upwell Citadel') and not FStationType then
                  Continue;

                Route := FRegionManager.GetJumpRoute(BestSellOrder.system_id, SystemID, FMinSec, FMaxSec);
                if Length(Route.SystemIDs) = 0 then Continue;
                var JumpCount := Length(Route.SystemIDs) - 1;
                if (JumpCount < 0) or (JumpCount > FMaxJumps) then Continue;
                if JumpCount < MinSourceJumps then
                begin
                  DeliverySystemID := SystemID;
                  // Save for result:
                  Jumps := JumpCount;
                  BuyOrderJumps := 0;
                  MinSourceJumps := JumpCount;
                  OrderResult.JumpRoute := Route;
                  Break;
                end;
              end;


              DistanceMap.Free;
            end
            else if TryStrToInt(BuyerRange, NumericBuyRange) then
            begin
              // Numeric Order Range
              FRegionManager.SystemsWithinJumpsOf(BestBuyOrder.system_id, NumericBuyRange, CandidateSystems, DistanceMap);
              MinSourceJumps := MaxInt; BestBuyOrderJumps := 0;
              for var SystemID in CandidateSystems do
              begin
                var Stations := FRegionManager.StationsInSystem(SystemID);
                if not Assigned(Stations) or (Stations.Count = 0) then
                  Continue;

                DeliveryStationID := Stations[0];
                DeliveryStationName := FRegionManager.StationIDToName(DeliveryStationID);

                // 2. Skip Upwell Citadel unless FStationType is true:
                if (FRegionManager.StationIDToName(DeliveryStationID) = 'Upwell Citadel') and not FStationType then
                  Continue;

                Route := FRegionManager.GetJumpRoute(BestSellOrder.system_id, SystemID, FMinSec, FMaxSec);
                if Length(Route.SystemIDs) = 0 then Continue;
                var JumpCount := Length(Route.SystemIDs) - 1;
                if (JumpCount < 0) or (JumpCount > FMaxJumps) then Continue;
                var OrderJumps := DistanceMap[SystemID];
                if (JumpCount < MinSourceJumps) and (OrderJumps <= NumericBuyRange) then
                begin
                  DeliverySystemID := SystemID;
                  Jumps := JumpCount;
                  BuyOrderJumps := OrderJumps;
                  MinSourceJumps := JumpCount;
                  OrderResult.JumpRoute := Route;
                  Break;
                end;
              end;


              DistanceMap.Free;
            end;
            // --------------- END DELIVERY BLOCK -------------------

            if (DestSystemID = -1) and (DeliverySystemID = -1) or (Jumps = -1) then
            begin Inc(SkippedPairs); Inc(SkippedReasonBadJumps); Continue; end;

            DestSecurity := FRegionManager.StationIDToSecurity(BestBuyOrder.station_id);

            // Only assign/trip result ONCE per valid candidate:
            OrderResult.ProfitPerJump    := NetProfit / Jumps;
            OrderResult.BuyOrderID       := BestBuyOrder.order_id;
            OrderResult.SellOrderID      := BestSellOrder.order_id;
            OrderResult.ItemName         := FRegionManager.TypeIDToName(TypeID);
            OrderResult.TypeID           := TypeID;
            OrderResult.SourceRegion     := SourceRegionName;
            OrderResult.SourceStation    := SourceStationName;
            OrderResult.SourceSecurity   := SourceSecurity;
            OrderResult.Jumps            := Jumps;
            OrderResult.BuyOrderRange    := BestBuyOrder.range;
            OrderResult.BuyOrderJumps    := BuyOrderJumps;
            OrderResult.DestRegion       := DestRegionName;
            OrderResult.DestSystemID     := DestSystemID;
            OrderResult.DestStation      := DestStationName;
            OrderResult.DestSecurity     := DestSecurity;
            OrderResult.DeliverySystemID := DeliverySystemID;
            OrderResult.DeliveryRegion   := FRegionmanager.RegionIDToName(FRegionManager.SystemIDToRegionID(DeliverySystemID));
            OrderResult.DeliveryStationID:= DeliveryStationID;
            OrderResult.DeliveryStation  := DeliveryStationName;
            OrderResult.Volume           := RealVol;
            OrderResult.BuyPrice         := BestSellOrder.price;
            OrderResult.SellPrice        := BestBuyOrder.price;
            OrderResult.TotalBuy         := BestSellOrder.price * RealVol;
            OrderResult.TotalSell        := BestBuyOrder.price * RealVol;
            OrderResult.NetProfit        := NetProfit;
            OrderResult.MinRouteSec      := OrderResult.JumpRoute.MinSecurity;
            OrderResult.SalesTax         := SalesTaxCost;
            OrderResult.ROI              := ROI;
            FAnalyzerResults.Add(OrderResult);
            Inc(ProfitableCount);
          end;
        end;
      end;
    end;
  end;

  // ---- Summary/Output ----
  FLogger.Log('--- ORDER SEARCH INDEXED SUMMARY ---');
  FLogger.Log(Format('Total pairs processed: %d', [TotalPairs]));
  FLogger.Log(Format('Pairs with no orders: %d', [SkippedReasonNoOrders]));
  SkippedIDsArr := SkippedNoNameTypeIDs.Keys.ToArray;
  SetLength(SkippedIDStrArr, Length(SkippedIDsArr));
  for i := 0 to High(SkippedIDsArr) do
    SkippedIDStrArr[i] := IntToStr(SkippedIDsArr[i]);
  skipTypeStr := String.Join(',', SkippedIDStrArr);
  FLogger.Log('Unique TypeIDs skipped for no name: ' + skipTypeStr);
  FLogger.Log(Format('Total skipped pairs: %d', [SkippedPairs]));
  FLogger.Log(Format('Total unique skipped TypeIDs: %d', [SkippedNoNameTypeIDs.Count]));
  SkippedNoNameTypeIDs.Free;
  FLogger.Log(Format('Pairs bad stations: %d', [SkippedReasonBadStations]));
  FLogger.Log(Format('Pairs bad jumps: %d', [SkippedReasonBadJumps]));
  FLogger.Log(Format('Pairs not profitable: %d', [SkippedReasonNotProfitable]));
  FLogger.Log(Format('Total profitable trips found: %d', [ProfitableCount]));
  // Sorting and output as before
  FAnalyzerResults.Sort(
    TComparer<TOrderTripResult>.Construct(
      function(const A, B: TOrderTripResult): Integer
      begin
        if A.NetProfit > B.NetProfit then Result := -1
        else if A.NetProfit < B.NetProfit then Result := 1
        else Result := 0;
      end
    )
  );
  if FAnalyzerResults.Count > 0 then
    OutputResultsToGrid(Grid, 9);
  FLogger.Log(Format('FindProfitableTripsToGrid elapsed ms: %d (%.2f seconds)', [Integer(SW.ElapsedMilliseconds), SW.ElapsedMilliseconds / 1000.0]));
end;


procedure TOrderAnalyzer.OutputResultsToGrid(Grid: TStringGrid; SortCol: Integer);
const
  HEADER_COUNT = 13;
var
  SecurityGradient: array[0..10] of TColor;
  MaxWidth, Row, c, w, tw: Integer;
  HEADERS: array[0..HEADER_COUNT] of string;
  CellText, VolumeStr: string;
  secColorIdx: Integer;
  secRating: Double;
begin
  // 1. Setup headers
  HEADERS[0]  := 'Item Name';
  HEADERS[1]  := 'From';
  HEADERS[2]  := 'Volume';
  HEADERS[3]  := 'Buy Price';
  HEADERS[4]  := 'Deliver To';
  HEADERS[5]  := 'Sell Price';
  HEADERS[6]  := 'Net Buy';
  HEADERS[7]  := 'Net Sell';
  HEADERS[8]  := 'Sales Tax';
  HEADERS[9]  := 'Net Profit';
  HEADERS[10] := 'Jumps';
  HEADERS[11] := 'Profit Per Jump';
  HEADERS[12] := 'ROI';

  SecurityGradient[10] := COLOR_SECURITY_10;
  SecurityGradient[9]  := COLOR_SECURITY_9;
  SecurityGradient[8]  := COLOR_SECURITY_8;
  SecurityGradient[7]  := COLOR_SECURITY_7;
  SecurityGradient[6]  := COLOR_SECURITY_6;
  SecurityGradient[5]  := COLOR_SECURITY_5;
  SecurityGradient[4]  := COLOR_SECURITY_4;
  SecurityGradient[3]  := COLOR_SECURITY_3;
  SecurityGradient[2]  := COLOR_SECURITY_2;
  SecurityGradient[1]  := COLOR_SECURITY_1;
  SecurityGradient[0]  := COLOR_SECURITY_0;

  Grid.ColCount := HEADER_COUNT;
  Grid.RowCount := FAnalyzerResults.Count + 1;

  // 2. Allocate cell color array
  SetLength(CellColors, Grid.ColCount, Grid.RowCount);
  for c := 0 to Grid.ColCount - 1 do
    for Row := 0 to Grid.RowCount - 1 do
      CellColors[c, Row] := clNone;

  // 3. Place headers
  for c := 0 to HEADER_COUNT - 1 do
    Grid.Cells[c, 0] := HEADERS[c];

  // 4. Prepare and sort a temporary array, store in SortedTradeResults
  SortedTradeResults := FAnalyzerResults.ToArray;
  TArray.Sort<TOrderTripResult>(
    SortedTradeResults,
    TComparer<TOrderTripResult>.Construct(
      function(const L, R: TOrderTripResult): Integer
      var
        LVal, RVal: Variant;
        cmp: TVariantRelationship;
        JumpsL, JumpsR: Integer;
      begin
        case SortCol of
          0: begin LVal := L.ItemName;          RVal := R.ItemName; end;
          1: begin LVal := L.SourceStation;     RVal := R.SourceStation; end;
          2: begin LVal := L.Volume;            RVal := R.Volume; end;
          3: begin LVal := L.BuyPrice;          RVal := R.BuyPrice; end;
          4: begin LVal := L.DestStation;       RVal := R.DestStation; end;
          5: begin LVal := L.SellPrice;         RVal := R.SellPrice; end;
          6: begin LVal := L.TotalBuy;          RVal := R.TotalBuy; end;
          7: begin LVal := L.TotalSell;         RVal := R.TotalSell; end;
          8: begin LVal := L.SalesTax;          RVal := R.SalesTax; end;
          9: begin LVal := L.NetProfit;         RVal := R.NetProfit; end;
          10:
            begin
              if L.BuyOrderJumps > 0 then
                JumpsL := L.Jumps - L.BuyOrderJumps
              else
                JumpsL := L.Jumps;
              if R.BuyOrderJumps > 0 then
                JumpsR := R.Jumps - R.BuyOrderJumps
              else
                JumpsR := R.Jumps;
              LVal := JumpsL; RVal := JumpsR;
            end;
          11: begin LVal := L.ProfitPerJump;    RVal := R.ProfitPerJump; end;
          12: begin LVal := L.ROI;              RVal := R.ROI; end;
        else
          LVal := L.ItemName; RVal := R.ItemName;
        end;
        cmp := VarCompareValue(LVal, RVal);
        case cmp of
          vrLessThan:
            if FSortDescending then Result := 1 else Result := -1;
          vrEqual: Result := 0;
          vrGreaterThan:
            if FSortDescending then Result := -1 else Result := 1;
        else
          Result := 0;
        end;
      end
    )
  );

  // 5. Output sorted results to the grid (display always matches SortedTradeResults)
  for Row := 1 to Length(SortedTradeResults) do
  begin
    VolumeStr := FmtFloat(SortedTradeResults[Row-1].Volume * FRegionmanager.TypeIDToVolume(SortedTradeResults[Row-1].TypeID))
                  + ' m³ (' + FmtFloat(SortedTradeResults[Row-1].Volume) + ' u)';
    Grid.Cells[0, Row] := SortedTradeResults[Row-1].ItemName;

    secColorIdx := Max(Round(SortedTradeResults[Row-1].SourceSecurity * 10), 0);
    secRating := Round(SortedTradeResults[Row-1].SourceSecurity * 10) / 10;
    CellColors[1, Row] := SecurityGradient[secColorIdx];
    Grid.Cells[1, Row] := SortedTradeResults[Row-1].SourceStation + ' (' + secRating.ToString() + ')';

    Grid.Cells[2, Row] := VolumeStr;
    Grid.Cells[3, Row] := FmtFloat(SortedTradeResults[Row-1].BuyPrice, 2);

    if SortedTradeResults[Row-1].DeliveryStationID > -1 then
    begin
      secColorIdx := Max(Round(FRegionManager.StationIDToSecurity(SortedTradeResults[Row-1].DeliveryStationID) * 10), 0);
      secRating := Round(FRegionManager.StationIDToSecurity(SortedTradeResults[Row-1].DeliveryStationID) * 10) / 10;
      CellColors[4, Row] := SecurityGradient[secColorIdx];
      Grid.Cells[4, Row] := FRegionManager.StationIDToName((SortedTradeResults[Row-1].DeliveryStationID)) + ' (' + secRating.ToString() + ')';
    end
    else
    begin
      secColorIdx := Max(Round(SortedTradeResults[Row-1].DestSecurity * 10), 0);
      secRating := Round(SortedTradeResults[Row-1].DestSecurity * 10) / 10;
      CellColors[4, Row] := SecurityGradient[secColorIdx];
      Grid.Cells[4, Row] := SortedTradeResults[Row-1].DestStation + ' (' + secRating.ToString() + ')';
    end;
    Grid.Cells[5, Row] := FmtFloat(SortedTradeResults[Row-1].SellPrice, 2);
    Grid.Cells[6, Row] := FmtFloat(SortedTradeResults[Row-1].TotalBuy);
    Grid.Cells[7, Row] := FmtFloat(SortedTradeResults[Row-1].TotalSell);
    Grid.Cells[8, Row] := FmtFloat(SortedTradeResults[Row-1].SalesTax);
    Grid.Cells[9, Row] := FmtFloat(SortedTradeResults[Row-1].NetProfit);
    if SortedTradeResults[Row-1].BuyOrderJumps > 0 then
      Grid.Cells[10, Row] := Format('%d (-%d)', [SortedTradeResults[Row-1].Jumps, SortedTradeResults[Row-1].BuyOrderJumps])
    else
      Grid.Cells[10, Row] := Format('%d', [SortedTradeResults[Row-1].Jumps]);
    Grid.Cells[11, Row] := FmtFloat(SortedTradeResults[Row-1].ProfitPerJump);
    Grid.Cells[12, Row] := Format('%.2f%%', [SortedTradeResults[Row-1].ROI]);
  end;

  // 6. Autosize columns
  tw := 0;
  for c := 1 to Grid.ColCount - 1 do
  begin
    MaxWidth := Grid.Canvas.TextWidth(Grid.Cells[c, 0]) + 20;
    for Row := 1 to Grid.RowCount - 1 do
    begin
      CellText := Grid.Cells[c, Row];
      w := Grid.Canvas.TextWidth(CellText) + 20;
      if w > MaxWidth then
        MaxWidth := w;
    end;
    Grid.ColWidths[c] := MaxWidth;
    tw := tw + MaxWidth;
  end;
  Grid.ColWidths[0] := 2100 - tw;
end;



end.

