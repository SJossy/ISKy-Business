unit MarketTreeBuilder;

interface

uses
  System.Generics.Collections, System.SysUtils, Vcl.ComCtrls, Common, Parser, System.Diagnostics, Winapi.Windows;

type
  TMarketTreeNodeData = class
  public
    ParentGroupID: string;
    MarketGroupID: string;
    Name: string;
    IsItem: Boolean;
    HasTypes: Boolean;
    TypeID: Integer;
    IconID: Integer;
    Description: string;
    constructor Create(
      const AParentGroupID, AMarketGroupID, AName: string;
      AIsItem, AHasTypes: Boolean;
      ATypeID, AIconID: Integer;
      const ADescription: string);
  end;
  TMarketTreeBuilder = class
  private
    class function BuildTypesByGroup(const TypesDict: TDictionary<Integer, TTypesRec>): TDictionary<string, TList<TTypesRec>>;
    class function AddGroupNode(TreeView: TTreeView; ParentNode: TTreeNode; const GroupRec: TMarketGroupRec; const TypesByGroup: TDictionary<string, TList<TTypesRec>>; var NodeCount: Integer): TTreeNode;
    class var FIsFiltered: Boolean;
  public
    class property IsFiltered: Boolean read FIsFiltered write FIsFiltered;
    class procedure BuildFullMarketTree(TreeView: TTreeView; const GroupMap: TDictionary<string, TMarketGroupRec>; const ChildMap: TDictionary<string, TList<string>>; const TypesDict: TDictionary<Integer, TTypesRec>);
    class procedure BuildFilteredMarketTree(TreeView: TTreeView; const GroupMap: TDictionary<string, TMarketGroupRec>; const ChildMap: TDictionary<string, TList<string>>; const FilterGroups: THashSet<string>; const FilterItems: TDictionary<Integer, TTypesRec>);
    class procedure FreeAllNodeData(TreeView: TTreeView);
    class procedure FilterMarketTree(TreeView: TTreeView; const MarketGroups: TDictionary<string, TMarketGroupRec>; const Types: TDictionary<Integer, TTypesRec>; const ParentToChildren: TDictionary<string, TList<string>>; const FilterText: string);
  end;

implementation

procedure DebugLog(const Msg: string);
begin
  OutputDebugString(PChar(Msg));
end;

{ TMarketTreeNodeData }
constructor TMarketTreeNodeData.Create(const AParentGroupID, AMarketGroupID, AName: string; AIsItem, AHasTypes: Boolean; ATypeID, AIconID: Integer; const ADescription: string);
begin
  ParentGroupID := AParentGroupID;
  MarketGroupID := AMarketGroupID;
  Name := AName;
  IsItem := AIsItem;
  HasTypes := AHasTypes;
  TypeID := ATypeID;
  IconID := AIconID;
  Description := ADescription;
end;

{ TMarketTreeBuilder }

class procedure TMarketTreeBuilder.FilterMarketTree(
  TreeView: TTreeView;
  const MarketGroups: TDictionary<string, TMarketGroupRec>;
  const Types: TDictionary<Integer, TTypesRec>;
  const ParentToChildren: TDictionary<string, TList<string>>;
  const FilterText: string);
var
  FilteredGroupIDs: THashSet<string>;
  FilteredItems: TDictionary<Integer, TTypesRec>;
  FilterLower: string;
  procedure IncludeParentGroups(const GroupID: string);
  var
    ParentGroup: TMarketGroupRec;
  begin
    if not FilteredGroupIDs.Contains(GroupID) and MarketGroups.TryGetValue(GroupID, ParentGroup) then
    begin
      FilteredGroupIDs.Add(GroupID);
      if (ParentGroup.parentGroupID <> '') and (ParentGroup.parentGroupID <> 'None') then
        IncludeParentGroups(ParentGroup.parentGroupID);
    end;
  end;
