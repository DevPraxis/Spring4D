{***************************************************************************}
{                                                                           }
{           Spring Framework for Delphi                                     }
{                                                                           }
{           Copyright (C) 2009-2011 DevJET                                  }
{                                                                           }
{           http://www.DevJET.net                                           }
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

/// <summary>
/// Defines the common interfaces for a service locator.
/// </summary>
unit Spring.Services;

{$I Spring.inc}

interface

uses
  TypInfo,
  Rtti,
  SysUtils,
  Spring;

type
  {$REGION 'Lifetime Type & Attributes'}

  ///	<summary>
  ///	  Lifetime Type Enumeration.
  ///	</summary>
  ///	<seealso cref="SingletonAttribute" />
  ///	<seealso cref="TransientAttribute" />
  ///	<seealso cref="SingletonPerThreadAttribute" />
  ///	<seealso cref="PooledAttribute" />
  TLifetimeType = (
    ///	<summary>
    ///	  Unknown lifetime type.
    ///	</summary>
    ltUnknown,

    ///	<summary>
    ///	  Single instance.
    ///	</summary>
    ltSingleton,

    ///	<summary>
    ///	  Different instances.
    ///	</summary>
    ltTransient,

    ///	<summary>
    ///	  Every thread has a single instance.
    ///	</summary>
    ltSingletonPerThread,

    ///	<summary>
    ///	  Instances are transient except that they are recyclable.
    ///	</summary>
    ltPooled,

    ///	<summary>
    ///	  Customized lifetime type.
    ///	</summary>
    ltCustom
  );

  ///	<summary>
  ///	  Represents an abstract lifetime attribute class base.
  ///	</summary>
  LifetimeAttributeBase = class abstract(TCustomAttribute)
  private
    fLifetimeType: TLifetimeType;
  public
    constructor Create(lifetimeType: TLifetimeType);
    property LifetimeType: TLifetimeType read fLifetimeType;
  end;

  ///	<summary>
  ///	  Applies this attribute when a component shares the single instance.
  ///	</summary>
  ///	<remarks>
  ///	  When this attribute is applied to a component, the shared instance will
  ///	  be returned whenever get the implementation of a service.
  ///	</remarks>
  ///	<example>
  ///	  <code lang="Delphi">
  ///	[Singleton]
  ///	TEmailSender = class(TInterfacedObject, IEmailSender)
  ///	//...
  ///	end;
  ///	  </code>
  ///	</example>
  ///	<seealso cref="TransientAttribute" />
  ///	<seealso cref="SingletonPerThreadAttribute" />
  ///	<seealso cref="PooledAttribute" />
  ///	<seealso cref="TLifetimeType" />
  SingletonAttribute = class(LifetimeAttributeBase)
  public
    constructor Create;
  end;

  ///	<summary>
  ///	  Represents that a new instance of the component will be created when
  ///	  requested.
  ///	</summary>
  ///	<remarks>
  ///	  <note type="note">
  ///	    This attribute is the default option.
  ///	  </note>
  ///	</remarks>
  ///	<seealso cref="SingletonAttribute" />
  ///	<seealso cref="SingletonPerThreadAttribute" />
  ///	<seealso cref="PooledAttribute" />
  ///	<seealso cref="TLifetimeType" />
  TransientAttribute = class(LifetimeAttributeBase)
  public
    constructor Create;
  end;

  ///	<summary>
  ///	  Applies this attribute when a component shares the single instance per
  ///	  thread.
  ///	</summary>
  ///	<seealso cref="SingletonAttribute" />
  ///	<seealso cref="TransientAttribute" />
  ///	<seealso cref="PooledAttribute" />
  ///	<seealso cref="TLifetimeType" />
  SingletonPerThreadAttribute = class(LifetimeAttributeBase)
  public
    constructor Create;
  end;

  ///	<summary>
  ///	  Represents that the target component can be pooled.
  ///	</summary>
  ///	<seealso cref="SingletonAttribute" />
  ///	<seealso cref="TransientAttribute" />
  ///	<seealso cref="SingletonPerThreadAttribute" />
  ///	<seealso cref="TLifetimeType" />
  PooledAttribute = class(LifetimeAttributeBase)
  private
    fMinPoolsize: Integer;
    fMaxPoolsize: Integer;
  public
    constructor Create(minPoolSize, maxPoolSize: Integer);
    property MinPoolsize: Integer read fMinPoolsize;
    property MaxPoolsize: Integer read fMaxPoolsize;
  end;

  ///	<summary>
  ///	  Applies the <c>InjectionAttribute</c> to injectable instance members of
  ///	  a class. e.g. constructors, methods, properties and even fields. Also
  ///	  works on parameters of a method.
  ///	</summary>
  ///	<seealso cref="ImplementsAttribute" />
  InjectionAttribute = class(TCustomAttribute)
  private
    fValue: string;
    function GetHasValue: Boolean;
  public
    constructor Create; overload;
    constructor Create(const value: string); overload;
    property Value: string read fValue;
    property HasValue: Boolean read GetHasValue;
  end;

  ///	<summary>
  ///	  Applies this attribute to tell the IoC container which service is
  ///	  implemented by the target component. In addition, a service name can be
  ///	  specified.
  ///	</summary>
  ///	<remarks>
  ///	  <note type="note">
  ///	    This attribute can be specified more than once.
  ///	  </note>
  ///	</remarks>
  ///	<example>
  ///	  <code lang="Delphi">
  ///	[Implements(TypeInfo(IEmailSender))]
  ///	TRegularEmailSender = class(TInterfacedObject, IEmailSender)
  ///	end;
  ///	[Implements(TypeInfo(IEmailSender), 'mock-email-sender')]
  ///	TMockEmailSender = class(TInterfacedObject, IEmailSender)
  ///	end;
  ///	  </code>
  ///	</example>
  ///	<seealso cref="InjectionAttribute" />
  ImplementsAttribute = class(TCustomAttribute)
  private
    fServiceType: PTypeInfo;
    fName: string;
  public
    constructor Create(serviceType: PTypeInfo); overload;
    constructor Create(serviceType: PTypeInfo; const name: string); overload;
    property ServiceType: PTypeInfo read fServiceType;
    property Name: string read fName;
  end;


  {$ENDREGION}


  {$REGION 'Lifecycle Interfaces'}

  ///	<summary>
  ///	  Lifecycle interface. If a component implements this interface, the dependency injection
  ///	  container will invoke the <c>Initialize</c> method when initiating an
  ///	  instance of the component.
  ///	</summary>
  ///	<seealso cref="IStartable" />
  ///	<seealso cref="IRecyclable" />
  ///	<seealso cref="IDisposable" />
  IInitializable = interface
    ['{A36BB399-E592-4DFB-A091-EDBA3BE0648B}']

    ///	<summary>
    ///	  Initializes the component.
    ///	</summary>
    procedure Initialize;
  end;

  ///	<summary>
  ///	  Lifecycle interface. Represents that the component can be started and stopped.
  ///	</summary>
  ///	<seealso cref="IInitializable" />
  ///	<seealso cref="IRecyclable" />
  ///	<seealso cref="IDisposable" />
  IStartable = interface
    ['{8D0252A1-7993-44AA-B0D9-326019B58E78}']
    procedure Start;
    procedure Stop;
  end;

  ///	<summary>
  ///	  Lifecycle interface. Only called for components that belongs to a pool
  ///	  when the component comes back to the pool.
  ///	</summary>
  ///	<seealso cref="IInitializable" />
  ///	<seealso cref="IStartable" />
  ///	<seealso cref="IDisposable" />
  IRecyclable = interface
    ['{85114F41-70E5-4AF4-A375-E445D4619E4D}']
    procedure Recycle;
  end;

  ///	<summary>
  ///	  Lifecycle interface. If the component implements this interface, all
  ///	  resources will be deallocate by calling the <c>Dispose</c> method.
  ///	</summary>
  ///	<seealso cref="IInitializable" />
  ///	<seealso cref="IStartable" />
  ///	<seealso cref="IRecyclable" />
  IDisposable = interface
    ['{6708F9BF-0237-462F-AFA2-DF8EF21939EB}']
    procedure Dispose;
  end;

  {$ENDREGION}

  /// <summary>
  /// Defines an abstract interface to locate services.
  /// </summary>
  IServiceLocator = interface
    ['{E8C39055-6634-4428-B343-2FB0E75527BC}']
    function GetService(serviceType: PTypeInfo): TValue; overload;
    function GetService(serviceType: PTypeInfo; const name: string): TValue; overload;

    function GetAllServices(serviceType: PTypeInfo): TArray<TValue>; overload;

    function HasService(serviceType: PTypeInfo): Boolean; overload;
    function HasService(serviceType: PTypeInfo; const name: string): Boolean; overload;
  end;

  TServiceLocatorDelegate = reference to function: IServiceLocator;

  /// <summary>
  /// Provides a portal to get and query an instance of a service. Use the global
  /// <see cref="Spring.Services|ServiceLocator" /> method to get the shared instance.
  /// </summary>
  /// <remarks>
  /// You should use ServiceLocator to query a service insteading of directly using Spring.DI namespace in your library.
  /// The namespace is supposed to be used to register components in your bootstrap code.
  /// </remarks>
  TServiceLocator = class sealed
  strict private
    class var
      fInstance: TServiceLocator;
    class constructor Create;
    class destructor Destroy;
  strict private
    fServiceLocatorProvider: TServiceLocatorDelegate;
    function GetServiceLocator: IServiceLocator;
  public
    procedure Initialize(const provider: TServiceLocatorDelegate);
    class property Instance: TServiceLocator read fInstance;
  public
    function GetService<T>: T; overload;
    function GetService<T>(const name: string): T; overload;
    function GetService(serviceType: PTypeInfo): TValue; overload;
    function GetService(serviceType: PTypeInfo; const name: string): TValue; overload;

    function GetAllServices<TServiceType>: TArray<TServiceType>; overload;
    function GetAllServices(serviceType: PTypeInfo): TArray<TValue>; overload;

    function HasService(serviceType: PTypeInfo): Boolean; overload;
    function HasService(serviceType: PTypeInfo; const name: string): Boolean; overload;
  end;

/// <summary>
/// Gets the shared instance of <see cref="TServiceLocator" /> class.
/// </summary>
/// <remarks>
/// Since Delphi doesn't support generic methods for interfaces, the result type is TServiceLocator insteading of IServiceLocator.
/// </remarks>
function ServiceLocator: TServiceLocator;

implementation

uses
  Spring.ResourceStrings;

function ServiceLocator: TServiceLocator;
begin
  Result := TServiceLocator.Instance;
end;


{$REGION 'Attributes'}

{ LifetimeAttributeBase }

constructor LifetimeAttributeBase.Create(lifetimeType: TLifetimeType);
begin
  inherited Create;
  fLifetimeType := lifetimeType;
end;

{ SingletonAttribute }

constructor SingletonAttribute.Create;
begin
  inherited Create(TLifetimeType.ltSingleton);
end;

{ TransientAttribute }

constructor TransientAttribute.Create;
begin
  inherited Create(TLifetimeType.ltTransient);
end;

{ SingletonPerThreadAttribute }

constructor SingletonPerThreadAttribute.Create;
begin
  inherited Create(TLifetimeType.ltSingletonPerThread);
end;

{ InjectionAttribute }

constructor InjectionAttribute.Create;
begin
  Create('');
end;

constructor InjectionAttribute.Create(const value: string);
begin
  inherited Create;
  fValue := value;
end;

function InjectionAttribute.GetHasValue: Boolean;
begin
  Result := fValue <> '';
end;

{ ImplementsAttribute }

constructor ImplementsAttribute.Create(serviceType: PTypeInfo);
begin
  Create(serviceType, '');
end;

constructor ImplementsAttribute.Create(serviceType: PTypeInfo;
  const name: string);
begin
  inherited Create;
  fServiceType := serviceType;
  fName := name;
end;

{ PooledAttribute }

constructor PooledAttribute.Create(minPoolSize, maxPoolSize: Integer);
begin
  inherited Create(ltPooled);
  fMinPoolsize := minPoolSize;
  fMaxPoolsize := maxPoolsize;
end;

{$ENDREGION}


{$REGION 'TServiceLocator'}

class constructor TServiceLocator.Create;
begin
  fInstance := TServiceLocator.Create;
end;

class destructor TServiceLocator.Destroy;
begin
  FreeAndNil(fInstance);
end;

procedure TServiceLocator.Initialize(const provider: TServiceLocatorDelegate);
begin
  fServiceLocatorProvider := provider;
end;

function TServiceLocator.GetServiceLocator: IServiceLocator;
begin
  if not Assigned(fServiceLocatorProvider) or (fServiceLocatorProvider() = nil) then
    raise EInvalidOperation.Create(SServiceLocatorNotInitialized);

  Result := fServiceLocatorProvider();
end;

function TServiceLocator.GetService(serviceType: PTypeInfo): TValue;
begin
  Result := GetServiceLocator.GetService(serviceType);
end;

function TServiceLocator.GetService(serviceType: PTypeInfo; const name: string): TValue;
begin
  Result := GetServiceLocator.GetService(serviceType, name);
end;

function TServiceLocator.GetService<T>: T;
var
  value: TValue;
begin
  value := GetService(TypeInfo(T));
  Result := value.AsType<T>;
end;

function TServiceLocator.GetService<T>(const name: string): T;
var
  value: TValue;
begin
  value := GetService(TypeInfo(T), name);
  Result := value.AsType<T>;
end;

function TServiceLocator.GetAllServices(serviceType: PTypeInfo): TArray<TValue>;
begin
  Result := GetServiceLocator.GetAllServices(serviceType);
end;

function TServiceLocator.GetAllServices<TServiceType>: TArray<TServiceType>;
var
  services: TArray<TValue>;
  i: Integer;
begin
  services := GetAllServices(TypeInfo(TServiceType));
  SetLength(Result, Length(services));
  for i := 0 to High(Result) do
  begin
    Result[i] := services[i].AsType<TServiceType>;
  end;
end;

function TServiceLocator.HasService(serviceType: PTypeInfo): Boolean;
begin
  Result := GetServiceLocator.HasService(serviceType);
end;

function TServiceLocator.HasService(serviceType: PTypeInfo; const name: string): Boolean;
begin
  Result := GetServiceLocator.HasService(serviceType, name);
end;

{$ENDREGION}

end.