unit v6_geometrics;
{$RANGECHECKS ON}

interface
uses v6_classes, math, v6_keys, sysutils, v6_cmds, v6_vars, v6_multitasking;

//type IPosition = interface;
//{private}type IPositionEqualable = specialize IEqualable<IPosition>;
type IPosition = interface(IObject) ['{D8F7E793-BE40-48AA-8C4B-D157997662A9}'] // Do not implement!
  function getX():integer;
  function getY():integer;
  function equals(other:IPosition):boolean;
end;
operator +(x, y:IPosition) z:IPosition;
operator -(x, y:IPosition) z:IPosition;

function createPosition(x, y:integer):IPosition;

type IPositionFactory = specialize IFactory<IPosition>;

type MovingDirection = (UP, DOWN, LEFT, RIGHT);
function MovingDirection_not(dir:MovingDirection):MovingDirection;
function MovingDirection_toString(dir:MovingDirection):string;

procedure checkPositive(val:integer; name:string);

type EPositionNotFoundException = class(Exception);

type IPositionDirectionConverter = interface ['{4959F2F9-F102-434C-AF3D-B999D176758C}']
    function calcNewPosition(pos:IPosition; direction:MovingDirection):IPosition;
    function calcDirectionFromPositions(from, toPos:IPosition):MovingDirection;
end;

type IMover = interface ['{2A500C09-1B5F-412C-8D78-BE1B87638FA1}']
  procedure move(dir:MovingDirection);
  function getPosition():IPosition;
  procedure setPosition(p:IPosition);
end;

type IMovingDirectionSettable = specialize ISettable<MovingDirection>;

type ISettableMover = interface(IMovingDirectionSettable) ['{1940DD04-7EB8-4A08-AF9E-8DCC6CD0071A}'] // Why is not there multiple interface inheritance? I want to implement ITask!
  procedure move();
end;

//type Bu

type MovingCommand = class(StdClass, ICommand)
  private dir:MovingDirection;
  private m:IMover;
  public constructor create(_m:IMover; _dir:MovingDirection);
  public procedure execute(); virtual;
end;

type MovingSetterCommand = class(StdClass, ICommand)
  private dir:MovingDirection;
  private m:ISettableMover;
  public constructor create(_m:ISettableMover; _dir:MovingDirection);
  public procedure execute(); virtual;
end;

type MovingSetterTask = class(AbstractTask)
  private m:ISettableMover;
  public constructor create(_m:ISettableMover);
  public procedure runStep(); override;
end;

procedure mapArrowKeysToMovingCommands(km:KeyManager; m:IMover);
procedure mapArrowKeysToMovingCommands(km:KeyManager; m:ISettableMover);

type ISize = interface ['{1DF870D8-6A9B-46DD-98A8-97631C1A7AAB}'] // Do not implement!
  function getWidth():integer;
  function getHeight():integer;
end;
function createSize(width, height:integer):ISize;
operator div (size:ISize; n:integer) part:ISize;
operator * (size:ISize; n:integer) part:ISize;

function createRectanglePositionDirectionConverter(size:ISize; allowOverflow:boolean):IPositionDirectionConverter;

type IRectangle = interface ['{DE92405F-3624-4B21-B33A-B1872F910F18}'] // Don't implement now!
  function getPosition():IPosition;
  function getSize():ISize;
  function getX1():integer;
  function getY1():integer;
  function getX2():integer;
  function getY2():integer;
  function getMidX():integer;
  function getMidY():integer;
  function getMaxRadius():integer;
  {function getTopLeft():Position;
  function getTopRight():Position;
  function getBottomLeft():Position;
  function getBottomRight():Position;}
end;

function createRectangle(pos:IPosition; s:ISize):IRectangle;
function createRectangle(left, top, width, height:integer):IRectangle;
type RectangleArray = array of IRectangle;
operator div (p:IRectangle; n:integer) rects:RectangleArray;

implementation
uses graph;

