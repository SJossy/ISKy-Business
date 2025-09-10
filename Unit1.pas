unit Unit1;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.StrUtils,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Imaging.pngimage,
  Vcl.ExtCtrls, Vcl.Grids, Vcl.ComCtrls, System.Net.URLClient, System.Generics.Collections,
  System.Net.HttpClient, System.Net.HttpClientComponent, Vcl.NumberBox, Math, System.Threading,
  System.ImageList, Vcl.ImgList, Vcl.Tabs, System.Generics.Defaults, Vcl.Menus, System.Diagnostics,
  System.UITypes, Vcl.Buttons, System.IOUtils, System.SyncObjs, Types, GDIPAPI, GDIPOBJ,
  Vcl.ButtonStylesAttributes, OrderAnalyzer, Vcl.Samples.Spin, System.Variants, System.RegularExpressions,
  Logger, Common, EsiClient, Parser, FileUtils, Downloader, RegionManager, RouteTools,
  MarketTreeBuilder , TransactionView, GridHelper;


type
  TRouteSegmentFormatter = function(const Rec: TSystemsRec): string;
  TLogProc = procedure(const Msg: string) of object;

  TSystemIDToRecFunc = function(SystemID: Integer): TSystemsRec of object;
  TNodeHintWindow = class(THintWindow);

