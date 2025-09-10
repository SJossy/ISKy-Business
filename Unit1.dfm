object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'ISKy Business'
  ClientHeight = 953
  ClientWidth = 2666
  Color = 1513239
  CustomTitleBar.CaptionAlignment = taCenter
  Constraints.MinHeight = 750
  Constraints.MinWidth = 1400
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clBlack
  Font.Height = -12
  Font.Name = 'Bahnschrift'
  Font.Style = []
  Position = poDesktopCenter
  RoundedCorners = rcOff
  StyleElements = [seClient, seBorder]
  StyleName = 'Auric'
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnMouseWheel = FormMouseWheel
  OnResize = FormResize
  OnShow = FormShow
  DesignSize = (
    2666
    953)
  TextHeight = 14
  object PanelTradeHistory: TPanel
    Left = 0
    Top = 39
    Width = 2667
    Height = 894
    Anchors = [akLeft, akTop, akRight, akBottom]
    Color = 1513239
    ParentBackground = False
    TabOrder = 4
    Visible = False
    DesignSize = (
      2667
      894)
    object GridTradeHistory: TStringGrid
      Left = 7
      Top = 7
      Width = 2655
      Height = 871
      Anchors = [akLeft, akTop, akRight, akBottom]
      BevelKind = bkFlat
      BevelOuter = bvNone
      Color = 2565927
      ColCount = 12
      DefaultColWidth = 150
      DefaultDrawing = False
      DrawingStyle = gdsGradient
      FixedColor = clSilver
      FixedCols = 0
      RowCount = 2
      Font.Charset = ANSI_CHARSET
      Font.Color = clBlack
      Font.Height = -15
      Font.Name = 'Bahnschrift Light SemiCondensed'
      Font.Style = []
      Options = [goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goDrawFocusSelected, goColSizing, goRowSelect, goFixedRowDefAlign]
      ParentFont = False
      PopupMenu = PopupMenuTradeHistory
      TabOrder = 0
      OnDrawCell = GridTradeHistoryDrawCell
      OnMouseDown = GridTradeHistoryMouseDown
    end
  end
  object panelTradeAnalyzer: TPanel
    Left = 0
    Top = 39
    Width = 2667
    Height = 894
    Anchors = [akLeft, akTop, akRight, akBottom]
    Color = 1513239
    ParentBackground = False
    TabOrder = 1
    object PanelAnalyzerLeftWindow: TPanel
      Left = 1
      Top = 1
      Width = 513
      Height = 892
      Align = alLeft
      Color = 1118481
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -15
      Font.Name = 'Bahnschrift'
      Font.Style = []
      ParentBackground = False
      ParentFont = False
      TabOrder = 0
      DesignSize = (
        513
        892)
      object PanelSelectedRegions: TPanel
        Left = 261
        Top = 164
        Width = 247
        Height = 719
        Anchors = [akLeft, akTop, akBottom]
        BevelInner = bvRaised
        BevelOuter = bvNone
        Color = clDefault
        ParentBackground = False
        TabOrder = 0
        object LabelTradeDest: TLabel
          Left = 1
          Top = 323
          Width = 245
          Height = 20
          Alignment = taCenter
          AutoSize = False
          Caption = 'Trade To'
          Color = clDefault
          Font.Charset = ANSI_CHARSET
          Font.Color = clWhite
          Font.Height = -15
          Font.Name = 'Bahnschrift SemiCondensed'
          Font.Style = []
          ParentColor = False
          ParentFont = False
          StyleElements = [seClient, seBorder]
        end
        object LabelTradeSource: TLabel
          Left = 1
          Top = 4
          Width = 245
          Height = 20
          Alignment = taCenter
          AutoSize = False
          Caption = 'Trade From'
          Color = clDefault
          Font.Charset = ANSI_CHARSET
          Font.Color = clWhite
          Font.Height = -15
          Font.Name = 'Bahnschrift SemiCondensed'
          Font.Style = []
          ParentColor = False
          ParentFont = False
          StyleElements = [seClient, seBorder]
        end
        object lbFromRegions: TListBox
          Left = 1
          Top = 27
          Width = 245
          Height = 290
          Style = lbOwnerDrawFixed
          BevelOuter = bvNone
          BorderStyle = bsNone
          Color = clDefault
          Font.Charset = ANSI_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Bahnschrift SemiCondensed'
          Font.Style = []
          ItemHeight = 18
          MultiSelect = True
          ParentFont = False
          Sorted = True
          TabOrder = 0
          StyleElements = [seClient, seBorder]
          OnDragDrop = lbFromRegionsDragDrop
          OnDragOver = lbFromRegionsDragOver
          OnDrawItem = IndentedListboxDrawItem
          OnKeyDown = lbFromRegionsKeyDown
        end
        object lbToRegions: TListBox
          Left = 1
          Top = 349
          Width = 245
          Height = 374
          Style = lbOwnerDrawFixed
          Align = alCustom
          BevelOuter = bvNone
          BorderStyle = bsNone
          Color = clDefault
          Font.Charset = ANSI_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Bahnschrift SemiCondensed'
          Font.Style = []
          ItemHeight = 18
          MultiSelect = True
          ParentFont = False
          Sorted = True
          TabOrder = 1
          StyleElements = [seClient, seBorder]
          OnDragDrop = lbToRegionsDragDrop
          OnDragOver = lbToRegionsDragOver
          OnDrawItem = IndentedListboxDrawItem
          OnKeyDown = lbToRegionsKeyDown
        end
      end
      object PanelAnalyzeParameters: TPanel
        Left = 8
        Top = 8
        Width = 500
        Height = 150
        BevelEdges = [beLeft, beRight]
        BevelInner = bvRaised
        BevelOuter = bvNone
        Color = 2236962
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -15
        Font.Name = 'Bahnschrift SemiCondensed'
        Font.Style = []
        ParentBackground = False
        ParentFont = False
        TabOrder = 1
        object LabelAccountingSkill: TLabel
          Left = 372
          Top = 78
          Width = 56
          Height = 16
          Caption = 'Accounting'
          Color = clDefault
          Font.Charset = ANSI_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Bahnschrift SemiCondensed'
          Font.Style = []
          ParentColor = False
          ParentFont = False
          StyleElements = [seClient, seBorder]
        end
        object LabelCargoCapacity: TLabel
          Left = 206
          Top = 78
          Width = 74
          Height = 16
          Alignment = taRightJustify
          Caption = ' Capacity (m3)'
          Color = clDefault
          Font.Charset = ANSI_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Bahnschrift SemiCondensed'
          Font.Style = []
          ParentColor = False
          ParentFont = False
          StyleElements = [seClient, seBorder]
        end
        object LabelISKBudget: TLabel
          Left = 225
          Top = 45
          Width = 55
          Height = 16
          Alignment = taRightJustify
          Caption = 'ISK Budget'
          Color = clDefault
          Font.Charset = ANSI_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Bahnschrift SemiCondensed'
          Font.Style = []
          ParentColor = False
          ParentFont = False
          StyleElements = [seClient, seBorder]
        end
        object LabelJumpLimit: TLabel
          Left = 396
          Top = 44
          Width = 57
          Height = 16
          Alignment = taRightJustify
          Caption = 'Jump Limit'
          Color = clDefault
          Font.Charset = ANSI_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Bahnschrift SemiCondensed'
          Font.Style = []
          ParentColor = False
          ParentFont = False
          StyleElements = [seClient, seBorder]
        end
        object LabelMaxSec: TLabel
          Left = 74
          Top = 39
          Width = 24
          Height = 18
          Alignment = taRightJustify
          AutoSize = False
          Caption = '1'
          Color = clDefault
          Font.Charset = ANSI_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Bahnschrift SemiCondensed'
          Font.Style = []
          ParentColor = False
          ParentFont = False
          StyleElements = [seClient, seBorder]
        end
        object LabelMaxSecurity: TLabel
          Left = 9
          Top = 39
          Width = 67
          Height = 16
          Alignment = taRightJustify
          Caption = 'Max Security'
          Color = clDefault
          Font.Charset = ANSI_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Bahnschrift SemiCondensed'
          Font.Style = []
          ParentColor = False
          ParentFont = False
          StyleElements = [seClient, seBorder]
        end
        object LabelMinSec: TLabel
          Left = 74
          Top = 5
          Width = 24
          Height = 18
          Alignment = taRightJustify
          AutoSize = False
          Caption = '0.5'
          Color = clDefault
          Font.Charset = ANSI_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Bahnschrift SemiCondensed'
          Font.Style = []
          ParentColor = False
          ParentFont = False
          StyleElements = [seClient, seBorder]
        end
        object LabelMinSecurity: TLabel
          Left = 9
          Top = 5
          Width = 64
          Height = 16
          Alignment = taRightJustify
          Caption = 'Min Security'
          Color = clDefault
          Font.Charset = ANSI_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Bahnschrift SemiCondensed'
          Font.Style = []
          ParentColor = False
          ParentFont = False
          StyleElements = [seClient, seBorder]
        end
        object LabelMinProfit: TLabel
          Left = 352
          Top = 10
          Width = 50
          Height = 16
          Caption = 'Min Profit'
          Color = clDefault
          Font.Charset = ANSI_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Bahnschrift SemiCondensed'
          Font.Style = []
          ParentColor = False
          ParentFont = False
          StyleElements = [seClient, seBorder]
        end
        object LabelMinROI: TLabel
          Left = 242
          Top = 11
          Width = 38
          Height = 16
          Alignment = taRightJustify
          Caption = 'Min ROI'
          Color = clDefault
          Font.Charset = ANSI_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Bahnschrift SemiCondensed'
          Font.Style = []
          ParentColor = False
          ParentFont = False
          StyleElements = [seClient, seBorder]
        end
        object CheckBoxUpwell: TCheckBox
          Left = 11
          Top = 77
          Width = 62
          Height = 17
          Hint = 
            'Selecting this will include player owned stations in search resu' +
            'lts'
          Caption = 'Upwell'
          Color = clDefault
          Font.Charset = ANSI_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Bahnschrift SemiCondensed'
          Font.Style = []
          ParentColor = False
          ParentFont = False
          ParentShowHint = False
          ShowHint = True
          TabOrder = 0
          StyleElements = [seClient, seBorder]
        end
        object NumberISKBudget: TNumberBox
          Left = 286
          Top = 39
          Width = 92
          Height = 28
          Alignment = taCenter
          AutoSize = False
          CurrencyFormat = nbcfNone
          Decimal = 0
          Font.Charset = ANSI_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Bahnschrift SemiCondensed'
          Font.Style = []
          Mode = nbmCurrency
          ParentFont = False
          TabOrder = 1
          Value = 1796962276.000000000000000000
        end
        object NumberISKMinProfit: TNumberBox
          Left = 414
          Top = 5
          Width = 80
          Height = 28
          Alignment = taCenter
          AutoSize = False
          CurrencyFormat = nbcfNone
          Decimal = 0
          Font.Charset = ANSI_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Bahnschrift SemiCondensed'
          Font.Style = []
          Mode = nbmCurrency
          ParentFont = False
          TabOrder = 2
          Value = 10000.000000000000000000
        end
        object NumberJumpLimit: TNumberBox
          Left = 459
          Top = 39
          Width = 34
          Height = 28
          Alignment = taCenter
          AutoSize = False
          CurrencyFormat = nbcfPostfixSpace
          Decimal = 0
          Font.Charset = ANSI_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Bahnschrift SemiCondensed'
          Font.Style = []
          ParentFont = False
          TabOrder = 3
          Value = 60.000000000000000000
        end
        object SpinAccountingLevel: TSpinEdit
          Left = 446
          Top = 73
          Width = 47
          Height = 28
          AutoSize = False
          Font.Charset = ANSI_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Bahnschrift SemiCondensed'
          Font.Style = []
          MaxValue = 5
          MinValue = 0
          ParentFont = False
          TabOrder = 4
          Value = 0
        end
        object TrackBarMaxSec: TTrackBar
          Left = 103
          Top = 39
          Width = 115
          Height = 28
          Min = -1
          Position = 10
          TabOrder = 5
          StyleElements = [seClient, seBorder]
          OnChange = TrackBarMaxSecChange
        end
        object TrackBarMinSec: TTrackBar
          Left = 103
          Top = 5
          Width = 115
          Height = 28
          Min = -1
          ParentShowHint = False
          Position = 5
          ShowHint = True
          TabOrder = 6
          StyleElements = [seClient, seBorder]
          OnChange = TrackBarMinSecChange
        end
        object CheckBoxDirect: TCheckBox
          Left = 90
          Top = 77
          Width = 103
          Height = 17
          Hint = 
            'Selecting this will include player owned stations in search resu' +
            'lts'
          Caption = 'Direct Delivery'
          Color = clDefault
          Font.Charset = ANSI_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Bahnschrift SemiCondensed'
          Font.Style = []
          ParentColor = False
          ParentFont = False
          ParentShowHint = False
          ShowHint = True
          TabOrder = 7
          StyleElements = [seClient, seBorder]
        end
        object NumberMinROI: TNumberBox
          Left = 286
          Top = 5
          Width = 51
          Height = 28
          Alignment = taCenter
          AutoSize = False
          CurrencyString = '%'
          CurrencyFormat = nbcfPostfixSpace
          Decimal = 0
          Font.Charset = ANSI_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Bahnschrift SemiCondensed'
          Font.Style = []
          Mode = nbmCurrency
          ParentFont = False
          TabOrder = 8
          Value = 1.000000000000000000
        end
        object ButtonGetTrades: TBitBtn
          Left = 7
          Top = 107
          Width = 486
          Height = 34
          Caption = 'Calculate Trade Opportunities'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -20
          Font.Name = 'Bahnschrift SemiCondensed'
          Font.Style = []
          ParentFont = False
          TabOrder = 9
          StyleElements = [seClient, seBorder]
          OnClick = ButtonGetTradesClick
        end
        object NumberBoxCargoCapacity: TNumberBox
          Left = 286
          Top = 73
          Width = 67
          Height = 28
          Alignment = taCenter
          AutoSize = False
          CurrencyString = 'm3'
          CurrencyFormat = nbcfPostfixSpace
          Decimal = 0
          Font.Charset = ANSI_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Bahnschrift SemiCondensed'
          Font.Style = []
          Mode = nbmCurrency
          ParentFont = False
          TabOrder = 10
          Value = 4095.000000000000000000
        end
      end
      object PanelRegionsList: TPanel
        Left = 8
        Top = 164
        Width = 247
        Height = 314
        BevelInner = bvRaised
        BevelOuter = bvNone
        Color = clDefault
        ParentBackground = False
        TabOrder = 2
        DesignSize = (
          247
          314)
        object chkEmpireSpaceOnly: TCheckBox
          Left = 43
          Top = 2
          Width = 189
          Height = 24
          Caption = 'Empire Regions Only'
          Checked = True
          Color = clDefault
          Font.Charset = ANSI_CHARSET
          Font.Color = clWhite
          Font.Height = -15
          Font.Name = 'Bahnschrift SemiCondensed'
          Font.Style = []
          ParentColor = False
          ParentFont = False
          State = cbChecked
          TabOrder = 0
          StyleElements = [seClient, seBorder]
          OnClick = chkEmpireSpaceOnlyClick
        end
        object ListboxRegions: TListBox
          Left = 1
          Top = 27
          Width = 245
          Height = 287
          Style = lbOwnerDrawFixed
          Anchors = [akLeft, akTop, akBottom]
          BevelEdges = []
          BevelOuter = bvNone
          BorderStyle = bsNone
          Color = clDefault
          DragMode = dmAutomatic
          Font.Charset = ANSI_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Bahnschrift SemiCondensed'
          Font.Style = []
          ItemHeight = 18
          MultiSelect = True
          ParentFont = False
          Sorted = True
          TabOrder = 1
          StyleElements = [seClient, seBorder]
          OnDrawItem = IndentedListboxDrawItem
          OnKeyDown = ListboxRegionsKeyDown
          OnMouseDown = ListboxRegionsMouseDown
        end
      end
      object PanelMarketTree: TPanel
        Left = 8
        Top = 484
        Width = 247
        Height = 399
        Anchors = [akLeft, akTop, akBottom]
        BevelEdges = []
        BevelInner = bvRaised
        BevelOuter = bvNone
        Color = 2565927
        ParentBackground = False
        TabOrder = 3
        DesignSize = (
          247
          399)
        object TreeViewMarket: TTreeView
          Left = 1
          Top = 27
          Width = 245
          Height = 371
          Anchors = [akLeft, akTop, akRight, akBottom]
          BevelOuter = bvNone
          BorderStyle = bsNone
          Color = clDefault
          Font.Charset = ANSI_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Bahnschrift SemiCondensed'
          Font.Style = []
          Indent = 19
          MultiSelect = True
          MultiSelectStyle = [msControlSelect, msShiftSelect]
          ParentFont = False
          ParentShowHint = False
          PopupMenu = PopupMenuMarketTree
          ReadOnly = True
          RightClickSelect = True
          ShowHint = True
          TabOrder = 0
          StyleElements = [seClient, seBorder]
          OnDblClick = TreeViewMarketDblClick
          OnMouseDown = TreeViewMarketMouseDown
        end
        object EditFilterMarket: TEdit
          Left = 1
          Top = 1
          Width = 245
          Height = 26
          Hint = 'Search'
          Anchors = [akLeft, akTop, akRight]
          BevelEdges = []
          BevelInner = bvNone
          BevelOuter = bvNone
          Color = clDefault
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -15
          Font.Name = 'Bahnschrift SemiCondensed'
          Font.Style = []
          ParentFont = False
          ParentShowHint = False
          ShowHint = True
          TabOrder = 1
          TextHint = 'Search'
          StyleElements = [seClient, seBorder]
          OnChange = EditFilterMarketChange
        end
        object pnlClearMarketFilter: TPanel
          Left = 271
          Top = 3
          Width = 0
          Height = 20
          Anchors = [akLeft, akTop, akRight]
          BevelOuter = bvNone
          Caption = 'x'
          Color = 2565927
          ParentBackground = False
          TabOrder = 2
          OnClick = pnlClearMarketFilterClick
        end
      end
    end
    object PanelAnalyzerRightWindow: TPanel
      Left = 514
      Top = 1
      Width = 2152
      Height = 892
      Margins.Left = 0
      Margins.Top = 0
      Margins.Right = 0
      Margins.Bottom = 0
      Align = alClient
      Color = 1118481
      ParentBackground = False
      TabOrder = 1
      DesignSize = (
        2152
        892)
      object PanelTradeResults: TPanel
        Left = 9
        Top = 9
        Width = 2137
        Height = 578
        Anchors = [akLeft, akTop, akRight, akBottom]
        BevelEdges = []
        BevelOuter = bvNone
        Caption = 'Trade Results'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -27
        Font.Name = 'Bahnschrift SemiCondensed'
        Font.Style = []
        ParentFont = False
        TabOrder = 3
      end
      object GridTradeResults: TStringGrid
        Left = 4
        Top = 7
        Width = 2143
        Height = 581
        Anchors = [akLeft, akTop, akRight, akBottom]
        BevelKind = bkFlat
        BevelOuter = bvNone
        ColCount = 13
        DefaultColWidth = 161
        DefaultDrawing = False
        DrawingStyle = gdsGradient
        FixedColor = clSilver
        FixedCols = 0
        RowCount = 2
        Font.Charset = ANSI_CHARSET
        Font.Color = clBlack
        Font.Height = -15
        Font.Name = 'Bahnschrift Light SemiCondensed'
        Font.Style = []
        Options = [goFixedHorzLine, goVertLine, goHorzLine, goDrawFocusSelected, goColSizing, goRowSelect, goFixedRowDefAlign]
        ParentFont = False
        PopupMenu = PopupMenuTradeGrid
        TabOrder = 0
        StyleElements = [seClient]
        StyleName = 'Auric'
        OnDblClick = GridTradeResultsDblClick
        OnDrawCell = GridTradeResultsDrawCell
        OnMouseDown = GridTradeResultsMouseDown
        OnMouseUp = GridTradeResultsMouseUp
      end
      object DebugMemo: TMemo
        Left = 1472
        Top = 593
        Width = 676
        Height = 290
        Anchors = [akLeft, akRight, akBottom]
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -12
        Font.Name = 'Bahnschrift'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 1
        StyleElements = [seClient, seBorder]
      end
      object PanelAnalyzerBottomWindow: TPanel
        Left = 4
        Top = 593
        Width = 1462
        Height = 289
        Anchors = [akLeft, akRight, akBottom]
        BevelOuter = bvNone
        Color = clWindow
        ParentBackground = False
        TabOrder = 2
        DesignSize = (
          1462
          289)
        object PanelRouteMap: TPanel
          Left = 605
          Top = 0
          Width = 289
          Height = 289
          Anchors = [akLeft, akBottom]
          BevelInner = bvRaised
          BevelOuter = bvNone
          Color = clBlack
          ParentBackground = False
          TabOrder = 0
          Visible = False
          StyleElements = []
          object PaintBoxTradeRoute: TPaintBox
            Left = 1
            Top = 1
            Width = 287
            Height = 287
            ParentShowHint = False
            ShowHint = True
            OnMouseDown = PaintBoxTradeRouteMouseDown
            OnMouseMove = PaintBoxTradeRouteMouseMove
            OnMouseUp = PaintBoxTradeRouteMouseUp
            OnPaint = PaintBoxTradeRoutePaint
          end
        end
        object PanelItemSummary: TPanel
          Left = 0
          Top = 0
          Width = 600
          Height = 289
          Anchors = [akLeft, akBottom]
          BevelInner = bvRaised
          BevelOuter = bvNone
          Color = clWindow
          ParentBackground = False
          TabOrder = 1
          Visible = False
          object LabelSellers: TLabel
            Left = 16
            Top = 80
            Width = 53
            Height = 23
            Caption = 'Sellers'
            Font.Charset = ANSI_CHARSET
            Font.Color = clWhite
            Font.Height = -19
            Font.Name = 'Bahnschrift SemiCondensed'
            Font.Style = [fsBold]
            ParentFont = False
            StyleElements = [seClient, seBorder]
          end
          object LabelTypeMarketGroup: TLabel
            Left = 85
            Top = 16
            Width = 425
            Height = 18
            Caption = 
              'Ship Equipment / Engineering Equipment / Capacitor Boosters / Me' +
              'dium /'
            Font.Charset = ANSI_CHARSET
            Font.Color = clWhite
            Font.Height = -15
            Font.Name = 'Bahnschrift SemiCondensed'
            Font.Style = []
            ParentFont = False
            StyleElements = [seClient, seBorder]
          end
          object LabelTypeName: TLabel
            Left = 85
            Top = 33
            Width = 205
            Height = 23
            Caption = 'Medium Capacitor Booster II'
            Font.Charset = ANSI_CHARSET
            Font.Color = clWhite
            Font.Height = -19
            Font.Name = 'Bahnschrift Light Condensed'
            Font.Style = [fsBold]
            ParentFont = False
            StyleElements = [seClient, seBorder]
          end
          object LabelBuyers: TLabel
            Left = 208
            Top = 80
            Width = 51
            Height = 23
            Caption = 'Buyers'
            Font.Charset = ANSI_CHARSET
            Font.Color = clWhite
            Font.Height = -19
            Font.Name = 'Bahnschrift SemiCondensed'
            Font.Style = [fsBold]
            ParentFont = False
            StyleElements = [seClient, seBorder]
          end
          object LabelSellerDetails: TLabel
            Left = 57
            Top = 109
            Width = 117
            Height = 18
            Caption = '1,000,000,000.00 ISK'
            Font.Charset = ANSI_CHARSET
            Font.Color = clWhite
            Font.Height = -15
            Font.Name = 'Bahnschrift SemiCondensed'
            Font.Style = []
            ParentFont = False
            StyleElements = [seClient, seBorder]
          end
          object LabelBuyerDetails: TLabel
            Left = 249
            Top = 109
            Width = 117
            Height = 18
            Caption = '1,000,000,000.00 ISK'
            Font.Charset = ANSI_CHARSET
            Font.Color = clWhite
            Font.Height = -15
            Font.Name = 'Bahnschrift SemiCondensed'
            Font.Style = []
            ParentFont = False
            StyleElements = [seClient, seBorder]
          end
          object LabelSellersLabels: TLabel
            Left = 16
            Top = 109
            Width = 35
            Height = 72
            Caption = 'Min:'#13#10'Avg:'#13#10'wAvg:'#13#10'Max:'
            Font.Charset = ANSI_CHARSET
            Font.Color = clWhite
            Font.Height = -15
            Font.Name = 'Bahnschrift SemiCondensed'
            Font.Style = []
            ParentFont = False
            StyleElements = [seClient, seBorder]
          end
          object LabelBuyersLabels: TLabel
            Left = 208
            Top = 109
            Width = 35
            Height = 72
            Caption = 'Max:'#13#10'Avg:'#13#10'wAvg:'#13#10'Min:'
            Font.Charset = ANSI_CHARSET
            Font.Color = clWhite
            Font.Height = -15
            Font.Name = 'Bahnschrift SemiCondensed'
            Font.Style = []
            ParentFont = False
            StyleElements = [seClient, seBorder]
          end
          object PaintBoxItemType: TPaintBox
            Left = 10
            Top = 10
            Width = 64
            Height = 64
            OnPaint = PaintBoxItemTypePaint
          end
        end
        object PanelRouteDetails: TPanel
          Left = 900
          Top = 0
          Width = 562
          Height = 289
          Alignment = taLeftJustify
          Anchors = [akLeft, akBottom]
          BevelInner = bvRaised
          BevelOuter = bvNone
          Color = clWindow
          ParentBackground = False
          TabOrder = 2
        end
      end
    end
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 929
    Width = 2666
    Height = 24
    Panels = <
      item
        Width = 399
      end
      item
        Width = 403
      end
      item
        Width = 1000
      end
      item
        Width = 50
      end
      item
        Width = 50
      end>
  end
  object ProgressBar: TProgressBar
    Left = 399
    Top = 931
    Width = 400
    Height = 22
    Anchors = [akLeft, akBottom]
    Position = 50
    TabOrder = 0
    Visible = False
  end
  object PanelMenuBar: TPanel
    Left = 0
    Top = 0
    Width = 2666
    Height = 42
    Align = alTop
    Color = clDefault
    ParentBackground = False
    TabOrder = 2
    object PanelSelectorAnalyzer: TPanel
      Left = 1
      Top = 1
      Width = 150
      Height = 32
      BevelOuter = bvNone
      Caption = 'Trade Analyzer'
      Color = clDefault
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -16
      Font.Name = 'Bahnschrift'
      Font.Style = [fsBold]
      ParentBackground = False
      ParentFont = False
      TabOrder = 0
      StyleElements = [seClient, seBorder]
      OnClick = PanelSelectorAnalyzerClick
    end
    object PanelSelectorTradeHistory: TPanel
      Left = 150
      Top = 1
      Width = 150
      Height = 32
      BevelOuter = bvNone
      Caption = 'Trade History'
      Color = clDefault
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -16
      Font.Name = 'Bahnschrift'
      Font.Style = [fsBold]
      ParentBackground = False
      ParentFont = False
      TabOrder = 1
      StyleElements = [seClient, seBorder]
      OnClick = PanelSelectorTradeHistoryClick
    end
    object PanelSelection: TPanel
      Left = 1
      Top = 33
      Width = 150
      Height = 6
      BevelOuter = bvNone
      Color = clMenuHighlight
      ParentBackground = False
      TabOrder = 2
      StyleElements = [seFont, seBorder]
    end
  end
  object TimerMarketFilter: TTimer
    Enabled = False
    Interval = 200
    OnTimer = TimerMarketFilterTimer
    Left = 48
    Top = 576
  end
  object PopupMenuMarketTree: TPopupMenu
    OnPopup = PopupMenuMarketTreePopup
    Left = 176
    Top = 576
    object AddManualTransaction1: TMenuItem
      Caption = 'Add Manual Trade'
      OnClick = AddManualTransaction1Click
    end
  end
  object PopupMenuTradeHistory: TPopupMenu
    Left = 2463
    Top = 183
    object AddTradeRecord: TMenuItem
      Caption = 'Add Trade'
    end
    object EditTradeRecord: TMenuItem
      Caption = 'Edit Trade'
      OnClick = EditTradeRecordClick
    end
    object DeleteTrade: TMenuItem
      Caption = 'Delete Trade(s)'
      OnClick = DeleteTradeClick
    end
  end
  object PopupMenuTradeGrid: TPopupMenu
    Left = 2463
    Top = 127
    object FindRouteTrades1: TMenuItem
      Caption = 'Find Route Trades to Station'
      OnClick = FindRouteTrades1Click
    end
  end
  object TimerAnimateLines: TTimer
    Interval = 30
    OnTimer = TimerAnimateLinesTimer
    Left = 1371
    Top = 641
  end
  object BalloonHint1: TBalloonHint
    Style = bhsStandard
    Left = 1726
    Top = 761
  end
end