procedure mapArrowKeysToMovingCommands(km:KeyManager; m:IMover);
begin
  km.setArrowKey(v6_keys.LEFT, MovingCommand.create(m, v6_geometrics.LEFT));
  km.setArrowKey(v6_keys.RIGHT, MovingCommand.create(m, v6_geometrics.RIGHT));
  km.setArrowKey(v6_keys.UP, MovingCommand.create(m, v6_geometrics.UP));
  km.setArrowKey(v6_keys.DOWN, MovingCommand.create(m, v6_geometrics.DOWN));
end;

procedure mapArrowKeysToMovingCommands(km:KeyManager; m:ISettableMover);
begin
  km.setArrowKey(v6_keys.LEFT, MovingSetterCommand.create(m, v6_geometrics.LEFT));
  km.setArrowKey(v6_keys.RIGHT, MovingSetterCommand.create(m, v6_geometrics.RIGHT));
  km.setArrowKey(v6_keys.UP, MovingSetterCommand.create(m, v6_geometrics.UP));
  km.setArrowKey(v6_keys.DOWN, MovingSetterCommand.create(m, v6_geometrics.DOWN));
end;

procedure checkPositive(val:integer; name:string);
begin
  if(val < 0)then begin
    raise ERangeError.create(name+' must not be '+intToStr(val));
  end;
end;

type Size = class(StdClass, ISize)
  private width, height:integer;
  public constructor create(_width, _height:integer);
  public function getWidth():integer; virtual;
  public function getHeight():integer; virtual;
  public function toString():string; override;
end;

function createSize(width, height:integer):ISize;
begin
  createSize := Size.create(width, height);
end;

constructor Size.create(_width, _height:integer);
begin
  checkPositive(_width, 'width');
  checkPositive(_height, 'height');
  width := _width;
  height := _height;
end;

function Size.toString():string;
begin
  checkExists();
  toString := '('+inherited toString()+'['+intToStr(getWidth())+', '+intToStr(getHeight())+'])';
end;

function Size.getWidth():integer;
begin
  getWidth := width;
end;
function Size.getHeight():integer;
begin
  getHeight := height;
end;

type Position = class(StdClass, IPosition)
  private x, y:integer;
  public constructor create(_x, _y:integer);
  public function getX():integer; virtual;
  public function getY():integer; virtual;
  public function toString():string; override;
  public function equals(other:IPosition):boolean; virtual;
end;

function Position.toString():string;
begin
  checkExists();
  toString := '['+intToStr(getX())+', '+intToStr(getY())+']';
end;

constructor Position.create(_x, _y:integer);
begin
  x := _x;
  y := _y;
end;

function Position.getX():integer;
begin
  getX := x;
end;

function Position.getY():integer;
begin
  getY := y;
end;

function createPosition(x, y:integer):IPosition;
begin
  createPosition := Position.create(x, y);
end;

type Rectangle = class(StdClass, IRectangle)
  private pos:IPosition;
  private s:ISize;
  public constructor create(_pos:IPosition; _s:ISize);
  public function getPosition():IPosition; virtual;
  public function getSize():ISize; virtual;
  {public function getTopLeft():Position; virtual;
  public function getTopRight():Position; virtual;
  public function getBottomLeft():Position; virtual;
  public function getBottomRight():Position; virtual;}
  public function getX1():integer; virtual;
  public function getY1():integer; virtual;
  public function getX2():integer; virtual;
  public function getY2():integer; virtual;
  public function getMidX():integer; virtual;
  public function getMidY():integer; virtual;
  public function getMaxRadius():integer; virtual;
  public function toString():string; override;
end;

function Rectangle.getMidX():integer;
begin
  getMidX := getPosition().getX()+(getSize.getWidth() div 2);
end;

function Rectangle.getMidY():integer;
begin
  getMidY := getPosition().getY()+(getSize.getHeight() div 2)
end;

function createRectangle(pos:IPosition; s:ISize):IRectangle;
begin
  createRectangle := Rectangle.create(pos, s);
end;

function createRectangle(left, top, width, height:integer):IRectangle;
begin
  createRectangle := createRectangle(createPosition(left, top), createSize(width, height));
end;

constructor Rectangle.create(_pos:IPosition; _s:ISize);
begin
  pos := _pos;
  s := _s;
end;

function Rectangle.getPosition():IPosition;
begin
  getPosition := pos;
end;

