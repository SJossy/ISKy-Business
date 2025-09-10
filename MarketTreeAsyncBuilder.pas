unit MarketTreeAsyncBuilder;

interface

uses
  System.Generics.Collections, System.SysUtils, Vcl.ComCtrls, Vcl.Forms, Common, Parser, System.Threading, System.Diagnostics, Winapi.Windows, System.Classes;

type
  TMarketTreeNodeRecipe = class
  public
    Name: string;
    IsItem: Boolean;
    TypeID: Integer;
    Children: TObjectList<TMarketTreeNodeRecipe>;
    constructor Create(const AName: string; AIsItem: Boolean; ATypeID: Integer);
    destructor Destroy; override;
  end;

  TMarketTreeAsyncBuilder = class
  public
    class procedure BuildFullMarketTreeAsync(TreeView: TTreeView;
      const GroupMap: TDictionary<string, TMarketGroupRec>;
      const ChildMap: TDictionary<string, TList<string>>;
      const TypesDict: TDictionary<Integer, TTypesRec>);

    class procedure BuildFilteredMarketTreeAsync(TreeView: TTreeView;
      const GroupMap: TDictionary<string, TMarketGroupRec>;
      const ChildMap: TDictionary<string, TList<string>>;
      const FilteredGroupIDs: THashSet<string>;
      const FilteredItems: TDictionary<Integer, TTypesRec>);
  end;

implementation

procedure DebugLog(const Msg: string);
begin
  OutputDebugString(PChar(Msg));
end;

{ TMarketTreeNodeRecipe }
constructor TMarketTreeNodeRecipe.Create(const AName: string; AIsItem: Boolean; ATypeID: Integer);
begin
  Name := AName;
  IsItem := AIsItem;
  TypeID := ATypeID;
  Children := TObjectList<TMarketTreeNodeRecipe>.Create;
end;

destructor TMarketTreeNodeRecipe.Destroy;
begin
  Children.Free;
  inherited;
end;

function BuildTypesByGroup(const TypesDict: TDictionary<Integer, TTypesRec>): TDictionary<string, TList<TTypesRec>>;
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

procedure BuildFilteredMarketTreeRecipe(
  const GroupMap: TDictionary<string, TMarketGroupRec>;
  const ChildMap: TDictionary<string, TList<string>>;
  const TypesByGroup: TDictionary<string, TList<TTypesRec>>;
  const FilteredGroupIDs: THashSet<string>;
  const FilteredItems: TDictionary<Integer, TTypesRec>;
  Roots: TObjectList<TMarketTreeNodeRecipe>
);

  function BuildFilteredSubtree(const GroupID: string): TMarketTreeNodeRecipe;
  var
    groupRec: TMarketGroupRec;
    Recipe: TMarketTreeNodeRecipe;
    ChildList: TList<string>;
    childID: string;
    FilteredType: TTypesRec;
    AddedChild: Boolean;
  begin
    DebugLog('BuildFilteredSubtree: ' + GroupID);

    if not FilteredGroupIDs.Contains(GroupID) then
    begin
      DebugLog('GroupID not in FilteredGroupIDs: ' + GroupID);
      Exit(nil);
    end;

    if not GroupMap.TryGetValue(GroupID, groupRec) then
    begin
      DebugLog('GroupID not found in GroupMap: ' + GroupID);
      Exit(nil);
    end;

    Recipe := TMarketTreeNodeRecipe.Create(groupRec.marketGroupName, False, 0);
    AddedChild := False;

    // Add filtered item children for this group
    for var ItemPair in FilteredItems do
    begin
      FilteredType := ItemPair.Value;
      if FilteredType.marketGroupID = GroupID then
      begin
        Recipe.Children.Add(TMarketTreeNodeRecipe.Create(FilteredType.typeName, True, FilteredType.typeID));
        DebugLog('Added item child for group ' + GroupID + ': ' + FilteredType.typeName);
        AddedChild := True;
      end;
    end;

    // Recurse filtered group children
    if ChildMap.TryGetValue(GroupID, ChildList) then
      for childID in ChildList do
      begin
        var SubNode := BuildFilteredSubtree(childID);
        if Assigned(SubNode) then
        begin
          Recipe.Children.Add(SubNode);
          DebugLog('Added group child for group ' + GroupID + ': ' + childID);
          AddedChild := True;
        end;
      end;

    if (Recipe.Children.Count > 0) or AddedChild then
      Result := Recipe
    else
    begin
      DebugLog('Recipe for group ' + GroupID + ' (' + groupRec.marketGroupName + ') had no children');
      Recipe.Free;
      Result := nil;
    end;
  end;