begin
  FIsFiltered := True;
  FilterLower := LowerCase(Trim(FilterText));
  FilteredGroupIDs := THashSet<string>.Create;
  FilteredItems := TDictionary<Integer, TTypesRec>.Create;
  try
    // Items
    for var typeRec in Types.Values do
    begin
      if (FilterLower = '') or (Pos(FilterLower, LowerCase(typeRec.typeName)) > 0) then
      begin
        FilteredItems.Add(typeRec.typeID, typeRec);
        IncludeParentGroups(typeRec.marketGroupID);
      end;
    end;
    // Groups
    for var groupRec in MarketGroups.Values do
    begin
      if (FilterLower = '') or
         (Pos(FilterLower, LowerCase(groupRec.marketGroupName)) > 0) or
         (Pos(FilterLower, LowerCase(groupRec.description)) > 0) then
      begin
        IncludeParentGroups(groupRec.marketGroupID);
      end;
    end;
    BuildFilteredMarketTree(TreeView, MarketGroups, ParentToChildren, FilteredGroupIDs, FilteredItems);
  finally
    FilteredGroupIDs.Free;
    FilteredItems.Free;
  end;
end;



class function TMarketTreeBuilder.BuildTypesByGroup(const TypesDict: TDictionary<Integer, TTypesRec>): TDictionary<string, TList<TTypesRec>>;
var
  TypeRec: TTypesRec;
  List: TList<TTypesRec>;
begin
  Result := TDictionary<string, TList<TTypesRec>>.Create;
  for TypeRec in TypesDict.Values do
  begin
    if not Result.TryGetValue(TypeRec.marketGroupID, List) then
    begin
      List := TList<TTypesRec>.Create;
      Result.Add(TypeRec.marketGroupID, List);
    end;
    List.Add(TypeRec);
  end;
end;

class function TMarketTreeBuilder.AddGroupNode(
  TreeView: TTreeView;
  ParentNode: TTreeNode;
  const GroupRec: TMarketGroupRec;
  const TypesByGroup: TDictionary<string, TList<TTypesRec>>;
  var NodeCount: Integer
): TTreeNode;
var
  GroupNode: TTreeNode;
  NodeData: TMarketTreeNodeData;
  TypeList: TList<TTypesRec>;
  TypeRec: TTypesRec;
  ItemData: TMarketTreeNodeData;
begin
  NodeData := TMarketTreeNodeData.Create(
    GroupRec.parentGroupID, GroupRec.marketGroupID,
    GroupRec.marketGroupName, False, GroupRec.hasTypes = 1, 0,
    GroupRec.iconID, GroupRec.description
  );
  GroupNode := TreeView.Items.AddChildObject(ParentNode, NodeData.Name, NodeData);
  Inc(NodeCount);

  if TypesByGroup.TryGetValue(GroupRec.marketGroupID, TypeList) then
  begin
    for TypeRec in TypeList do
    begin
      ItemData := TMarketTreeNodeData.Create(
        GroupRec.marketGroupID, GroupRec.marketGroupID, TypeRec.typeName, True,
        False, TypeRec.typeID, TypeRec.iconID, TypeRec.description
      );
      TreeView.Items.AddChildObject(GroupNode, ItemData.Name, ItemData);
      Inc(NodeCount);
    end;
  end;
  Result := GroupNode;
end;

class procedure TMarketTreeBuilder.BuildFullMarketTree(
  TreeView: TTreeView;
  const GroupMap: TDictionary<string, TMarketGroupRec>;
  const ChildMap: TDictionary<string, TList<string>>;
  const TypesDict: TDictionary<Integer, TTypesRec>);
var
  groupRec: TMarketGroupRec;
  TypesByGroup: TDictionary<string, TList<TTypesRec>>;
  SW: TStopwatch;
  NodeCount: Integer;
  procedure Traverse(const GroupID: string; ParentNode: TTreeNode);
  var
    CurGroup: TMarketGroupRec;
    CurNode: TTreeNode;
    ChildList: TList<string>;
    ChildID: string;
  begin
    if not GroupMap.TryGetValue(GroupID, CurGroup) then Exit;
    CurNode := TMarketTreeBuilder.AddGroupNode(TreeView, ParentNode, CurGroup, TypesByGroup, NodeCount);
    if ChildMap.TryGetValue(GroupID, ChildList) then
      for ChildID in ChildList do
        Traverse(ChildID, CurNode);
  end;
