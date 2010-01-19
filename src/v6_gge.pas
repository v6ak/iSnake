unit v6_gge;
{$RANGECHECKS ON}
{
FIXME: exceptions
}

interface
uses v6_classes, sysutils, v6_graph, v6_cmds, v6_keys, v6_geometrics, v6_vars;
// I know that there is no Dependency Injection (see http://en.wikipedia.org/wiki/Dependency_injection ) in the drawing interfaces and the drawing is global, but I have to use the graph unit interface and I'm bored by writing object wrappers for everything.

type Grid = class; 
type ICell = interface;

type ICellFactory = specialize IFactory<ICell>;

type ICellValidator = specialize IValidator<ICell>;

type ConstantCellFactory = class(StdClass, ICellFactory)
  private c:ICell;
  public constructor create(_c:ICell);
  public function createInstance():ICell; virtual;
end;

function NilCellValidator_getInstance():ICellValidator;

type ICellInfo = interface(IObject) ['{7BC18065-8D6E-492A-9845-FB7C8364ECA3}'] // Do not imlement it!
  function getPosition():IPosition;
  function getCell():ICell;
  procedure repaint();
  function getGrid():Grid;
end;

type IReplacementInfo = interface(IObject) ['{D6483FD4-E6DB-4C75-ABB0-17A34278F917}'] // Do not imlement it!
  function getReplacementInfo():ICellInfo;
  function getReplacedInfo():ICellInfo;
  function getGrid():Grid;
  function getPositionDirectionConverter():IPositionDirectionConverter;
  function getDirection():MovingDirection;
end;

type ICell = interface(IObject) ['{B81F8F67-1BF5-43E6-B1D4-9B9206DD322C}']
  procedure draw(pos:IRectangle; gpos:IPosition);
  function canBeReplacedBy(event:IReplacementInfo):boolean;
  function canReplace(event:IReplacementInfo; dir:MovingDirection):boolean;
  procedure notifyReplacedBy(event:IReplacementInfo);
  procedure notifyReplacedSomething(event:IReplacementInfo);
  procedure notifyMoved(event:IReplacementInfo);
end;

// errors when moving a cell
type {abstract} EMovingException = class (Exception)
  {package-private constructor create()}
end;

type {final} EUnallowedMovingCycleException = class(EMovingException)
end;

type {final} EMovingArgue = class(EMovingException)
  private p1, p2:IPosition;
  {package-private} public constructor create(_p1, _p2:IPosition);
  public function getFirstPosition():IPosition;
  public function getSecondPosition():IPosition;
end;

type {abstract} EMovingRefused = class (EMovingException)
  {package-private constructor create()}
end;

type {final} EMovingRefusedByTarget = class (EMovingRefused)
  {package-private} public constructor create(by, what:ICell);
end;

type {final} EMovingRefusedByReplacement = class (EMovingRefused)
  {package-private} public constructor create(by, what:ICell);
end;

type {final} EMovingOverflow = class (EMovingException)
  {package-private constructor create()}
end;

// conditions for replacing a cell
type {abstract} EReplacingCondition = class(Exception)
  {package-private constructor create()}
end;

type ERequiredMoveException = class(EReplacingCondition)
  private dir:MovingDirection;
  public constructor create(_dir:MovingDirection);
  public function getDirection():MovingDirection;
end;

type GridGameArray = array of array of ICell;

