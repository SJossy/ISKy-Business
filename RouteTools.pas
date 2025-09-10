unit RouteTools;

interface

uses
  System.SysUtils, System.Math, System.Types, Winapi.Windows, Vcl.Graphics,
  GDIPAPI, GDIPOBJ, System.UITypes, System.Generics.Collections, Common;

procedure DrawRouteEveStyle(
  Bitmap: TBitmap;
  const AllSystems: TArray<TSystemsRec>;
  const Route: TJumpRoute;
  SelectedNodeIdx, HilitedNodeIdx: Integer;
  var RouteSystems: TArray<TSystemsRec>;
  var Cx, Cy: TArray<Integer>;
  var ClampedZoom: Double;
  Zoom: Double;                // <-- add this parameter!
  PanX, PanY: Integer;
  DashAnimPhase: Integer = 0;
  MarginPct: Double = 0.12
);


implementation

function ClampDouble(const Value, MinVal, MaxVal: Double): Double;
begin
  if Value < MinVal then Exit(MinVal)
  else if Value > MaxVal then Exit(MaxVal)
  else Result := Value;
end;

function MakeColor(a, r, g, b: Byte): TGPColor; inline;
begin
  Result := (a shl 24) + (r shl 16) + (g shl 8) + b;
end;

procedure DrawAlphaNode(Bitmap: TBitmap; X, Y: Integer; BaseColor: TColor; Zoom: Double; Selected: Boolean; Hilited: Boolean);
var
  Graphics: TGPGraphics;
  GlowBrush: TGPSolidBrush;
  OutlinePen: TGPPen;
  GlowColor: TGPColor;
  GlowRadius, NodeRadius, r: Double;
  BaseR, BaseG, BaseB: Integer;
  alpha: Integer;
  Steps, step: Integer;
  frac: Double;
  MaxAlpha: Integer;
  Scale: Double;
begin
  Scale := 1.8 - 0.01 * ((Zoom - 1.0) / (2.25 - 1.0));
  GlowRadius := 7 * Scale * 0.5;
  NodeRadius := 7 * Scale;
  Steps := 15;
  MaxAlpha := 65;
  Graphics := TGPGraphics.Create(Bitmap.Canvas.Handle);
  BaseR := GetRValue(BaseColor);
  BaseG := GetGValue(BaseColor);
  BaseB := GetBValue(BaseColor);

  // Draw outer glow
  for step := Steps downto 1 do
  begin
    frac := step / Steps;
    r := GlowRadius * frac;
    alpha := Round(MaxAlpha * frac * frac * frac);
    if alpha > 0 then
    begin
      GlowColor := MakeColor(alpha, BaseR, BaseG, BaseB);
      GlowBrush := TGPSolidBrush.Create(GlowColor);
      Graphics.FillEllipse(GlowBrush, Round(X - r), Round(Y - r), Round(r * 2), Round(r * 2));
      GlowBrush.Free;
    end;
  end;

  // Highlighted or selected outline
  if Selected then
  begin
    OutlinePen := TGPPen.Create(MakeColor(255, 255, 255, 255), 2);
    Graphics.DrawEllipse(OutlinePen, Round(X - NodeRadius*0.75), Round(Y - NodeRadius*0.75), Round(NodeRadius*0.75 * 2), Round(NodeRadius*0.75 * 2));
    OutlinePen.Free;
  end
  else if Hilited then
  begin
    OutlinePen := TGPPen.Create(MakeColor(128, 255, 255, 255), 2);
    Graphics.DrawEllipse(OutlinePen, Round(X - NodeRadius*0.75), Round(Y - NodeRadius*0.75), Round(NodeRadius*0.75 * 2), Round(NodeRadius*0.75 * 2));
    OutlinePen.Free;
  end;
  Graphics.Free;
end;

procedure DrawRouteEveStyle(
  Bitmap: TBitmap;
  const AllSystems: TArray<TSystemsRec>;
  const Route: TJumpRoute;
  SelectedNodeIdx, HilitedNodeIdx: Integer;
  var RouteSystems: TArray<TSystemsRec>;
  var Cx, Cy: TArray<Integer>;
  var ClampedZoom: Double;
  Zoom: Double;                // <-- add this parameter!
  PanX, PanY: Integer;
  DashAnimPhase: Integer = 0;
  MarginPct: Double = 0.12
);
var
  i, SecIdx: Integer;
  PBWidth, PBHeight, Margin: Integer;
  SysMap: TDictionary<Integer, TSystemsRec>;
  XMin, XMax, ZMin, ZMax, MapSize: Double;
  dx, dy, x, y, x2, y2, segLen, t: Double;
  ColorA, ColorB: TColor;
  LabelText, SysTxt, SecTxt: string;
  GPGraphics: TGPGraphics;
  GPFont: TGPFont;
  LabelBrush: TGPSolidBrush;
  Origin: TGPPointF;

