unit v6_classes;
{$RANGECHECKS ON}
{$COPERATORS ON}

interface
//type x = integer;
type IObject = interface ['{684CEB4B-FE3E-45D2-A954-ED8B4B95CABF}']// I might add an method! Do not implement it!
  function getClassName():string;
  function toString():string;
  function getId():longint;
end;
operator + (o:IObject; s:string)r:string;
operator + (s:string; o:IObject)r:string;
function interfaceToStr(c:IInterface):string;
function nilOrString(o:IObject):string;

type generic IEqualable<_T> = interface ['{14AEBAB1-2943-4D6C-9829-9C2389696FB2}']
  function equals(other:_T):boolean;
end;

type ISpecial = interface ['{EBB3518C-1472-4DDD-A028-002D520382FE}']
end;

type SimpleProcedure = procedure;

type generic ICloneable<_T> = interface ['{B47C9D72-8C58-4A93-900F-36BCC3DC6B08}']
  function clone():_T;
end;

type generic IConvertor<_F, _T> = interface ['{0B306AD8-C0AD-4D6C-90AA-2BD43C9FEC9E}']
  function convert(x:_F):_T;
end;

type StdClass=class(TInterfacedObject, IObject)
  private a, b:longint;
  private id:longint;
  public constructor create();
  public destructor destroy(); override;
  protected procedure checkExists();
  public function getClassName():string; virtual;
  public function toString():string; virtual;
  public function getId():longint; virtual;
end;

{private}type
  PAutoDisposer_Rec = ^AutoDisposer_Rec;
  AutoDisposer_Rec =  record
    obj:TObject;
    next:PAutoDisposer_Rec;
  end;

procedure shiftRight(var a, b, c:IInterface);
procedure shiftLeft(var a, b, c:IInterface);

type IAutoDisposer = interface ['{77500F2B-4D01-48CE-98C5-B590847DC592}']
  procedure add(p:TObject);
  procedure addRef(p:IInterface);
end;

type AutoDisposer = class(StdClass, IAutoDisposer)
  private first:PAutoDisposer_Rec;
  public constructor create();
  public destructor destroy(); override;
  public procedure add(p:TObject);
  public procedure addRef(p:IInterface);
end;

type generic Reference<_T> = class(StdClass)
  private v:_T;
  public function get():_T;
  public procedure setValue(val:_T);
end;

implementation
uses sysutils;

function Reference.get():_T;
begin
  get := v;
end;

procedure Reference.setValue(val:_T);
begin
  v := val;
end;

type InterfaceObject = class(StdClass)
  private i:IInterface;
  public constructor create(_i:IInterface);
  public destructor destroy();override;
end;

constructor InterfaceObject.create(_i:IInterface);
begin
  i := _i;
  i._addRef();
end;

destructor InterfaceObject.destroy();
begin
  i._release();
end;

constructor AutoDisposer.create();
begin
  first := NIL;
end;

destructor AutoDisposer.destroy();
var p, toDispose:PAutoDisposer_Rec;
  o:TObject;
begin
  p := first;
  while( p <> NIL ) do begin
    o := p^.obj;
    o.free();
    toDispose := p;
    p := p^.next;
    dispose(toDispose);
  end;
  inherited destroy();
end;

procedure AutoDisposer.add(p:TObject);
var r:PAutoDisposer_Rec;
begin
  r := new(PAutoDisposer_Rec);
  r^.next := first;
  r^.obj := p;
  first := r;
end;

procedure AutoDisposer.addRef(p:IInterface);
begin
  add(InterfaceObject.create(p));
end;

function StdClass.getId():longint;
begin
  getId := id;
end;

var nid:longint;

// StdClass
constructor StdClass.create();
begin
  id := nid;
  inc(nid);
  a := random(MAXLONGINT);
  b := a;
end;

procedure StdClass.checkExists();
begin
  if( self = NIL )then begin
    raise Exception.create('This instance is NIL!');
  end;
  if( a <> b )then begin
    raise Exception.create('This instance does not exist and is not NIL!');
  end;
end;

destructor StdClass.destroy();
begin
  a += 1;
end;

function StdClass.getClassName():string;
begin
  getClassName := className;
end;

function StdClass.toString():string;
begin
  toString := '[object '+getClassName()+']';
end;

procedure shiftRight(var a, b, c:IInterface);
begin
  c := b;
  b := a;
end;

procedure shiftLeft(var a, b, c:IInterface);
begin
  a := b;
  b := c;
end;


function interfaceToStr(c:IInterface):string;
begin
  if(supports(c, IObject))then begin
    interfaceToStr := (c as IObject).toString();
  end else begin
    interfaceToStr := '[an IUnknown]'
  end;
end;

function nilOrString(o:IObject):string;
begin
  if( o = NIL ) then begin
    nilOrString := 'NIL';
  end else begin
    nilOrString := o.toString();
  end;
end;

operator + (o:IObject; s:string)r:string;
begin
  r := nilOrString(o)+s;
end;

operator + (s:string; o:IObject)r:string;
begin
  r := s+nilOrString(o);
end;
{//typecheck violation:
var a:IObject; b:IAutoDisposer; c:IObject;
begin
  shiftRight(a, b, c); // works (= can be compiled WITHOUT WARNING!)
  b := a; // does not work
}
begin
  nid := 0;
end.