type Grid{<E extends Cell>} = class(AbstractPaintable) // I've not found an equivalent mechanism to Java generics like E extends Cell :( 
  private left, top:integer;
  private width, height:integer;
  private eWidth, eHeight:integer;
  private sd:ISpaceDrawer;
  private game:array of array of ICell{E}; // see http://www.freepascal.org/docs-html/ref/refsu14.html
  public constructor create(_left, _top, _width, _height, x, y:integer; _sd:ISpaceDrawer);
  public constructor create(_left, _top, _width, _height:integer; arr:GridGameArray; _sd:ISpaceDrawer);
  public function getSize():ISize;
  private function checkReplacing(repl:IReplacementInfo; dir:MovingDirection; pc:IPositionDirectionConverter):IPosition;
  private procedure repaint(); override;
  private function getCellInfo(pos:IPosition):ICellInfo;
  public procedure repaintCell(x, y:integer);
  public procedure repaintCell(pos:IPosition);
  private procedure checkRange(x, y:integer);
  public function getCell(pos:IPosition):ICell;
  public procedure setCell(x, y:integer; c:ICell{E}); // WARNING: No replacing rule will be used and no replacing handler will be called!
  public procedure setCell(pos:IPosition; c:ICell{E});// WARNING: No replacing rule will be used and no replacing handler will be called!
  //public procedure replaceCell(x, y:integer; c:ICell{E});// for safe replacing - check Cell.canBeReplacedBy(PCell) and hadlers like Cell.notifyReplacedBy(PCell) and Cell.notifyReplacedSomething(PCell) will be used.
  public function moveCell(x, y:integer; direction:MovingDirection; allowOverflow:boolean):IPosition;
  public function moveCell(startPos:IPosition; direction:MovingDirection; allowOverflow:boolean):IPosition;
  public function moveCell(startPos:IPosition; movingAcceptedCommand:ICommand; direction:MovingDirection; allowOverflow:boolean):IPosition;
  public function moveCell(startPos:IPosition; lcf:ICellFactory; movingAcceptedCommand:ICommand; direction:MovingDirection; allowOverflow:boolean):IPosition;
end;

type ISettableCellFactory = specialize ISettable<ICellFactory>;

type Mover = class(StdClass, IMover, ISettableCellFactory)
  private g:Grid;
  private pos:IPosition;
  private allowOverflow:boolean;
  private crashCommand:ICommand;
  private cf:ICellFactory;
  public constructor create(_g:Grid; _pos:IPosition; _allowOverflow:boolean);
  public constructor create(_g:Grid; x, y:integer; _allowOverflow:boolean);
  public procedure setCrashCommand(cmd:ICommand); virtual;
  public function getPosition():IPosition; virtual;
  public procedure setPosition(p:IPosition); virtual;
  public function getCell():ICell; virtual;
  public procedure move(dir:MovingDirection); virtual;
  public procedure move(dir:MovingDirection; commitCmd:ICommand); virtual;
  public procedure setValue(_cf:ICellFactory); virtual;
end;

implementation

uses graph, strutils, crt, v6_debug;

const MovingDirection_LEFT = MovingDirection(LEFT);

type CellInfo = class(StdClass, ICellInfo, IObject)
  private pos:IPosition; cell:ICell;
  private g:Grid;
  public constructor create(_pos:IPosition; _cell:ICell; _g:Grid);
  public function getPosition():IPosition; virtual;
  public function getGrid():Grid; virtual;
  public function getCell():ICell; virtual;
  public procedure repaint(); virtual;
  public function toString():string; override;
end;

constructor CellInfo.create(_pos:IPosition; _cell:ICell; _g:Grid);
begin
  pos := _pos;
  cell := _cell;
  g := _g;
end;

function CellInfo.toString():string;
begin
  toString := '('+inherited toString()+': '+getCell()+', '+getPosition()+')';
end;

function CellInfo.getGrid():Grid;
begin
  getGrid := g;
end;

procedure CellInfo.repaint();
begin
  getGrid().repaintCell(getPosition());
end;

function CellInfo.getPosition():IPosition;
begin
  getPosition := pos;
end;

function CellInfo.getCell():ICell;
begin
  getCell := cell;
end;
  