var
  groupRec: TMarketGroupRec;
begin
  DebugLog('FilteredGroupIDs count: ' + FilteredGroupIDs.Count.ToString);
  DebugLog('FilteredItems count: ' + FilteredItems.Count.ToString);

  for groupRec in GroupMap.Values do
    if ((groupRec.parentGroupID = '') or SameText(groupRec.parentGroupID, 'None'))
        and FilteredGroupIDs.Contains(groupRec.marketGroupID) then
    begin
      DebugLog('Trying root group: ' + groupRec.marketGroupName + ' (' + groupRec.marketGroupID + ')');
      var RootNode := BuildFilteredSubtree(groupRec.marketGroupID);
      if Assigned(RootNode) then
      begin
        DebugLog('Added root node: ' + RootNode.Name);
        Roots.Add(RootNode);
      end
      else
        DebugLog('No matching subtree for root group: ' + groupRec.marketGroupName);
    end;

  DebugLog('Total filtered root recipe nodes: ' + Roots.Count.ToString);
end;

procedure PopulateTreeViewFromRecipe(TreeView: TTreeView; Roots: TObjectList<TMarketTreeNodeRecipe>);
  procedure AddNodeRecursively(const Recipe: TMarketTreeNodeRecipe; ParentNode: TTreeNode);
  var
    Node: TTreeNode;
  begin
    Node := TreeView.Items.AddChild(ParentNode, Recipe.Name);
    Node.Data := Recipe;
    for var Child in Recipe.Children do
      AddNodeRecursively(Child, Node);
  end;
begin
  DebugLog('Populating TreeView with ' + Roots.Count.ToString + ' root nodes.');
  TreeView.Items.BeginUpdate;
  try
    TreeView.Items.Clear;
    for var Root in Roots do
      AddNodeRecursively(Root, nil);
  finally
    TreeView.Items.EndUpdate;
  end;
end;

{ TMarketTreeAsyncBuilder }
procedure BuildMarketTreeRecipe(
  const GroupMap: TDictionary<string, TMarketGroupRec>;
  const ChildMap: TDictionary<string, TList<string>>;
  const TypesByGroup: TDictionary<string, TList<TTypesRec>>;
  Roots: TObjectList<TMarketTreeNodeRecipe>
);

  function BuildSubtree(const GroupID: string): TMarketTreeNodeRecipe;
  var
    groupRec: TMarketGroupRec;
    Recipe: TMarketTreeNodeRecipe;
    ChildList: TList<string>;
    TypeList: TList<TTypesRec>;
    typeRec: TTypesRec;
    childID: string;
    AddedChild: Boolean;
  begin
    if not GroupMap.TryGetValue(GroupID, groupRec) then
    begin
      DebugLog('GroupID not found in GroupMap: ' + GroupID);
      Exit(nil);
    end;

    Recipe := TMarketTreeNodeRecipe.Create(groupRec.marketGroupName, False, 0);
    AddedChild := False;

    // Add item children (types)
    if TypesByGroup.TryGetValue(GroupID, TypeList) then
      for typeRec in TypeList do
      begin
        Recipe.Children.Add(TMarketTreeNodeRecipe.Create(typeRec.typeName, True, typeRec.typeID));
        AddedChild := True;
      end;

    // Recurse children groups
    if ChildMap.TryGetValue(GroupID, ChildList) then
      for childID in ChildList do
      begin
        var SubNode := BuildSubtree(childID);
        if Assigned(SubNode) then
        begin
          Recipe.Children.Add(SubNode);
          DebugLog('Added child group to group ' + GroupID + ': ' + childID);
          AddedChild := True;
        end;
      end;

    if (Recipe.Children.Count > 0) or AddedChild then
      Result := Recipe
    else
    begin
      DebugLog('Recipe for group ' + GroupID + ' (' + groupRec.marketGroupName + ') had no children');
      Recipe.Free;
      Result := nil;
    end;
  end;

