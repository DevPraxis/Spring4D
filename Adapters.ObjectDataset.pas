unit Adapters.ObjectDataset;

interface

uses
  Adapters.ObjectDataset.Abstract
  ,Adapters.ObjectDataset.ExprParser
  ,Core.Algorythms.Sort
  ,Classes
  ,Spring.Collections
  ,Rtti
  ,DB
  ,TypInfo
  ;

type
  TObjectDataset = class(TAbstractObjectDataset)
  private
    FDataList: IList;
    FDefaultStringFieldLength: Integer;
    FFilterIndex: Integer;
    FFilterParser: TExprParser;
    FItemTypeInfo: PTypeInfo;
    FIndexFieldList: IList<TIndexFieldInfo>;
    FProperties: IList<TRttiProperty>;
    FSort: string;
    FSorted: Boolean;
    FCtx: TRttiContext;

    FOnAfterFilter: TNotifyEvent;
    FOnAfterSort: TNotifyEvent;
    FOnBeforeFilter: TNotifyEvent;
    FOnBeforeSort: TNotifyEvent;

    function GetSort: string;
    procedure SetSort(const Value: string);
    function GetFilterCount: Integer;
  protected
    procedure DoAfterOpen; override;
    procedure DoDeleteRecord(Index: Integer); override;
    procedure DoGetFieldValue(Field: TField; Index: Integer; var Value: Variant); override;
    procedure DoPostRecord(Index: Integer; Append: Boolean); override;
    procedure RebuildPropertiesCache(); override;

    function DataListCount(): Integer; override;
    function GetCurrentDataList(): IList; override;
    function GetRecordCount: Integer; override;
    function RecordConformsFilter: Boolean; override;
    procedure UpdateFilter(); override;

    procedure DoOnAfterFilter(); virtual;
    procedure DoOnBeforeFilter(); virtual;
    procedure DoOnBeforeSort(); virtual;
    procedure DoOnAfterSort(); virtual;

    function CompareRecords(const Item1, Item2: TValue; AIndexFieldList: IList<TIndexFieldInfo>): Integer; virtual;
    function ConvertPropertyValueToVariant(const AValue: TValue): Variant; virtual;
    function InternalGetFieldValue(AField: TField; const AItem: TValue): Variant; virtual;
    function ParserGetVariableValue(Sender: TObject; const VarName: string; var Value: Variant): Boolean; virtual;
    function ParserGetFunctionValue(Sender: TObject; const FuncName: string; const Args: Variant
      ; var ResVal: Variant): Boolean; virtual;
    procedure DoFilterRecord(AIndex: Integer); virtual;
    procedure InitRttiPropertiesFromItemType(AItemTypeInfo: PTypeInfo); virtual;
    procedure InternalSetSort(const AValue: string); virtual;
    procedure LoadFieldDefsFromFields(Fields: TFields; FieldDefs: TFieldDefs); virtual;
    procedure LoadFieldDefsFromItemType; virtual;
    procedure RefreshFilter(); virtual;

    function  IsCursorOpen: Boolean; override;
    procedure InternalInitFieldDefs; override;
    procedure InternalOpen; override;
    procedure SetFilterText(const Value: string); override;

    function GetChangedSortText(const ASortText: string): string;
    function CreateIndexList(const ASortText: string): IList<TIndexFieldInfo>;
    function FieldInSortIndex(AField: TField): Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Clone(ASource: TObjectDataset);

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Returns underlying model object from the current row.
    ///	</summary>
    {$ENDREGION}
    function GetCurrentModel<T: class>(): T;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Returns newly created list of data containing only filtered items.
    ///	</summary>
    {$ENDREGION}
    function GetFilteredDataList<T: class>(): IList<T>;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Sets the list which will represent the data for the dataset. Dataset
    ///	  will create it's fields based on model's public or published 
    ///	  properties which are marked with <c>[Column]</c> attribute.
    ///	</summary>
    {$ENDREGION}
    procedure SetDataList<T: class>(ADataList: IList<T>);

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Returns the total count of filtered records.
    ///	</summary>
    {$ENDREGION}
    property FilterCount: Integer read GetFilterCount;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Checks if dataset is sorted.
    ///	</summary>
    {$ENDREGION}
    property Sorted: Boolean read FSorted;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Sorting conditions separated by commas. Can set  different sort order
    ///	  for multiple fields - <c>Asc</c> stands for ascending, <c>Desc</c> -
    ///	  descending.
    ///	</summary>
    ///	<example>
    ///	  <code>
    ///	MyDataset.Sort := 'Name, Id Desc, Description Asc';</code>
    ///	</example>
    {$ENDREGION}
    property Sort: string read GetSort write SetSort;

    property DataList: IList read FDataList;
  published
    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Default length for the string type field in the dataset.
    ///	</summary>
    ///	<remarks>
    ///	  Defaults to <c>250</c> if not set.
    ///	</remarks>
    {$ENDREGION}
    property DefaultStringFieldLength: Integer read FDefaultStringFieldLength write FDefaultStringFieldLength default 250;
    property Filter;
    property Filtered;
    property FilterOptions;


    property AfterCancel;
    property AfterClose;
    property AfterDelete;
    property AfterEdit;
    property AfterInsert;
    property AfterOpen;
    property AfterPost;
    property AfterRefresh;
    property AfterScroll;
    property BeforeCancel;
    property BeforeClose;
    property BeforeDelete;
    property BeforeEdit;
    property BeforeInsert;
    property BeforeOpen;
    property BeforePost;
    property BeforeRefresh;
    property BeforeScroll;

    property OnAfterFilter: TNotifyEvent read FOnAfterFilter write FOnAfterFilter;
    property OnBeforeFilter: TNotifyEvent read FOnBeforeFilter write FOnBeforeFilter;
    property OnAfterSort: TNotifyEvent read FOnAfterSort write FOnAfterSort;
    property OnBeforeSort: TNotifyEvent read FOnBeforeSort write FOnBeforeSort;
    property OnDeleteError;
    property OnEditError;
    property OnFilterRecord;
    property OnNewRecord;
    property OnPostError;
  end;

