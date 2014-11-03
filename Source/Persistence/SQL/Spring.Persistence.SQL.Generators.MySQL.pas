﻿{***************************************************************************}
{                                                                           }
{           Spring Framework for Delphi                                     }
{                                                                           }
{           Copyright (c) 2009-2014 Spring4D Team                           }
{                                                                           }
{           http://www.spring4d.org                                         }
{                                                                           }
{***************************************************************************}
{                                                                           }
{  Licensed under the Apache License, Version 2.0 (the "License");          }
{  you may not use this file except in compliance with the License.         }
{  You may obtain a copy of the License at                                  }
{                                                                           }
{      http://www.apache.org/licenses/LICENSE-2.0                           }
{                                                                           }
{  Unless required by applicable law or agreed to in writing, software      }
{  distributed under the License is distributed on an "AS IS" BASIS,        }
{  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. }
{  See the License for the specific language governing permissions and      }
{  limitations under the License.                                           }
{                                                                           }
{***************************************************************************}

{$I Spring.inc}

unit Spring.Persistence.SQL.Generators.MySQL;

interface

uses
  Spring.Persistence.Mapping.Attributes,
  Spring.Persistence.SQL.Commands,
  Spring.Persistence.SQL.Generators.Ansi,
  Spring.Persistence.SQL.Interfaces,
  Spring.Persistence.SQL.Types;

type
  /// <summary>
  ///   Represents <b>MySQL</b> SQL generator.
  /// </summary>
  TMySQLGenerator = class(TAnsiSQLGenerator)
  public
    function GetQueryLanguage: TQueryLanguage; override;
    function GenerateCreateSequence(const command: TCreateSequenceCommand): string; override;
    function GenerateGetLastInsertId(const identityColumn: ColumnAttribute): string; override;
    function GenerateGetNextSequenceValue(const sequence: SequenceAttribute): string; override;
    function GetSQLDataTypeName(const field: TSQLCreateField): string; override;
    function GetEscapeFieldnameChar: Char; override;
  end;

implementation

uses
  StrUtils,
  Spring.Persistence.SQL.Register;


{$REGION 'TMySQLGenerator'}

function TMySQLGenerator.GenerateCreateSequence(
  const command: TCreateSequenceCommand): string;
begin
  Result := '';
end;

function TMySQLGenerator.GenerateGetLastInsertId(
  const identityColumn: ColumnAttribute): string;
begin
  Result := 'SELECT LAST_INSERT_ID();';
end;

function TMySQLGenerator.GenerateGetNextSequenceValue(
  const sequence: SequenceAttribute): string;
begin
  Result := '';
end;

// Pü 2014-06-01:
// MySQL has the backtick as FieldEscape unless MySQL is set to Ansi mode
function TMySQLGenerator.GetEscapeFieldnameChar: Char;
begin
  Result := '`';
end;

function TMySQLGenerator.GetQueryLanguage: TQueryLanguage;
begin
  Result := qlMySQL;
end;

function TMySQLGenerator.GetSQLDataTypeName(const field: TSQLCreateField): string;
begin
  Result := inherited GetSQLDataTypeName(field);
  if StartsText('NUMERIC', Result) then
    Result := 'DECIMAL' + Copy(Result, 8, Length(Result))
  else if StartsText('NCHAR', Result) then
    Result := Copy(Result, 2, Length(Result)) + ' CHARACTER SET ucs2'
  else if StartsText('NVARCHAR', Result) then
    Result := Copy(Result, 2, Length(Result)) + ' CHARACTER SET ucs2';
end;

{$ENDREGION}


initialization
  TSQLGeneratorRegister.RegisterGenerator(TMySQLGenerator.Create);

end.
