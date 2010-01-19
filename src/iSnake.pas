program iSnake;
uses v6_debug, v6_gge, v6_gge_cells, v6_cmds, v6_keys, v6_geometrics, v6_keyacc, v6_multitasking, v6_waiting, v6_classes, v6_vars, graph, v6_graph, sysutils, crt;

{$RANGECHECKS ON}
{$COPERATORS ON}

type SnakeHeadCellCellFactory = class(StdClass, ICellFactory)
  private add:integer;
  private wcf:ICellFactory;
  public constructor create(_wcf:ICellFactory);
  public procedure inc();
  public function createInstance():ICell; virtual;
end;

constructor SnakeHeadCellCellFactory.create(_wcf:ICellFactory);
begin
  add := 0;
  wcf := _wcf;
end;

procedure SnakeHeadCellCellFactory.inc();
begin
  add += 1;
  deb('SnakeHeadCellCellFactory.inc()');
end;

function SnakeHeadCellCellFactory.createInstance():ICell;
begin
  if(add > 0)then begin
    createInstance := wcf.createInstance();
    dec(add);
  end;
end;

type ISnakeBodyCell = interface(ICell) ['{35441460-D617-4F40-B5E8-27970C5346B6}']
end;

type AbstractSnakeHeadCell = specialize AbstractLinkedDirectionHeadCell<ISnakeBodyCell>;

type SnakeHeadCell = class(AbstractSnakeHeadCell, ISpecial)
  private cf:SnakeHeadCellCellFactory;
  private ad:IAutoDisposer;
  //private id:longint;
  private color:word;
  public constructor create(_direction:MovingDirection; _sis:IIntSettable; _color:word);
  //public destructor destroy(); override;
  public procedure draw(pos:IRectangle; gpos:IPosition); override;
  protected function canMoveTo(c:ICell):boolean; override;
  protected procedure ate(); override;
  public function wrapCellFactory(wcf:ICellFactory):ICellFactory;
end;

constructor SnakeHeadCell.create(_direction:MovingDirection; _sis:IIntSettable; _color:word);
begin
  inherited create(_direction, _sis, false);
  ad := Autodisposer.create();
  cf := NIL;
  color := _color;
end;

{destructor SnakeHeadCell.destroy();
begin
  inherited destroy();
  //deb('-id', id);
end;}

procedure SnakeHeadCell.ate();
begin
  if(cf <> NIL)then begin
    cf.inc();
  end;
end;

function SnakeHeadCell.canMoveTo(c:ICell):boolean;
begin
  if( c <> NIL )then begin
    canMoveTo := supports(c, IEatableCell) or supports(c, IMovableCell);
  end else begin
    canMoveTo := true;
  end;
end;

function SnakeHeadCell.wrapCellFactory(wcf:ICellFactory):ICellFactory;
begin
  cf := SnakeHeadCellCellFactory.create(wcf);
  ad.addRef(cf);
  wrapCellFactory := cf;
end;

procedure SnakeHeadCell.draw(pos:IRectangle; gpos:IPosition);
begin
  setFillStyle(1, color);
  bar(pos{.getX1(), pos.getY1(), pos.getX2(), pos.getY2()});
  setColor(RED);
  line(pos.getX1(), pos.getY1(), pos.getX2(), pos.getY2());
  line(pos.getX1(), pos.getY2(), pos.getX2(), pos.getY1());
end;

type AbstractSnakeBodyCell = specialize AbstractLinkedDirectionBodyCell<ISnakeBodyCell>;

type SnakeBodyCell = class(AbstractSnakeBodyCell, ISnakeBodyCell)
  private color:word;
  public constructor create(dir:MovingDirection; next:ILinkedDirectionCell; _color:word);
  public procedure draw(pos:IRectangle; gpos:IPosition); override;
  protected function canMoveTo(c:ICell):boolean; override;
end;

constructor SnakeBodyCell.create(dir:MovingDirection; next:ILinkedDirectionCell; _color:word);
begin
  inherited create(dir, false, next);
  color := _color;
end;

function SnakeBodyCell.canMoveTo(c:ICell):boolean;
begin
  canMoveTo := supports(c, ILinkedDirectionCell);
end;