var
  groupRec: TMarketGroupRec;
begin
  DebugLog('Building full market tree: group count = ' + GroupMap.Count.ToString);
  for groupRec in GroupMap.Values do
    if (groupRec.parentGroupID = '') or SameText(groupRec.parentGroupID, 'None') then
    begin
      DebugLog('Trying root group: ' + groupRec.marketGroupName + ' (' + groupRec.marketGroupID + ')');
      var RootNode := BuildSubtree(groupRec.marketGroupID);
      if Assigned(RootNode) then
      begin
        DebugLog('Added root node: ' + RootNode.Name);
        Roots.Add(RootNode);
      end
      else
        DebugLog('No matching subtree for root group: ' + groupRec.marketGroupName);
    end;
  DebugLog('Total root recipe nodes (full build): ' + Roots.Count.ToString);
end;


class procedure TMarketTreeAsyncBuilder.BuildFullMarketTreeAsync(
  TreeView: TTreeView;
  const GroupMap: TDictionary<string, TMarketGroupRec>;
  const ChildMap: TDictionary<string, TList<string>>;
  const TypesDict: TDictionary<Integer, TTypesRec>);
begin
  TTask.Run(procedure
  var
    TypesByGroup: TDictionary<string, TList<TTypesRec>>;
    Roots: TObjectList<TMarketTreeNodeRecipe>;
    SW: TStopwatch;
  begin
    SW := TStopwatch.StartNew;
    TypesByGroup := BuildTypesByGroup(TypesDict);
    Roots := TObjectList<TMarketTreeNodeRecipe>.Create;
    try
      BuildMarketTreeRecipe(GroupMap, ChildMap, TypesByGroup, Roots);
      for var List in TypesByGroup.Values do List.Free;
      TypesByGroup.Free;

      TThread.Queue(nil, procedure
      var
        SWUI: TStopwatch;
      begin
        SWUI := TStopwatch.StartNew;
        PopulateTreeViewFromRecipe(TreeView, Roots);
        Roots.Free;
      end);
    except
      Roots.Free;
      for var List in TypesByGroup.Values do List.Free;
      TypesByGroup.Free;
      raise;
    end;
  end);
end;

class procedure TMarketTreeAsyncBuilder.BuildFilteredMarketTreeAsync(
  TreeView: TTreeView;
  const GroupMap: TDictionary<string, TMarketGroupRec>;
  const ChildMap: TDictionary<string, TList<string>>;
  const FilteredGroupIDs: THashSet<string>;
  const FilteredItems: TDictionary<Integer, TTypesRec>);
begin
  TTask.Run(procedure
  var
    TypesByGroup: TDictionary<string, TList<TTypesRec>>;
    Roots: TObjectList<TMarketTreeNodeRecipe>;
    SW: TStopwatch;
  begin
    SW := TStopwatch.StartNew;
    TypesByGroup := BuildTypesByGroup(FilteredItems);
    Roots := TObjectList<TMarketTreeNodeRecipe>.Create;
    try
      BuildFilteredMarketTreeRecipe(GroupMap, ChildMap, TypesByGroup, FilteredGroupIDs, FilteredItems, Roots);
      DebugLog('[MarketTreeAsyncBuilder] BuildFilteredMarketTreeRecipe in BG took ' + SW.ElapsedMilliseconds.ToString + ' ms');
      for var List in TypesByGroup.Values do List.Free;
      TypesByGroup.Free;

      TThread.Queue(nil, procedure
      var
        SWUI: TStopwatch;
      begin
        SWUI := TStopwatch.StartNew;
        PopulateTreeViewFromRecipe(TreeView, Roots);
        DebugLog('[MarketTreeAsyncBuilder] PopulateTreeViewFromRecipe (filtered) took ' + SWUI.ElapsedMilliseconds.ToString + ' ms, ' +
          'total recipe nodes: ' + Roots.Count.ToString);
        Roots.Free;
      end);
    except
      Roots.Free;
      FilteredGroupIDs.Free;
      FilteredItems.Free;
      for var List in TypesByGroup.Values do List.Free;
      TypesByGroup.Free;
      raise;
    end;
  end);
end;

end.

