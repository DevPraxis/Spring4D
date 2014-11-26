unit Spring.Persistence.ObjectDataset.Blobs;

interface

uses
  Classes,
  DB,
  Spring.Persistence.ObjectDataset.Abstract;

type
  TODBlobStream = class(TMemoryStream)
  private
    FField: TBlobField;
    FDataSet: TAbstractObjectDataset;
    FBuffer: TRecordBuffer;
    FFieldNo: Integer;
    FModified: Boolean;
    FData: Variant;
    FFieldData: Variant;
  protected
    procedure ReadBlobData;
    function Realloc(var NewCapacity: Longint): Pointer; override;
  public
    constructor Create(Field: TBlobField; Mode: TBlobStreamMode);
    destructor Destroy; override;
    function Write(const Buffer; Count: Longint): Longint; override;
    procedure Truncate;
  end;

implementation

uses
  DBConsts,
  Variants;

{ TODBlobStream }

constructor TODBlobStream.Create(Field: TBlobField; Mode: TBlobStreamMode);
begin
  inherited Create;
  FField := Field;
  FFieldNo := FField.FieldNo - 1;
  FDataSet := FField.Dataset as TAbstractObjectDataset;
  FFieldData := Null;
  FData := Null;
  if not FDataSet.GetActiveRecBuf(FBuffer) then
    Exit;
  if Mode <> bmRead then
  begin
    if FField.ReadOnly then
      DatabaseErrorFmt(SFieldReadOnly, [FField.DisplayName], FDataSet);
    if not(FDataSet.State in [dsEdit, dsInsert]) then
      DatabaseError(SNotEditing, FDataSet);
  end;
  if Mode = bmWrite then
    Truncate
  else
    ReadBlobData;
end;

destructor TODBlobStream.Destroy;
begin
  if FModified then
  begin
    FDataSet.SetFieldData(FField, @FData);
    FField.Modified := True;
    FDataSet.DataEvent(deFieldChange, Longint(FField));
  end;
  inherited Destroy;
end;

procedure TODBlobStream.ReadBlobData;
begin
  {$IF CompilerVersion >= 24}
  FFieldData := FField.AsVariant;
  {$ELSE}
  FDataSet.GetFieldData(FField, @FFieldData, True);
  {$IFEND}
  if not VarIsNull(FFieldData) then
  begin
    if VarType(FFieldData) = varOleStr then
    begin
      if FField.BlobType = ftWideMemo then
        Size := Length(WideString(FFieldData)) * sizeof(widechar)
      else
      begin
        { Convert OleStr into a pascal string (format used by TBlobField) }
        FFieldData := AnsiString(FFieldData);
        Size := Length(FFieldData);
      end;
    end
    else
      Size := VarArrayHighBound(FFieldData, 1) + 1;
    FFieldData := Null;
  end;
end;

function TODBlobStream.Realloc(var NewCapacity: Integer): Pointer;
 procedure VarAlloc(var V: Variant; Field: TFieldType);
  var
    W: WideString;
    S: AnsiString;
  begin
    if Field = ftMemo then
    begin
      if not VarIsNull(V) then
        S := AnsiString(V);
      SetLength(S, NewCapacity);
      V := S;
    end
    else if Field = ftWideMemo then
    begin
      if not VarIsNull(V) then
        W := WideString(V);
      SetLength(W, NewCapacity div 2);
      V := W;
    end
    else
    begin
      if VarIsClear(V) or VarIsNull(V) then
        V := VarArrayCreate([0, NewCapacity - 1], varByte)
      else
        VarArrayRedim(V, NewCapacity - 1);
    end;
  end;

begin
  Result := Memory;
  if NewCapacity <> Capacity then
  begin
    if VarIsArray(FData) then
      VarArrayUnlock(FData);
    if NewCapacity = 0 then
    begin
      FData := Null;
      Result := nil;
    end
    else
    begin
      if VarIsNull(FFieldData) then
        VarAlloc(FData, FField.DataType)
      else
        FData := FFieldData;
      if VarIsArray(FData) then
        Result := VarArrayLock(FData)
      else
        Result := TVarData(FData).VString;
    end;
  end;
end;

procedure TODBlobStream.Truncate;
begin
  Clear;
  FModified := True;
end;

function TODBlobStream.Write(const Buffer; Count: Integer): Longint;
begin
  Result := inherited Write(Buffer, Count);
  FModified := True;
end;

end.