procedure SnakeBodyCell.draw(pos:IRectangle; gpos:IPosition);
{var p:IPosition;
var size:ISize;
var rect:IRectangle;}
var dir1, dir2:MovingDirection;
var rects:array of IRectangle;
var mdo:array [MovingDirection] of byte;
begin
  {
    6, 3, 0
    1, 4, 7
    2, 5, 8
  }
  mdo[LEFT] := 1;
  mdo[RIGHT] := 7;
  mdo[UP] := 3;
  mdo[DOWN] := 5;
  rects := pos div 3;
  // clear
  setFillStyle(1, WHITE);
  bar(pos);
  // fill "to"
  dir1 := getDirection();
  setBkColor(WHITE);
  setFillStyle(2, color);
  bar(rects[mdo[dir1]]);
  // fill "from" an "current"
  dir2 := MovingDirection_not(getOldDirection());
  setFillStyle(1, color);
  bar(rects[mdo[dir2]]);
  bar(rects[4]);
end;

type SnakeBodyCellFactory = class(StdClass, ILinkedDirectionCellFactory)
  private color:word;
  public constructor create(_color:word);
  public function createInstance(dir:MovingDirection; next:ILinkedDirectionCell):ILinkedDirectionCell; virtual;
end;

constructor SnakeBodyCellFactory.create(_color:word);
begin
  color := _color;
end;

function SnakeBodyCellFactory.createInstance(dir:MovingDirection; next:ILinkedDirectionCell):ILinkedDirectionCell;
begin
  createInstance := SnakeBodyCell.create(dir, next, color);
end;

type BrickCell = class(AbstractStraightMovableCell)
  public procedure draw(pos:IRectangle; gpos:IPosition); override;
end;

procedure BrickCell.draw(pos:IRectangle; gpos:IPosition);
begin
  setFillStyle(1, WHITE);
  bar(pos{.getX1(), pos.getY1(), pos.getX2(), pos.getY2()});
  setColor(BLUE);
  setFillStyle(1, YELLOW);
  bar3D(pos.getX1()+1, pos.getY1()+(pos.getSize().getHeight() div 3)+1, pos.getX2()-(pos.getSize().getHeight() div 3)-1, pos.getY2()-1, pos.getSize().getHeight() div 3, true);
end;

type TemporaryBrickCell = class(BrickCell)
  private mtl:integer;
  private c:ICell;
  public constructor create(_mtl:integer);
  public constructor create(_mtl:integer; _c:ICell);
  public procedure notifyMoved(event:IReplacementInfo); override;
  public procedure draw(pos:IRectangle; gpos:IPosition); override;
end;

constructor TemporaryBrickCell.create(_mtl:integer; _c:ICell);
begin
  mtl := _mtl;
  c := _c;
end;

constructor TemporaryBrickCell.create(_mtl:integer);
begin
  create(_mtl, NIL);
end;

procedure TemporaryBrickCell.notifyMoved(event:IReplacementInfo);
var myInfo :ICellInfo;
begin
  inherited notifyMoved(event);
  dec(mtl);
  myInfo := event.getReplacedInfo();
  if( mtl < 1 )then begin
    event.getGrid().setCell(myInfo.getPosition(), c);
  end else begin
    myInfo.repaint();
  end;
end;

procedure TemporaryBrickCell.draw(pos:IRectangle; gpos:IPosition);
begin
  inherited draw(pos, gpos);
  useTextSettingsType(createTextSettingsType(0, 0, 4, LEFTTEXT, TOPTEXT));
  outTextXY(pos.getX1()+5, pos.getY1()+5, intToStr(mtl));
end;

type WallCell = class(AbstractUnreplacableCell, ICell)
  public procedure draw(pos:IRectangle; gpos:IPosition); override;
end;
procedure WallCell.draw(pos:IRectangle; gpos:IPosition);
begin
  setFillStyle(1, GREEN);
  bar(pos{.getX1(), pos.getY1(), pos.getX2(), pos.getY2()});
end;

type FoodCell = class(AbstractEatableCell)
  public procedure draw(pos:IRectangle; gpos:IPosition); override;