function Rectangle.getMaxRadius():integer;
begin
  getMaxRadius := min((getSize().getHeight() div 2), (getSize().getWidth() div 2));
end;

function Rectangle.getSize():ISize;
begin
  getSize := s;
end;

function Rectangle.toString():string;
begin
  checkExists();
  toString := inherited toString()+': '+interfaceToStr(getPosition())+': '+interfaceToStr(getSize());
end;

{function Rectangle.getTopLeft():integer;
begin
  getTopLeft := createPosition(getX1());
end;

function Rectangle.getTopRight():integer; virtual;
function Rectangle.getBottomLeft():integer; virtual;
function Rectangle.getBottomRight():integer; virtual;}
function Rectangle.getX1():integer;
begin
  getX1 := getPosition().getX();
end;

function Rectangle.getY1():integer;
begin
  getY1 := getPosition().getY();
end;

function Rectangle.getX2():integer;
begin
  getX2 := getPosition().getX() + getSize().getWidth();
end;

function Rectangle.getY2():integer;
begin
  getY2 := getPosition().getY() + getSize().getHeight();
end;

operator +(x, y:IPosition) z:IPosition;
begin
  z := createPosition(x.getX()+y.getX(), x.getY()+y.getY());
end;

operator -(x, y:IPosition):IPosition;
begin
  z := createPosition(x.getX()-y.getX(), x.getY()-y.getY());
end;

function Position.equals(other:IPosition):boolean;
begin
  equals := (other.getX() = getX()) and (other.getY() = getY());
end;

constructor MovingCommand.create(_m:IMover; _dir:MovingDirection);
begin
  m := _m;
  dir := _dir;
end;

procedure MovingCommand.execute();
begin
  m.move(dir);
end;

type RectanglePositionDirectionConverter = class(StdClass, IPositionDirectionConverter)
  private size:ISize; allowOverflow:boolean;
  public constructor create(_size:ISize; _allowOverflow:boolean);
  public function calcNewPosition(from:IPosition; dir:MovingDirection):IPosition; virtual;
  public function calcDirectionFromPositions(from, toPos:IPosition):MovingDirection; virtual;
  private procedure checkRange(pos:IPosition);
  private function minus(a, b:IPosition):IPosition;
end;

function createRectanglePositionDirectionConverter(size:ISize; allowOverflow:boolean):IPositionDirectionConverter;
begin
  createRectanglePositionDirectionConverter := RectanglePositionDirectionConverter.create(size, allowOverflow);
end;

constructor RectanglePositionDirectionConverter.create(_size:ISize; _allowOverflow:boolean);
begin
  size := _size;
  allowOverflow := _allowOverflow;
end;

function RectanglePositionDirectionConverter.minus(a, b:IPosition):IPosition;
  function minusOverflow({@ch}a, b, size:integer):integer;
  begin
    if( (a = 0) and (b = size-1) )then begin
      // a - b = 0 - max => overflow
      // move right and overflow: 0+1 - overflow(max+1) = 1 - 0
      minusOverflow := 1 - 0;
    end else if ( (a = size-1) and (b = 0) )then begin
      // a - b = max - 0
      // move left and overflow: (max-1) - overflow(0-1) = (max-1) - max = max -1 -max = -1
      minusOverflow := -1;
    end else begin
      // simple
      minusOverflow := a - b;
    end;
  end;
    {if(coor < 0) then begin
      deb('add: coor=', coor);
      coor += size-1;
      deb('after-add: coor=', coor);
    end;
    deb('before mod: coor=', coor, ', size=', size, ', res=', coor mod (size-1));
    repairCoordinate := coor mod (size-1);
  end;}
begin
  if(allowOverflow)then begin
    minus := createPosition(minusOverflow(a.getX(), b.getX(), size.getWidth()), minusOverflow(a.getY(), b.getY(), size.getHeight()));
  end else begin
    minus := a-b;
  end;
end;

function RectanglePositionDirectionConverter.calcDirectionFromPositions(from, toPos:IPosition):MovingDirection;
var diffs: array [-1 .. 1] of array [-1 .. 1] of byte = (
    (0, 1, 0),
    (2, 0, 3),
    (0, 4, 0)
  );