type
  TForm1 = class(TForm)
    StatusBar: TStatusBar;
    ProgressBar: TProgressBar;
    TimerMarketFilter: TTimer;
    panelTradeAnalyzer: TPanel;
    PanelAnalyzerLeftWindow: TPanel;
    PanelSelectedRegions: TPanel;
    LabelTradeDest: TLabel;
    LabelTradeSource: TLabel;
    lbFromRegions: TListBox;
    lbToRegions: TListBox;
    PanelAnalyzerRightWindow: TPanel;
    GridTradeResults: TStringGrid;
    PopupMenuMarketTree: TPopupMenu;
    PanelMenuBar: TPanel;
    PanelSelectorAnalyzer: TPanel;
    PanelSelectorTradeHistory: TPanel;
    DebugMemo: TMemo;
    PanelItemSummary: TPanel;
    LabelSellers: TLabel;
    LabelTypeMarketGroup: TLabel;
    LabelTypeName: TLabel;
    LabelBuyers: TLabel;
    LabelSellerDetails: TLabel;
    LabelBuyerDetails: TLabel;
    LabelSellersLabels: TLabel;
    LabelBuyersLabels: TLabel;
    AddManualTransaction1: TMenuItem;
    PanelTradeHistory: TPanel;
    GridTradeHistory: TStringGrid;
    PopupMenuTradeHistory: TPopupMenu;
    AddTradeRecord: TMenuItem;
    EditTradeRecord: TMenuItem;
    DeleteTrade: TMenuItem;
    PanelSelection: TPanel;
    PopupMenuTradeGrid: TPopupMenu;
    PanelAnalyzeParameters: TPanel;
    LabelAccountingSkill: TLabel;
    LabelCargoCapacity: TLabel;
    LabelISKBudget: TLabel;
    LabelJumpLimit: TLabel;
    LabelMaxSec: TLabel;
    LabelMaxSecurity: TLabel;
    LabelMinSec: TLabel;
    LabelMinSecurity: TLabel;
    LabelMinProfit: TLabel;
    LabelMinROI: TLabel;
    CheckBoxUpwell: TCheckBox;
    NumberISKBudget: TNumberBox;
    NumberISKMinProfit: TNumberBox;
    NumberJumpLimit: TNumberBox;
    SpinAccountingLevel: TSpinEdit;
    TrackBarMaxSec: TTrackBar;
    TrackBarMinSec: TTrackBar;
    CheckBoxDirect: TCheckBox;
    NumberMinROI: TNumberBox;
    ButtonGetTrades: TBitBtn;
    NumberBoxCargoCapacity: TNumberBox;
    PanelRegionsList: TPanel;
    chkEmpireSpaceOnly: TCheckBox;
    ListboxRegions: TListBox;
    PanelMarketTree: TPanel;
    TreeViewMarket: TTreeView;
    EditFilterMarket: TEdit;
    pnlClearMarketFilter: TPanel;
    FindRouteTrades1: TMenuItem;
    PanelRouteMap: TPanel;
    PanelAnalyzerBottomWindow: TPanel;
    PaintBoxTradeRoute: TPaintBox;
    PanelTradeResults: TPanel;
    TimerAnimateLines: TTimer;
    BalloonHint1: TBalloonHint;
    PanelRouteDetails: TPanel;
    PaintBoxItemType: TPaintBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ListboxRegionsMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure lbToRegionsDragOver(Sender, Source: TObject; X,
      Y: Integer; State: TDragState; var Accept: Boolean);
    procedure lbFromRegionsDragOver(Sender, Source: TObject; X,
      Y: Integer; State: TDragState; var Accept: Boolean);
    procedure lbToRegionsDragDrop(Sender, Source: TObject; X,
      Y: Integer);
    procedure lbFromRegionsDragDrop(Sender, Source: TObject; X,
      Y: Integer);
    procedure lbToRegionsKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure lbFromRegionsKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure GridTradeResultsDblClick(Sender: TObject);
    procedure EditFilterMarketChange(Sender: TObject);
    procedure TimerMarketFilterTimer(Sender: TObject);
    procedure GridTradeResultsDrawCell(Sender: TObject; ACol, ARow: LongInt; Rect: TRect; State: TGridDrawState);
    procedure chkEmpireSpaceOnlyClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure pnlClearMarketFilterClick(Sender: TObject);
    procedure TreeViewMarketDblClick(Sender: TObject);
    procedure TreeViewMarketMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormShow(Sender: TObject);
    procedure PanelSelectorTradeHistoryClick(Sender: TObject);
    procedure PanelSelectorAnalyzerClick(Sender: TObject);
    procedure TrackBarMinSecChange(Sender: TObject);
    procedure TrackBarMaxSecChange(Sender: TObject);
    procedure GridTradeResultsMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure AddManualTransaction1Click(Sender: TObject);
    procedure GridTradeHistoryDrawCell(Sender: TObject; ACol, ARow: LongInt;
      Rect: TRect; State: TGridDrawState);
    procedure DeleteTradeClick(Sender: TObject);
    procedure EditTradeRecordClick(Sender: TObject);
    procedure GridTradeHistoryMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure GridTradeResultsMouseDown(Sender: TObject;
      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure PopupMenuMarketTreePopup(Sender: TObject);
    procedure IndentedListboxDrawItem(Control: TWinControl; Index: Integer; Rect: TRect; State: TOwnerDrawState);
    procedure ButtonGetTradesClick(Sender: TObject);
    procedure ListboxRegionsKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FindRouteTrades1Click(Sender: TObject);
    procedure PaintBoxTradeRoutePaint(Sender: TObject);
    procedure PaintBoxTradeRouteMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure PaintBoxTradeRouteMouseMove(Sender: TObject; Shift: TShiftState;
      X, Y: Integer);
    procedure PaintBoxTradeRouteMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure OutputNodeDataToPanel(const sRec: TSystemsRec);
    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure TimerAnimateLinesTimer(Sender: TObject);
    procedure PaintBoxItemTypePaint(Sender: TObject);
  private
    FInitialised: Boolean;
    Analyzer: TOrderAnalyzer;
    Parser: TParser;
    FRootGroupOrder: TList<string>;
    FLastFullTree: Boolean;
    FMarketTreeIsFiltered: Boolean;
    MapBitmap: TBitMap;
    RouteBitmap: TBitMap;
    CellColors: array of array of TColor;
    ItemBitmap: TBitMap;
    SystemRecs: TArray<TSystemsRec>;
    Cx, Cy: TArray<Integer>;
    ClampedZoom: Double;
    procedure LoadOrCreateTradeHistoryDict(var Dict: TDictionary<Integer, TTradeHistoryRec>; const FileName: string);
    procedure OutputTradeHistory(SortCol: Integer);
    procedure PopulateListBoxRegions;
    procedure SetupGrids;
    procedure ClearResults;
    function GetNextTradeHistoryID: Integer;
    function GetSelectedTypeIDs(TreeView: TTreeView): TArray<Integer>;
    procedure HideNodeHint;
  end;

var
  Form1: TForm1;
  RegionManager: TRegionManager;
  SkipDownloadsWhileLoggerging: Boolean = true;
  Downloader: TDownloader;
  LogCS: TCriticalSection = nil;
  FAnalyzerResults: TList<TOrderTripResult>;
  FSortDesc: Boolean;
  FSortCol: Integer;
  Logger: TLogger;
  TradeHistory: TDictionary<Integer, TTradeHistoryRec>;
  FAllocatedTreeNodeCount: Integer;
  FFreedTreeNodeCount: Integer;
  MyRoute: TJumpRoute;
  PanX: Integer = 0;
  PanY: Integer = 0;
  MousePanStartX: Integer = 0;
  MousePanStartY: Integer = 0;
  MousePanLastX: Integer = 0;
  MousePanLastY: Integer = 0;
  MouseX, MouseY: Integer;
  MouseMoved: Boolean = False;
  HilitedNodeIdx: Integer = -1;
  SelectedNodeIdx: Integer = -1;
  IsPanning: Boolean = False;
  Zoom: Double = 1.0;
  LastMouseX: Integer = -1;
  LastMouseY: Integer = -1;
  DashAnimPhase: Integer = 0;
  RouteDashLen: Integer = 12;
  RouteGapLen: Integer = 8;
  NodeHint: TNodeHintWindow = nil;
  EmptyRoute: TJumpRoute;
implementation
{$R *.dfm}

function ClampDouble(Value, Min, Max: Double): Double;
begin
  if Value < Min then
    Result := Min
  else if Value > Max then
    Result := Max
  else
    Result := Value;
end;

function MergeListBoxesUniqueIDs(lb1, lb2: TListBox): TArray<Integer>;
var
  Dict: TDictionary<Integer, Boolean>;
  i, regionID: Integer;
  name: string;
begin
  Dict := TDictionary<Integer, Boolean>.Create;
  try
    for i := 0 to lb1.Items.Count - 1 do
    begin
      name := lb1.Items[i];
      regionID := RegionManager.RegionNameToID(name);
      if regionID <> 0 then
        Dict.AddOrSetValue(regionID, True);
    end;

    for i := 0 to lb2.Items.Count - 1 do
    begin
      name := lb2.Items[i];
      regionID := RegionManager.RegionNameToID(name);
      if regionID <> 0 then
        Dict.AddOrSetValue(regionID, True);
    end;

    Result := Dict.Keys.ToArray;
  finally
    Dict.Free;
  end;
end;


procedure TForm1.HideNodeHint;
begin
  if Assigned(NodeHint) then
  begin
    NodeHint.ReleaseHandle;
    FreeAndNil(NodeHint);
  end;
end;

function FmtFloat(Value: Double; Decimals: Integer = 0): string;
begin
  Result := FormatFloat('#,##0.' + DupeString('0', Decimals), Value);
end;

procedure DrawBitmapSection(DestCanvas: TCanvas; DestRect: TRect; SrcBitmap: TBitmap; SrcRect: TRect);
begin
  StretchBlt(
    DestCanvas.Handle,
    DestRect.Left, DestRect.Top,
    DestRect.Right - DestRect.Left,
    DestRect.Bottom - DestRect.Top,
    SrcBitmap.Canvas.Handle,
    SrcRect.Left, SrcRect.Top,
    SrcRect.Right - SrcRect.Left,
    SrcRect.Bottom - SrcRect.Top,
    SRCCOPY
  );
end;

procedure TForm1.LoadOrCreateTradeHistoryDict(var Dict: TDictionary<Integer, TTradeHistoryRec>; const FileName: string);
begin
  if Assigned(Dict) then
    Dict.Clear
  else
    Dict := TDictionary<Integer, TTradeHistoryRec>.Create;

  if FileExists(FileName) then
    Parser.LoadTradeHistory(Dict)
  // else -- Dict is simply left empty
end;

procedure TForm1.AddManualTransaction1Click(Sender: TObject);
begin
  FormTransaction.Mode := 'MANUAL';
  FormTransaction.TypeID := RegionManager.TypeNameToID(TreeViewMarket.Selected.Text);
  FormTransaction.OrderID := GetNextTradeHistoryID;
  if FormTransaction.ShowModal = mrOk then
  begin
    TradeHistory.AddOrSetValue(GetNextTradeHistoryID, FormTransaction.ResultMarketOrder);
    Parser.SaveTradeHistory(TradeHistory);
    GridHelper.History.OutputToGrid(GridTradeHistory, TradeHistory, RegionManager, 0, FSortDescending);
//    OutputTradeHistory(0);
  end;
end;

procedure TForm1.EditTradeRecordClick(Sender: TObject);
begin
  FormTransaction.Mode := 'EDIT';

  if (GridTradeHistory.Row > 0) and (GridTradeHistory.Row < GridTradeHistory.RowCount) then
  begin
    FormTransaction.OrderID := StrToInt(GridTradeHistory.Cells[0, GridTradeHistory.Row]);
    FormTransaction.TypeID := RegionManager.TypeNameToID(GridTradeHistory.Cells[2, GridTradeHistory.Row]);
    FormTransaction.Trade := TradeHistory[FormTransaction.OrderID];
    if FormTransaction.ShowModal = mrOk then
    begin
      TradeHistory.AddOrSetValue(FormTransaction.OrderID, FormTransaction.ResultMarketOrder);
      Parser.SaveTradeHistory(TradeHistory);
      GridHelper.History.OutputToGrid(GridTradeHistory, TradeHistory, RegionManager, 0, FSortDescending);
      //OutputTradeHistory(0);
    end;
  end;
end;

procedure TForm1.FindRouteTrades1Click(Sender: TObject);
var
  order: TOrderTripResult;
  idx: Integer;
  SelectedIDs: TArray<Integer>;
begin
  idx := GridTradeResults.Row;
  order := SortedTradeResults[idx - 1];
  SelectedIDs := GetSelectedTypeIDs(TreeViewMarket);
  Analyzer.SetSelectedTypeIDs(SelectedIDs);
  //Analyzer.FindRouteProfitableTrips(GridTradeResults, order.JumpRoute, order.DeliveryStationID, order.DeliverySystemID);
  if Analyzer.AnalyzerResults.Count > 0 then
  begin
    GridTradeResults.Visible := true;
    PanelTradeResults.Visible := false;
  end else
  begin
    GridTradeResults.Visible := false;
    PanelTradeResults.Caption := 'No Trades Found';
    PanelTradeResults.Visible := true;
  end
end;

procedure TForm1.chkEmpireSpaceOnlyClick(Sender: TObject);
begin
  PopulateListBoxRegions;
end;

procedure TForm1.SetupGrids;
begin
  with GridTradeResults do
  begin
    ColCount := 13;

    Options := Options + [goColSizing, goRowSelect, goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine];

    DefaultRowHeight := 22;
    RowHeights[0] := 28;

    Font.Name := 'Bahnschrift';
    Font.Size := 10;

    // Header names
    Cells[0, 0]   := 'Item Name';
    Cells[1, 0]   := 'From';
    Cells[2, 0]   := 'Volume';
    Cells[3, 0]   := 'Buy Price';
    Cells[4, 0]   := 'Deliver To';
    Cells[5, 0]   := 'Sell Price';
    Cells[6, 0]   := 'Net Buy';
    Cells[7, 0]   := 'Net Sell';
    Cells[8, 0]   := 'Sales Tax';
    Cells[9, 0]   := 'Net Profit';
    Cells[10, 0]  := 'Jumps';
    Cells[11, 0]  := 'Profit Per Jump';
    Cells[12, 0]  := 'ROI';

    ColWidths[0]  := 378;
    ColWidths[1]  := 441;
    ColWidths[2]  := 128;
    ColWidths[3]  := 99;
    ColWidths[4]  := 401;
    ColWidths[5]  := 96;
    ColWidths[6]  := 81;
    ColWidths[7]  := 81;
    ColWidths[8]  := 72;
    ColWidths[9]  := 71;
    ColWidths[10] := 58;
    ColWidths[11] := 102;
    ColWidths[12] := 92;
  end;
  with GridTradeHistory do
  begin
    ColCount := 12;

    Options := Options + [goColSizing, goRowSelect, goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine];

    DefaultRowHeight := 22;
    RowHeights[0] := 28;

    Font.Name := 'Bahnschrift';
    Font.Size := 10;
    Cells[0, 0]  := 'Date/Time';
    Cells[1, 0]  := 'Item Name';
    Cells[2, 0]  := 'From';
    Cells[3, 0]  := 'Volume';
    Cells[4, 0]  := 'Buy Price';
    Cells[5, 0]  := 'Deliver To';
    Cells[6, 0]  := 'Sell Price';
    Cells[7, 0]  := 'Net Buy';
    Cells[8, 0]  := 'Net Sell';
    Cells[9, 0]  := 'Sales Tax';
    Cells[10, 0] := 'Net Profit';
    Cells[11, 0] := 'ROI';
  end;
end;


function GetRegionIDs(ListBox: TListBox): TArray<Integer>;
var
  I: Integer;
  IDs: TList<Integer>;
begin
  IDs := TList<Integer>.Create;
  try
    for I := 0 to ListBox.Count - 1 do
      IDs.Add(RegionManager.RegionNameToID(ListBox.Items[I]));
    Result := IDs.ToArray;
  finally
    IDs.Free;
  end;
end;

function TForm1.GetSelectedTypeIDs(TreeView: TTreeView): TArray<Integer>;
  procedure CollectItemTypeIDs(Node: TTreeNode; IDs: TList<Integer>);
  var
    Child: TTreeNode;
    NodeData: TMarketTreeNodeData;
  begin
    if Node <> nil then
    begin
      if (Node.Data <> nil) then
      begin
        NodeData := TMarketTreeNodeData(Node.Data);
        if NodeData.IsItem then
          IDs.Add(NodeData.TypeID);
      end;
      Child := Node.getFirstChild;
      while Child <> nil do
      begin
        CollectItemTypeIDs(Child, IDs);
        Child := Child.getNextSibling;
      end;
    end;
  end;
var
  IDs: TList<Integer>;
  i: Integer;
  Node: TTreeNode;
begin
  IDs := TList<Integer>.Create;
  Result := [];
  try
    if TreeView.SelectionCount > 0 then
    begin
      for i := 0 to TreeView.SelectionCount - 1 do
      begin
        Node := TreeView.Selections[i];
        CollectItemTypeIDs(Node, IDs);
      end;
    end;
    Result := IDs.ToArray;
  finally
    IDs.Free;
  end;
end;

procedure TForm1.lbToRegionsDragDrop(Sender, Source: TObject; X, Y: Integer);
var
  i: Integer;
  regionName: string;
  regionID: Integer;
  regionIDs: TList<Integer>;
  regionIDArray: TArray<Integer>;
begin
  regionIDs := TList<Integer>.Create;
  try
    for i := 0 to ListBoxRegions.Items.Count - 1 do
      if ListBoxRegions.Selected[i] then
      begin
        regionName := ListBoxRegions.Items[i];
        // Add region name to target if it's not already present
        if lbToRegions.Items.IndexOf(regionName) = -1 then
          lbToRegions.Items.Add(regionName);
        // Look up region ID and add if valid/not yet in list
        regionID := RegionManager.RegionNameToID(Trim(regionName));
        if (regionID > 0) and (regionIDs.IndexOf(regionID) = -1) then
          regionIDs.Add(regionID);
      end;
    // If any regions were added, load them
    if regionIDs.Count > 0 then
    begin
      regionIDArray := regionIDs.ToArray;
      RegionManager.EnqueueRegionsForLoad(regionIDArray, 'marketcache\');
      // ButtonAnalyze.Enabled will be re-enabled by RegionManager when loading completes
    end;
  finally
    regionIDs.Free;
  end;
end;

procedure TForm1.lbFromRegionsDragDrop(Sender, Source: TObject; X, Y: Integer);
var
  i: Integer;
  regionName: string;
  regionID: Integer;
  regionIDs: TList<Integer>;
  regionIDArray: TArray<Integer>;
begin
  regionIDs := TList<Integer>.Create;
  try
    for i := 0 to ListBoxRegions.Items.Count - 1 do
      if ListBoxRegions.Selected[i] then
      begin
        regionName := ListBoxRegions.Items[i];
        // Add region name to target if it's not already present
        if lbFromRegions.Items.IndexOf(regionName) = -1 then
          lbFromRegions.Items.Add(regionName);
        // Look up region ID and add if valid/not yet in list
        regionID := RegionManager.RegionNameToID(Trim(regionName));
        if (regionID > 0) and (regionIDs.IndexOf(regionID) = -1) then
          regionIDs.Add(regionID);
      end;
    // If any regions were added, load them
    if regionIDs.Count > 0 then
    begin
      regionIDArray := regionIDs.ToArray;
      RegionManager.EnqueueRegionsForLoad(regionIDArray, 'marketcache\');
      // ButtonAnalyze.Enabled will be re-enabled by RegionManager when all loads complete
    end;
  finally
    regionIDs.Free;
  end;
end;

procedure TForm1.lbFromRegionsDragOver(Sender, Source: TObject; X,
  Y: Integer; State: TDragState; var Accept: Boolean);
begin
  Accept := Source = ListboxRegions;
end;

procedure TForm1.lbToRegionsKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  i: Integer;
begin
  if Key = VK_DELETE then
  begin
    for i := lbToRegions.Items.Count - 1 downto 0 do
      if lbToRegions.Selected[i] then
        lbToRegions.Items.Delete(i);
    Key := 0;
  end;
  if (Key = Ord('A')) and (ssCtrl in Shift) and lbToRegions.MultiSelect then
  begin
    for i := 0 to lbToRegions.Items.Count - 1 do
      lbToRegions.Selected[i] := True;
    Key := 0; // Optional: suppress further processing
  end;
end;

procedure TForm1.lbFromRegionsKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  i: Integer;
begin
  if Key = VK_DELETE then
  begin
    for i := lbFromRegions.Items.Count - 1 downto 0 do
      if lbFromRegions.Selected[i] then
        lbFromRegions.Items.Delete(i);
    Key := 0;
  end;
  if (Key = Ord('A')) and (ssCtrl in Shift) and lbFromRegions.MultiSelect then
  begin
    for i := 0 to lbFromRegions.Items.Count - 1 do
      lbFromRegions.Selected[i] := True;
    Key := 0; // Optional: suppress further processing
  end;
end;


procedure TForm1.IndentedListboxDrawItem(Control: TWinControl; Index: Integer; Rect: TRect; State: TOwnerDrawState);
const
  Indent = 22;
var
  LB: TListBox;
  Y: Integer;
  Text: String;
begin
  LB := Control as TListBox;
  Text := LB.Items[Index];

  // Always fill the provided rectangle
  LB.Canvas.FillRect(Rect);

  // Optionally, highlight selected/focused differently
  if odSelected in State then
    LB.Canvas.Font.Style := [fsBold]
  else
    LB.Canvas.Font.Style := [];

  // Calculate Y for vertical centering
  Y := Rect.Top + (Rect.Height - LB.Canvas.TextHeight(Text)) div 2;
  LB.Canvas.TextOut(Rect.Left + Indent, Y, Text);
end;

procedure TForm1.ListboxRegionsKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  LB: TListBox;
  i: Integer;
begin
  LB := Sender as TListBox;
  if (Key = Ord('A')) and (ssCtrl in Shift) and LB.MultiSelect then
  begin
    for i := 0 to LB.Items.Count - 1 do
      LB.Selected[i] := True;
    Key := 0; // Optional: suppress further processing
  end;
end;

procedure TForm1.ListboxRegionsMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  ListboxRegions.BeginDrag(False);
end;

procedure TForm1.PanelSelectorAnalyzerClick(Sender: TObject);
begin
  panelTradeAnalyzer.Visible := true;
  panelTradeHistory.Visible := false;
  PanelSelection.Left := PanelSelectorAnalyzer.Left;
end;

procedure TForm1.PanelSelectorTradeHistoryClick(Sender: TObject);
begin
  panelTradeAnalyzer.Visible := false;
  panelTradeHistory.Visible := true;
  PanelSelection.Left := panelSelectorTradeHistory.Left;
end;

procedure TForm1.lbToRegionsDragOver(Sender, Source: TObject; X,
  Y: Integer; State: TDragState; var Accept: Boolean);
begin
  Accept := Source = ListboxRegions;
end;

function FormatName(const Rec: TSystemsRec): string;
begin
  Result := Rec.SystemName;
end;

function FormatNameSec(const Rec: TSystemsRec): string;
begin
  Result := Format('%s [%.1f]', [Rec.SystemName, Rec.security]);
end;

procedure FilterStringGridByColumnPartial(
  const SourceGrid: TStringGrid;
  DestGrid: TStringGrid;
  ColIndex: Integer;
  const FilterValue: string
);
var
  SrcRow, DestRow, Col: Integer;
begin
  // Set up DestGrid with same column count
  DestGrid.ColCount := SourceGrid.ColCount;

  // Copy header row
  for Col := 0 to SourceGrid.ColCount - 1 do
    DestGrid.Cells[Col, 0] := SourceGrid.Cells[Col, 0];

  DestRow := 1;
  for SrcRow := 1 to SourceGrid.RowCount - 1 do
  begin
    if SourceGrid.Cells[ColIndex, SrcRow] = FilterValue then
    begin
      DestGrid.RowCount := DestRow + 1; // Ensure row exists
      for Col := 0 to SourceGrid.ColCount - 1 do
        DestGrid.Cells[Col, DestRow] := SourceGrid.Cells[Col, SrcRow];
      Inc(DestRow);
    end;
  end;

  if DestRow = 1 then
    DestGrid.RowCount := 2; // At least one row for header + empty
end;

procedure TForm1.pnlClearMarketFilterClick(Sender: TObject);
begin
  EditFilterMarket.Text := '';
  //BuildMarketTree(TreeViewMarket, Parser.FMarketGroups, Parser.FParentToChildren, Parser.FTypes);
  TMarketTreeBuilder.BuildFullMarketTree(TreeViewMarket, Parser.FMarketGroups, Parser.FParentToChildren, Parser.FTypes);
  //TMarketTreeAsyncBuilder.BuildFullMarketTreeAsync(TreeViewMarket, Parser.FMarketGroups, Parser.FParentToChildren, Parser.FTypes);
  TreeViewMarket.FullCollapse;
  FMarketTreeIsFiltered := false;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  ClearResults;
  Form1.Caption := 'ISKy Business - ' +Titles[Random(Length(Titles))];
  SetupGrids;
  Logger := TLogger.Create(StatusBar, ProgressBar, DebugMemo);
  Downloader := TDownloader.Create(Logger);
  Parser := TParser.Create(Logger);
  RegionManager := TRegionManager.Create(Parser, Logger);
  PopulateListBoxRegions;
  //BuildMarketTree(TreeViewMarket, Parser.FMarketGroups, Parser.FParentToChildren, Parser.FTypes);
  TMarketTreeBuilder.BuildFullMarketTree(TreeViewMarket, Parser.FMarketGroups, Parser.FParentToChildren, Parser.FTypes);
  //TMarketTreeAsyncBuilder.BuildFullMarketTreeAsync(TreeViewMarket, Parser.FMarketGroups, Parser.FParentToChildren, Parser.FTypes);
  FLastFullTree := False;
  EmptyRoute := Default(TJumpRoute);
 end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  //MarketTreeCacheOld.Free;
  if Assigned(Analyzer) then
    Analyzer.Free;
  FRootGroupOrder.Free;
  LogCS.Free;
  MapBitmap.Free;
  RouteBitmap.Free;
end;

procedure TForm1.FormMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
const
  ZOOM_STEP = 0.25;
var
  PrevZoom, NewZoom: Double;
begin
  var MousePosClient := PaintBoxTradeRoute.ScreenToClient(MousePos);

  if PtInRect(PaintBoxTradeRoute.ClientRect, MousePosClient) then
  begin
    var MouseX := MousePosClient.X;
    var MouseY := MousePosClient.Y;

    PrevZoom := Zoom;
    NewZoom := PrevZoom;
    if WheelDelta > 0 then
      NewZoom := ClampDouble(PrevZoom + ZOOM_STEP, MIN_ZOOM, MAX_ZOOM)
    else
      NewZoom := ClampDouble(PrevZoom - ZOOM_STEP, MIN_ZOOM, MAX_ZOOM);

    LastMouseX := MouseX;
    LastMouseY := MouseY;

    if NewZoom <> PrevZoom then
    begin
      if NewZoom > PrevZoom then
      begin
        // Zoom in: keep focus under mouse
        PanX := Round(MouseX - (MouseX - PanX) * (NewZoom / PrevZoom));
        PanY := Round(MouseY - (MouseY - PanY) * (NewZoom / PrevZoom));
      end
      else
      begin
        // Zoom out: slide pan smoothly toward center (PanX/PanY = 0)
        if PrevZoom > MIN_ZOOM then
        begin
          var t := (NewZoom - MIN_ZOOM) / (PrevZoom - MIN_ZOOM); // t decreases as zoom approaches min
          PanX := Round(PanX * t);
          PanY := Round(PanY * t);
        end;
      end;
      Zoom := NewZoom;

      // Hard lock pan at center ONLY when zoom is exactly minimum
      if Abs(NewZoom - MIN_ZOOM) < 1e-6 then
      begin
        PanX := 0;
        PanY := 0;
      end;
    end;

    // You can optionally reproject/clamp here, or let draw method handle as shown earlier
    PaintBoxTradeRoute.Invalidate;
    Handled := True;
  end;
end;

procedure TForm1.FormResize(Sender: TObject);
begin
  lbFromRegions.Height  := Round((PanelSelectedRegions.Height - 48) / 2) -4;
  lbToRegions.Height    := Round((PanelSelectedRegions.Height - 48) / 2) -8;
  lbFromRegions.Top     := LabelTradeSource.Top + LabelTradeSource.Height +4;
  LabelTradeDest.Top    := lbFromRegions.Top + lbFromRegions.Height +4;
  lbToRegions.Top       := PanelSelectedRegions.Height - lbToRegions.Height -1;
end;

procedure TForm1.FormShow(Sender: TObject);
begin

  if not FInitialised then
  begin
    FInitialised := True;


    // Download all static SDE CSVs (1-day cache)
    Downloader.DownloadFile   (RegionsURL, RegionsFile,       7);
    Parser.LoadRegions        (RegionsFile, RegionsBin);

    Downloader.DownloadFile   (SystemssURL, SystemsFile,  7);
    Parser.LoadSystems        (SystemsFile, SystemsBin);

    Downloader.DownloadFile   (StationsURL, StationsFile,      7);
    Parser.LoadStations       (StationsFile, StationsBin);

    Downloader.DownloadFile   (TypesURL, TypesFile,         7);
    Parser.LoadTypes;

    Downloader.DownloadFile   (MarketGroupsURL, MarketGroupsFile,  7);
    Parser.LoadMarketGroups   (MarketGroupsFile, MarketGroupsBin);

    Downloader.DownloadFile   (SystemJumpsURL,     SystemJumpsFile,   7);
    Parser.LoadSystemJumps    (SystemJumpsFile, SystemJumpsBin);
    Parser.BuildAllPairsJumpsMatrix;
    PopulateListBoxRegions;

    //BuildMarketTree(TreeViewMarket, Parser.FMarketGroups, Parser.FParentToChildren, Parser.FTypes);
    TMarketTreeBuilder.BuildFullMarketTree(TreeViewMarket, Parser.FMarketGroups, Parser.FParentToChildren, Parser.FTypes);
    //TMarketTreeAsyncBuilder.BuildFullMarketTreeAsync(TreeViewMarket, Parser.FMarketGroups, Parser.FParentToChildren, Parser.FTypes);
    TreeViewMarket.SortType := stText;

    LoadOrCreateTradeHistoryDict(TradeHistory, TradeHistoryBin);
    GridHelper.History.OutputToGrid(GridTradeHistory, TradeHistory, RegionManager, 0, FSortDescending);
//    OutputTradeHistory(0);

    FormTransaction.RegionManager := RegionManager;
    FormTransaction.Downloader := Downloader;
  end;
end;

function TForm1.GetNextTradeHistoryID: Integer;
var
  Keys: TArray<Integer>;
  MaxID, i: Integer;
begin
  Keys := TradeHistory.Keys.ToArray;
  MaxID := 0;
  for i := 0 to High(Keys) do
    if Keys[i] > MaxID then
      MaxID := Keys[i];
  Result := MaxID + 1;
end;
procedure TForm1.GridTradeResultsDblClick(Sender: TObject);
var
  SysID, idx: Integer;
  order: TOrderTripResult;
  SysPath, Info: string;
begin
  idx := GridTradeResults.Row;
  if (GridTradeResults.RowCount > 1) and (idx > 0) and (idx <= Length(SortedTradeResults)) then
  begin
    order := SortedTradeResults[idx - 1];
    SysPath := '';
    for SysID in order.JumpRoute.SystemIDs do
      SysPath := SysPath + Format('(%s) %s [%.1f] > ', [
        RegionManager.RegionIDToName(RegionManager.SystemIDToRegionID(SysID)),
        RegionManager.SystemIDToName(SysID),
        RegionManager.SystemSecurity(SysID)
      ]);
    Delete(SysPath, Length(SysPath) - 2, 3);
    Info :=
      'Item:              ' + order.ItemName + sLineBreak +
      'TypeID:            ' + IntToStr(order.TypeID) + sLineBreak +
      'Buy OrderID:       ' + IntToStr(order.BuyOrderID) + sLineBreak +
      'Sell OrderID:      ' + IntToStr(order.SellOrderID) + sLineBreak +
      'Source Region:     ' + order.SourceRegion + ' ( ' + RegionManager.RegionNameToID(order.SourceRegion).ToString + ')' + sLineBreak +
      'Source Station:    ' + order.SourceStation + sLineBreak +
      'Dest Region:       ' + order.DestRegion + ' ( ' + RegionManager.RegionNameToID(order.DestRegion).ToString + ')' + sLineBreak +
      'Dest Station:      ' + order.DestStation + sLineBreak +
      'Delivery Station:  ' + RegionManager.StationIDToName(order.DeliveryStationID) + sLineBreak +
      'Range:             ' + order.BuyOrderRange + sLineBreak +
      'Jumps:             ' + IntToStr(order.Jumps) + sLineBreak +
      'Volume:            ' + FormatFloat('#,##0', order.Volume) + ' units (' + FormatFloat('#,##0.00', order.Volume * RegionManager.TypeIDToVolume(order.TypeID)) + ' m³)' + sLineBreak +
      'Buy Price:         ' + FormatFloat('#,##0', order.BuyPrice) + sLineBreak +
      'Sell Price:        ' + FormatFloat('#,##0', order.SellPrice) + sLineBreak +
      'Total Buy:         ' + FormatFloat('#,##0', order.TotalBuy) + sLineBreak +
      'Total Sell:        ' + FormatFloat('#,##0', order.TotalSell) + sLineBreak +
      'Profit:            ' + FormatFloat('#,##0', order.NetProfit) + sLineBreak +
      'Sales Tax:         ' + FormatFloat('#,##0', order.SalesTax) + sLineBreak +
      'Route:             ' + SysPath;
    Logger.Log(Info);

    FormTransaction.RegionManager := RegionManager;
    FormTransaction.Downloader := Downloader;
    FormTransaction.Mode := 'ADD';
    FormTransaction.Order := order;
    if FormTransaction.ShowModal = mrOk then
    begin
      TradeHistory.AddOrSetValue(GetNextTradeHistoryID, FormTransaction.ResultMarketOrder);
      Parser.SaveTradeHistory(TradeHistory);
      GridHelper.History.OutputToGrid(GridTradeHistory, TradeHistory, RegionManager, 0, FSortDescending);
      //OutputTradeHistory(0);
    end;
  end;
end;

procedure TForm1.ButtonGetTradesClick(Sender: TObject);
  function AllKeysExist(const Keys: TArray<Integer>; Dict: TDictionary<Integer, TRegionInfo>): Boolean;
  var
    i: Integer;
  begin
    for i := 0 to High(Keys) do
      if not Dict.ContainsKey(Keys[i]) then
        Exit(False);
    Result := True;
  end;
begin
  if (lbFromRegions.Count = 0) or (lbToRegions.Count = 0) then
    Exit;
  if not AllKeysExist(MergeListBoxesUniqueIDs(lbFromRegions, lbToRegions), RegionManager.FLoadedRegions) then
    Exit;
  GridTradeResults.RowCount := 2;

  Analyzer := TOrderAnalyzer.Create(Parser, RegionManager, Logger);
  Analyzer.SetMinProfit(NumberISKMinProfit.ValueFloat);
  Analyzer.SetAvailableISK(NumberISKBudget.Value);
  Analyzer.SetCargoCapacity(NumberBoxCargoCapacity.Value);
  Analyzer.SetMaxJumps(NumberJumpLimit.ValueInt);
  Analyzer.SetMinSec(TrackBarMinSec.Position / 10.0);
  Analyzer.SetMaxSec(TrackBarMaxSec.Position / 10.0);
  Analyzer.SetSourceRegions(GetRegionIDs(lbFromRegions));
  Analyzer.SetDestRegions(GetRegionIDs(lbToRegions));
  Analyzer.SetSelectedTypeIDs(GetSelectedTypeIDs(TreeViewMarket));
  Analyzer.SetStationType(CheckBoxUpwell.Checked);
  Analyzer.RequireDirect(CheckBoxDirect.Checked);
  Analyzer.SetMinROI(NumberMinROI.ValueFloat);
  Analyzer.SetAccountingLevel(SpinAccountingLevel.Value);

  Analyzer.FindProfitableTrips(GridTradeResults);
  if Analyzer.AnalyzerResults.Count > 0 then
  begin
    GridTradeResults.Visible := true;
    PanelTradeResults.Visible := false;
  end else
  begin
    GridTradeResults.Visible := false;
    PanelTradeResults.Caption := 'No Trades Found';
    PanelTradeResults.Visible := true;
  end
end;

procedure TForm1.OutputTradeHistory(SortCol: Integer);
const
  HEADER_COUNT = 13;
var
  HEADERS: array[0..HEADER_COUNT] of string;
  secColorIdx, Row, c, w, MaxWidth: Integer;
  TypeName, VolumeStr, CellText: string;
  Rec: TTradeHistoryRec;
  NetProfit, NetBuy, NetSell, SalesTax, secRating: double;
  TradeList: TList<TPair<Integer, TTradeHistoryRec>>;
begin
  // Set up headers (unchanged)
  HEADERS[0]  := 'ID';
  HEADERS[1]  := 'Date/Time';
  HEADERS[2]  := 'Item Name';
  HEADERS[3]  := 'From';
  HEADERS[4]  := 'Volume';
  HEADERS[5]  := 'Buy Price';
  HEADERS[6]  := 'Deliver To';
  HEADERS[7]  := 'Sell Price';
  HEADERS[8]  := 'Net Buy';
  HEADERS[9]  := 'Net Sell';
  HEADERS[10] := 'Sales Tax';
  HEADERS[11] := 'Net Profit';
  HEADERS[12] := 'ROI';
  GridTradeHistory.ColCount := HEADER_COUNT;
  GridTradeHistory.RowCount := TradeHistory.Count + 1;

  // Place headers
  for c := 0 to HEADER_COUNT do
    GridTradeHistory.Cells[c, 0] := HEADERS[c];
  // Allocate cell color array
  SetLength(CellColors, GridTradeHistory.ColCount, GridTradeHistory.RowCount);
  for c := 0 to GridTradeHistory.ColCount-1 do
    for Row := 0 to GridTradeHistory.RowCount-1 do
      CellColors[c, Row] := clNone;

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
              0: begin LVal := L.Key;                        RVal := R.Key; end; // ID
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
              vrLessThan:
                if FSortDescending then
                  Result := 1
                else
                  Result := -1;
              vrEqual:
                Result := 0;
              vrGreaterThan:
                if FSortDescending then
                  Result := -1
                else
                  Result := 1;
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
      GridTradeHistory.Cells[0, Row] := Key.ToString;
      GridTradeHistory.Cells[1, Row] := FormatDateTime('yyyy/MM/dd HH:mm', Rec.DateTime);
      GridTradeHistory.Cells[2, Row] := TypeName;
      secColorIdx := Max(Round(RegionManager.StationIDToSecurity(Rec.BuyStationID)*10), 0);
      secRating := Round(RegionManager.StationIDToSecurity(Rec.BuyStationID)*10)/10;
      CellColors[3, Row] := SecurityColors[secColorIdx];
      GridTradeHistory.Cells[3, Row] := RegionManager.StationIDToName(Rec.BuyStationID) + ' (' + secRating.ToString() + ')';
      GridTradeHistory.Cells[4, Row] := VolumeStr;
      GridTradeHistory.Cells[5, Row] := FmtFloat(Rec.BuyPrice, 2);
      secColorIdx := Max(Round(RegionManager.StationIDToSecurity(Rec.SellStationID)*10), 0);
      secRating := Round(RegionManager.StationIDToSecurity(Rec.SellStationID)*10)/10;
      CellColors[6, Row] := SecurityColors[secColorIdx];
      GridTradeHistory.Cells[6, Row] := RegionManager.StationIDToName(Rec.SellStationID) + ' (' + secRating.ToString() + ')';
      GridTradeHistory.Cells[7, Row] := FmtFloat(Rec.SellPrice, 2);
      GridTradeHistory.Cells[8, Row] := FmtFloat(NetBuy, 2);
      GridTradeHistory.Cells[9, Row] := FmtFloat(NetSell, 2);
      GridTradeHistory.Cells[10, Row] := FmtFloat(SalesTax, 2);
      GridTradeHistory.Cells[11, Row] := FmtFloat(NetProfit, 2);
      GridTradeHistory.Cells[12, Row] := Format('%.2f%%', [(NetProfit / NetBuy * 100)]);
    end;
  finally
    TradeList.Free;
  end;

  for c := 0 to GridTradeHistory.ColCount - 1 do
  begin
    MaxWidth := GridTradeHistory.Canvas.TextWidth(GridTradeHistory.Cells[c, 0]) + 20;
    for Row := 1 to GridTradeHistory.RowCount - 1 do
    begin
      CellText := GridTradeHistory.Cells[c, Row];
      w := GridTradeHistory.Canvas.TextWidth(CellText) + 20;
      if w > MaxWidth then
        MaxWidth := w;
    end;
    GridTradeHistory.ColWidths[c] := MaxWidth;
  end;
end;

procedure TForm1.GridTradeResultsDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
var
  CellText: string;
const
  NumCells: set of Byte = [3,5,6,7,8,10];
  LEFT_MARGIN = 8;
  RIGHT_MARGIN = 8;
var
  DrawRect: TRect;
  AlignFlags: Integer;
begin

  with GridTradeResults, Canvas do
  begin

    CellText := Cells[ACol, ARow];
    Font.Name := 'Bahnschrift Light Condensed';

    if ARow = 0 then
    begin
      Brush.Color := clWindow;
      Font.Style := [];
      Font.Size := 12;
      Font.Color := clWhite;
    end
    else
    begin

      Font.Style := [];
      Font.Size := 12;
      if (Analyzer <> nil) and
         (ACol >= 0) and (ACol < Length(Analyzer.CellColors)) and
         (ARow >= 0) and (ARow < Length(Analyzer.CellColors[ACol])) and
         (Analyzer.CellColors[ACol, ARow] <> clNone) then
        Font.Color := Analyzer.CellColors[ACol, ARow]
      else
        Font.Color := clWhite;
    end;

    if gdSelected in State then
      Brush.Color := $00000000
    else if (ARow > 0) and (ARow mod 2 = 1) then
      Brush.Color := BG_COLOR
    else
      Brush.Color := BG_COLOR_LIGHT;

    FillRect(Rect);

    DrawRect := Rect;
    if (ACol in NumCells) and (ARow > 0) then
    begin
      DrawRect.Right := DrawRect.Right - RIGHT_MARGIN;
      AlignFlags := DT_RIGHT or DT_VCENTER or DT_SINGLELINE;
    end
    else
    begin
      DrawRect.Left := DrawRect.Left + LEFT_MARGIN;
      AlignFlags := DT_LEFT or DT_VCENTER or DT_SINGLELINE;
    end;
    DrawText(Handle, PChar(CellText), Length(CellText), DrawRect, AlignFlags);
  end;

end;



procedure TForm1.GridTradeResultsMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Col, Row: Integer;

begin
  GridTradeResults.MouseToCell(X, Y, Col, Row);
  if Row = 0 then
  begin
    Analyzer.OutputResultsToGrid(GridTradeResults, Col);
    FSortDescending := not FSortDescending;
  end;
end;

procedure TForm1.PaintBoxItemTypePaint(Sender: TObject);
begin
  if Assigned(ItemBitMap) and not ItemBitmap.Empty then
  begin
    // For transparency, if using a PNG, also consider TPngImage
    PaintBoxItemType.Canvas.Draw(0, 0, ItemBitmap); // Top-left; supports mask transparency if set
  end;
end;

procedure TForm1.PaintBoxTradeRouteMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then
  begin
    IsPanning := True;
    MousePanStartX := X;
    MousePanStartY := Y;
    MousePanLastX := X;
    MousePanLastY := Y;
    MouseMoved := False;
    //HideNodeHint;
  end;

end;

procedure TForm1.PaintBoxTradeRouteMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  i: Integer;
  dx, dy, dist, minDist: Double;
  ClosestIdx: Integer;
  sRec: TSystemsRec;
  hint: string;
begin
  if IsPanning then
  begin
    PanX := PanX + (X - MousePanLastX);
    PanY := PanY + (Y - MousePanLastY);
    MousePanLastX := X;
    MousePanLastY := Y;
    PaintBoxTradeRoute.Invalidate;
    Application.CancelHint;
    Exit;
  end;
  MouseX := X;
  MouseY := Y;
  minDist := 10000;
  ClosestIdx := -1;
  HilitedNodeIdx := -1;
  for i := 0 to High(SystemRecs) do
  begin
    dx := MouseX - Cx[i];
    dy := MouseY - Cy[i];
    dist := sqrt(dx * dx + dy * dy);
    if dist < minDist then
    begin
      minDist := dist;
      ClosestIdx := i;
    end;
  end;
  if (ClosestIdx <> -1) and (minDist < (7 * ClampedZoom + 8)) then
    HilitedNodeIdx := ClosestIdx
  else
    HilitedNodeIdx := -1;

  if HilitedNodeIdx <> -1 then
  begin
    sRec := SystemRecs[HilitedNodeIdx];
    hint :=
      'System: ' + sRec.SystemName + sLineBreak +
      'Security: ' + Format('%.1f', [sRec.Security]) + sLineBreak +
      'Region: ' + RegionManager.RegionIDToName(sRec.RegionID);
      PaintBoxTradeRoute.Hint := hint;
      Application.ActivateHint(PaintBoxTradeRoute.ClientToScreen(Point(MouseX + 20, MouseY)));
  end else
    Application.CancelHint;


  PaintBoxTradeRoute.Invalidate;
end;


procedure TForm1.OutputNodeDataToPanel(const sRec: TSystemsRec);
var
  RegionName: string;
  Details: string;
begin
  RegionName := RegionManager.RegionIDToName(sRec.RegionID);

  Details :=
    'System: '   + sRec.SystemName             + sLineBreak +
    'Security: ' + FormatFloat('0.0', sRec.Security) + sLineBreak +
    'Region: '   + RegionName                  + sLineBreak +
    'Solar System ID: ' + IntToStr(sRec.SystemID) + sLineBreak;

  // Optionally display more attributes from TSystemsRec if needed:
  // Details := Details + 'Constellation ID: ' + IntToStr(sRec.ConstellationID) + sLineBreak;
  // Details := Details + 'Additional Data: ...' + sLineBreak;

  PanelRouteDetails.Caption := Details;
end;




procedure TForm1.PaintBoxTradeRouteMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  i: Integer;
  dx, dy, NodeRadius: Integer;
  found: Boolean;
begin
  if Button = mbLeft then
  begin
    found := False;
    NodeRadius := 7; // your node size

    if IsPanning then
    begin
      // Only treat as click if mouse didn't move far
      if (Abs(X - MousePanStartX) <= 4) and (Abs(Y - MousePanStartY) <= 4) then
      begin
        for i := 0 to High(SystemRecs) do
        begin
          dx := X - Cx[i];
          dy := Y - Cy[i];
          if Sqrt(dx * dx + dy * dy) <= NodeRadius then
          begin
            SelectedNodeIdx := i;
            OutputNodeDataToPanel(SystemRecs[i]);
            found := True;
            Break;
          end;
        end;
        // Deselect if not clicking on a node
        if not found then
        begin
          SelectedNodeIdx := -1;
          PanelRouteDetails.Caption := '';
        end;
        PaintBoxTradeRoute.Invalidate; // Update highlight display
      end;
      // If mouse moved far, it was a pan/drag—no selection/deselection.
      IsPanning := False;
    end;
  end;
end;




procedure TForm1.PaintBoxTradeRoutePaint(Sender: TObject);
begin
  if not Assigned(RouteBitmap) then
    RouteBitmap := TBitmap.Create;
  RouteBitmap.SetSize(PaintBoxTradeRoute.Width, PaintBoxTradeRoute.Height);

  //DrawRouteEveStyle(RouteBitmap, Regionmanager.AllSystems, MyRoute, SelectedNodeIdx, HilitedNodeIdx, Zoom, PanX, PanY, DashAnimPhase);
  DrawRouteEveStyle(
    RouteBitmap,
    Regionmanager.AllSystems,          // dictionary or array of all TSystemsRec
    MyRoute     ,        // route
    SelectedNodeIdx,
    HilitedNodeIdx,
    SystemRecs,          // var
    Cx,                  // var
    Cy,                  // var
    ClampedZoom,         // var
    Zoom,
    PanX, PanY,
    DashAnimPhase,
    0.12
  );
  PaintBoxTradeRoute.Canvas.Draw(0, 0, RouteBitmap);

  // After painting, reset so future paints (not wheel-induced) use -1, -1.
  LastMouseX := -1;
  LastMouseY := -1;
end;

procedure TForm1.GridTradeResultsMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  TypeID, idx: integer;
  Order: TOrderTripResult;
  TypeName, TestName: string;
  ShipTypeID: Integer;
  NameParts: TArray<string>;
  i: Integer;
  isSKIN: Boolean;
  Col, Row: Integer;
  procedure OverlaySkinIcon(MainBitmap: TBitmap);
  var
    Png: TPngImage;
    DestRect: TRect;
  begin
    Png := TPngImage.Create;
    try
      Png.LoadFromResourceName(HInstance, 'SKIN');
      DestRect := Rect(MainBitmap.Width - 32, MainBitmap.Height - 32, MainBitmap.Width, MainBitmap.Height);
      Png.Draw(MainBitmap.Canvas, DestRect);
    finally
      Png.Free;
    end;
  end;
begin
  GridTradeResults.MouseToCell(X, Y, Col, Row);
  if Row > 0 then
  begin
    isSKIN := false;
    idx := Row;
    if (Length(SortedTradeResults) > 0) and (idx-1 < Length(SortedTradeResults)) then
    begin
      Order := SortedTradeResults[idx - 1];
      TypeID := Order.TypeID;
      TypeName := Regionmanager.TypeIDToName(TypeID);
      ShipTypeID := TypeID;
      if TypeName.EndsWith(' SKIN') then
      begin
        isSKIN := true;
        TypeName := Trim(Copy(TypeName, 1, Length(TypeName) - 5));
        NameParts := TypeName.Split([' ']);
        for i := Length(NameParts) downto 1 do
        begin
          TestName := string.Join(' ', Copy(NameParts, 0, i));
          ShipTypeID := Regionmanager.TypeNameToID(TestName);
          if ShipTypeID <> 0 then
          begin
            TypeName := TestName;
            Break;
          end;
        end;
      end;
      LabelTypeMarketGroup.Caption := StringReplace(Regionmanager.MarketGroupBreadcrumb(TypeID), '&', '&&', [rfReplaceAll]);
      LabelTypeName.Caption := Regionmanager.TypeIDToName(TypeID);
      LabelSellerDetails.Caption :=
        Format('%s ISK' + sLineBreak + '%s ISK' + sLineBreak + '%s ISK' + sLineBreak + '%s ISK',
          [
            FormatFloat('#,##0.00', RegionManager.GlobalMarketStats[TypeID].SellMin),
            FormatFloat('#,##0.00', RegionManager.GlobalMarketStats[TypeID].SellAvg),
            FormatFloat('#,##0.00', RegionManager.GlobalMarketStats[TypeID].SellWeighted),
            FormatFloat('#,##0.00', RegionManager.GlobalMarketStats[TypeID].SellMax)
          ]);
      LabelBuyerDetails.Caption :=
        Format('%s ISK' + sLineBreak + '%s ISK' + sLineBreak + '%s ISK' + sLineBreak + '%s ISK',
          [
            FormatFloat('#,##0.00', RegionManager.GlobalMarketStats[TypeID].BuyMax),
            FormatFloat('#,##0.00', RegionManager.GlobalMarketStats[TypeID].BuyAvg),
            FormatFloat('#,##0.00', RegionManager.GlobalMarketStats[TypeID].BuyWeighted),
            FormatFloat('#,##0.00', RegionManager.GlobalMarketStats[TypeID].BuyMin)
          ]);

      if Assigned(ItemBitmap) then
        ItemBitmap.Free;

      if TypeName.EndsWith(' Blueprint') then
        ItemBitmap := Downloader.GetEveImageBitmap('types', ShipTypeID.ToString, 'bp', '64')
      else
      if isSKIN then
      begin
        ItemBitmap := Downloader.GetEveImageBitmap('types', ShipTypeID.ToString, 'icon', '64');
        OverlaySkinIcon(ItemBitmap);
      end
      else
        ItemBitmap := Downloader.GetEveImageBitmap('types', ShipTypeID.ToString, 'icon', '64');
      PaintBoxItemType.Invalidate; // Triggers repaint

      PanelItemSummary.Visible := true;
      MyRoute := Order.JumpRoute;  // or similar, depending on your model
      // --- Map Route.SystemIDs to SystemRecs ---
      SetLength(SystemRecs, Length(MyRoute.SystemIDs));
      for i := 0 to High(MyRoute.SystemIDs) do
        SystemRecs[i] := RegionManager.SystemIDToRec(MyRoute.SystemIDs[i]);
      // Re-project node positions
      SetLength(Cx, Length(SystemRecs));
      SetLength(Cy, Length(SystemRecs));
      // Reset mouse highlight
      HilitedNodeIdx := -1;
      SelectedNodeIdx := -1;
      PanelRouteMap.Visible := true;
      PaintBoxTradeRoute.Invalidate;         // Triggers OnPaint, showing the new route
    end else
    begin
      PanelRouteMap.Visible := false;
      PanelItemSummary.Visible := false;
    end;
  end;
end;


procedure TForm1.GridTradeHistoryDrawCell(Sender: TObject; ACol, ARow: LongInt; Rect: TRect; State: TGridDrawState);
var
  CellText: string;
const
  NumCells: set of Byte = [3,5,6,7,8,10];
  LEFT_MARGIN = 8;
  RIGHT_MARGIN = 8;
var
  DrawRect: TRect;
  AlignFlags: Integer;
begin
  with GridTradeHistory, Canvas do
  begin
    CellText := Cells[ACol, ARow];
    Font.Name := 'Bahnschrift Light Condensed';
    if ARow = 0 then
    begin
      Brush.Color := $00000000;
      Font.Style := [];
      Font.Size := 12;
      Font.Color := clWhite;
    end
    else
    begin
      Font.Style := [];
      Font.Size := 12;
      if (TradeHistory.Count > 0) and
         (ACol >= 0) and (ACol < Length(GridHelper.History.CellColors)) and
         (ARow >= 0) and (ARow < Length(GridHelper.History.CellColors[ACol])) and
         (GridHelper.History.CellColors[ACol, ARow] <> clNone) then
        Font.Color := GridHelper.History.CellColors[ACol, ARow]
      else
        Font.Color := clWhite;
    end;
    if gdSelected in State then
      Brush.Color := $00000000
    else if (ARow > 0) and (ARow mod 2 = 1) then
      Brush.Color := BG_COLOR
    else
      Brush.Color := BG_COLOR_LIGHT;
    FillRect(Rect);

    DrawRect := Rect;
    if (ACol in NumCells) and (ARow > 0) then
    begin
      DrawRect.Right := DrawRect.Right - RIGHT_MARGIN;
      AlignFlags := DT_RIGHT or DT_VCENTER or DT_SINGLELINE;
    end
    else
    begin
      DrawRect.Left := DrawRect.Left + LEFT_MARGIN;
      AlignFlags := DT_LEFT or DT_VCENTER or DT_SINGLELINE;
    end;
    DrawText(Handle, PChar(CellText), Length(CellText), DrawRect, AlignFlags);
  end;
end;

procedure TForm1.GridTradeHistoryMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Col, Row: Integer;
begin
  GridTradeHistory.MouseToCell(X, Y, Col, Row);
  if Row = 0 then
  begin
    GridHelper.History.OutputToGrid(GridTradeHistory, TradeHistory, RegionManager, 0, FSortDescending);
//    OutputTradeHistory(Col);
    FSortDescending := not FSortDescending;
  end;
end;

procedure TForm1.ClearResults;
begin
  PanelItemSummary.Visible := false;
end;

procedure TForm1.DeleteTradeClick(Sender: TObject);
var
  r, c, i, TxnID: Integer;
  SelTop, SelBottom: Integer;
  Confirm: Integer;
begin
  SelTop := GridTradeHistory.Selection.Top;
  SelBottom := GridTradeHistory.Selection.Bottom;

  if (SelTop > 0) and (SelBottom < GridTradeHistory.RowCount) and (SelTop <= SelBottom) then
  begin
    Confirm := MessageDlg('Delete the selected trade history records?', mtConfirmation, [mbYes, mbNo], 0);
    if Confirm = mrYes then
    begin
      for r := SelBottom downto SelTop do
      begin
        if TryStrToInt(GridTradeHistory.Cells[0, r], TxnID) then
        begin
          if TradeHistory.ContainsKey(TxnID) then
            TradeHistory.Remove(TxnID);

          for c := 0 to GridTradeHistory.ColCount - 1 do
            for i := r to GridTradeHistory.RowCount - 2 do
              CellColors[c, i] := CellColors[c, i + 1];
          SetLength(CellColors, GridTradeHistory.ColCount, GridTradeHistory.RowCount - 1);

          for i := r to GridTradeHistory.RowCount - 2 do
            for c := 0 to GridTradeHistory.ColCount - 1 do
              GridTradeHistory.Cells[c, i] := GridTradeHistory.Cells[c, i + 1];

          GridTradeHistory.RowCount := GridTradeHistory.RowCount - 1;
        end;
      end;
      Parser.SaveTradeHistory(TradeHistory);
    end;
  end;
end;



procedure TForm1.PopulateListBoxRegions;
var
  i: Integer;
  rec: TRegionsRec;
begin
  ListBoxRegions.Items.Clear;
  for i := 0 to RegionManager.RegionCount-1 do
  begin
    rec := RegionManager.RegionIndexToRec(i);
    if (not chkEmpireSpaceOnly.Checked) or (rec.factionID <> 0) then
      ListBoxRegions.Items.Add(rec.regionName);
  end;
end;

procedure TForm1.PopupMenuMarketTreePopup(Sender: TObject);
var
  Node: TTreeNode;
  Data: TMarketTreeNodeData;
begin
  Node := TreeViewMarket.Selected;
  if (Node <> nil) and (Node.Data <> nil) then
  begin
    Data := TMarketTreeNodeData(Node.Data);
    if Data.IsItem then
      AddManualTransaction1.Enabled := True
    else
      AddManualTransaction1.Enabled := False;
  end
  else
    AddManualTransaction1.Enabled := False;
end;

procedure TForm1.EditFilterMarketChange(Sender: TObject);
begin
  if (EditFilterMarket.Text <> '') then
  begin
    TimerMarketFilter.Enabled := False;
    TimerMarketFilter.Enabled := True;
    // FMarketTreeIsFiltered will be set True when the filter runs
  end
  else
  begin
    if TMarketTreeBuilder.IsFiltered then
    begin
      // Use your currently enabled build:
      TMarketTreeBuilder.BuildFullMarketTree(TreeViewMarket, Parser.FMarketGroups, Parser.FParentToChildren, Parser.FTypes);
      //TMarketTreeAsyncBuilder.BuildFullMarketTreeAsync(TreeViewMarket, Parser.FMarketGroups, Parser.FParentToChildren, Parser.FTypes);

      FMarketTreeIsFiltered := False;
    end;
    // If already unfiltered, do nothing
  end;
end;


procedure TForm1.TimerAnimateLinesTimer(Sender: TObject);
begin
  DashAnimPhase := (DashAnimPhase + 1) mod (RouteDashLen + RouteGapLen);
  PaintBoxTradeRoute.Invalidate;
end;

procedure TForm1.TimerMarketFilterTimer(Sender: TObject);
begin
  Logger.Log(Format('Filtering Market Tree: %s', [EditFilterMarket.Text]));
  TimerMarketFilter.Enabled := False;
  //FilterMarketTree(EditFilterMarket.Text);
  TMarketTreeBuilder.FilterMarketTree(TreeViewMarket, Parser.FMarketGroups, Parser.FTypes, Parser.FParentToChildren, EditFilterMarket.Text);

end;


procedure TForm1.TrackBarMaxSecChange(Sender: TObject);
begin
  LabelMaxSec.Caption := (TrackBarMaxSec.Position / 10).ToString();
end;

procedure TForm1.TrackBarMinSecChange(Sender: TObject);
begin
  LabelMinSec.Caption := (TrackBarMinSec.Position / 10).ToString();
end;

procedure TForm1.TreeViewMarketDblClick(Sender: TObject);
var
  Node: TTreeNode;
  Data: TMarketTreeNodeData;
begin
  // Uses selected node (single-selection mode)
  Node := TreeViewMarket.Selected;
  if (Node <> nil) and (Node.Data <> nil) then
  begin
    Data := TMarketTreeNodeData(Node.Data);
    Logger.Log(
      'Name='         + Data.Name +
      ', MarketGroupID=' + Data.MarketGroupID +
      ', ParentGroupID=' + Data.ParentGroupID +
      ', IsItem='     + BoolToStr(Data.IsItem, True) +
      ', HasTypes='   + BoolToStr(Data.HasTypes, True) +
      ', TypeID='     + Data.TypeID.ToString +
      ', IconID='     + Data.IconID.ToString +
      ', Description=' + Data.Description
    );
  end;
end;

procedure TForm1.TreeViewMarketMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Node: TTreeNode;
begin
  Node := TreeViewMarket.GetNodeAt(X, Y);
  if Node = nil then
  begin
    // For single-select TreeViews:
    TreeViewMarket.Selected := nil;
    // For multi-select (if available):
    if TreeViewMarket.SelectionCount > 0 then
      TreeViewMarket.ClearSelection;
  end;
  if Button = mbRight then
  begin
    Node := TreeViewMarket.GetNodeAt(X, Y);
    if Node <> nil then
      TreeViewMarket.Selected := Node;  // or use Focused for multi-select
  end;
end;


end.

