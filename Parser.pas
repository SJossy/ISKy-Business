unit Parser;

interface

uses
  System.IOUtils, Math, Winapi.Windows,System.SysUtils, System.Classes, System.Generics.Collections, System.StrUtils,
  DateUtils, System.Net.HttpClient, System.Net.HttpClientComponent, System.Net.URLClient, System.Threading,
  Common, Logger;

type
  TRouteSegmentFormatter = function(const Rec: TSystemsRec): string;
  TLogProc = procedure(const Msg: string) of object;
  TParser = class
  private
    FTypesArr: TArray<TTypesRec>;
    FMarketGroupsArr: TArray<TMarketGroupRec>;
    FLogger: TLogger;
    function LoadFromCache(const BinFile, SrcFile: string; const LoadProc: TProc<TStream>): Boolean;
    procedure SaveToCache(const BinFile: string; const SaveProc: TProc<TStream>);
    procedure WriteString(S: TStream; const str: string);
    function ReadString(S: TStream): string;
  public
    FTypes: TDictionary<Integer, TTypesRec>;
    AllShipTypes: TList<TTypesRec>;    FRegions: TDictionary<Integer, TRegionsRec>;
    FSystems: TDictionary<Integer, TSystemsRec>;
    FStations: TDictionary<Int64, TStationsRec>;
    FSystemToStations: TDictionary<Integer, TList<Int64>>;
    FSystemJumps: TDictionary<Integer, TArray<Integer>>;
    FAllPairsJumps: TDictionary<Integer, TDictionary<Integer, Integer>>;
    FMarketGroups: TDictionary<string, TMarketGroupRec>;
    FParentToChildren: TDictionary<string, TList<string>>;
    FRegionToSolarSystemIDs: TDictionary<Integer, TList<Integer>>;
    constructor Create(aDebug: TLogger);
    destructor Destroy; override;
    property TypesArr: TArray<TTypesRec> read FTypesArr;
    property MarketGroupsArr: TArray<TMarketGroupRec> read FMarketGroupsArr;
    procedure LoadTypes;
    procedure LoadMarketGroups(const CSVFile, CacheFile: string);
    procedure SaveTradeHistory(const Dict: TDictionary<Integer, TTradeHistoryRec>);
    procedure LoadTradeHistory(const Dict: TDictionary<Integer, TTradeHistoryRec>);
    procedure LoadRegions(const CSVFile, CacheFile: string);
    procedure LoadSystems(const CSVFile, CacheFile: string);
    procedure LoadSystemJumps(const CSVFile, CacheFile: string);
    procedure CalculateBFSJumpDistances(RootSystem: Integer; JumpDistances: TDictionary<Integer,Integer>);
    procedure BuildAllPairsJumpsMatrix;
    procedure LoadStations(const CSVFile, CacheFile: string);
    procedure BuildRegionToSolarSystemIDs;
    procedure UpdateType(const Rec: TTypesRec);
    procedure FindAllDescendantGroups(const StartID: string; MarketGroups: TDictionary<string, TMarketGroupRec>; var Descendants: TList<string>);
  end;

implementation

constructor TParser.Create(aDebug: TLogger);
begin
  inherited Create;
  FLogger := aDebug;
  FMarketGroups := TDictionary<string, TMarketGroupRec>.Create;
  FParentToChildren := TDictionary<string, TList<string>>.Create;
  FTypes := TDictionary<Integer, TTypesRec>.Create;
  FRegions := TDictionary<Integer, TRegionsRec>.Create;
  FSystems := TDictionary<Integer, TSystemsRec>.Create;
  FStations := TDictionary<Int64, TStationsRec>.Create;
  FSystemJumps := TDictionary<Integer, TArray<Integer>>.Create;
end;


procedure TParser.WriteString(S: TStream; const str: string);
var
  Len: Integer;
begin
  Len := Length(str);
  S.WriteBuffer(Len, SizeOf(Len));
  if Len > 0 then
    S.WriteBuffer(Pointer(str)^, Len * SizeOf(Char));
end;

function TParser.ReadString(S: TStream): string;
var
  Len: Integer;
begin
  Result := '';
  S.ReadBuffer(Len, SizeOf(Len));
  if Len > 0 then
  begin
    SetLength(Result, Len);
    S.ReadBuffer(Pointer(Result)^, Len * SizeOf(Char));
  end;
end;

function TParser.LoadFromCache(const BinFile, SrcFile: string;
  const LoadProc: TProc<TStream>): Boolean;
var
  BinStream: TFileStream;
  SrcTime, BinTime: TDateTime;
begin
  Result := False;

  if (not FileExists(BinFile)) or (not FileExists(SrcFile)) then
    Exit;

  BinTime := FileDateToDateTime(FileAge(BinFile));
  SrcTime := FileDateToDateTime(FileAge(SrcFile));
  if SrcTime > BinTime then
    Exit;

  try
    BinStream := TFileStream.Create(BinFile, fmOpenRead or fmShareDenyWrite);
    try
      LoadProc(BinStream);
      Result := True;
      FLogger.Log('Loaded from cache: ' + BinFile);
    finally
      BinStream.Free;
    end;
  except
    on E: Exception do
    begin
      FLogger.Log(Format('Error reading cache file "%s": %s', [BinFile, E.Message]));
      try
        if FileExists(BinFile) then
        begin
          DeleteFile(BinFile);
          FLogger.Log('Deleted corrupt cache file: ' + BinFile);
        end;
      except
      end;
      Result := False;
    end;
  end;
