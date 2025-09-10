unit TransactionView;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls, Vcl.ExtCtrls, System.Types,
  Downloader, Common, RegionManager, Vcl.NumberBox, Logger, Vcl.WinXPickers, DateUtils, Vcl.Imaging.pngimage;
type
  TFormTransaction = class(TForm)
    PanelTradeSummary: TPanel;
    LabelTypeMarketGroup: TLabel;
    LabelTypeName: TLabel;
    Label1: TLabel;
    ComboBoxSourceRegion: TComboBox;
    Label2: TLabel;
    Label3: TLabel;
    ComboBoxSourceStation: TComboBox;
    Label4: TLabel;
    NumberBoxQuantity: TNumberBox;
    Label5: TLabel;
    NumberBoxBuyPrice: TNumberBox;
    NumberBoxSellPrice: TNumberBox;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    ComboBoxDeliveryRegion: TComboBox;
    ComboBoxDeliveryStation: TComboBox;
    Label9: TLabel;
    NumberBoxSalesTax: TNumberBox;
    pnlConfirmTrade: TPanel;
    DatePicker: TDatePicker;
    TimePicker: TTimePicker;
    PaintBox: TPaintBox;
    procedure FormShow(Sender: TObject);
    procedure ComboBoxSourceRegionExit(Sender: TObject);
    procedure ComboBoxSourceRegionSelect(Sender: TObject);
    procedure ComboBoxDeliveryRegionExit(Sender: TObject);
    procedure ComboBoxDeliveryRegionSelect(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure panelMouseEnter(Sender: TObject);
    procedure panelMouseLeave(Sender: TObject);
    procedure panelMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure panelMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure pnlConfirmTradeClick(Sender: TObject);
    procedure PaintBoxPaint(Sender: TObject);
  private
    FRegionManager: TRegionManager;
    FOrder: TOrderTripResult;
    FTrade: TTradeHistoryRec;
    FDownloader: TDownloader;
    FTypeID: Integer;
    FMode: string;
    FOrderID: Integer;
    ItemBitmap: TBitMap;
    procedure PopulateComboBoxRegions(ComboBox: TComboBox);
  public
    ResultMarketOrder: TTradeHistoryRec;
    ResultOrderNo: Integer;
    property RegionManager: TRegionManager read FRegionManager write FRegionManager;
    property Downloader: TDownloader read FDownloader write FDownloader;
    property Order: TOrderTripResult read FOrder write FOrder;
    property Mode: string read FMode write FMode;
    property Trade: TTradeHistoryRec read FTrade write FTrade;
    property OrderID: Integer read FOrderID write FOrderID;
    property TypeID: Integer read FTypeID write FTypeID;
  end;

var
  FormTransaction: TFormTransaction;
  CallCount: Integer = 0;
implementation

{$R *.dfm}


procedure TFormTransaction.PanelMouseEnter(Sender: TObject);
begin
  if Sender is TPanel then
    TPanel(Sender).Color := clSkyBlue; // highlight color
end;

procedure TFormTransaction.PanelMouseLeave(Sender: TObject);
begin
  if Sender is TPanel then
    TPanel(Sender).Color := BG_COLOR_DARK; // default/button color
end;

procedure TFormTransaction.PanelMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Sender is TPanel then
    TPanel(Sender).Color := clHighlight; // pressed color
end;

procedure TFormTransaction.PanelMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Sender is TPanel then
    TPanel(Sender).Color := clSkyBlue; // revert to hover
end;



procedure TFormTransaction.pnlConfirmTradeClick(Sender: TObject);
begin
  with ResultMarketOrder do
  begin
    DateTime := DateOf(DatePicker.Date) + TimeOf(TimePicker.Time);
    TypeID := FTypeID;
    BuyRegionID := FRegionManager.RegionNameToID(ComboBoxSourceRegion.Text);
    BuyStationID := FRegionManager.StationNameToID(ComboBoxSourceStation.Text);
    SellRegionID := FRegionManager.RegionNameToID(ComboBoxDeliveryRegion.Text);
    SellStationID := FRegionManager.StationNameToID(ComboBoxDeliveryStation.Text);
    BuyPrice := NumberBoxBuyPrice.ValueFloat;
    SellPrice := NumberBoxSellPrice.ValueFloat;
    Quantity := NumberBoxQuantity.ValueInt;
    SalesTax := NumberBoxSalesTax.ValueFloat;
  end;
  ModalResult := mrOk;
end;

procedure TFormTransaction.ComboBoxSourceRegionExit(Sender: TObject);
var
  rec: TStationsRec;
  I: Integer;
begin
  if ComboBoxSourceRegion.Items.IndexOf(ComboBoxSourceRegion.Text) = -1 then
  begin
    // The entered text does not match any item
    ComboBoxSourceRegion.ItemIndex := -1;
    ComboBoxSourceRegion.Text := '';
  end
  else
  begin
    ComboBoxSourceStation.Items.Clear;
    for I := 0 to FRegionManager.StationCount-1 do
    begin
      rec := FRegionmanager.StationIndexToRec(I);
      if rec.RegionID = FRegionManager.RegionNameToID(ComboBoxSourceRegion.Text) then
        ComboBoxSourceStation.Items.Add(rec.StationName);
    end;
  end;
end;

procedure TFormTransaction.ComboBoxDeliveryRegionExit(Sender: TObject);
var
  rec: TStationsRec;
  I: Integer;
begin
  if ComboBoxDeliveryRegion.Items.IndexOf(ComboBoxDeliveryRegion.Text) = -1 then
  begin
    // The entered text does not match any item
    ComboBoxDeliveryRegion.ItemIndex := -1;
    ComboBoxDeliveryRegion.Text := '';
  end
  else
  begin
    ComboBoxDeliveryStation.Items.Clear;
    for I := 0 to FRegionManager.StationCount-1 do
    begin
      rec := FRegionmanager.StationIndexToRec(I);
      if rec.RegionID = FRegionManager.RegionNameToID(ComboBoxDeliveryRegion.Text) then
        ComboBoxDeliveryStation.Items.Add(rec.StationName);
    end;
  end;
end;

procedure TFormTransaction.ComboBoxSourceRegionSelect(Sender: TObject);
var
  rec: TStationsRec;
  I: Integer;
begin
    ComboBoxSourceStation.Items.Clear;
    for I := 0 to FRegionManager.StationCount-1 do
    begin
      rec := FRegionmanager.StationIndexToRec(I);
      if rec.RegionID = FRegionManager.RegionNameToID(ComboBoxSourceRegion.Text) then
        ComboBoxSourceStation.Items.Add(rec.StationName);
    end;
end;

procedure TFormTransaction.ComboBoxDeliveryRegionSelect(Sender: TObject);
var
  rec: TStationsRec;
  I: Integer;
begin
    ComboBoxDeliveryStation.Items.Clear;
    for I := 0 to FRegionManager.StationCount-1 do
    begin
      rec := FRegionmanager.StationIndexToRec(I);
      if rec.RegionID = FRegionManager.RegionNameToID(ComboBoxDeliveryRegion.Text) then
        ComboBoxDeliveryStation.Items.Add(rec.StationName);
    end;
end;

procedure TFormTransaction.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  FOrder.ItemName := '';
end;

procedure TFormTransaction.FormShow(Sender: TObject);
var
  i, ShipTypeID: Integer;
  TestName, TypeName: string;
  NameParts: TArray<string>;
  isSKIN: Boolean;
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
  PopulateComboBoxRegions(ComboBoxSourceRegion);
  PopulateComboBoxRegions(ComboBoxDeliveryRegion);
  if FOrder.ItemName = '' then
    FTypeID := FTypeID
  else FTypeID := FOrder.TypeID;
  TypeName := FRegionmanager.TypeIDToName(FTypeID);
  ShipTypeID := FTypeID;
  if TypeName.EndsWith(' SKIN') then
  begin
    isSKIN := true;
    TypeName := Trim(Copy(TypeName, 1, Length(TypeName) - 5));
    NameParts := TypeName.Split([' ']);
    for i := Length(NameParts) downto 1 do
    begin
      TestName := string.Join(' ', Copy(NameParts, 0, i));
      ShipTypeID := FRegionmanager.TypeNameToID(TestName);
      if ShipTypeID <> 0 then
      begin
        TypeName := TestName;
        Break;
      end;
    end;
  end;
  LabelTypeMarketGroup.Caption := StringReplace(FRegionmanager.MarketGroupBreadcrumb(FTypeID), '&', '&&', [rfReplaceAll]);
  LabelTypeName.Caption := FRegionmanager.TypeIDToName(FTypeID);

  if Mode = 'MANUAL' then
  begin
    NumberBoxQuantity.Value := 0;
    NumberBoxBuyPrice.Value := 0;
    NumberBoxSellPrice.Value := 0;
    NumberBoxSalesTax.Value := 0;
    ComboBoxSourceRegion.Text := '';
    ComboBoxSourceStation.Text := '';
    ComboBoxDeliveryRegion.Text := '';
    ComboBoxDeliveryStation.Text := '';
    DatePicker.Date := Date;
    TimePicker.Time := Time;
  end
  else if Mode = 'ADD' then
  begin
    NumberBoxQuantity.Value := FOrder.Volume;
    NumberBoxBuyPrice.Value := FOrder.BuyPrice;
    NumberBoxSellPrice.Value := FOrder.SellPrice;
    NumberBoxSalesTax.Value := Forder.SalesTax;
    ComboBoxSourceRegion.Text := FOrder.SourceRegion;
    ComboBoxSourceStation.Text := FOrder.SourceStation;
    if FOrder.DeliveryStationID > 0 then
    begin
      ComboBoxDeliveryRegion.Text := FOrder.DeliveryRegion;
      ComboBoxDeliveryStation.Text := FOrder.DeliveryStation;
    end
    else
    begin
      ComboBoxDeliveryRegion.Text := FOrder.DestRegion;
      ComboBoxDeliveryStation.Text := FOrder.DestStation;
    end;
    DatePicker.Date := Date;
    TimePicker.Time := Time;
  end
  else if Mode = 'EDIT' then
  begin
    NumberBoxQuantity.Value := Trade.Quantity;
    NumberBoxBuyPrice.Value := Trade.BuyPrice;
    NumberBoxSellPrice.Value := Trade.SellPrice;
    NumberBoxSalesTax.Value := Trade.SalesTax;
    ComboBoxSourceRegion.Text := RegionManager.RegionIDToName(Trade.BuyRegionID);
    ComboBoxSourceStation.Text := RegionManager.StationIDToName(Trade.BuyStationID);
    ComboBoxDeliveryRegion.Text := RegionManager.RegionIDToName(Trade.SellRegionID);
    ComboBoxDeliveryStation.Text := RegionManager.StationIDToName(Trade.SellStationID);
    DatePicker.Date := DateOf(Trade.DateTime);
    TimePicker.Time := TimeOf(Trade.DateTime);
  end;

  if Assigned(ItemBitmap) then
    ItemBitmap.Free;

  if TypeName.EndsWith(' Blueprint') then
    ItemBitmap := Downloader.GetEveImageBitmap('types', ShipTypeID.ToString, 'bp', '128')
  else
  if isSKIN then
  begin
    ItemBitmap := Downloader.GetEveImageBitmap('types', ShipTypeID.ToString, 'icon', '128');
    OverlaySkinIcon(ItemBitmap);
  end
  else
    ItemBitmap := Downloader.GetEveImageBitmap('types', ShipTypeID.ToString, 'icon', '128');

  PaintBox.Invalidate; // Triggers repaint
end;


procedure TFormTransaction.PaintBoxPaint(Sender: TObject);
begin
  if Assigned(ItemBitMap) and not ItemBitmap.Empty then
  begin
    // For transparency, if using a PNG, also consider TPngImage
    PaintBox.Canvas.Draw(0, 0, ItemBitmap); // Top-left; supports mask transparency if set
  end;
end;

procedure TFormTransaction.PopulateComboBoxRegions(ComboBox: TComboBox);
var
  i: Integer;
  rec: TRegionsRec;
begin
  ComboBox.Items.Clear;
  for i := 0 to FRegionManager.RegionCount-1 do
  begin
    rec := FRegionManager.RegionIndexToRec(i);
    ComboBox.Items.Add(rec.regionName);
  end;
end;


end.