var types: array [1 .. 4] of MovingDirection = (UP, LEFT, RIGHT, DOWN);
var diff:IPosition;
  mdb:byte;
begin
  checkRange(toPos);
  {
  examples with overflow:
  * size 8*8 (range 0-7, 0-7)
    * [7, 7] -> [7, 0]: UP      
  }
  diff := minus(toPos, from);
  try
    mdb := diffs[diff.getY(), diff.getX()];
    calcDirectionFromPositions := types[mdb];
  except on ERangeError do
    raise EPositionNotFoundException.create('Cannot determine direct direction from '+from.toString()+' to '+toPos.toString());
  end;
end;

procedure RectanglePositionDirectionConverter.checkRange(pos:IPosition);
begin
  if(
    (pos.getX() < 0)
    or (pos.getY() < 0)
    or (pos.getX()>=size.getWidth())
    or (pos.getY()>=size.getHeight())
  )then begin
    raise ERangeError.create(intToStr(pos.getX())+':'+intToStr(pos.getY())+' is out of range 0-'+intToStr(size.getWidth()-1)+':0-'+intToStr(size.getHeight()-1));
  end;
end;

function RectanglePositionDirectionConverter.calcNewPosition(from:IPosition; dir:MovingDirection):IPosition;
  procedure repairCoordinate(var val:integer; max:integer);
  begin
    if(val = -1) then begin
      val := max;
    end else if (val = max+1) then begin
      val := 0;
    end;
  end;
var x2, y2:integer;
begin
  //deb('allowOverflow: [', size.getWidth(), '*', size.getHeight(), ']', allowOverflow);
  checkRange(from);
  x2 := from.getX();
  y2 := from.getY();
  case dir of
    LEFT:
      dec(x2);
    RIGHT:
      inc(x2);
    UP:
      dec(y2);
    DOWN:
      inc(y2);
  else // unexpected
    raise Exception.create('Unknown MovingDirection!');
  end;
  if(allowOverflow)then begin
    repairCoordinate(x2, size.getWidth()-1);
    repairCoordinate(y2, size.getHeight()-1);
  end;
  checkRange(createPosition(x2, y2));
  calcNewPosition := createPosition(x2, y2)
end;

function MovingDirection_not(dir:MovingDirection):MovingDirection;
begin
  case (dir) of
    UP: MovingDirection_not := DOWN ;
    DOWN:  MovingDirection_not := UP;
    LEFT:  MovingDirection_not := RIGHT;
    RIGHT: MovingDirection_not := LEFT;
  else
    raise Exception.create('Unknown MovingDirection!');;
  end;
end;

constructor MovingSetterCommand.create(_m:ISettableMover; _dir:MovingDirection);
begin
  m := _m;
  dir := _dir;
end;

procedure MovingSetterCommand.execute();
begin
  m.setValue(dir);
end;

constructor MovingSetterTask.create(_m:ISettableMover);
begin
  m := _m;
end;

procedure MovingSetterTask.runStep();
begin
  m.move();
end;

function MovingDirection_toString(dir:MovingDirection):string;
begin
  case (dir) of
    UP: MovingDirection_toString := 'UP';
    DOWN: MovingDirection_toString := 'DOWN';
    LEFT: MovingDirection_toString := 'LEFT';
    RIGHT: MovingDirection_toString := 'RIGHT';
  else
    MovingDirection_toString := '<>';
  end;
end;

operator div (size:ISize; n:integer) part:ISize;
begin
  part := createSize(size.getWidth() div n, size.getHeight() div n);
end;

operator * (size:ISize; n:integer) part:ISize;
begin
  part := createSize(size.getWidth() * n, size.getHeight() * n);
end;

operator div (p:IRectangle; n:integer) rects:RectangleArray;
var i, j:integer;
var subsize:ISize;
begin
  subsize := p.getSize() div n;
  setLength(rects, n*n);
  for i := 0 to n-1 do begin
    for j := 0 to n-1 do begin
      rects[n*i+j] := createRectangle(
        createPosition(p.getPosition().getX()+i*subsize.getWidth(), p.getPosition().getY()+j*subsize.getHeight()),
        subsize
      );
    end;
  end;
end;

end.