end;

procedure TParser.SaveToCache(const BinFile: string;
  const SaveProc: TProc<TStream>);
var
  BinStream: TFileStream;
  TempFile: string;
begin
  TempFile := BinFile + '.tmp';
  try
    BinStream := TFileStream.Create(TempFile, fmCreate);
    try
      SaveProc(BinStream);
    finally
      BinStream.Free;
    end;
    if FileExists(BinFile) then
      DeleteFile(BinFile);
    RenameFile(TempFile, BinFile);
    FLogger.Log('Saved parsed data to cache: ' + BinFile);
  except
    on E: Exception do
    begin
      FLogger.Log(Format('Error writing cache file "%s": %s', [BinFile, E.Message]));
      if FileExists(TempFile) then
        DeleteFile(TempFile);
    end;
  end;
end;

function ReadNextCSVRow(Stream: TStream; const Delim: Char = ','): string;
var
  ch: AnsiChar;
  InQuotes: Boolean;
  Row: string;
  BytesRead: Integer;
begin
  Row := '';
  InQuotes := False;
  while Stream.Position < Stream.Size do
  begin
    BytesRead := Stream.Read(ch, 1);
    if BytesRead <> 1 then
      Break;
    if ch = '"' then
    begin
      InQuotes := not InQuotes;
      Row := Row + ch;
      Continue;
    end;
    // Handle newline
    if (ch = #13) or (ch = #10) then
    begin
      if not InQuotes then
      begin
        // Handle CR LF
        if (ch = #13) and (Stream.Position < Stream.Size) then
        begin
          Stream.Read(ch, 1);
          if ch <> #10 then
            Stream.Position := Stream.Position - 1;
        end;
        Break;  // End of row
      end
      else
        Row := Row + ch; // Embedded line
      Continue;
    end;
    Row := Row + ch;
  end;
  Result := Row;
end;

function ParseCSVLine(const Line: string; const Delim: Char = ','): TArray<string>;
var
  i, Len: Integer;
  InQuotes: Boolean;
  Field: string;
begin
  Result := [];
  InQuotes := False;
  i := 1;
  Len := Length(Line);
  Field := '';
  while i <= Len do
  begin
    if Line[i] = '"' then
    begin
      InQuotes := not InQuotes;
      Inc(i);
      Continue;
    end;
    if (Line[i] = Delim) and (not InQuotes) then
    begin
      Result := Result + [Field];
      Field := '';
      Inc(i);
      Continue;
    end;
    Field := Field + Line[i];
    Inc(i);
  end;
  Result := Result + [Field];
end;


destructor TParser.Destroy;
var
  lst: TList<string>;
  lst2: TList<Integer>;

begin
  for lst in FParentToChildren.Values do
    lst.Free;
  FParentToChildren.Free;
  //FMarketGroups.Free;
  FTypes.Free;
  FRegions.Free;
  FStations.Free;
  FSystems.Clear;
  if Assigned(FRegionToSolarSystemIDs) then
  begin
    for var list in FRegionToSolarSystemIDs.Values do
      list.Free;
    FRegionToSolarSystemIDs.Free;
  end;
  inherited;
end;


procedure TParser.LoadRegions(const CSVFile, CacheFile: string);
var
  FileStream: TFileStream;
  idxID, idxName, idxFaction: Integer;
  HeaderFields: Integer;
  rec: TRegionsRec;
  Cols: TArray<string>;
  Line: string;
begin
  if LoadFromCache(CacheFile, CSVFile,
    procedure(S: TStream)
    var
      Count, i: Integer;
      recLocal: TRegionsRec;
    begin
      S.ReadBuffer(Count, SizeOf(Count));
      for i := 1 to Count do
      begin
        S.ReadBuffer(recLocal.regionID, SizeOf(recLocal.regionID));
        recLocal.regionName := ReadString(S);
        S.ReadBuffer(recLocal.factionID, SizeOf(recLocal.factionID));
        FRegions.AddOrSetValue(recLocal.regionID, recLocal);
      end;
    end) then Exit;
  FRegions.Clear;
  if not FileExists(CSVFile) then Exit;
  FileStream := TFileStream.Create(CSVFile, fmOpenRead or fmShareDenyWrite);
  try
    Line := ReadNextCSVRow(FileStream);
    Cols := ParseCSVLine(Line);
    HeaderFields := Length(Cols);
    idxID := -1; idxName := -1; idxFaction := -1;
    for var c := 0 to High(Cols) do
    begin
      if Cols[c] = 'regionID' then idxID := c;
      if Cols[c] = 'regionName' then idxName := c;
      if Cols[c] = 'factionID' then idxFaction := c;
    end;
    // All columns must be present
    if (idxID < 0) or (idxName < 0) or (idxFaction < 0) then Exit;
    while FileStream.Position < FileStream.Size do
    begin
      Line := ReadNextCSVRow(FileStream);
      if Line = '' then Continue;
      Cols := ParseCSVLine(Line);
      if Length(Cols) < HeaderFields then Continue;
      rec.regionID := StrToIntDef(Cols[idxID], 0);
      rec.regionName := Cols[idxName];
      rec.factionID := StrToIntDef(Cols[idxFaction], 0);
      FRegions.AddOrSetValue(rec.regionID, rec);
    end;
  finally
    FileStream.Free;
  end;
  SaveToCache(CacheFile,
    procedure(S: TStream)
    var
      recLocal: TRegionsRec;
      Count: Integer;
    begin
      Count := FRegions.Count;
      S.WriteBuffer(Count, SizeOf(Count));
      for recLocal in FRegions.Values do
      begin
        S.WriteBuffer(recLocal.regionID, SizeOf(recLocal.regionID));
        WriteString(S, recLocal.regionName);
        S.WriteBuffer(recLocal.factionID, SizeOf(recLocal.factionID));
      end;
    end);
end;

procedure TParser.BuildRegionToSolarSystemIDs;
var
  Rec: TSystemsRec;
  SystemsList: TList<Integer>;
begin
  // Free and rebuild if already exists
  if Assigned(FRegionToSolarSystemIDs) then
  begin
    for SystemsList in FRegionToSolarSystemIDs.Values do
      SystemsList.Free;
    FRegionToSolarSystemIDs.Free;
  end;

  FRegionToSolarSystemIDs := TDictionary<Integer, TList<Integer>>.Create;

  for Rec in FSystems.Values do
  begin
    if not FRegionToSolarSystemIDs.TryGetValue(Rec.regionID, SystemsList) then
    begin
      SystemsList := TList<Integer>.Create;
      FRegionToSolarSystemIDs.Add(Rec.regionID, SystemsList);
    end;
    SystemsList.Add(Rec.systemID);
  end;
end;

procedure TParser.LoadStations(const CSVFile, CacheFile: string);
var
  FileStream: TFileStream;
  idxID, idxName, idxRegionID, idxSystemID, idxSecurity: Integer;
  HeaderFields: Integer;
  rec: TStationsRec;
  Cols: TArray<string>;
  Line: string;
begin
  // Clear or initialize the system-to-stations map
  if Assigned(FSystemToStations) then
  begin
    for var List in FSystemToStations.Values do List.Free;
    FSystemToStations.Free;
  end;
  FSystemToStations := TDictionary<Integer, TList<Int64>>.Create;

  if LoadFromCache(CacheFile, CSVFile,
    procedure(S: TStream)
    var
      Count, i: Integer;
      recLocal: TStationsRec;
    begin
      S.ReadBuffer(Count, SizeOf(Count));
      for i := 1 to Count do
      begin
        S.ReadBuffer(recLocal.stationID, SizeOf(recLocal.stationID));
        recLocal.stationName := ReadString(S);
        S.ReadBuffer(recLocal.regionID, SizeOf(recLocal.regionID));
        S.ReadBuffer(recLocal.systemID, SizeOf(recLocal.systemID));
        S.ReadBuffer(recLocal.security, SizeOf(recLocal.security));
        FStations.AddOrSetValue(recLocal.stationID, recLocal);
        // Populate system-to-stations map
        if not FSystemToStations.ContainsKey(recLocal.systemID) then
          FSystemToStations.Add(recLocal.systemID, TList<Int64>.Create);
        FSystemToStations[recLocal.systemID].Add(recLocal.stationID);
      end;
    end) then Exit;

  FStations.Clear;
  if not FileExists(CSVFile) then Exit;
  FileStream := TFileStream.Create(CSVFile, fmOpenRead or fmShareDenyWrite);
  try
    Line := ReadNextCSVRow(FileStream);
    Cols := ParseCSVLine(Line);
    HeaderFields := Length(Cols);
    idxID := -1; idxName := -1; idxRegionID := -1; idxSystemID := -1; idxSecurity := -1;
    for var c := 0 to High(Cols) do
    begin
      if Cols[c] = 'stationID' then idxID := c;
      if Cols[c] = 'stationName' then idxName := c;
      if Cols[c] = 'regionID' then idxRegionID := c;
      if Cols[c] = 'solarSystemID' then idxSystemID := c;
      if Cols[c] = 'security' then idxSecurity := c;
    end;
    if (idxID < 0) or (idxName < 0) or (idxRegionID < 0) or (idxSystemID < 0) or (idxSecurity < 0) then Exit;
    while FileStream.Position < FileStream.Size do
    begin
      Line := ReadNextCSVRow(FileStream);
      if Line = '' then Continue;
      Cols := ParseCSVLine(Line);
      if Length(Cols) < HeaderFields then Continue;
      rec.stationID := StrToIntDef(Cols[idxID], 0);
      rec.stationName := Cols[idxName];
      rec.regionID := StrToIntDef(Cols[idxRegionID], 0);
      rec.systemID := StrToIntDef(Cols[idxSystemID], 0);
      rec.security := StrToFloatDef(Cols[idxSecurity], 0.0);
      FStations.AddOrSetValue(rec.stationID, rec);
      // Populate system-to-stations map
      if not FSystemToStations.ContainsKey(rec.systemID) then
        FSystemToStations.Add(rec.systemID, TList<Int64>.Create);
      FSystemToStations[rec.systemID].Add(rec.stationID);
    end;
  finally
    FileStream.Free;
  end;
  SaveToCache(CacheFile,
    procedure(S: TStream)
    var
      recLocal: TStationsRec;
      Count: Integer;
    begin
      Count := FStations.Count;
      S.WriteBuffer(Count, SizeOf(Count));
      for recLocal in FStations.Values do
      begin
        S.WriteBuffer(recLocal.stationID, SizeOf(recLocal.stationID));
        WriteString(S, recLocal.stationName);
        S.WriteBuffer(recLocal.regionID, SizeOf(recLocal.regionID));
        S.WriteBuffer(recLocal.systemID, SizeOf(recLocal.systemID));
        S.WriteBuffer(recLocal.security, SizeOf(recLocal.security));
      end;
    end);
end;


procedure TParser.LoadMarketGroups(const CSVFile, CacheFile: string);
var
  FileStream: TFileStream;
  idxID, idxParent, idxName, idxDesc, idxIcon, idxHasTypes: Integer;
  HeaderFields: Integer;
  rec: TMarketGroupRec;
  Cols: TArray<string>;
  parent: string;
  Line: string;
  AllShipGroupIDs: TList<string>;
  ShipTypePair: TPair<Integer, TTypesRec>;
begin
  // Try to load from cache, fallback to CSV if not available
  if LoadFromCache(CacheFile, CSVFile,
    procedure(S: TStream)
    var
      Count, i, icount, j: Integer;
      recLocal: TMarketGroupRec;
      parentID, childID: string;
      lst: TList<string>;
    begin
      S.ReadBuffer(Count, SizeOf(Count));
      for i := 1 to Count do
      begin
        recLocal.marketGroupID := ReadString(S);
        recLocal.parentGroupID := ReadString(S);
        recLocal.marketGroupName := ReadString(S);
        recLocal.description := ReadString(S);
        S.ReadBuffer(recLocal.iconID, SizeOf(recLocal.iconID));
        S.ReadBuffer(recLocal.hasTypes, SizeOf(recLocal.hasTypes));
        FMarketGroups.AddOrSetValue(recLocal.marketGroupID, recLocal);
      end;
      S.ReadBuffer(icount, SizeOf(icount));
      for i := 1 to icount do
      begin
        parentID := ReadString(S);
        S.ReadBuffer(j, SizeOf(j));
        lst := TList<string>.Create;
        FParentToChildren.Add(parentID, lst);
        while j > 0 do
        begin
          childID := ReadString(S);
          lst.Add(childID);
          Dec(j);
        end;
      end;
    end) then
  begin
    // Pre-cache array for fast access in filters
    FMarketGroupsArr := FMarketGroups.Values.ToArray;
    Exit;
  end;

  // Manual CSV Parse
  FMarketGroups.Clear;
  for parent in FParentToChildren.Keys do
    FParentToChildren[parent].Free;
  FParentToChildren.Clear;

  if not FileExists(CSVFile) then Exit;
  FileStream := TFileStream.Create(CSVFile, fmOpenRead or fmShareDenyWrite);
  try
    Line := ReadNextCSVRow(FileStream);
    Cols := ParseCSVLine(Line);
    HeaderFields := Length(Cols);

    idxID := -1; idxParent := -1; idxName := -1;
    idxDesc := -1; idxIcon := -1; idxHasTypes := -1;
    for var c := 0 to High(Cols) do
    begin
      if Cols[c] = 'marketGroupID' then idxID := c;
      if Cols[c] = 'parentGroupID' then idxParent := c;
      if Cols[c] = 'marketGroupName' then idxName := c;
      if Cols[c] = 'description' then idxDesc := c;
      if Cols[c] = 'iconID' then idxIcon := c;
      if Cols[c] = 'hasTypes' then idxHasTypes := c;
    end;
    if (idxID < 0) or (idxName < 0) then Exit;

    while FileStream.Position < FileStream.Size do
    begin
      Line := ReadNextCSVRow(FileStream);
      if Line = '' then Continue;
      Cols := ParseCSVLine(Line);
      if Length(Cols) < HeaderFields then Continue;

      rec.marketGroupID := Cols[idxID];

      if idxParent >= 0 then
        rec.parentGroupID := Cols[idxParent]
      else
        rec.parentGroupID := '';

      rec.marketGroupName := Cols[idxName];

      if idxDesc >= 0 then
        rec.description := Cols[idxDesc]
      else
        rec.description := '';

      if idxIcon >= 0 then
        rec.iconID := StrToIntDef(Cols[idxIcon], 0)
      else
        rec.iconID := 0;
      if (rec.iconID <= 0) or (rec.iconID > 10000) then
        rec.iconID := 1;

      if idxHasTypes >= 0 then
        rec.hasTypes := StrToIntDef(Cols[idxHasTypes], 0)
      else
        rec.hasTypes := 0;

      FMarketGroups.AddOrSetValue(rec.marketGroupID, rec);
      parent := rec.parentGroupID;
      if not FParentToChildren.ContainsKey(parent) then
        FParentToChildren.Add(parent, TList<string>.Create);
      FParentToChildren[parent].Add(rec.marketGroupID);
    end;

    // Pre-cache array after CSV load
    FMarketGroupsArr := FMarketGroups.Values.ToArray;
    AllShipGroupIDs := TList<string>.Create;
    try
      AllShipGroupIDs.Add('4'); // Ships root marketGroupID
      FindAllDescendantGroups('4', FMarketGroups, AllShipGroupIDs);

      AllShipTypes := TList<TTypesRec>.Create;
      try
        for ShipTypePair in FTypes do // ShipTypePair is a simple local variable
          if AllShipGroupIDs.Contains(ShipTypePair.Value.marketGroupID) then
            AllShipTypes.Add(ShipTypePair.Value);

        // AllShipTypes now contains all ship types under the "Ships" market group.
        // ... use AllShipTypes as needed ...
      finally
        AllShipTypes.Free;
      end;
    finally
      AllShipGroupIDs.Free;
    end;

  finally
    FileStream.Free;
  end;
end;

procedure TParser.FindAllDescendantGroups(const StartID: string; MarketGroups: TDictionary<string, TMarketGroupRec>; var Descendants: TList<string>);
var
  Group: TMarketGroupRec;
  Pair: TPair<string, TMarketGroupRec>;
begin
  for Pair in MarketGroups do
    if Pair.Value.parentGroupID = StartID then
    begin
      Descendants.Add(Pair.Key);
      // Recursive call for nested children
      FindAllDescendantGroups(Pair.Key, MarketGroups, Descendants);
    end;
end;

procedure TParser.LoadTypes;
var
  FileStream: TFileStream;
  idxTypeID, idxName, idxMarketGroupID, idxVolume, idxDescription, idxIconID: Integer;
  HeaderFields: Integer;
  rec: TTypesRec;
  Cols: TArray<string>;
  Line: string;
begin
  if LoadFromCache(TypesBin, TypesFile,
    procedure(S: TStream)
    var Count, i: Integer; recLocal: TTypesRec;
    begin
      S.ReadBuffer(Count, SizeOf(Count));
      for i := 1 to Count do
      begin
        S.ReadBuffer(recLocal.typeID, SizeOf(recLocal.typeID));
        recLocal.typeName := ReadString(S);
        recLocal.marketGroupID := ReadString(S);
        S.ReadBuffer(recLocal.volume, SizeOf(recLocal.volume));
        recLocal.description := ReadString(S);                     // NEW FIELD
        S.ReadBuffer(recLocal.iconID, SizeOf(recLocal.iconID));    // NEW FIELD
        if (recLocal.marketGroupID = '') or SameText(recLocal.marketGroupID, 'None') then
          Continue;
        FTypes.AddOrSetValue(recLocal.typeID, recLocal);
      end;
    end)
  then Exit;
  FTypes.Clear;
  if not FileExists(TypesFile) then Exit;
  FileStream := TFileStream.Create(TypesFile, fmOpenRead or fmShareDenyWrite);
  try
    // Read and parse header row
    Line := ReadNextCSVRow(FileStream);
    Cols := ParseCSVLine(Line);
    HeaderFields := Length(Cols);
    idxTypeID := -1; idxName := -1; idxMarketGroupID := -1; idxVolume := -1;
    for var c := 0 to High(Cols) do
    begin
      if SameText(Cols[c], 'typeID') then idxTypeID := c;
      if SameText(Cols[c], 'typeName') then idxName := c;
      if SameText(Cols[c], 'marketGroupID') then idxMarketGroupID := c;
      if SameText(Cols[c], 'volume') then idxVolume := c;
      if SameText(Cols[c], 'description') then idxDescription := c; // NEW
      if SameText(Cols[c], 'iconID') then idxIconID := c;           // NEW
    end;

    if (idxTypeID < 0) or (idxName < 0) then Exit;
    while FileStream.Position < FileStream.Size do
    begin
      Line := ReadNextCSVRow(FileStream);
      if Line = '' then Continue;
      Cols := ParseCSVLine(Line);
      if Length(Cols) < HeaderFields then
      begin
        Continue;
      end;

      // Market Group ID
      if idxMarketGroupID >= 0 then
      begin
        if (Cols[idxMarketGroupID] = '') or SameText(Cols[idxMarketGroupID], 'None') then
          Continue;
        rec.marketGroupID := Cols[idxMarketGroupID]
      end;
      // Type ID
      rec.typeID := StrToIntDef(Cols[idxTypeID], 0);
      // Type Name
      rec.typeName := Cols[idxName];
      rec.lowerTypeName := LowerCase(rec.typeName);
      // Volume handling
      if (idxVolume >= 0) and (idxVolume < Length(Cols)) then
        rec.volume := StrToFloatDef(Cols[idxVolume], 0)
      else
        rec.volume := 0;
      // Description
      if (idxDescription >= 0) and (idxDescription < Length(Cols)) then
        rec.description := Cols[idxDescription]
      else
        rec.description := '';
      // Icon ID
      if (idxIconID >= 0) and (idxIconID < Length(Cols)) then
        rec.iconID := StrToInt64Def(Cols[idxIconID], 0)
      else
        rec.iconID := 0;
      FTypes.AddOrSetValue(rec.typeID, rec);
    end;
  finally
    FileStream.Free;
  end;
  SaveToCache(TypesBin,
    procedure(S: TStream)
    var Count: Integer; recLocal: TTypesRec;
    begin
      Count := FTypes.Count;
      S.WriteBuffer(Count, SizeOf(Count));
      for recLocal in FTypes.Values do
      begin
        S.WriteBuffer(recLocal.typeID, SizeOf(recLocal.typeID));
        WriteString(S, recLocal.typeName);
        WriteString(S, recLocal.marketGroupID);
        S.WriteBuffer(recLocal.volume, SizeOf(recLocal.volume));
        WriteString(S, recLocal.description);
        S.WriteBuffer(recLocal.iconID, SizeOf(recLocal.iconID));
      end;
    end);
    FTypesArr := FTypes.Values.ToArray;

end;

procedure TParser.UpdateType(const Rec: TTypesRec);
begin
  FTypes.AddOrSetValue(Rec.typeID, Rec);
  FTypesArr := FTypes.Values.ToArray;
  SaveToCache(TypesBin,
      procedure(S: TStream)
      var Count: Integer; recLocal: TTypesRec;
      begin
        Count := FTypes.Count;
        S.WriteBuffer(Count, SizeOf(Count));
        for recLocal in FTypes.Values do
        begin
          S.WriteBuffer(recLocal.typeID, SizeOf(recLocal.typeID));
          WriteString(S, recLocal.typeName);
          WriteString(S, recLocal.marketGroupID);
          S.WriteBuffer(recLocal.volume, SizeOf(recLocal.volume));
          WriteString(S, recLocal.description);
          S.WriteBuffer(recLocal.iconID, SizeOf(recLocal.iconID));
        end;
      end);
end;

procedure TParser.SaveTradeHistory(const Dict: TDictionary<Integer, TTradeHistoryRec>);
var
  FS: TFileStream;
  Pair: TPair<Integer, TTradeHistoryRec>;
  Count: Integer;
begin
  FS := TFileStream.Create(TradeHistoryBin, fmCreate or fmOpenWrite);
  try
    Count := Dict.Count;
    FS.WriteBuffer(Count, SizeOf(Count)); // Save dictionary count
    for Pair in Dict do
    begin
      FS.WriteBuffer(Pair.Key, SizeOf(Pair.Key));     // Save transaction number (key)
      FS.WriteBuffer(Pair.Value, SizeOf(TTradeHistoryRec)); // Save record
    end;
  finally
    FS.Free;
  end;
end;

procedure TParser.LoadTradeHistory(const Dict: TDictionary<Integer, TTradeHistoryRec>);
var
  FS: TFileStream;
  I, Count, Key: Integer;
  Rec: TTradeHistoryRec;
begin
  Dict.Clear;
  FS := TFileStream.Create(TradeHistoryBin, fmOpenRead);
  try
    FS.ReadBuffer(Count, SizeOf(Count)); // Read dictionary count
    for I := 1 to Count do
    begin
      FS.ReadBuffer(Key, SizeOf(Key)); // Read transaction number
      FS.ReadBuffer(Rec, SizeOf(TTradeHistoryRec)); // Read record
      Dict.AddOrSetValue(Key, Rec);
    end;
  finally
    FS.Free;
  end;
end;

procedure TParser.LoadSystemJumps(const CSVFile, CacheFile: string);
var
  Lines, Fields: TStringList;
  idxFrom, idxTo: Integer;
  Row, ExpectedCols: Integer;
  fromID, toID: Integer;
  TempNeighborMap: TDictionary<Integer, TList<Integer>>;
  NeighborList: TList<Integer>;
  NeighborsArr: TArray<Integer>;
begin
  // Cache load: now reads/writes TArray<Integer> instead of TList<Integer>
  if LoadFromCache(CacheFile, CSVFile,
    procedure(S: TStream)
    var
      Count, i, j, sysID, connCount, connID: Integer;
      Arr: TArray<Integer>;
    begin
      S.ReadBuffer(Count, SizeOf(Count));
      for i := 1 to Count do
      begin
        S.ReadBuffer(sysID, SizeOf(sysID));
        S.ReadBuffer(connCount, SizeOf(connCount));
        SetLength(Arr, connCount);
        for j := 0 to connCount - 1 do
        begin
          S.ReadBuffer(connID, SizeOf(connID));
          Arr[j] := connID;
        end;
        FSystemJumps.AddOrSetValue(sysID, Arr);
      end;
    end
  ) then Exit;

  FSystemJumps.Clear;
  if not FileExists(CSVFile) then Exit;
  Lines := TStringList.Create;
  Fields := TStringList.Create;
  TempNeighborMap := TDictionary<Integer, TList<Integer>>.Create; // Temporary for building before converting to array
  Fields.StrictDelimiter := True;
  Fields.Delimiter := ',';
  Fields.QuoteChar := '"';
  try
    Lines.LoadFromFile(CSVFile, TEncoding.UTF8);
    if Lines.Count < 2 then Exit;
    Fields.DelimitedText := Lines[0];
    ExpectedCols := Fields.Count;
    idxFrom := Fields.IndexOf('fromSolarSystemID');
    idxTo := Fields.IndexOf('toSolarSystemID');
    if (idxFrom < 0) or (idxTo < 0) then Exit;
    for Row := 1 to Lines.Count - 1 do
    begin
      Fields.DelimitedText := Lines[Row];
      if Fields.Count < ExpectedCols then Continue;
      fromID := StrToIntDef(Fields[idxFrom], 0);
      toID := StrToIntDef(Fields[idxTo], 0);
      if (fromID = 0) or (toID = 0) then Continue;

      // Build bidirectional jump links in temp lists
      if not TempNeighborMap.ContainsKey(fromID) then
        TempNeighborMap.Add(fromID, TList<Integer>.Create);
      if not TempNeighborMap.ContainsKey(toID) then
        TempNeighborMap.Add(toID, TList<Integer>.Create);

      if not TempNeighborMap[fromID].Contains(toID) then
        TempNeighborMap[fromID].Add(toID);
      if not TempNeighborMap[toID].Contains(fromID) then
        TempNeighborMap[toID].Add(fromID);
    end;

    // After CSV parse, transfer lists to arrays and free lists
    for var sysID in TempNeighborMap.Keys do
    begin
      NeighborList := TempNeighborMap[sysID];
      NeighborsArr := NeighborList.ToArray;
      FSystemJumps.AddOrSetValue(sysID, NeighborsArr);
      NeighborList.Free;
    end;
    TempNeighborMap.Free;
  finally
    Fields.Free;
    Lines.Free;
  end;

  // Save cache as arrays
  SaveToCache(CacheFile,
    procedure(S: TStream)
    var
      sysID, connCount, connID: Integer;
      Arr: TArray<Integer>;
      Count: Integer;
    begin
      Count := FSystemJumps.Count;
      S.WriteBuffer(Count, SizeOf(Count));
      for sysID in FSystemJumps.Keys do
      begin
        Arr := FSystemJumps[sysID];
        S.WriteBuffer(sysID, SizeOf(sysID));
        connCount := Length(Arr);
        S.WriteBuffer(connCount, SizeOf(connCount));
        for connID in Arr do
          S.WriteBuffer(connID, SizeOf(connID));
      end;
    end
  );
end;

procedure TParser.BuildAllPairsJumpsMatrix;
var
  SystemID, TargetID: Integer;
  JumpDistances: TDictionary<Integer, Integer>;
begin
  if Assigned(FAllPairsJumps) then
    FAllPairsJumps.Free;
  FAllPairsJumps := TDictionary<Integer, TDictionary<Integer, Integer>>.Create;
  for SystemID in FSystemJumps.Keys do
  begin
    JumpDistances := TDictionary<Integer, Integer>.Create;
    // BFS from SystemID to all others
    CalculateBFSJumpDistances(SystemID, JumpDistances); // <-- see below
    FAllPairsJumps.Add(SystemID, JumpDistances);
  end;
end;

procedure TParser.CalculateBFSJumpDistances(RootSystem: Integer; JumpDistances: TDictionary<Integer,Integer>);
var
  Queue: TQueue<Integer>;
  Visited: TDictionary<Integer,Integer>;
  Current, Neighbor: Integer;
  Neighbors: TArray<Integer>;
begin
  Queue := TQueue<Integer>.Create;
  Visited := TDictionary<Integer,Integer>.Create;
  try
    Queue.Enqueue(RootSystem);
    Visited.Add(RootSystem, 0);
    JumpDistances.Add(RootSystem, 0);
    while Queue.Count > 0 do
    begin
      Current := Queue.Dequeue;
      if FSystemJumps.TryGetValue(Current, Neighbors) then
      begin
        for Neighbor in Neighbors do
        begin
          if not Visited.ContainsKey(Neighbor) then
          begin
            Visited.Add(Neighbor, Visited[Current] + 1);
            JumpDistances.Add(Neighbor, Visited[Neighbor]);
            Queue.Enqueue(Neighbor);
          end;
        end;
      end;
    end;
  finally
    Queue.Free;
    Visited.Free;
  end;
end;


procedure TParser.LoadSystems(const CSVFile, CacheFile: string);
var
  FileStream: TFileStream;
  idxRegion, idxID, idxConstellation, idxName, idxSecurity: Integer;
  idxX, idxY, idxZ: Integer;
  HeaderFields: Integer;
  rec: TSystemsRec;
  Cols: TArray<string>;
  Line: string;
  Loaded: Boolean;
begin
  Loaded := False;
  if LoadFromCache(CacheFile, CSVFile,
    procedure(S: TStream)
    var
      Count, i: Integer;
      recLocal: TSystemsRec;
    begin
      if FSystems = nil then
        FSystems := TDictionary<Integer, TSystemsRec>.Create
      else
        FSystems.Clear;
      S.ReadBuffer(Count, SizeOf(Count));
      for i := 1 to Count do
      begin
        S.ReadBuffer(recLocal.SystemID, SizeOf(recLocal.SystemID));
        S.ReadBuffer(recLocal.constellationID, SizeOf(recLocal.constellationID));
        recLocal.SystemName := ReadString(S);
        S.ReadBuffer(recLocal.security, SizeOf(recLocal.security));
        S.ReadBuffer(recLocal.regionID, SizeOf(recLocal.regionID));
        S.ReadBuffer(recLocal.x, SizeOf(recLocal.x));
        S.ReadBuffer(recLocal.y, SizeOf(recLocal.y));
        S.ReadBuffer(recLocal.z, SizeOf(recLocal.z));
        FSystems.AddOrSetValue(recLocal.SystemID, recLocal);
      end;
      Loaded := True;
    end) then
  begin
    BuildRegionToSolarSystemIDs; // <-- Call here after cache load
    Exit;
  end;

  if FSystems = nil then
    FSystems := TDictionary<Integer, TSystemsRec>.Create
  else
    FSystems.Clear;
  if not FileExists(CSVFile) then Exit;
  FileStream := TFileStream.Create(CSVFile, fmOpenRead or fmShareDenyWrite);
  try
    Line := ReadNextCSVRow(FileStream);
    Cols := ParseCSVLine(Line);
    HeaderFields := Length(Cols);

    // Index lookup for each column:
    idxID := -1; idxConstellation := -1; idxName := -1;
    idxSecurity := -1; idxRegion := -1; idxX := -1; idxY := -1; idxZ := -1;
    for var c := 0 to High(Cols) do
    begin
      if Cols[c] = 'solarSystemID'      then idxID := c;
      if Cols[c] = 'constellationID'    then idxConstellation := c;
      if Cols[c] = 'solarSystemName'    then idxName := c;
      if Cols[c] = 'security'           then idxSecurity := c;
      if Cols[c] = 'regionID'           then idxRegion := c;
      if Cols[c] = 'x'                  then idxX := c;
      if Cols[c] = 'y'                  then idxY := c;
      if Cols[c] = 'z'                  then idxZ := c;
    end;
    if (idxID < 0) or (idxConstellation < 0) or (idxName < 0) or
       (idxSecurity < 0) or (idxRegion < 0) or
       (idxX < 0) or (idxY < 0) or (idxZ < 0) then Exit;

    while FileStream.Position < FileStream.Size do
    begin
      Line := ReadNextCSVRow(FileStream);
      if Line = '' then Continue;
      Cols := ParseCSVLine(Line);
      if Length(Cols) < HeaderFields then Continue;
      rec.SystemID      := StrToIntDef(Cols[idxID], 0);
      rec.constellationID := StrToInt64Def(Cols[idxConstellation], 0);
      rec.SystemName    := Cols[idxName];
      rec.security      := StrToFloatDef(Cols[idxSecurity], 0);
      rec.regionID      := StrToIntDef(Cols[idxRegion], 0);
      rec.x := StrToFloatDef(Cols[idxX], 0.0);
      rec.y := StrToFloatDef(Cols[idxY], 0.0);
      rec.z := StrToFloatDef(Cols[idxZ], 0.0);
      if rec.SystemID <> 0 then
        FSystems.AddOrSetValue(rec.SystemID, rec);
    end;
  finally
    FileStream.Free;
  end;

  SaveToCache(CacheFile,
    procedure(S: TStream)
    var
      recLocal: TSystemsRec;
      Count: Integer;
    begin
      Count := FSystems.Count;
      S.WriteBuffer(Count, SizeOf(Count));
      for recLocal in FSystems.Values do
      begin
        S.WriteBuffer(recLocal.SystemID, SizeOf(recLocal.SystemID));
        S.WriteBuffer(recLocal.constellationID, SizeOf(recLocal.constellationID));
        WriteString(S, recLocal.SystemName);
        S.WriteBuffer(recLocal.security, SizeOf(recLocal.security));
        S.WriteBuffer(recLocal.regionID, SizeOf(recLocal.regionID));
        S.WriteBuffer(recLocal.x, SizeOf(recLocal.x));
        S.WriteBuffer(recLocal.y, SizeOf(recLocal.y));
        S.WriteBuffer(recLocal.z, SizeOf(recLocal.z));
      end;
    end);

  BuildRegionToSolarSystemIDs; // <-- Call here after CSV load
end;



end.

