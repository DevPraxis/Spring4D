unit Mapping.CodeGenerator.Abstract;

interface

uses
  Spring.Collections
  ,Core.Types
  ,Spring
  ;

type
  TColumnData = class
  private
    FIsAutoGenerated: Boolean;
    FColumnName: string;
    FColumnLength: Nullable<Integer>;
    FColumnPrecision: Nullable<Integer>;
    FColumnScale: Nullable<Integer>;
    FColumnDescription: Nullable<string>;
    FIsRequired: Boolean;
    FIsUnique: Boolean;
    FDontInsert: Boolean;
    FDontUpdate: Boolean;
    FIsPrimaryKey: Boolean;
    FNotNull: Boolean;
    FIsHidden: Boolean;
    FColumnTypeName: string;
  public
    constructor Create(); virtual;

    property ColumnName: string read FColumnName write FColumnName;
    property ColumnLength: Nullable<Integer> read FColumnLength write FColumnLength;
    property ColumnPrecision: Nullable<Integer> read FColumnPrecision write FColumnPrecision;
    property ColumnScale: Nullable<Integer> read FColumnScale write FColumnScale;
    property ColumnDescription: Nullable<string> read FColumnDescription write FColumnDescription;
    property ColumnTypeName: string read FColumnTypeName write FColumnTypeName;


    property IsAutogenerated: Boolean read FIsAutoGenerated write FIsAutoGenerated;
    property IsRequired: Boolean read FIsRequired write FIsRequired;
    property IsUnique: Boolean read FIsUnique write FIsUnique;
    property IsPrimaryKey: Boolean read FIsPrimaryKey write FIsPrimaryKey;
    property DontInsert: Boolean read FDontInsert write FDontInsert;
    property DontUpdate: Boolean read FDontUpdate write FDontUpdate;
    property NotNull: Boolean read FNotNull write FNotNull;
    property IsHidden: Boolean read FIsHidden write FIsHidden;
  end;

  TEntityModelData = class
  private
    FTableName: string;
    FSchemaName: string;
    FColumns: IList<TColumnData>;
  public
    constructor Create(); virtual;
    destructor Destroy; override;

    function ToString(): string; override;

    property TableName: string read FTableName write FTableName;
    property SchemaName: string read FSchemaName write FSchemaName;


    property Columns: IList<TColumnData> read FColumns;
  end;

  TAbstractCodeGenerator = class(TInterfacedObject)
  protected
    function GetEntityTypePrefix(): string; virtual;
    function GetFielnamePrefix(): string; virtual;
    function GetIndent(): string; virtual;

    function DoGenerate(AEntityData: TEntityModelData): string; virtual; abstract;
  end;

implementation

uses
  SysUtils
  ;

{ TEntityData }

constructor TEntityModelData.Create;
begin
  inherited Create;
  FColumns := TCollections.CreateObjectList<TColumnData>(True);
end;

destructor TEntityModelData.Destroy;
begin
  inherited Destroy;
end;

function TEntityModelData.ToString: string;
var
  LSchema: string;
begin
  LSchema := SchemaName;

  if LSchema <> '' then
    LSchema := LSchema + '.';

  Result := Format('%0:S%1:S [%2:D]', [LSchema, TableName, Columns.Count]);
end;

{ TColumnData }

constructor TColumnData.Create;
begin
  inherited Create;
end;

{ TAbstractCodeGenerator }

function TAbstractCodeGenerator.GetEntityTypePrefix: string;
begin
  Result := 'T';
end;

function TAbstractCodeGenerator.GetFielnamePrefix: string;
begin
  Result := 'F';
end;

function TAbstractCodeGenerator.GetIndent: string;
begin
  Result := '  ';
end;

end.
