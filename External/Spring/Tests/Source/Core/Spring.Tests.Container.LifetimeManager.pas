{***************************************************************************}
{                                                                           }
{           Spring Framework for Delphi                                     }
{                                                                           }
{           Copyright (c) 2009-2012 Spring4D Team                           }
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

unit Spring.Tests.Container.LifetimeManager;

interface

uses
  Classes,
  TestFramework,
  Rtti,
  SysUtils,
  TypInfo,
  Spring,
  Spring.Container.Core,
  Spring.Container.LifetimeManager;

type
  TMockContext = class(TInterfacedObject, IContainerContext)
  public
    function GetDependencyResolver: IDependencyResolver;
    function GetInjectionFactory: IInjectionFactory;
    function GetComponentRegistry: IComponentRegistry;
  public
    function HasService(serviceType: PTypeInfo): Boolean; overload;
    function HasService(const name: string): Boolean; overload;
    function CreateLifetimeManager(model: TComponentModel): ILifetimeManager;
    property ComponentRegistry: IComponentRegistry read GetComponentRegistry;
    property DependencyResolver: IDependencyResolver read GetDependencyResolver;
    property InjectionFactory: IInjectionFactory read GetInjectionFactory;
  end;

  TMockActivator = class(TInterfaceBase, IComponentActivator, IInterface)
  private
    fModel: TComponentModel;
  public
    constructor Create(model: TComponentModel);
    function CreateInstance: TObject; overload;
    function CreateInstance(resolver: IDependencyResolver): TObject; overload;
    property Model: TComponentModel read fModel;
  end;

  TMockObject = class
  end;

  TMockComponent = class(TComponent, IInterface)
  private
    fRefCount: Integer;
  protected
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  end;

//  [Ignore]
  TLifetimeManagerTestCase = class abstract(TTestCase)
  protected
    fContainerContext: IContainerContext;
    fContext: TRttiContext;
    fLifetimeManager: ILifetimeManager;
    fModel: TComponentModel;
    fActivator: TMockActivator;
    procedure SetUp; override;
    procedure TearDown; override;
  end;

  TTestSingletonLifetimeManager = class(TLifetimeManagerTestCase)
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestReferences;
  end;

  TTestRefCounting = class(TTestCase)
  protected
    fContainerContext: IContainerContext;
    fContext: TRttiContext;
    fLifetimeManager: ILifetimeManager;
    fModel: TComponentModel;
    fActivator: TMockActivator;
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestReferences;
  end;

  TTestTransientLifetimeManager = class(TLifetimeManagerTestCase)
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestReferences;
  end;

  TTestPerThreadLifetimeManager = class(TLifetimeManagerTestCase)

  end;

implementation

uses
  Spring.Services;

{ TLifetimeManagerTestCase }

procedure TLifetimeManagerTestCase.SetUp;
begin
  inherited;
  fContainerContext := TMockContext.Create;
  fContext := TRttiContext.Create;
  fModel := TComponentModel.Create(fContainerContext, fContext.GetType(TMockObject).AsInstance);
  fActivator := TMockActivator.Create(fModel);
  fModel.ComponentActivator := fActivator;
end;

procedure TLifetimeManagerTestCase.TearDown;
begin
  fActivator.Free;
  fModel.Free;
  fContext.Free;
  fContainerContext := nil;
  inherited;
end;

{ TTestSingletonLifetimeManager }

procedure TTestSingletonLifetimeManager.SetUp;
begin
  inherited;
  fLifetimeManager := TSingletonLifetimeManager.Create(fModel);
end;

procedure TTestSingletonLifetimeManager.TearDown;
begin
  fLifetimeManager := nil;
  inherited;
end;

procedure TTestSingletonLifetimeManager.TestReferences;
var
  obj1, obj2: TObject;