end;
procedure FoodCell.draw(pos:IRectangle; gpos:IPosition);
begin
  setBkColor(BLACK);
  setFillStyle(1, BLACK);
  bar(pos{.getX1(), pos.getY1(), pos.getX2(), pos.getY2()});
  setColor(RED);
  //deb('------------BEFORE----------');
  //('pos:'+interfaceToStr(pos), pos.getMidX(), pos.getMidY(), pos.getMaxRadius());
  circle(pos.getMidX(), pos.getMidY(), pos.getMaxRadius());
  //deb('------------AFTER----------');
end;

type FoodCellFactory = class(StdClass, IEatableCellAteCommandFactory)
  public function createInstance(cmd:ICommand):AbstractEatableCell; virtual;
end;

function FoodCellFactory.createInstance(cmd:ICommand):AbstractEatableCell;
begin
  createInstance := FoodCell.create(cmd, 1);
end;

type CellType = (WALL, BRICK, NOTH);

function typeToCell(t:CellType):ICell;
var mtl:integer;
begin
  case t of
    WALL: typeToCell := WallCell.create();
    NOTH:  typeToCell := NIL;
    BRICK: begin
        mtl := random(5);
        if(mtl = 0)then begin
          typeToCell := BrickCell.create();
        end else begin
          typeToCell := TemporaryBrickCell.create(mtl);
        end;
      end;
  else
    raise Exception.create('Unknown CellType');
  end;
end;

function createGrid():Grid;
var g:Grid;
var game: array[0..17] of array[0..15] of CellType = (
  ( WALL, NOTH, NOTH, WALL, NOTH, NOTH,BRICK, WALL, WALL, NOTH, NOTH, WALL, NOTH, NOTH,BRICK, WALL),
  ( WALL, NOTH, NOTH, WALL, NOTH, NOTH, NOTH, WALL, WALL, NOTH, NOTH, WALL, NOTH, NOTH, NOTH, WALL),
  ( NOTH, NOTH, WALL, WALL, NOTH, NOTH, NOTH, NOTH, NOTH, NOTH, WALL, WALL, NOTH, NOTH, NOTH, NOTH),
  ( WALL, NOTH, NOTH, WALL, NOTH, NOTH, NOTH, WALL, WALL, NOTH, NOTH, WALL, NOTH, NOTH, NOTH, WALL),
  ( NOTH, NOTH, NOTH, NOTH, NOTH, NOTH, NOTH, WALL, NOTH, NOTH, NOTH, NOTH, NOTH, NOTH, NOTH, WALL),
  ( WALL, NOTH,BRICK, WALL, NOTH, NOTH, NOTH, WALL, WALL, NOTH,BRICK, WALL, NOTH, NOTH, NOTH, WALL),
  ( WALL, NOTH, NOTH, WALL, NOTH, NOTH, NOTH, WALL, WALL, NOTH, NOTH, WALL, NOTH, NOTH, NOTH, WALL),
  ( WALL, NOTH,BRICK, WALL, NOTH, NOTH,BRICK, WALL, WALL, NOTH,BRICK, WALL, NOTH, NOTH,BRICK, WALL),
  ( WALL, NOTH, NOTH, WALL, NOTH, NOTH,BRICK, WALL, WALL, NOTH, NOTH, WALL, NOTH, NOTH,BRICK, WALL),
  ( WALL, NOTH, NOTH, WALL, NOTH, NOTH, NOTH, WALL, WALL, NOTH, NOTH, WALL, NOTH, NOTH, NOTH, WALL),
  ( NOTH, NOTH, WALL, WALL, NOTH, NOTH, NOTH, NOTH, NOTH, NOTH, WALL, WALL, NOTH, NOTH, NOTH, NOTH),
  ( WALL, NOTH, NOTH, WALL, NOTH, NOTH, NOTH, WALL, WALL, NOTH, NOTH, WALL, NOTH, NOTH, NOTH, WALL),
  ( NOTH, NOTH, NOTH, NOTH, NOTH, NOTH, NOTH, WALL, NOTH, NOTH, NOTH, NOTH, NOTH, NOTH, NOTH, WALL),
  ( WALL, NOTH,BRICK, WALL, NOTH, NOTH, NOTH, WALL, WALL, NOTH,BRICK, WALL, NOTH, NOTH, NOTH, WALL),
  ( WALL, NOTH, NOTH, WALL, NOTH, NOTH, NOTH, WALL, WALL, NOTH, NOTH, WALL, NOTH, NOTH, NOTH, WALL),
  ( WALL, NOTH,BRICK, WALL, NOTH, NOTH,BRICK, WALL, WALL, NOTH,BRICK, WALL, NOTH, NOTH,BRICK, WALL),
  ( WALL, NOTH,BRICK, WALL, NOTH, NOTH,BRICK, WALL, WALL, NOTH,BRICK, WALL, NOTH, NOTH,BRICK, WALL),
  ( WALL, NOTH,BRICK, WALL, NOTH, NOTH,BRICK, WALL, WALL, NOTH,BRICK, WALL, NOTH, NOTH,BRICK, WALL)
);
var i, j:integer;
//var theEater:ILinkedDirectionCell;
begin
  g := Grid.create(0, 50, getMaxX(), getMaxY()-50, length(game), length(game[0]), ColorSpaceDrawer.create(WHITE));
  for i := low(game) to high(game) do begin
    for j := low(game[i]) to high(game[i]) do begin
      g.setCell(i, j, typeToCell(game[i, j]));
    end;
  end;
  createGrid := g;
