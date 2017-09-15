{***************************************************************************}
{                                                                           }
{           Spring Framework for Delphi                                     }
{                                                                           }
{           Copyright (c) 2009-2017 Spring4D Team                           }
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

unit Spring.Reactive.Observable.Return;

interface

uses
  Spring,
  Spring.Reactive,
  Spring.Reactive.Internal.Producer,
  Spring.Reactive.Internal.Sink;

type
  TReturn<TSource> = class(TProducer<TSource>)
  private
    fValue: TSource;
    fScheduler: IScheduler;

    type
      TSink = class(TSink<TSource>)
      private
        fParent: TReturn<TSource>;
        procedure Invoke;
      public
        constructor Create(const parent: TReturn<TSource>;
          const observer: IObserver<TSource>; const cancel: IDisposable);
        function Run: IDisposable;
      end;
  protected
    function CreateSink(const observer: IObserver<TSource>;
      const cancel: IDisposable): TObject; override;
    function Run(const sink: TObject): IDisposable; override;
  public
    constructor Create(const value: TSource; const scheduler: IScheduler);
  end;

implementation


{$REGION 'TReturn<TSource>'}

constructor TReturn<TSource>.Create(const value: TSource; const scheduler: IScheduler);
begin
  inherited Create;
  fValue := value;
  fScheduler := scheduler;
end;

function TReturn<TSource>.CreateSink(const observer: IObserver<TSource>;
  const cancel: IDisposable): TObject;
begin
  Result := TSink.Create(Self, observer, cancel);
end;

function TReturn<TSource>.Run(const sink: TObject): IDisposable;
begin
  Result := TSink(sink).Run;
end;

{$ENDREGION}


{$REGION 'TReturn<TSource>.TSink'}

constructor TReturn<TSource>.TSink.Create(const parent: TReturn<TSource>;
  const observer: IObserver<TSource>; const cancel: IDisposable);
begin
  inherited Create(observer, cancel);
  fParent := parent;
end;

procedure TReturn<TSource>.TSink.Invoke;
begin
  Observer.OnNext(fParent.fValue);
  Observer.OnCompleted;
  Dispose;
end;

function TReturn<TSource>.TSink.Run: IDisposable;
begin
  Result := fParent.fScheduler.Schedule(Invoke);
end;

{$ENDREGION}


end.