type ReplacementInfo = class(StdClass, IReplacementInfo)
  private whatInfo, byInfo:ICellInfo;
  private g:Grid;
  private pdc:IPositionDirectionConverter;
  public constructor create(_whatInfo, _byInfo:ICellInfo; _g:Grid; _pdc:IPositionDirectionConverter);
  public function getReplacementInfo():ICellInfo; virtual;
  public function getReplacedInfo():ICellInfo; virtual;
  public function getGrid():Grid; virtual;
  public function getPositionDirectionConverter():IPositionDirectionConverter; virtual;
  public function getDirection():MovingDirection; virtual;
  public function toString():string; override;
end;

constructor ReplacementInfo.create(_whatInfo, _byInfo:ICellInfo; _g:Grid; _pdc:IPositionDirectionConverter);
begin
  whatInfo := _whatInfo;
  byInfo := _byInfo;
  g := _g;
  pdc := _pdc;
end;

function ReplacementInfo.toString():string;
begin
  toString := '('+inherited toString()+getReplacementInfo() +'->'+ getReplacedInfo()+')';
end;

function ReplacementInfo.getDirection():MovingDirection;
begin
  getDirection := getPositionDirectionConverter().calcDirectionFromPositions(getReplacementInfo().getPosition(), getReplacedInfo().getPosition());
end;

function ReplacementInfo.getPositionDirectionConverter():IPositionDirectionConverter;
begin
  getPositionDirectionConverter := pdc;
end;

function ReplacementInfo.getReplacementInfo():ICellInfo;
begin
  getReplacementInfo := byInfo;
end;

function ReplacementInfo.getReplacedInfo():ICellInfo;
begin
  getReplacedInfo := whatInfo;
end;

function ReplacementInfo.getGrid():Grid;
begin
  getGrid := g;
end;

constructor ConstantCellFactory.create(_c:ICell);
begin
  c := _c;
end;

function ConstantCellFactory.createInstance():ICell;
begin
  createInstance := c;
end;


constructor Grid.create(_left, _top, _width, _height:integer; arr:GridGameArray; _sd:ISpaceDrawer);
var x, y:integer;
begin
  inherited create();
  checkPositive(_width, 'width');
  checkPositive(_height, 'height');
  x := length(arr);
  y := length(arr[1]);
  sd := _sd;
  game := arr;
  //deb('high(game):', high(game), '/', getSize().getHeight());
  left := _left;
  top := _top;
  width := _width;
  height := _height;
  eWidth := trunc(width/x);
  //deb('eWidth: ', eWidth);
  eHeight := trunc(height/y);
  //deb('eHeight: ', eHeight);
end;

constructor Grid.create(_left, _top, _width, _height, x, y:integer; _sd:ISpaceDrawer);
var arr:GridGameArray;
var i, j:integer;
begin
  setLength(arr, x, y);
  for i := 0 to high(arr) do begin // see http://www.freepascal.org/docs-html/ref/refsu14.html
    for j := 0 to high(arr[i]) do begin
      arr[i, j]:= NIL;
    end;
  end;
  create(_left, _top, _width, _height, arr, _sd);
end;

{constructor Grid.init(_left, _top, _width, _height, x, y:integer; _sd:PSpaceDrawer);
var i, j:integer;
begin
  setLength(game, x, y);
  for i := 0 to high(game) do begin // see http://www.freepascal.org/docs-html/ref/refsu14.html
    for j := 0 to high(game[i]) do begin
      game[i, j]:= NIL;
    end;
  end;
  left := _left;
  top := _top;
  width := _width;
  height := _height;
  paint := false;
  eWidth := trunc(width/x);
  eHeight := trunc(height/y);
end;}

{destructor Grid.destroy();
begin
end;}


procedure Grid.repaint();
var i, j:integer;
begin
  for i := 0 to high(game) do begin // see http://www.freepascal.org/docs-html/ref/refsu14.html
    for j := 0 to high(game[i]) do begin
      repaintCell(i, j);
    end;
  end;
end;

function Grid.getSize():ISize;
begin
  getSize := createSize(length(game), length(game[0]));
