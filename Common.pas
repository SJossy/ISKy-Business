unit Common;

interface

uses
  System.SysUtils,
  System.UITypes,
  Winapi.Windows,
  Vcl.Graphics, Vcl.Themes, Vcl.Styles,
  System.Net.HttpClient, System.Net.URLClient, System.Classes,
  System.Generics.Collections, System.JSON;

type
  TTypesRec = record
    typeID: Integer;
    typeName: string;
    lowerTypeName: string;
    marketGroupID: string;
    volume: Double;
    description: string;
    iconID: Int64;
  end;

  TRegionsRec = record
    RegionID: Integer;
    RegionName: string;
    FactionID: Integer;
  end;

  TSystemsRec = record
    RegionID: Integer;
    ConstellationID: Int64;
    SystemID: Integer;
    SystemName: string;
    Security: Double;
    x,y,z: Double;
  end;

  TStationsRec = record
    StationID: Int64;
    StationName: string;
    RegionID: Integer;
    SystemID: Integer;
    Security: Double;
  end;

  TMarketGroupRec = record
    marketGroupID: string;
    parentGroupID: string;
    marketGroupName: string;
    description: string;
    iconID: Integer;
    hasTypes: Integer;
  end;

  TMarketOrderRec = record
    duration: Integer;
    is_buy_order: Boolean;
    issued: string;
    min_volume: Integer;
    order_id: Int64;
    price: Double;
    range: string;
    system_id: Integer;
    type_id: Integer;
    volume_remain: Integer;
    volume_total: Integer;
    http_last_modified: string;
    station_id: Int64;
    region_id: Integer;
  end;

  TMarketStats = record
    SellMin, SellMax, SellAvg, SellWeighted: Double;
    BuyMin, BuyMax, BuyAvg, BuyWeighted: Double;
  end;

  TTradeHistoryRec = record
    DateTime: TDateTime;
    TypeID: Integer;
    BuyRegionID: Integer;
    BuySystemID: Integer;
    BuyStationID: Int64;
    SellRegionID: Integer;
    SellSystemID: Integer;
    SellStationID: Int64;
    BuyPrice: double;
    SellPrice: double;
    Quantity: integer;
    SalesTax: double;
  end;

  TRegionInfo = record
    RegionID: Integer;
    LastLoaded: TDateTime;
    CacheAge: Integer;
    // Add more as needed
  end;

  TJumpRoute = record
    SystemIDs: TArray<Integer>;
    DestinationSystemID: Integer;
    JumpsFromDest: Integer;
    MinSecurity: Double;
    MaxSecurity: Double;
  end;

  TOrderTripResult = record
    ItemName: string;
    TypeID: Integer;
    BuyOrderID: Int64;
    SellOrderID: Int64;
    Volume: Double;
    NetProfit: Double;
    ProfitPerJump: Double;
    BuyPrice: Double;
    SellPrice: Double;
    TotalBuy: Double;
    TotalSell: Double;
    SourceRegion: string;
    SourceSecurity: double;
    SourceStation: string;
    DestRegion: string;
    DestSystemID: Integer;
    DestSecurity: double;
    DestStation: string;
    DeliverySystemID: Integer;
    DeliveryStationID: Integer;
    DeliveryRegion: string;
    DeliveryStation: string;
    Jumps: Integer;
    JumpRoute: TJumpRoute;
    BuyOrderRange: string;
    BuyOrderJumps: Integer;
    MinRouteSec: Double;
    SalesTax: Double;
    ROI: Double;
    SellMinPrice: Double;
    SellAvgPrice: Double;
    SellMaxPrice: Double;
    SellWeightedAvg: Double;
    BuyMinPrice: Double;
    BuyAvgPrice: Double;
    BuyMaxPrice: Double;
    BuyWeightedAvg: Double;
  end;

  TTradeAnnotation = record
    SystemID: Integer;
    Trades: TArray<record
      ItemName: string;
      TypeID: Integer;
      Volume: Double;
      NetProfit: Double;
      SuggestedBuyOrderID: Int64;
      SuggestedSellOrderID: Int64;
    end>;
  end;

  TPageFetchResult = record
    Success: Boolean;
    NotModified304: Boolean;
    PageContent: string;
    PageNumber: Integer;
    Headers: TNetHeaders;
    ETagHeader: string;
    ExpiresHeader: string;
    LastModifiedHeader: string;
    ErrorMsg: string;
  end;