implementation

uses
  Core.Utils
  ,Mapping.RttiExplorer
  ,Mapping.Attributes
  ,SysUtils
  ,StrUtils
  ,Variants
  ,Core.Reflection
  ,Spring.SystemUtils
  ,DateUtils
  ,Adapters.ObjectDataset.ExprParser.Functions
  ;

type
  EObjectDatasetException = class(Exception);
  
  {$WARNINGS OFF}
  TWideCharSet = set of Char;
  {$WARNINGS ON}

function SplitString(const AText: string; const ADelimiters: TWideCharSet;
  const ARemoveEmptyEntries: Boolean): TArray<string>;
var
  LResCount, I, LLag,
    LPrevIndex, LCurrPiece: NativeInt;
  LPiece: string;
begin
  { Initialize, set all to zero }
  SetLength(Result , 0);

  { Do nothing for empty strings }
  if System.Length(AText) = 0 then
    Exit;

  { Determine the length of the resulting array }
  LResCount := 0;

  for I := 1 to System.Length(AText) do
    if CharInSet(AText[I], ADelimiters) then
      Inc(LResCount);

  { Set the length of the output split array }
  SetLength(Result, LResCount + 1);

  { Split the string and fill the resulting array }
  LPrevIndex := 1;
  LCurrPiece := 0;
  LLag := 0;

  for I := 1 to System.Length(AText) do
    if CharInSet(AText[I], ADelimiters) then
    begin
      LPiece := System.Copy(AText, LPrevIndex, (I - LPrevIndex));

      if ARemoveEmptyEntries and (System.Length(LPiece) = 0) then
        Inc(LLag)
      else
        Result[LCurrPiece - LLag] := LPiece;

      { Adjust prev index and current piece }
      LPrevIndex := I + 1;
      Inc(LCurrPiece);
    end;

  { Copy the remaining piece of the string }
  LPiece := Copy(AText, LPrevIndex, System.Length(AText) - LPrevIndex + 1);

  { Doom! }
  if ARemoveEmptyEntries and (System.Length(LPiece) = 0) then
    Inc(LLag)
  else
    Result[LCurrPiece - LLag] := LPiece;

  { Re-adjust the array for the missing pieces }
  if LLag > 0 then
    System.SetLength(Result, LResCount - LLag + 1);