end;

procedure Grid.repaintCell(pos:IPosition);
begin
  repaintCell(pos.getX(), pos.getY());
end;

procedure Grid.repaintCell(x, y:integer);
var gc:ICell;
begin
  if(isPaintingEnabled())then begin
    gc := game[x, y];
    if( gc = NIL )then begin
      sd.drawSpace(createRectangle(left+x*eWidth, top+y*eHeight, eWidth, eHeight));
    end else begin
      checkExists();
      gc.draw(createRectangle(createPosition(left+x*eWidth, top+y*eHeight), createSize(eWidth, eHeight)), createPosition(x, y));
    end;
  end;
end;

procedure Grid.checkRange(x, y:integer);
begin
  if( (x < 0) or (y < 0) or (x>high(game)) or (y>high(game[0])) ) then begin
    raise EMovingOverflow.create(intToStr(x)+':'+intToStr(y)+' is out of range 0-'+intToStr(high(game))+':0-'+intToStr(high(game[0])));
  end;
end;

procedure Grid.setCell(pos:IPosition; c:ICell);
begin
  setCell(pos.getX(), pos.getY(), c);
end;

procedure Grid.setCell(x, y:integer; c:ICell);
begin
  checkRange(x, y);
  game[x, y] := c;
  if(isPaintingEnabled())then begin
    repaintCell(x, y);
  end;
end;

function Grid.getCellInfo(pos:IPosition):ICellInfo;
begin
  getCellInfo := CellInfo.create(pos, game[pos.getX(), pos.getY()], self);
end;

{procedure deb(s:string; c:ICell);
begin
  if(supports(c, IObject))then begin
    deb(s, '.getClassName(): ', (c as IObject).getClassName());
  end;
end;}

function Grid.checkReplacing(repl:IReplacementInfo; dir:MovingDirection; pc:IPositionDirectionConverter):IPosition;
  function cellInfoToCell(ci:ICellInfo):ICell;
  begin
    if ( ci = NIL ) then begin
      cellInfoToCell := NIL;
    end else begin
      cellInfoToCell := ci.getCell();
    end;
  end;
var move:IPosition;
  procedure setMove(_move:IPosition);
  begin
    if( move <> NIL )then begin
      if(not move.equals(_move)) then begin
        raise EMovingArgue.create(move, _move);
      end;
    end;
    move := _move;
  end;
  procedure handleReplacingCondition(pos:IPosition; e:EReplacingCondition);
  begin
    if(e is ERequiredMoveException) then begin
      try
        setMove(pc.calcNewPosition(pos, (e as ERequiredMoveException).getDirection()));
      except on e:ERangeError do begin
        raise EMovingOverflow.create(e.message);
      end end;
    end else begin
      raise Exception.create('Unknown EReplacingCondition: '+e.className);
    end;
  end;

var what, by:ICell;
begin
  deb('repl', repl);
  //deb('ckeckReplacing: enter');
  //crt.readKey();
  //deb('');
  move := NIL;
  what := cellInfoToCell(repl.getReplacedInfo());
  by := cellInfoToCell(repl.getReplacementInfo());
  //deb('checkRepl:'+interfaceToStr(what) +' -> '+ interfaceToStr(by));
  if( by <> NIL )then begin
    try
      if( not by.canReplace(repl, dir) ) then begin
        raise EMovingRefusedByTarget.create(by, what);
      end;
    except on e:EReplacingCondition do begin
      //deb('errRC: '#9+interfaceToStr(what) +' -> '+ interfaceToStr(by));
      handleReplacingCondition(repl.getReplacementInfo().getPosition(), e);
    end end;
  end;
  if( what <> NIL )then begin
    try
      if( not what.canBeReplacedBy(repl) )then begin
        //deb('ref: '#9+interfaceToStr(what) +' -> '+ interfaceToStr(by));
        raise EMovingRefusedByReplacement.create(by, what);
      end;
    except on e:EReplacingCondition do
      begin
        //deb('errRC: '#9+interfaceToStr(what) +' -> '+ interfaceToStr(by));
        handleReplacingCondition(repl.getReplacedInfo().getPosition(), e);
      end;
    end;
  end;
  checkReplacing := move;