begin
  FIsFiltered := False;
  TypesByGroup := BuildTypesByGroup(TypesDict);
  NodeCount := 0;
  try
    SW := TStopwatch.StartNew;
    TreeView.Items.BeginUpdate;
    try
      FreeAllNodeData(TreeView);
      TreeView.Items.Clear;
      for groupRec in GroupMap.Values do
        if (groupRec.parentGroupID = '') or SameText(groupRec.parentGroupID, 'None') then
          Traverse(groupRec.marketGroupID, nil);
    finally
      TreeView.Items.EndUpdate;
    end;
    TreeView.SortType := stText;
    DebugLog('[MarketTreeBuilder] BuildFullMarketTree took ' + SW.ElapsedMilliseconds.ToString + ' ms');
    DebugLog('Total nodes created: ' + NodeCount.ToString);
  finally
    for var List in TypesByGroup.Values do List.Free;
    TypesByGroup.Free;
  end;
end;

class procedure TMarketTreeBuilder.BuildFilteredMarketTree(
  TreeView: TTreeView;
  const GroupMap: TDictionary<string, TMarketGroupRec>;
  const ChildMap: TDictionary<string, TList<string>>;
  const FilterGroups: THashSet<string>;
  const FilterItems: TDictionary<Integer, TTypesRec>);
var
  groupRec: TMarketGroupRec;
  TypesByGroup: TDictionary<string, TList<TTypesRec>>;
  SW: TStopwatch;
  NodeCount: Integer;
  procedure AddFilteredGroup(GroupID: string; ParentNode: TTreeNode);
  var
    group: TMarketGroupRec;
    node: TTreeNode;
    childID: string;
    children: TList<string>;
  begin
    if not GroupMap.TryGetValue(GroupID, group) then Exit;
    node := AddGroupNode(TreeView, ParentNode, group, TypesByGroup, NodeCount);
    if ChildMap.TryGetValue(GroupID, children) then
      for childID in children do
        if FilterGroups.Contains(childID) then
          AddFilteredGroup(childID, node);
  end;
begin
  TypesByGroup := BuildTypesByGroup(FilterItems);
  NodeCount := 0;
  try
    SW := TStopwatch.StartNew;
    TreeView.Items.BeginUpdate;
    try
      FreeAllNodeData(TreeView);
      TreeView.Items.Clear;
      for groupRec in GroupMap.Values do
        if ((groupRec.parentGroupID = '') or SameText(groupRec.parentGroupID, 'None'))
          and FilterGroups.Contains(groupRec.marketGroupID) then
            AddFilteredGroup(groupRec.marketGroupID, nil);
      if TreeView.Items.Count = 0 then
        TreeView.Items.Add(nil, 'No results found');
    finally
      TreeView.Items.EndUpdate;
    end;
    TreeView.SortType := stText;
    DebugLog('[MarketTreeBuilder] BuildFilteredMarketTree took ' + SW.ElapsedMilliseconds.ToString + ' ms');
    DebugLog('Total nodes created: ' + NodeCount.ToString);
  finally
    for var List in TypesByGroup.Values do List.Free;
    TypesByGroup.Free;
  end;
end;

class procedure TMarketTreeBuilder.FreeAllNodeData(TreeView: TTreeView);
var
  i: Integer;
  SW: TStopwatch;
begin
  SW := TStopwatch.StartNew;
  for i := 0 to TreeView.Items.Count - 1 do
    if Assigned(TreeView.Items[i].Data) then
    begin
      TObject(TreeView.Items[i].Data).Free;
      TreeView.Items[i].Data := nil;
    end;
  DebugLog('[MarketTreeBuilder] FreeAllNodeData took ' + SW.ElapsedMilliseconds.ToString + ' ms');
end;

end.