end;

{ TObjectDataset }

procedure TObjectDataset.Clone(ASource: TObjectDataset);
begin
  if Active then
    Close;

  FItemTypeInfo := ASource.FItemTypeInfo;
  FDataList := ASource.DataList;
  IndexList.DataList := ASource.IndexList.DataList;
  IndexList.Rebuild;

  FilterOptions := ASource.FilterOptions;
  Filter := ASource.Filter;
  Filtered := ASource.Filtered;
  Open;
  if ASource.Sorted then
    Sort := ASource.Sort;
end;

function TObjectDataset.CompareRecords(const Item1, Item2: TValue;
  AIndexFieldList: IList<TIndexFieldInfo>): Integer;
var
  i: Integer;
  LFieldInfo: TIndexFieldInfo;
  LValue1, LValue2: TValue;
begin
  Result := 0;

  for i := 0 to AIndexFieldList.Count - 1 do
  begin
    LFieldInfo := AIndexFieldList[i];
    LValue1 := LFieldInfo.RttiProperty.GetValue(TRttiExplorer.GetRawPointer(Item1));
    LValue2 := LFieldInfo.RttiProperty.GetValue(TRttiExplorer.GetRawPointer(Item2));

    Result := CompareValue(LValue1, LValue2);
    if LFieldInfo.Descending then
      Result := -Result;

    if Result <> 0 then
      Exit;
  end;
end;

function TObjectDataset.ConvertPropertyValueToVariant(const AValue: TValue): Variant;
begin
  Result := TUtils.AsVariant(AValue);
end;

constructor TObjectDataset.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FProperties := TCollections.CreateList<TRttiProperty>;
  FFilterParser := TExprParser.Create;
  FFilterParser.OnGetVariable := ParserGetVariableValue;
  FFilterParser.OnExecuteFunction := ParserGetFunctionValue;
  FDefaultStringFieldLength := 250;
  FCtx := TRttiContext.Create;
end;

function TObjectDataset.CreateIndexList(const ASortText: string): IList<TIndexFieldInfo>;
var
  LText, LItem: string;
  LSplittedFields: TArray<string>;
  LIndexFieldItem: TIndexFieldInfo;
  iPos: Integer;
begin
  Result := TCollections.CreateList<TIndexFieldInfo>;
  LSplittedFields := SplitString(ASortText, [','], True);
  for LText in LSplittedFields do
  begin
    LItem := UpperCase(LText);
    LIndexFieldItem.Descending := PosEx('DESC', LItem) > 1;
    LItem := Trim(LText);
    iPos := PosEx(' ', LItem);
    if iPos > 1 then
      LItem := Copy(LItem, 1, iPos - 1);           
    
    LIndexFieldItem.Field := FindField(LItem);
    LIndexFieldItem.RttiProperty := FProperties[LIndexFieldItem.Field.Index];
    LIndexFieldItem.CaseInsensitive := True;
    Result.Add(LIndexFieldItem);
  end;
end;

function TObjectDataset.DataListCount: Integer;
begin
  Result := 0;
  if Assigned(FDataList) then
    Result := FDataList.Count;
end;

destructor TObjectDataset.Destroy;
begin
  FFilterParser.Free;
  inherited Destroy;
end;