end;

function Grid.moveCell(x, y:integer; direction:MovingDirection; allowOverflow:boolean):IPosition;
begin
  moveCell := moveCell(createPosition(x, y), direction, allowOverflow);
end;

type CondsArray = array of array of IPosition;

{procedure debCondsArray(arr:CondsArray);
var i, j:integer;
begin
  deb('CondsArray:');
  for i := 0 to high(arr) do begin
    for j := 0 to high(arr[i]) do begin
      deb(arr[i, j]+'':8);
    end;
    deb('');
  end;
  deb(reverseString('CondsArray:'));
end;}

type MovingType = (REPLACE, MOVE);

function Grid.getCell(pos:IPosition):ICell;
begin
  //deb('high(game): ', high(game));
  getCell := game[pos.getX(), pos.getY()];
end;

function Grid.moveCell(startPos:IPosition; direction:MovingDirection; allowOverflow:boolean):IPosition;
begin
  moveCell := moveCell(startPos, NIL, direction, allowOverflow);
end;

function Grid.moveCell(startPos:IPosition; movingAcceptedCommand:ICommand; direction:MovingDirection; allowOverflow:boolean):IPosition;
begin
  moveCell := moveCell(startPos, ConstantCellFactory.create(NIL), movingAcceptedCommand, direction, allowOverflow);
end;

function Grid.moveCell(startPos:IPosition; lcf:ICellFactory; movingAcceptedCommand:ICommand; direction:MovingDirection; allowOverflow:boolean):IPosition;
var pc:IPositionDirectionConverter;
var ncp:IPosition;
  function moveAll(conds:CondsArray; fromPos:IPosition; notify:MovingType):IPosition;
  var toPos:IPosition;
  var event:IReplacementInfo;
  var c:ICell;
  var last:boolean;
  //var notify:MovingType;
  begin
    // satisfy the other condition
    //deb('fromPos: '+fromPos);
    toPos := conds[fromPos.getX(), fromPos.getY()];
    //ncp := toPos;
    moveAll := toPos;
    conds[fromPos.getX(), fromPos.getY()] := NIL;
    //notify := REPLACE;
    //deb('toPos: '+toPos);
    last := true;
    if( conds[toPos.getX(), toPos.getY()] <> NIL )then begin
      moveAll(conds, toPos, MOVE);
      //notify := MOVE;
      //deb('notLast');
      last := false;
    end;
    // move fromPos -> toPos
    // create event
    event := ReplacementInfo.create(getCellInfo(toPos), getCellInfo(fromPos), self, pc);
    // set the first cell
    setCell(event.getReplacedInfo().getPosition(), event.getReplacementInfo().getCell());
    if( notify = REPLACE ) then begin
      c := lcf.createInstance();
      setCell(ncp, c); // TODO:???
      if( c <> NIL )then begin
        moveCell := startPos;
      end;
    end;
    //deb('Grid.move(...): notifyMoved: '+interfaceToStr(event.getReplacementInfo().getCell())+' -> '+interfaceToStr(event.getReplacedInfo().getCell()));
    event.getReplacementInfo().getCell().notifyMoved(event);
    {
    getReplacedInfo x getReplacementInfo:
    if( notify= REPLACE )then begin
      deb('Grid.move(...): replace: '+interfaceToStr(event.getReplacementInfo().getCell())+' -> '+interfaceToStr(event.getReplacedInfo().getCell()));
      if( event.getReplacementInfo().getCell() <> NIL )then begin
        event.getReplacedInfo().getCell().notifyReplacedBy(event);
      end;
    end;}
    //deb('last:', last);
    //deb('event.getReplacedInfo().getCell()', interfaceToStr(event.getReplacedInfo().getCell()));
    if( last and (event.getReplacedInfo().getCell() <> NIL) )then begin
      event.getReplacedInfo().getCell().notifyReplacedBy(event);
    end;
  end;