begin
  SysMap := TDictionary<Integer, TSystemsRec>.Create(Length(AllSystems));
  try
    // Build lookup for system ID
    for i := 0 to High(AllSystems) do
      SysMap.AddOrSetValue(AllSystems[i].SystemID, AllSystems[i]);
    SetLength(RouteSystems, Length(Route.SystemIDs));
    for i := 0 to High(Route.SystemIDs) do
      if not SysMap.TryGetValue(Route.SystemIDs[i], RouteSystems[i]) then
        raise Exception.CreateFmt('Route system ID %d not found in system mapping!', [Route.SystemIDs[i]]);

    Bitmap.PixelFormat := pf32bit;
    PBWidth := Bitmap.Width;
    PBHeight := Bitmap.Height;
    Margin := Round(PBWidth * MarginPct);
    Bitmap.Canvas.Brush.Color := $1A1A1A;
    Bitmap.Canvas.FillRect(Rect(0, 0, PBWidth, PBHeight));

    ClampedZoom := ClampDouble(Zoom, MIN_ZOOM, MAX_ZOOM);

    if Length(RouteSystems) = 0 then Exit;
    XMin := RouteSystems[0].x; XMax := RouteSystems[0].x;
    ZMin := RouteSystems[0].z; ZMax := RouteSystems[0].z;
    for i := 1 to High(RouteSystems) do
    begin
      XMin := Min(XMin, RouteSystems[i].x);
      XMax := Max(XMax, RouteSystems[i].x) + 40;
      ZMin := Min(ZMin, RouteSystems[i].z);
      ZMax := Max(ZMax, RouteSystems[i].z);
    end;
    MapSize := Max(XMax - XMin, ZMax - ZMin);

    SetLength(Cx, Length(RouteSystems));
    SetLength(Cy, Length(RouteSystems));
    for i := 0 to High(RouteSystems) do
    begin
      Cx[i] := Margin + Round((RouteSystems[i].x - XMin) / MapSize * (PBWidth - 2 * Margin) * ClampedZoom) + PanX;
      Cy[i] := Margin + Round((-(RouteSystems[i].z - ZMax)) / MapSize * (PBHeight - 2 * Margin) * ClampedZoom) + PanY;
    end;

    // Draw dashed lines
    for i := 0 to High(RouteSystems) - 1 do
    begin
      ColorA := ColorToRGB(SecurityColors[Max(Round(RouteSystems[i].Security * 10), 0)]);
      ColorB := ColorToRGB(SecurityColors[Max(Round(RouteSystems[i+1].Security * 10), 0)]);
      dx := (Cx[i] - Cx[i+1]);
      dy := (Cy[i] - Cy[i+1]);
      segLen := sqrt(dx*dx + dy*dy);
      var PatternLen := 12 + 8;
      var FracMod := DashAnimPhase mod PatternLen;
      t := -FracMod;
      while t < segLen do
      begin
        x := Cx[i+1] + dx * (Max(t, 0)/segLen);
        y := Cy[i+1] + dy * (Max(t, 0)/segLen);
        x2 := Cx[i+1] + dx * (Min((t+12), segLen)/segLen);
        y2 := Cy[i+1] + dy * (Min((t+12), segLen)/segLen);
        var frac := Max(t, 0) / segLen;
        var DashColor := RGB(
          Round((1-frac)*GetRValue(ColorB) + frac*GetRValue(ColorA)),
          Round((1-frac)*GetGValue(ColorB) + frac*GetGValue(ColorA)),
          Round((1-frac)*GetBValue(ColorB) + frac*GetBValue(ColorA))
        );
        if t + 12 > 0 then
        begin
          Bitmap.Canvas.Pen.Color := DashColor;
          Bitmap.Canvas.Pen.Width := 2;
          Bitmap.Canvas.Pen.Style := psSolid;
          Bitmap.Canvas.MoveTo(Round(x), Round(y));
          Bitmap.Canvas.LineTo(Round(x2), Round(y2));
        end;
        t := t + PatternLen;
      end;
    end;

    // Draw nodes
    for i := 0 to High(RouteSystems) do
    begin
      SecIdx := Max(Round(RouteSystems[i].Security * 10), 0);
      ColorA := ColorToRGB(SecurityColors[SecIdx]);
      DrawAlphaNode(
        Bitmap,
        Cx[i], Cy[i], ColorA, ClampedZoom,
        (i = SelectedNodeIdx),
        (i = HilitedNodeIdx) and (i <> SelectedNodeIdx)
      );
    end;

    // Draw system labels
    for i := 0 to High(RouteSystems) do
    begin
      SecIdx := Max(Round(RouteSystems[i].Security * 10), 0);
      ColorA := ColorToRGB(SecurityColors[SecIdx]);
      Bitmap.Canvas.Font.Name := 'Bahnschrift SemiCondensed';
      Bitmap.Canvas.Font.Size := 10;
      Bitmap.Canvas.Brush.Style := bsClear;
      var zoomOffset := Round(2 * Min(ClampedZoom, 5));
      var labelOffset := 4 + zoomOffset;
      SysTxt := RouteSystems[i].SystemName + ' ';
      SecTxt := Format('%.1f', [RouteSystems[i].Security]);
      LabelText := SysTxt + SecTxt;
      var LabelWidth := Bitmap.Canvas.TextWidth(LabelText);
      var LabelHeight := Bitmap.Canvas.TextHeight(LabelText);
      var unclampedLabelX := Cx[i] + labelOffset;
      var unclampedLabelY := Cy[i] - 5;
      var LabelX := unclampedLabelX;
      var LabelY := unclampedLabelY;
      if LabelX + LabelWidth > PBWidth then LabelX := PBWidth - LabelWidth - 2;
      if LabelX < 2 then LabelX := 2;
      if LabelY < 2 then LabelY := 2;
      if LabelY + LabelHeight > PBHeight then LabelY := PBHeight - LabelHeight - 2;
      var fadeRight := ClampDouble((PBWidth - (unclampedLabelX + LabelWidth)) / LABEL_FADE_MARGIN, 0, 1);
      var fadeLeft := ClampDouble((unclampedLabelX - 2) / LABEL_FADE_MARGIN, 0, 1);
      var fadeTop := ClampDouble((unclampedLabelY - 2) / LABEL_FADE_MARGIN, 0, 1);
      var fadeBottom := ClampDouble((PBHeight - (unclampedLabelY + LabelHeight)) / LABEL_FADE_MARGIN, 0, 1);
      var posFade := Min(Min(fadeRight, fadeLeft), Min(fadeTop, fadeBottom));
      var zoomFade: Double := 1.0;
      if (i <> 0) and (i <> High(RouteSystems)) then
      begin
        if ClampedZoom <= 1.75 then
          zoomFade := 0.0
        else
          zoomFade := ClampDouble((ClampedZoom - 1.75) / (MAX_ZOOM - 1.75), 0.0, 1.0);
      end;
      var finalFade := posFade * zoomFade;
      if (i = 0) or (i = High(RouteSystems)) then finalFade := posFade;
      var Alpha := Round(255 * finalFade);
      if Alpha > 0 then
      begin
        GPGraphics := TGPGraphics.Create(Bitmap.Canvas.Handle);
        GPFont := TGPFont.Create('Bahnschrift SemiCondensed', 10);
        LabelBrush := TGPSolidBrush.Create(MakeColor(Alpha, 255, 255, 255));
        Origin.X := LabelX;
        Origin.Y := LabelY;
        GPGraphics.DrawString(SysTxt, Length(SysTxt), GPFont, Origin, LabelBrush);
        LabelBrush.Free;
        LabelBrush := TGPSolidBrush.Create(MakeColor(Alpha, GetRValue(ColorA), GetGValue(ColorA), GetBValue(ColorA)));
        Origin.X := LabelX + Bitmap.Canvas.TextWidth(SysTxt);
        GPGraphics.DrawString(SecTxt, Length(SecTxt), GPFont, Origin, LabelBrush);
        LabelBrush.Free;
        GPFont.Free;
        GPGraphics.Free;
      end;
    end;
  finally
    SysMap.Free;
  end;
end;



end.

