unit GridHelper;

interface

uses
  System.SysUtils, System.StrUtils, Vcl.Grids, System.Generics.Collections, Vcl.Graphics,
  System.Variants, Math, System.Generics.Defaults,
  Common, RegionManager;

// Core helper—for trade history
type
  TCellColorGrid = array of array of TColor;
  THistoryGridHelper = class
  private
    FCellColors: TCellColorGrid;
  public
    property CellColors: TCellColorGrid read FCellColors;
    procedure OutputToGrid(
      Grid: TStringGrid;
      const TradeHistory: TDictionary<Integer, TTradeHistoryRec>;
      RegionManager: TRegionManager;
      SortCol: Integer;
      FSortDescending: Boolean = False
    );
  end;

// For future trade results and other grids
type
  TResultsGridHelper = class
  private
    FCellColors: TCellColorGrid;
  public
    property CellColors: TCellColorGrid read FCellColors;
    // In the future: implement OutputToGrid for results grid here!
  end;

var
  History: THistoryGridHelper;
  Results: TResultsGridHelper;

implementation

function FmtFloat(Value: Double; Decimals: Integer = 0): string;
begin
  Result := FormatFloat('#,##0.' + DupeString('0', Decimals), Value);
end;

procedure THistoryGridHelper.OutputToGrid(
  Grid: TStringGrid;
  const TradeHistory: TDictionary<Integer, TTradeHistoryRec>;
  RegionManager: TRegionManager;
  SortCol: Integer;
  FSortDescending: Boolean = False
);
const
  HEADER_COUNT = 12;
  HEADERS: array[0..HEADER_COUNT] of string = (
    'ID', 'Date/Time', 'Item Name', 'From', 'Volume', 'Buy Price', 'Deliver To',
    'Sell Price', 'Net Buy', 'Net Sell', 'Sales Tax', 'Net Profit', 'ROI'
  );
var
  Row, c, w, MaxWidth: Integer;
  TypeName, VolumeStr, CellText: string;
  Rec: TTradeHistoryRec;
  NetProfit, NetBuy, NetSell, SalesTax, secRating: double;
  TradeList: TList<TPair<Integer, TTradeHistoryRec>>;
  secColorIdx: Integer;