procedure TObjectDataset.DoAfterOpen;
begin
  if Filtered then
  begin
    UpdateFilter;
    First;
  end;
  inherited DoAfterOpen;
end;

procedure TObjectDataset.DoDeleteRecord(Index: Integer);
begin
  IndexList.DeleteModel(Index);
end;

procedure TObjectDataset.DoGetFieldValue(Field: TField; Index: Integer; var Value: Variant);
var
  LItem: TValue;
begin
  LItem := IndexList.GetModel(Index);
  Value := InternalGetFieldValue(Field, LItem);
end;

procedure TObjectDataset.DoOnAfterFilter;
begin
  if Assigned(FOnAfterFilter) then
    FOnAfterFilter(Self);
end;

procedure TObjectDataset.DoOnAfterSort;
begin
  if Assigned(FOnAfterSort) then
    FOnAfterSort(Self);
end;

procedure TObjectDataset.DoOnBeforeFilter;
begin
  if Assigned(FOnBeforeFilter) then
    FOnBeforeFilter(Self);
end;

procedure TObjectDataset.DoOnBeforeSort;
begin
  if Assigned(FOnBeforeSort) then
    FOnBeforeSort(Self);
end;

procedure TObjectDataset.DoPostRecord(Index: Integer; Append: Boolean);
var
  LItem: TValue;
  LConvertedValue: TValue;
  LValueFromVariant: TValue;
  LFieldValue: Variant;
  i: Integer;
  LProp: TRttiProperty;
  LField: TField;
  LNeedsSort: Boolean;
begin
  if State = dsInsert then
    LItem := TRttiExplorer.CreateType(FItemTypeInfo)
  else
    LItem := IndexList.GetModel(Index);

  LNeedsSort := False;

  for i := 0 to ModifiedFields.Count - 1 do
  begin
    LField := ModifiedFields[i];

    if not LNeedsSort and Sorted then
    begin
      LNeedsSort := FieldInSortIndex(LField);
    end;

    LProp := FProperties[LField.FieldNo - 1];
    LFieldValue := LField.Value;
    if VarIsNull(LFieldValue) then
    begin
      LProp.SetValue(TRttiExplorer.GetRawPointer(LItem), TValue.Empty);
    end
    else
    begin
      LValueFromVariant := TUtils.FromVariant(LFieldValue);

      if TUtils.TryConvert(LValueFromVariant, nil, LProp, LItem.AsObject, LConvertedValue) then
     // if TValueConverter.Default.TryConvertTo(LValueFromVariant, LProp.PropertyType.Handle, LConvertedValue, TValue.Empty) then
        LProp.SetValue(TRttiExplorer.GetRawPointer(LItem), LConvertedValue);
    end;
  end;

  if State = dsInsert then
  begin
    if Append then
      Index := IndexList.AddModel(LItem)
    else
      IndexList.InsertModel(LItem, Index);
  end;

  DoFilterRecord(Index);
  if Sorted and LNeedsSort then
    InternalSetSort(Sort);

  SetCurrent(Index);
end;

function TObjectDataset.FieldInSortIndex(AField: TField): Boolean;
var
  i: Integer;
begin
  if Sorted and Assigned(FIndexFieldList) then
  begin
    for i := 0 to FIndexFieldList.Count - 1 do
    begin
      if (AField = FIndexFieldList[i].Field) then
      begin
        Exit(True);
      end;
    end;
  end;
  Result := False;
end;

function TObjectDataset.GetChangedSortText(const ASortText: string): string;
begin
  Result := ASortText;

  if EndsStr(' ', Result) then
    Result := Copy(Result, 1, Length(Result) - 1)
  else
    Result := Result + ' ';
end;

function TObjectDataset.GetCurrentDataList: IList;
begin
  Result := DataList;
end;

function TObjectDataset.GetCurrentModel<T>: T;
begin
  Result := System.Default(T);
  if Active and (Index > -1) and (Index < RecordCount) then
  begin
    Result := IndexList.GetModel(Index).AsType<T>;
  end;