end;


var g:Grid;
  ad:IAutoDisposer;
  tm:TaskManager;
  km:KeyManager;
  p:MultiPaintable;
  posX:integer;
  
function addSnake(pos:IPosition; dir:MovingDirection; color:word):ISettableMover;
var m:DirectionCellMover;
  head:SnakeHeadCell;
  sbcf:ILinkedDirectionCellFactory;
  scoreDrawer:TextDrawer;
begin
  scoreDrawer := TextDrawer.create(BLACK, WHITE, posX, 0, createTextSettingsType(0, 0, 4, LEFTTEXT, TOPTEXT), '0');
  posX += 100;
  head := SnakeHeadCell.create(LEFT, IntegerToStringSettable.create(scoreDrawer), color);
  sbcf := SnakeBodyCellFactory.create(color);
  m := DirectionCellMover.create(g, head, pos, true)
    .addCell(sbcf, LEFT)
    .addCell(sbcf, LEFT)
    .addCell(sbcf, LEFT)
    {.addCell(sbcf, LEFT)
    .addCell(sbcf, LEFT)
    .addCell(sbcf, LEFT)
    .addCell(sbcf, LEFT)
    .addCell(sbcf, LEFT)};
  m.setCrashCommand(m.getDeletionCommand());
  m.setValue(head.wrapCellFactory(m.wrapCellFactory(sbcf)));
  addSnake := m; // TODO: wrap by BufferedSettableMover
  //ad.addRef(scoreDrawer);
  p.add(scoreDrawer);
  tm.add(MovingSetterTask.create(m));
end;

var sm:ISettableMover;
var fm:FoodManager;
begin
  {$IFDEF deb}
  v6_debug.setOutput(FileOutput.create('iSnake.log'));
  {$ENDIF}
  randomize();
  posX := 0;
  ad := Autodisposer.create();
  openGraph(ad);
  p := MultiPaintable.create();
  ad.addRef(p);
  g := createGrid();
  p.add(g);
  ad.addRef(g);
  tm := TaskManager.create();
  ad.addRef(tm);
  km := KeyManager.create(createIntervalWaitingStrategyFactory(0.5), WinCrtKeyAccess_getInstance());
  tm.add(km);
  // add first player
  sm := addSnake(createPosition(2, 13), LEFT, BLUE);
  mapArrowKeysToMovingCommands(km, sm);
  // add second player - another key mapping
  sm := addSnake(createPosition(5, 5), LEFT, 8);
  km.setKey('a', MovingSetterCommand.create(sm, v6_geometrics.LEFT));
  km.setKey('d', MovingSetterCommand.create(sm, v6_geometrics.RIGHT));
  km.setKey('w', MovingSetterCommand.create(sm, v6_geometrics.UP));
  km.setKey('s', MovingSetterCommand.create(sm, v6_geometrics.DOWN));
  
  km.setKey(#27, tm.getStopCommand());
  
  fm := FoodManager.create(g, FoodCellFactory.create(), 5);
  ad.addRef(fm);
  tm.add(fm);
  
  p.setPaint(true); // show
  
  tm.run();// RUN!!!
end.