var conds:CondsArray;
var i, j:integer;
var event:IReplacementInfo;
var fromPos, toPos:IPosition;
begin
  //crt.clrscr();
  // init
  ncp := startPos;
  //deb('ncp:'+ncp);
  pc := createRectanglePositionDirectionConverter(createSize(length(game), length(game[0])), allowOverflow);
  setLength(conds, length(game), length(game[0]));
  //deb('game:', length(game), '*', length(game[0]));
  for i := 0 to high(conds) do begin
    for j := 0 to high(conds[i]) do begin
      conds[i, j] := NIL;
    end;
  end;
  // collect events
  fromPos := startPos;
  try
    toPos := pc.calcNewPosition(fromPos, direction);
  except on e:ERangeError do
    raise EMovingOverflow.create(e.message);
  end;
  conds[fromPos.getX(), fromPos.getY()] := toPos;
  moveCell := toPos;
  //deb('');
  //deb('---moveCell = ', toPos);
  assert( toPos <> NIL );
  while( toPos <> NIL ) do begin
    //deb('collect:enter');
    //crt.readKey();
    if( conds[toPos.getX(), toPos.getY()] <> NIL )then begin
      deb('a cycle');
      if(toPos = startPos)then begin
        deb('normal cycle');
        //deb('CYCLE!');
        ncp := conds[startPos.getX(), startPos.getY()];
        lcf := ConstantCellFactory.create(game[startPos.getX(), startPos.getY()]);
        //deb('lcf:', interfaceToStr(lcf.createInstance()));
        break;
      end else begin
        deb('abnormal cycle');
        // disable it!
        raise EUnallowedMovingCycleException.create('This moving cycle is not allowed!');
      end;
    end;
    //deb(fromPos.toString()+' -> '+toPos.toString());
    event := ReplacementInfo.create(getCellInfo(toPos), getCellInfo(fromPos), self, pc);
    conds[toPos.getX(), toPos.getY()] := checkReplacing(event, direction, pc);
    //deb('fromPos:'+fromPos);
    //bed('toPos:'+toPos);
    //deb('conds[toPos.getX(), toPos.getY()]]:'+conds[toPos.getX(), toPos.getY()]);
    // fromPos -> toPos (new:fromPos) -> conds[fromPos.getX(), fromPos.getY()] (new:toPos)
    shiftLeft(fromPos, toPos, conds[toPos.getX(), toPos.getY()]);
    //deb('fromPos:'+fromPos);
    //deb('toPos:'+toPos);
    {if(toPos <> NIL)then begin
      deb('conds[toPos.getX(), toPos.getY()]]:'+conds[toPos.getX(), toPos.getY()]);
    end;}
  end;
  //debCondsArray(conds);
  // all events are collected
  if(movingAcceptedCommand <> NIL)then begin
    movingAcceptedCommand.execute();
  end;
  //crt.readKey();
  // replace and notify
  //deb('startPos: '+startPos);
  //deb('endPos:'+conds[startPos.getX(), startPos.getY()]);
  moveAll(conds, startPos, REPLACE);
  {fromPos := startPos;
  fromCell := ???conds[fromPos.getX(), fromPos.getY()];
  while( fromPos <> NIL )do begin
    // init iteration
    toPos := conds[fromPos.getX(), fromPos.getY()];
    event := ReplacementInfo.create(getCellInfo(toPos), CellInfo.create(fromPos, originalCell), self);
    // move fromPos (originalCell) -> toPos (getCell(toPos))
    moveCellSimply(event);
    setCell(event.getReplacementInfo().getPosition(), NIL);
    setCell(event.getReplacedInfo().getPosition(), event.getReplacementInfo().getCell());
    // notify
    // FIXME: conditions
    if( event.getReplacedInfo().getCell() <> NIL )then begin
      event.getReplacedInfo().getCell().notifyReplacedBy(event);
    end;
    if( event.getReplacementInfo().getCell() <> NIL )then begin
      event.getReplacementInfo().getCell().notifyReplacedSomething(event);
    end;
    if( not resultHasBeenSet )then begin // set result once
      moveCell := event.getReplacedInfo().getPosition();
      resultHasBeenSet := true;
    end;
    // reinit
    fromPos := toPos;
    //// fromPos -> toPos -> conds[fromPos.getX(), fromPos.getY()]
    //shift(fromPos, toPos, conds[fromPos.getX(), fromPos.getY()]);
  end;}