end;

function TObjectDataset.GetFilterCount: Integer;
begin
  Result := 0;
  if Filtered then
    Result := IndexList.Count;
end;

function TObjectDataset.GetFilteredDataList<T>: IList<T>;
var
  LList: IList;
  i: Integer;
begin
  Result := TCollections.CreateObjectList<T>(False);
  LList := Result.AsList;
  for i := 0 to IndexList.Count - 1 do
  begin
    LList.Add(IndexList.GetModel(i));
  end;
end;

function TObjectDataset.GetRecordCount: Integer;
begin
  Result := IndexList.Count;
end;

function TObjectDataset.GetSort: string;
begin
  Result := FSort;
end;

procedure TObjectDataset.InitRttiPropertiesFromItemType(AItemTypeInfo: PTypeInfo);
var
  LType: TRttiType;
  LProp: TRttiProperty;
  LAttrib: TCustomAttribute;
begin
  FProperties.Clear;

  LType := FCtx.GetType(AItemTypeInfo);
  for LProp in LType.GetProperties do
  begin
    if not (LProp.Visibility in [mvPublic, mvPublished]) then
      Continue;

    for LAttrib in LProp.GetAttributes do
    begin
      if (LAttrib is GetColumnAttributeClass) or (LAttrib is ColumnAttribute) then
      begin
        FProperties.Add(LProp);
        Break;
      end;
    end;
  end;
end;

function TObjectDataset.InternalGetFieldValue(AField: TField; const AItem: TValue): Variant;
var
  LProperty: TRttiProperty;
begin
  if FProperties.IsEmpty then
    InitRttiPropertiesFromItemType(AItem.TypeInfo);

  LProperty := FProperties[AField.FieldNo - 1];
  Result := ConvertPropertyValueToVariant(LProperty.GetValue(TRttiExplorer.GetRawPointer(AItem)));
end;

procedure TObjectDataset.InternalInitFieldDefs;
begin
  FieldDefs.Clear;
  if Fields.Count > 0 then
  begin
    LoadFieldDefsFromFields(Fields, FieldDefs);
  end
  else
  begin
    LoadFieldDefsFromItemType;
  end;
end;

procedure TObjectDataset.InternalOpen;
begin
  inherited InternalOpen;

  if DefaultFields then
    CreateFields;

  Reserved := Pointer(FieldListCheckSum);
  BindFields(True);
  SetRecBufSize();
end;

procedure TObjectDataset.InternalSetSort(const AValue: string);
var
  Pos: Integer;
  LDataList: IList;
  LOldValue: Boolean;
  LOwnsObjectsProp: TRttiProperty;
  LChanged: Boolean;
begin
  if IsEmpty then
    Exit;

  DoOnBeforeSort();

  LChanged := AValue <> FSort;
  FIndexFieldList := CreateIndexList(AValue);

  Pos := Current;
  LDataList := FDataList;
  LOldValue := True;
  LOwnsObjectsProp := FCtx.GetType(LDataList.AsObject.ClassType).GetProperty('OwnsObjects');
  try
    if Assigned(LOwnsObjectsProp) then
    begin
      LOldValue := LOwnsObjectsProp.GetValue(LDataList.AsObject).AsBoolean;
      LOwnsObjectsProp.SetValue(LDataList.AsObject, False);
    end;
    if LChanged then
      TMergeSort.Sort(IndexList, CompareRecords, FIndexFieldList)
    else
      TInsertionSort.Sort(IndexList, CompareRecords, FIndexFieldList);

    FSorted := FIndexFieldList.Count > 0;
    FSort := AValue;

  finally
    if Assigned(LOwnsObjectsProp) then
      LOwnsObjectsProp.SetValue(LDataList.AsObject, LOldValue);
    SetCurrent(Pos);
  end;
  DoOnAfterSort();
