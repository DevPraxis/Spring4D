{***************************************************************************}
{                                                                           }
{           Spring Framework for Delphi                                     }
{                                                                           }
{           Copyright (C) 2009-2010 DevJet                                  }
{                                                                           }
{           http://www.DevJet.net                                           }
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

unit Spring.Logging.Appenders;

interface

uses
  Classes,
  SysUtils,
  Windows,
  Spring,
  Spring.Collections,
  Spring.Configuration,
  Spring.Logging.Core;

type
  TAppenderBase = class abstract(TInterfacedObject, IBulkAppender, IAppender,
    IConfigurable, ILoggerRepositoryInit)
  private
    fName: string;
    fThreshold: TLevel;
    fClosed: Boolean;
    fLayout: ILayout;
    fRepository: ILoggerRepository;
    function GetName: string;
    procedure SetName(const value: string);
    procedure SetLayout(const value: ILayout);
    procedure SetThreshold(const Value: TLevel);
  protected
    procedure Lock;
    procedure Unlock;
  protected
    procedure DoAppend(const event: TLoggingEvent); virtual;
    procedure DoClose; virtual;
    procedure DoConfigure(const configuration: IConfigurationNode); virtual;
    function AcceptEvent(const event: TLoggingEvent): Boolean; virtual;
    function CanAppend: Boolean; virtual;
    function RequireLayout: Boolean; virtual;
    function Format(const event: TLoggingEvent): string; virtual;
  protected
    { ILoggerRepositoryInit }
    procedure InitializeRepository(const repository: ILoggerRepository);
    { IConfigurable }
    procedure Configure(const configuration: IConfigurationNode);
  public
    constructor Create;
    destructor Destroy; override;
    { IBulkAppender }
    procedure Append(const events: IEnumerable<TLoggingEvent>); overload; virtual;
    { IAppender }
    procedure Close;
    procedure Append(const event: TLoggingEvent); overload;
    property Name: string read GetName write SetName;
    property Layout: ILayout read fLayout write SetLayout;
    property Threshold: TLevel read fThreshold write SetThreshold;
  end;

  TConsoleAppender = class(TAppenderBase)
  protected
    procedure DoAppend(const event: TLoggingEvent); override;
  end;

  TOutputDebugStringAppender = class(TAppenderBase)
  protected
    procedure DoAppend(const event: TLoggingEvent); override;
  end;

//  TFileAppender = class(TTextWriterAppender)
//
//  end;

implementation

uses Spring.Logging.Utils;


{$REGION 'TAppenderBase'}

constructor TAppenderBase.Create;
begin
  inherited Create;
  fThreshold := TLevel.All;
//  fErrorHandler := TOnlyOnceErrorHandler.Create(ClassName);
end;

destructor TAppenderBase.Destroy;
begin
  if not fClosed then
  begin
    TInternalLogger.Debug('TAppenderBase: Destroying appender named ['+fName+'].');
    Close;
  end;
  inherited Destroy;
end;

procedure TAppenderBase.Lock;
begin
  MonitorEnter(Self);
end;

procedure TAppenderBase.Unlock;
begin
  MonitorExit(Self);
end;

procedure TAppenderBase.Close;
begin
  Lock;
  try
    if not fClosed then
    begin
      DoClose;
      fClosed := True;
    end;
  finally
    Unlock;
  end;
end;

procedure TAppenderBase.Configure(const configuration: IConfigurationNode);
begin
  TArgument.CheckNotNull(configuration, 'configuration');
  Lock;
  try
    DoConfigure(configuration);
  finally
    Unlock;
  end;
end;

function TAppenderBase.AcceptEvent(const event: TLoggingEvent): Boolean;
begin
  Result := (event.LoggerLevel <> nil) and
    event.LoggerLevel.IsGreaterThanOrEqualTo(Threshold);
end;

procedure TAppenderBase.Append(const event: TLoggingEvent);
begin
  Lock;
  try
    try
      if CanAppend and AcceptEvent(event) then
        DoAppend(event);
    except on e: Exception do
      // TODO: Internal log
    end;
  finally
    Unlock;
  end;
end;

procedure TAppenderBase.Append(const events: IEnumerable<TLoggingEvent>);
var
  event: TLoggingEvent;
begin
  for event in events do
  begin
    Append(event);
  end;
end;

procedure TAppenderBase.DoAppend(const event: TLoggingEvent);
begin
end;

procedure TAppenderBase.DoClose;
begin
end;

procedure TAppenderBase.DoConfigure(const configuration: IConfigurationNode);
var
  node: IConfigurationNode;
  layoutType: string;
  level: TLevel;
begin
  fName := configuration.Attributes['name'];
  node := configuration.FindNode('threshold');
  if node <> nil then
  begin
    level := fRepository.FindLevel(node.Attributes['value']);
    SetThreshold(level);
  end;
  if RequireLayout then
  begin
    node := configuration.FindNode('layout');
    if node = nil then
    begin
      // TODO: Handle internal exception.
      Exit;
    end;
    layoutType := node.Attributes['type'];
    fLayout := fRepository.CreateLayout(layoutType);
    TryConfigure(fLayout, node);
  end;
end;

function TAppenderBase.Format(const event: TLoggingEvent): string;
begin
  Assert(Layout <> nil, 'Layout should not be nil.');
  Result:= Layout.Format(event);
end;

function TAppenderBase.CanAppend: Boolean;
begin
  Result := not RequireLayout or (Layout <> nil);
end;

function TAppenderBase.RequireLayout: Boolean;
begin
  Result := True;
end;

function TAppenderBase.GetName: string;
begin
  Result := fName;
end;

procedure TAppenderBase.InitializeRepository(
  const repository: ILoggerRepository);
begin
  fRepository := repository;
end;

procedure TAppenderBase.SetName(const value: string);
begin
  fName := name;
end;

procedure TAppenderBase.SetThreshold(const Value: TLevel);
begin
  if value <> nil then
  begin
    fThreshold := Value;
  end
  else
  begin
    fThreshold := TLevel.All;
    // TODO: Internal log
  end;
end;

procedure TAppenderBase.SetLayout(const value: ILayout);
begin
  if fLayout <> value then
    fLayout := value;
end;

{$ENDREGION}

{ TConsoleAppender }

procedure TConsoleAppender.DoAppend(const event: TLoggingEvent);
begin
  Write(Format(Event));
end;

{ TOutputDebugStringAppend }

procedure TOutputDebugStringAppender.DoAppend(const event: TLoggingEvent);
var
  outString: string;
begin
  outString := Format(event);
  Windows.OutputDebugString(PWidechar(outString));
end;

end.