begin
  Grid.ColCount := HEADER_COUNT;
  Grid.RowCount := TradeHistory.Count + 1;
  // Place headers
  for c := 0 to HEADER_COUNT do
    Grid.Cells[c, 0] := HEADERS[c];

  // Allocate cell color array
  SetLength(FCellColors, Grid.ColCount, Grid.RowCount);
  for c := 0 to Grid.ColCount-1 do
    for Row := 0 to Grid.RowCount-1 do
      FCellColors[c, Row] := clNone;

  // Gather key/value pairs and sort
  TradeList := TList<TPair<Integer, TTradeHistoryRec>>.Create;
  try
    for var K in TradeHistory.Keys do
      TradeList.Add(TPair<Integer, TTradeHistoryRec>.Create(K, TradeHistory[K]));
    TradeList.Sort(
      TComparer<TPair<Integer, TTradeHistoryRec>>.Construct(
        function(const L, R: TPair<Integer, TTradeHistoryRec>): Integer
        var
          LVal, RVal: Variant;
          cmp: TVariantRelationship;
        begin
          case SortCol of
            0: begin LVal := L.Key;                        RVal := R.Key; end;
            1: begin LVal := L.Value.DateTime;             RVal := R.Value.DateTime; end;
            2: begin LVal := RegionManager.TypeIDToName(L.Value.TypeID);
                          RVal := RegionManager.TypeIDToName(R.Value.TypeID); end;
            3: begin LVal := RegionManager.StationIDToName(L.Value.BuyStationID);
                          RVal := RegionManager.StationIDToName(R.Value.BuyStationID); end;
            4: begin LVal := L.Value.Quantity * RegionManager.TypeIDToVolume(L.Value.TypeID);
                          RVal := R.Value.Quantity * RegionManager.TypeIDToVolume(R.Value.TypeID); end;
            5: begin LVal := L.Value.BuyPrice;             RVal := R.Value.BuyPrice; end;
            6: begin LVal := RegionManager.StationIDToName(L.Value.SellStationID);
                          RVal := RegionManager.StationIDToName(R.Value.SellStationID); end;
            7: begin LVal := L.Value.SellPrice;            RVal := R.Value.SellPrice; end;
            8: begin LVal := L.Value.BuyPrice * L.Value.Quantity;
                          RVal := R.Value.BuyPrice * R.Value.Quantity; end;
            9: begin LVal := L.Value.SellPrice * L.Value.Quantity;
                          RVal := R.Value.SellPrice * R.Value.Quantity; end;
            10: begin LVal := L.Value.SalesTax;            RVal := R.Value.SalesTax; end;
            11: begin
                LVal := L.Value.SellPrice * L.Value.Quantity - L.Value.BuyPrice * L.Value.Quantity - L.Value.SalesTax;
                RVal := R.Value.SellPrice * R.Value.Quantity - R.Value.BuyPrice * R.Value.Quantity - R.Value.SalesTax;
                end;
            12: begin
                LVal := (L.Value.SellPrice * L.Value.Quantity - L.Value.BuyPrice * L.Value.Quantity - L.Value.SalesTax)
                              / (L.Value.BuyPrice * L.Value.Quantity);
                RVal := (R.Value.SellPrice * R.Value.Quantity - R.Value.BuyPrice * R.Value.Quantity - R.Value.SalesTax)
                              / (R.Value.BuyPrice * R.Value.Quantity);
                end;
            else
                LVal := L.Key; RVal := R.Key;
          end;
          cmp := VarCompareValue(LVal, RVal);
          case cmp of
            vrLessThan:    if FSortDescending then Result := 1 else Result := -1;
            vrEqual:       Result := 0;
            vrGreaterThan: if FSortDescending then Result := -1 else Result := 1;
          else
            Result := 0;
          end;
        end
      )
    );
    for Row := 1 to TradeList.Count do
    begin
      var Key := TradeList[Row-1].Key;
      Rec := TradeList[Row-1].Value;
      TypeName := RegionManager.TypeIDToName(Rec.TypeID);
      NetBuy := Rec.BuyPrice * Rec.Quantity;
      NetSell := Rec.SellPrice * Rec.Quantity;
      SalesTax := Rec.SalesTax;
      VolumeStr := FmtFloat(Rec.Quantity * RegionManager.TypeIDToVolume(Rec.TypeID)) + ' m³ (' + FmtFloat(Rec.Quantity) + ' u)';
      NetProfit := NetSell - NetBuy - SalesTax;
      Grid.Cells[0, Row] := Key.ToString;
      Grid.Cells[1, Row] := FormatDateTime('yyyy/MM/dd HH:mm', Rec.DateTime);
      Grid.Cells[2, Row] := TypeName;
      secColorIdx := Max(Round(RegionManager.StationIDToSecurity(Rec.BuyStationID)*10), 0);
      secColorIdx := Min(secColorIdx, High(SecurityColors));
      secRating := Round(RegionManager.StationIDToSecurity(Rec.BuyStationID)*10)/10;
      FCellColors[3, Row] := SecurityColors[secColorIdx];
      Grid.Cells[3, Row] := RegionManager.StationIDToName(Rec.BuyStationID) + ' (' + secRating.ToString() + ')';
      Grid.Cells[4, Row] := VolumeStr;
      Grid.Cells[5, Row] := FmtFloat(Rec.BuyPrice, 2);
      secColorIdx := Max(Round(RegionManager.StationIDToSecurity(Rec.SellStationID)*10), 0);
      secColorIdx := Min(secColorIdx, High(SecurityColors));
      secRating := Round(RegionManager.StationIDToSecurity(Rec.SellStationID)*10)/10;
      FCellColors[6, Row] := SecurityColors[secColorIdx];
      Grid.Cells[6, Row] := RegionManager.StationIDToName(Rec.SellStationID) + ' (' + secRating.ToString() + ')';
      Grid.Cells[7, Row] := FmtFloat(Rec.SellPrice, 2);
      Grid.Cells[8, Row] := FmtFloat(NetBuy, 0);
      Grid.Cells[9, Row] := FmtFloat(NetSell, 0);
      Grid.Cells[10, Row] := FmtFloat(SalesTax, 0);
      Grid.Cells[11, Row] := FmtFloat(NetProfit, 0);
      Grid.Cells[12, Row] := Format('%.0f%%', [(NetProfit / NetBuy * 100)]);
    end;
  finally
    TradeList.Free;
  end;
  for c := 0 to Grid.ColCount - 1 do
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
  end;
end;

initialization
  History := THistoryGridHelper.Create;
  Results := TResultsGridHelper.Create;

finalization
  History.Free;
  Results.Free;

end.