end;

function TObjectDataset.IsCursorOpen: Boolean;
begin
  Result := Assigned(FDataList);
end;

procedure TObjectDataset.LoadFieldDefsFromFields(Fields: TFields; FieldDefs: TFieldDefs);
var
  i: integer;
  LField: TField;
  LFieldDef: TFieldDef;
begin
  for I := 0 to Fields.Count - 1 do
  begin
    LField := Fields[I];
    if FieldDefs.IndexOf(LField.FieldName) = -1 then
    begin
      LFieldDef := FieldDefs.AddFieldDef;
      LFieldDef.Name := LField.FieldName;
      LFieldDef.DataType := LField.DataType;
      LFieldDef.Size := LField.Size;
      if LField.Required then
        LFieldDef.Attributes := [DB.faRequired];
      if LField.ReadOnly then
        LFieldDef.Attributes := LFieldDef.Attributes + [DB.faReadonly];
      if (LField.DataType = ftBCD) and (LField is TBCDField) then
        LFieldDef.Precision := TBCDField(LField).Precision;
      if LField is TObjectField then
        LoadFieldDefsFromFields(TObjectField(LField).Fields, LFieldDef.ChildDefs);
    end;
  end;
end;

procedure TObjectDataset.LoadFieldDefsFromItemType;
var
  i: Integer;
  LProp: TRttiProperty;
  LAttrib: TCustomAttribute;
  LPropPrettyName: string;
  LFieldType: TFieldType;
  LFieldDef: TObjectDatasetFieldDef;
  LLength, LPrecision, LScale: Integer;
  LRequired, LDontUpdate, LHidden: Boolean;

  procedure DoGetFieldType(ATypeInfo: PTypeInfo);
  var
    LTypeInfo: PTypeInfo;
  begin
    case ATypeInfo.Kind of
      tkInteger:
      begin
        LLength := -2;
        if (ATypeInfo = TypeInfo(Word)) then
        begin
          LFieldType := ftWord;
        end
        else if (ATypeInfo = TypeInfo(SmallInt)) then
        begin
          LFieldType := ftSmallint;
        end
        else
        begin
          LFieldType := ftInteger;
        end;
      end;
      tkEnumeration:
      begin
        if (ATypeInfo = TypeInfo(Boolean)) then
        begin
          LFieldType := ftBoolean;
          LLength := -2;
        end
        else
        begin
          LFieldType := ftWideString;
          if LLength = -2 then
            LLength := FDefaultStringFieldLength;
        end;
      end;
      tkFloat:
      begin
        if (ATypeInfo = TypeInfo(TDate)) then
        begin
          LFieldType := ftDate;
          LLength := -2;
        end
        else if (ATypeInfo = TypeInfo(TDateTime)) then
        begin
          LFieldType := ftDateTime;
          LLength := -2;
        end
        else if (ATypeInfo = TypeInfo(Currency)) then
        begin
          LFieldType := ftCurrency;
          LLength := -2;
        end
        else if (ATypeInfo = TypeInfo(TTime)) then
        begin
          LFieldType := ftTime;
          LLength := -2;
        end
        else if (LPrecision <> -2) or (LScale <> -2) then
        begin
          LFieldType := ftBCD;
          LLength := -2;
        end
        else
        begin
          LFieldType := ftFloat;
          LLength := -2;
        end;
      end;
      tkString, tkLString, tkChar:
      begin
        LFieldType := ftString;
        if LLength = -2 then
          LLength := FDefaultStringFieldLength;
      end;
      tkVariant, tkArray, tkDynArray:
      begin
        LFieldType := ftVariant;
        LLength := -2;
      end;
      tkClass:
      begin
        if TypeInfo(TStringStream) = ATypeInfo then
          LFieldType := ftMemo
        else
          LFieldType := ftBlob;
        LLength := -2;
        LDontUpdate := True;
      end;
      tkRecord:
      begin
        if TryGetUnderlyingTypeInfo(ATypeInfo, LTypeInfo) then
        begin
          DoGetFieldType(LTypeInfo);
        end;
      end;
      tkInt64:
      begin
        LFieldType := ftLargeint;
        LLength := -2;
      end;
      tkUString, tkWString, tkWChar, tkSet:
      begin
        LFieldType := ftWideString;
        if LLength = -2 then
          LLength := FDefaultStringFieldLength;
      end;
    end;
  end;

