unit v6_vars;
{$RANGECHECKS ON}

interface

uses v6_classes;

type generic ISettable<_T> = interface ['{F48781A7-923A-458A-B40B-194A9B74A386}']
  procedure setValue(val:_T);
end;

type generic IValidator<_T> = interface ['{0792A38F-FED8-40AB-B25F-DADECD1A5A78}']
  function isValid(val:_T):boolean;
end;

{type INumber = interface
    function get():integer;
    procedure setValue(val:integer);
    procedure inc();
    procedure inc(val:integer);
    procedure dec();
    procedure dec(val:integer);
    procedure addModifyListener(l:IModifyListener);
  end;

???}

{type generic FuncConvertorSettable<_F, _T> = class(StdClass, ISettable)
  private conv:function(v:_F):_T;
  type TFunc = function(v:_F):_T;
  public constructor create(f:TFunc);
end;}

type IStringSettable = specialize ISettable<string>;
type IIntSettable = specialize ISettable<integer>;

type IntegerToStringSettable = class(StdClass, IIntSettable)
  private ss:IStringSettable;
  public constructor create(_ss:IStringSettable);
  public procedure setValue(val:integer);
end;

type generic IFactory<_T> = interface ['{E1EEF859-E477-4B53-97BD-B9442EE2A824}']
  function createInstance():_T;
end;

type generic IParametrisedFactory<_F, _T> = interface ['{815355AA-F3A9-4A63-8AC2-0F3D7A662D98}']
  function createInstance(arg:_F):_T;
end;

implementation

uses sysutils;

constructor IntegerToStringSettable.create(_ss:IStringSettable);
begin
  ss := _ss;
end;

procedure IntegerToStringSettable.setValue(val:integer);
begin
  ss.setValue(intToStr(val));
end;

end.