end;

constructor ERequiredMoveException.create(_dir:MovingDirection);
begin
  dir := _dir;
end;

function ERequiredMoveException.getDirection():MovingDirection;
begin
  getDirection := dir;
end;

function debCells(by, what:ICell):string;
begin
  debCells := interfaceToStr(what) + ' -> ' + interfaceToStr(by);
end;

constructor EMovingRefusedByReplacement.create(by, what:ICell);
begin
  inherited create('Moving refused by the replacement cell: '+debCells(what, by));
end;

constructor EMovingRefusedByTarget.create(by, what:ICell);
begin
  inherited create('Moving refused by the cell to replace: '+debCells(what, by));
end;

constructor EMovingArgue.create(_p1, _p2:IPosition);
begin
  inherited create('Cannot move to '+_p1.toString()+' and to '+_p2.toString()+ 'because of different positions!');
  p1 := _p1;
  p2 := _p2;
end;

function EMovingArgue.getFirstPosition():IPosition;
begin
  getFirstPosition := p1;
end;

function EMovingArgue.getSecondPosition():IPosition;
begin
  getSecondPosition := p2;
end;

constructor Mover.create(_g:Grid; x, y:integer; _allowOverflow:boolean);
begin
  create(_g, createPosition(x, y), _allowOverflow);
end;

constructor Mover.create(_g:Grid; _pos:IPosition; _allowOverflow:boolean);
begin
  g := _g;
  pos := _pos;
  allowOverflow := _allowOverflow;
  cf := ConstantCellFactory.create(NIL);
end;

procedure Mover.setValue(_cf:ICellFactory);
begin
  cf := _cf;
end;

function Mover.getCell():ICell;
begin
  getCell := g.getCell(getPosition());
end;

function Mover.getPosition():IPosition;
begin
  getPosition := pos;
end;

procedure Mover.setPosition(p:IPosition);
begin
  pos := p;
end;

procedure Mover.move(dir:MovingDirection);
begin
  move(dir, NIL);
end;

procedure Mover.move(dir:MovingDirection; commitCmd:ICommand);
begin
  //deb('cf:'+interfaceToStr(cf));
  try
    pos := g.moveCell(pos, cf, commitCmd, dir, allowOverflow);
  except on e:EMovingException do
    // deb('cannot be replaced:'+e.className()+': '+e.message);
    if(crashCommand <> NIL)then begin
      crashCommand.execute();
    end;
  end;
end;

procedure Mover.setCrashCommand(cmd:ICommand);
begin
  crashCommand := cmd;
end;

type NilCellValidator = class(StdClass, ICellValidator)
  public function isValid(c:ICell):boolean;
end;

function NilCellValidator.isValid(c:ICell):boolean;
begin
  isValid := c = NIL;
end;


var ncvi:NilCellValidator;
function NilCellValidator_getInstance():ICellValidator;
begin
  if( ncvi = NIL )then begin
    ncvi := NilCellValidator.create();
  end;
  NilCellValidator_getInstance := ncvi;
end;

begin
  ncvi := NIL;
end.