const
  DEBUG: Boolean = true;

  BG_COLOR_LIGHT  = $002E2E2E; // RGB(46,46,46)
  BG_COLOR        = $00272727; // RGB(39,39,39)
  BG_COLOR_DARK   = $00222222; // RGB(34,34,34)

  COLOR_SECURITY_0  = $0064328d;
  COLOR_SECURITY_1  = $00202073;
  COLOR_SECURITY_2  = $000f44ce;
  COLOR_SECURITY_3  = $000f44ce;
  COLOR_SECURITY_4  = $00076ddb;
  COLOR_SECURITY_5  = $0083fff5;
  COLOR_SECURITY_6  = $0055e772;
  COLOR_SECURITY_7  = $00a4db61;
  COLOR_SECURITY_8  = $00f8ce4e;
  COLOR_SECURITY_9  = $00eb9aeb;
  COLOR_SECURITY_10 = $00e2752c;
  SecurityColors: array[0..10] of TColor = (
    COLOR_SECURITY_0, COLOR_SECURITY_1, COLOR_SECURITY_2, COLOR_SECURITY_3,
    COLOR_SECURITY_4, COLOR_SECURITY_5, COLOR_SECURITY_6, COLOR_SECURITY_7,
    COLOR_SECURITY_8, COLOR_SECURITY_9, COLOR_SECURITY_10
  );

  TypesURL              = 'https://www.fuzzwork.co.uk/dump/latest/invTypes.csv';
  MarketGroupsURL       = 'https://www.fuzzwork.co.uk/dump/latest/invMarketGroups.csv';
  RegionsURL            = 'https://www.fuzzwork.co.uk/dump/latest/mapRegions.csv';
  SystemssURL           = 'https://www.fuzzwork.co.uk/dump/latest/mapSolarSystems.csv';
  StationsURL           = 'https://www.fuzzwork.co.uk/dump/latest/staStations.csv';
  SystemJumpsURL        = 'https://www.fuzzwork.co.uk/dump/latest/mapSolarSystemJumps.csv';
  MarketOrdersURL       = 'https://data.everef.net/market-orders/market-orders-latest.v3.csv.bz2';

  TypesFile             = 'cache\invTypes.csv';
  TypesBin              = 'cache\invTypes.bin';
  MarketGroupsFile      = 'cache\invMarketGroups.csv';
  MarketGroupsBin       = 'cache\invMarketGroups.bin';
  RegionsFile           = 'cache\mapRegions.csv';
  RegionsBin            = 'cache\mapRegions.bin';
  SystemsFile           = 'cache\mapSolarSystems.csv';
  SystemsBin            = 'cache\mapSolarSystems.bin';
  SystemJumpsFile       = 'cache\mapSolarSystemJumps.csv';
  SystemJumpsBin        = 'cache\mapSolarSystemJumps.bin';
  SystemJumpsMatrixBin  = 'cache\mapSolarSystemJumpsMatrix.bin';
  StationsFile          = 'cache\staStations.csv';
  StationsBin           = 'cache\staStations.bin';
  OrdersBZ2             = 'cache\market-orders-latest.v3.csv.bz2';
  OrdersBin             = 'cache\market-orders-latest.v3.bin';
  TradeHistoryBin       = 'cache\trade-history.bin';

  Titles: array[0..5] of string = (
    'Smuggle Smarter. Sell Faster. ISKy Business.',
    'Where There’s Risk, There’s ISK.',
    'Serious About Space Profit, Not Serious About Anything Else.',
    'More ISK. Less Risk.',
    'SCC-Approved ISKy Business',
    'Route Master—Earn Faster');

  MIN_ZOOM = 1;
  MAX_ZOOM = 8;
  LABEL_FADE_MARGIN = 20; // Pixels from edge where fading begins

  USER_AGENT = 'ISKY Business/0.0.0 (steven@jossy.co)';

var
  FSortDescending: Boolean;
  SortedTradeResults: TArray<TOrderTripResult>;

implementation

end.

