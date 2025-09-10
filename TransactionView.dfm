object FormTransaction: TFormTransaction
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  Caption = 'Transaction'
  ClientHeight = 298
  ClientWidth = 730
  Color = 1118481
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poMainFormCenter
  RoundedCorners = rcOff
  StyleElements = [seClient, seBorder]
  StyleName = 'Auric'
  OnClose = FormClose
  OnShow = FormShow
  TextHeight = 15
  object PanelTradeSummary: TPanel
    Left = 8
    Top = 8
    Width = 714
    Height = 241
    Color = clWindow
    ParentBackground = False
    TabOrder = 0
    object LabelTypeMarketGroup: TLabel
      Left = 140
      Top = 9
      Width = 366
      Height = 16
      Caption = 
        'Ship Equipment / Engineering Equipment / Capacitor Boosters / Me' +
        'dium /'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWhite
      Font.Height = -13
      Font.Name = 'Bahnschrift SemiCondensed'
      Font.Style = []
      ParentFont = False
      StyleElements = [seClient, seBorder]
    end
    object LabelTypeName: TLabel
      Left = 140
      Top = 26
      Width = 178
      Height = 23
      Caption = 'Medium Capacitor Booster II'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'Bahnschrift Condensed'
      Font.Style = [fsBold]
      ParentFont = False
      StyleElements = [seClient, seBorder]
    end
    object Label1: TLabel
      Left = 359
      Top = 60
      Width = 96
      Height = 18
      Caption = 'Transaction Date'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWhite
      Font.Height = -15
      Font.Name = 'Bahnschrift SemiCondensed'
      Font.Style = []
      ParentFont = False
      StyleElements = [seClient, seBorder]
    end
    object Label2: TLabel
      Left = 22
      Top = 176
      Width = 85
      Height = 18
      Caption = 'Source Region'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWhite
      Font.Height = -15
      Font.Name = 'Bahnschrift SemiCondensed'
      Font.Style = []
      ParentFont = False
      StyleElements = [seClient, seBorder]
    end
    object Label3: TLabel
      Left = 22
      Top = 205
      Width = 86
      Height = 18
      Caption = 'Source Station'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWhite
      Font.Height = -15
      Font.Name = 'Bahnschrift SemiCondensed'
      Font.Style = []
      ParentFont = False
      StyleElements = [seClient, seBorder]
    end
    object Label4: TLabel
      Left = 140
      Top = 60
      Width = 46
      Height = 18
      Caption = 'Quantity'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWhite
      Font.Height = -15
      Font.Name = 'Bahnschrift SemiCondensed'
      Font.Style = []
      ParentFont = False
      StyleElements = [seClient, seBorder]
    end
    object Label5: TLabel
      Left = 140
      Top = 89
      Width = 56
      Height = 18
      Caption = 'Buy Price'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWhite
      Font.Height = -15
      Font.Name = 'Bahnschrift SemiCondensed'
      Font.Style = []
      ParentFont = False
      StyleElements = [seClient, seBorder]
    end
    object Label6: TLabel
      Left = 140
      Top = 118
      Width = 58
      Height = 18
      Caption = 'Sell Price'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWhite
      Font.Height = -15
      Font.Name = 'Bahnschrift SemiCondensed'
      Font.Style = []
      ParentFont = False
      StyleElements = [seClient, seBorder]
    end
    object Label7: TLabel
      Left = 359
      Top = 205
      Width = 92
      Height = 18
      Caption = 'Delivery Station'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWhite
      Font.Height = -15
      Font.Name = 'Bahnschrift SemiCondensed'
      Font.Style = []
      ParentFont = False
      StyleElements = [seClient, seBorder]
    end
    object Label8: TLabel
      Left = 359
      Top = 176
      Width = 91
      Height = 18
      Caption = 'Delivery Region'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWhite
      Font.Height = -15
      Font.Name = 'Bahnschrift SemiCondensed'
      Font.Style = []
      ParentFont = False
      StyleElements = [seClient, seBorder]
    end
    object Label9: TLabel
      Left = 359
      Top = 89
      Width = 83
      Height = 18
      Caption = 'Sales Taxation'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWhite
      Font.Height = -15
      Font.Name = 'Bahnschrift SemiCondensed'
      Font.Style = []
      ParentFont = False
      StyleElements = [seClient, seBorder]
    end
    object PaintBox: TPaintBox
      Left = 6
      Top = 7
      Width = 128
      Height = 128
      OnPaint = PaintBoxPaint
    end
    object ComboBoxSourceRegion: TComboBox
      Left = 142
      Top = 171
      Width = 203
      Height = 23
      DropDownCount = 16
      Sorted = True
      TabOrder = 0
      OnExit = ComboBoxSourceRegionExit
      OnSelect = ComboBoxSourceRegionSelect
    end
    object ComboBoxSourceStation: TComboBox
      Left = 142
      Top = 200
      Width = 203
      Height = 23
      DropDownCount = 16
      DropDownWidth = 350
      Sorted = True
      TabOrder = 1
    end
    object NumberBoxQuantity: TNumberBox
      Left = 224
      Top = 55
      Width = 121
      Height = 23
      TabOrder = 2
    end
    object NumberBoxBuyPrice: TNumberBox
      Left = 224
      Top = 84
      Width = 121
      Height = 23
      CurrencyString = 'ISK'
      CurrencyFormat = nbcfPostfixSpace
      Mode = nbmCurrency
      TabOrder = 3
    end
    object NumberBoxSellPrice: TNumberBox
      Left = 224
      Top = 113
      Width = 121
      Height = 23
      CurrencyString = 'ISK'
      CurrencyFormat = nbcfPostfixSpace
      Mode = nbmCurrency
      TabOrder = 4
    end
    object ComboBoxDeliveryRegion: TComboBox
      Left = 486
      Top = 171
      Width = 203
      Height = 23
      DropDownCount = 16
      Sorted = True
      TabOrder = 5
      OnExit = ComboBoxDeliveryRegionExit
      OnSelect = ComboBoxDeliveryRegionSelect
    end
    object ComboBoxDeliveryStation: TComboBox
      Left = 486
      Top = 200
      Width = 203
      Height = 23
      DropDownCount = 16
      DropDownWidth = 350
      Sorted = True
      TabOrder = 6
    end
    object NumberBoxSalesTax: TNumberBox
      Left = 486
      Top = 84
      Width = 203
      Height = 23
      CurrencyString = 'ISK'
      CurrencyFormat = nbcfPostfixSpace
      Mode = nbmCurrency
      TabOrder = 7
    end
    object DatePicker: TDatePicker
      Left = 486
      Top = 53
      Width = 116
      Height = 25
      Date = 45905.000000000000000000
      DateFormat = 'yyyy/MM/dd'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Segoe UI'
      Font.Style = []
      TabOrder = 8
    end
    object TimePicker: TTimePicker
      Left = 608
      Top = 53
      Width = 81
      Height = 25
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Segoe UI'
      Font.Style = []
      TabOrder = 9
      Time = 45905.258351076390000000
      TimeFormat = 'HH:mm'
    end
  end
  object pnlConfirmTrade: TPanel
    Left = 8
    Top = 255
    Width = 714
    Height = 36
    Cursor = crHandPoint
    Caption = 'Confirm Trade Record'
    Color = 2236962
    Font.Charset = ANSI_CHARSET
    Font.Color = clWhite
    Font.Height = -19
    Font.Name = 'Bahnschrift SemiCondensed'
    Font.Style = []
    ParentBackground = False
    ParentFont = False
    TabOrder = 1
    StyleElements = [seClient, seBorder]
    OnClick = pnlConfirmTradeClick
    OnMouseDown = panelMouseDown
    OnMouseEnter = panelMouseEnter
    OnMouseLeave = panelMouseLeave
    OnMouseUp = panelMouseUp
  end
end