begin
  InitRttiPropertiesFromItemType(FItemTypeInfo);

  if FProperties.IsEmpty then
    raise EObjectDatasetException.Create(SColumnPropertiesNotSpecified);

  for i := 0 to FProperties.Count - 1 do
  begin
    LProp := FProperties[i];
    LPropPrettyName := LProp.Name;
    LLength := -2;
    LPrecision := -2;
    LScale := -2;
    LRequired := False;
    LDontUpdate := False;
    LHidden := False;

    for LAttrib in LProp.GetAttributes do
    begin
      if LAttrib is ColumnAttribute then
      begin
        if (ColumnAttribute(LAttrib).Name <> '') then
          LPropPrettyName := ColumnAttribute(LAttrib).Name;

        if (ColumnAttribute(LAttrib).Length <> 0) then
          LLength := ColumnAttribute(LAttrib).Length;

        if (ColumnAttribute(LAttrib).Precision <> 0) then
          LPrecision := ColumnAttribute(LAttrib).Precision;

        if (ColumnAttribute(LAttrib).Scale <> 0) then
          LScale := ColumnAttribute(LAttrib).Scale;

        if (ColumnAttribute(LAttrib).Description <> '') then
          LPropPrettyName := ColumnAttribute(LAttrib).Description;

        LRequired := ( cpRequired in ColumnAttribute(LAttrib).Properties );
        LDontUpdate := ( cpDontInsert in ColumnAttribute(LAttrib).Properties )
          or ( cpDontUpdate in ColumnAttribute(LAttrib).Properties );

        LHidden :=  ( cpHidden in ColumnAttribute(LAttrib).Properties );

        Break;
      end;
    end;

    LFieldType := ftWideString;

    DoGetFieldType(LProp.PropertyType.Handle);

    LFieldDef := FieldDefs.AddFieldDef as TObjectDatasetFieldDef;
    LFieldDef.Name := LProp.Name;
    LFieldDef.SetRealDisplayName(LPropPrettyName);

    LFieldDef.DataType := LFieldType;
    if LLength <> -2 then
      LFieldDef.Size := LLength;

    LFieldDef.Required := LRequired;

    if LFieldType in [ftFMTBcd, ftBCD] then
    begin
      if LPrecision <> -2 then
        LFieldDef.Precision := LPrecision;

      if LScale <> -2 then
        LFieldDef.Size := LScale;
    end;

    if LDontUpdate then
      LFieldDef.Attributes := LFieldDef.Attributes + [DB.faReadOnly];

    LFieldDef.Visible := not LHidden;

    if not LProp.IsWritable then
      LFieldDef.Attributes := LFieldDef.Attributes + [DB.faReadOnly];
  end;
end;

function TObjectDataset.ParserGetFunctionValue(Sender: TObject; const FuncName: string;
  const Args: Variant; var ResVal: Variant): Boolean;
var
  LGetValueFunc: TFunctionGetValueProc;
begin
  Result := TFilterFunctions.TryGetFunction(FuncName, LGetValueFunc);
  if Result then
  begin
    ResVal := LGetValueFunc(Args);
  end;
end;

function TObjectDataset.ParserGetVariableValue(Sender: TObject; const VarName: string;
  var Value: Variant): Boolean;
var
  LField: TField;