begin
  obj1 := fLifetimeManager.GetInstance;
  obj2 := fLifetimeManager.GetInstance;
  try
    CheckIs(obj1, TMockObject, 'obj1');
    CheckIs(obj2, TMockObject, 'obj2');
    CheckSame(obj1, obj2);
    CheckSame(fActivator.Model, fModel);
  finally
    fLifetimeManager.ReleaseInstance(obj1);
    fLifetimeManager.ReleaseInstance(obj2);
  end;
end;

{ TTestTransientLifetimeManager }

procedure TTestTransientLifetimeManager.SetUp;
begin
  inherited;
  fLifetimeManager := TTransientLifetimeManager.Create(fModel);
end;

procedure TTestTransientLifetimeManager.TearDown;
begin
  fLifetimeManager := nil;
  inherited;
end;

procedure TTestTransientLifetimeManager.TestReferences;
var
  obj1, obj2: TObject;
begin
  obj1 := fLifetimeManager.GetInstance;
  obj2 := fLifetimeManager.GetInstance;
  try
    CheckIs(obj1, TMockObject, 'obj1');
    CheckIs(obj2, TMockObject, 'obj2');
    CheckTrue(obj1 <> obj2);
    CheckSame(fActivator.Model, fModel);
  finally
    fLifetimeManager.ReleaseInstance(obj1);
    fLifetimeManager.ReleaseInstance(obj2);
  end;
end;

{ TMockComponentActivator }

constructor TMockActivator.Create(
  model: TComponentModel);
begin
  inherited Create;
  fModel := model;
end;

function TMockActivator.CreateInstance: TObject;
begin
  Result := fModel.ComponentType.MetaclassType.Create;
end;

function TMockActivator.CreateInstance(
  resolver: IDependencyResolver): TObject;
begin
  Result := CreateInstance;
end;

{ TMockContext }

function TMockContext.CreateLifetimeManager(
  model: TComponentModel): ILifetimeManager;
begin
  raise Exception.Create('CreateLifetimeManager');
end;

function TMockContext.GetComponentRegistry: IComponentRegistry;
begin
  raise Exception.Create('GetComponentRegistry');
end;

function TMockContext.GetDependencyResolver: IDependencyResolver;
begin
  raise Exception.Create('GetDependencyResolver');
end;

function TMockContext.GetInjectionFactory: IInjectionFactory;
begin
  raise Exception.Create('GetInjectionFactory');
end;

function TMockContext.HasService(const name: string): Boolean;
begin
  raise Exception.Create('HasService');
end;

function TMockContext.HasService(serviceType: PTypeInfo): Boolean;
begin
  raise Exception.Create('HasService');
end;

{ TMockComponent }

function TMockComponent._AddRef: Integer;
begin
  Inc(fRefCount);
  Result := fRefCount;
end;

function TMockComponent._Release: Integer;
begin
  Dec(fRefCount);
  Result := fRefCount;
  if Result = 0 then
    Destroy;
end;

{ TTestRefCounting }

procedure TTestRefCounting.SetUp;
begin
  inherited;
  fContainerContext := TMockContext.Create;
  fContext := TRttiContext.Create;
  fModel := TComponentModel.Create(fContainerContext, fContext.GetType(TMockComponent).AsInstance);
  fModel.RefCounting := TRefCounting.True;
  fActivator := TMockActivator.Create(fModel);
  fModel.ComponentActivator := fActivator;
end;

procedure TTestRefCounting.TearDown;
begin
  fActivator.Free;
  fModel.Free;
  fContext.Free;
  fContainerContext := nil;
  inherited;
end;

procedure TTestRefCounting.TestReferences;
var
  obj: TObject;
  intf: IInterface;
begin
  fLifetimeManager := TSingletonLifetimeManager.Create(fModel);
  obj := fLifetimeManager.GetInstance;
  CheckTrue(Supports(obj, IInterface, intf), 'interface not supported');
  intf := nil;
  fLifetimeManager := nil;
end;

end.