begin
  Result := False;

  if not FilterCache.TryGetValue(VarName, Value) then
  begin
    LField := FindField(Varname);
    if Assigned(LField) then
    begin
      Value := InternalGetFieldValue(LField, FDataList[FFilterIndex]);
      FilterCache.Add(VarName, Value);
      Result := True;
    end;
  end
  else
  begin
    Result := True;
  end;
end;

procedure TObjectDataset.RebuildPropertiesCache;
var
  LType: TRttiType;
  i: Integer;
begin
  FProperties.Clear;
  LType := FCtx.GetType(FItemTypeInfo);
  for i := 0 to Fields.Count - 1 do
  begin
    FProperties.Add( LType.GetProperty(Fields[i].FieldName) );
  end;
end;

function TObjectDataset.RecordConformsFilter: Boolean;
begin
  Result := True;
  if (FFilterIndex >= 0) and (FFilterIndex <  DataListCount ) then
  begin
    if Assigned(OnFilterRecord) then
      OnFilterRecord(Self, Result)
    else
    begin
      if (FFilterParser.Eval()) then
      begin
        Result := FFilterParser.Value;
      end;
    end;
  end
  else
    Result := False;
end;

procedure TObjectDataset.RefreshFilter;
var
  i: Integer;
begin
  IndexList.Clear;
  if not IsFilterEntered then
  begin
    IndexList.Rebuild;
    Exit;
  end;

  for i := 0 to FDataList.Count - 1 do
  begin
    FFilterIndex := i;
    FilterCache.Clear;
    if RecordConformsFilter then
    begin
      IndexList.Add(i, FDataList[i]);
    end;
  end;
  FilterCache.Clear;
end;

procedure TObjectDataset.DoFilterRecord(AIndex: Integer);
begin
  if (IsFilterEntered) and (AIndex > -1) and (AIndex < RecordCount) then
  begin
    FilterCache.Clear;
    FFilterIndex := IndexList[AIndex].DataListIndex;
    if not RecordConformsFilter then
    begin
      IndexList.Delete(AIndex);
    end;
  end;
end;

procedure TObjectDataset.SetDataList<T>(ADataList: IList<T>);
begin
  FItemTypeInfo := TypeInfo(T);
  FDataList := ADataList.AsList;
  IndexList.DataList := FDataList;
  IndexList.Rebuild;
end;


procedure TObjectDataset.SetFilterText(const Value: string);
begin
  if (Value = Filter) then
    Exit;

  if Active then
  begin
    CheckBrowseMode;
    inherited SetFilterText(Value);

    if Filtered then
    begin
      UpdateFilter;
      First;
    end
    else
    begin
      UpdateFilter();
      Resync([]);
      First;
    end;
  end
  else
  begin
    inherited SetFilterText(Value);
  end;
end;

procedure TObjectDataset.SetSort(const Value: string);
begin
  CheckActive;
  if State in dsEditModes then
    Post;

  UpdateCursorPos;
  InternalSetSort(Value);
  Resync([]);
end;

procedure TObjectDataset.UpdateFilter;
var
  LSaveState: TDataSetState;
begin
  if not Active then
    Exit;

  DoOnBeforeFilter;

  if IsFilterEntered then
  begin
    FFilterParser.EnableWildcardMatching := not (foNoPartialCompare in FilterOptions);
    FFilterParser.CaseInsensitive := foCaseInsensitive in FilterOptions;

    if foCaseInsensitive in FilterOptions then
      FFilterParser.Expression := AnsiUpperCase(Filter)
    else
      FFilterParser.Expression := Filter;
  end;

  LSaveState := SetTempState(dsFilter);
  try
    RefreshFilter();
  finally
    RestoreState(LSaveState);
  end;

  DisableControls;
  try
    First;
    if Sorted then
      InternalSetSort( GetChangedSortText(Sort) );   //must use mergesort so we change sort text
  finally
    EnableControls;
  end;
  UpdateCursorPos;
  Resync([]);
  First;

  DoOnAfterFilter;
end;

end.
