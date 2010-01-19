unit v6_gge_cells;
{$RANGECHECKS ON}
{$COPERATORS ON}

interface
uses v6_classes, v6_geometrics, v6_gge, v6_game, v6_vars, sysutils, v6_multitasking, v6_cmds;

{private} type pboolean = ^boolean;

type AbstractCell = class(StdClass, ICell)
  public procedure draw(pos:IRectangle; gpos:IPosition); virtual; abstract;
  public function canBeReplacedBy(event:IReplacementInfo):boolean; virtual; abstract;
  public function canReplace(event:IReplacementInfo; dir:MovingDirection):boolean; virtual;
  public procedure notifyReplacedBy(event:IReplacementInfo); virtual;
  public procedure notifyReplacedSomething(event:IReplacementInfo); virtual;
  public procedure notifyMoved(event:IReplacementInfo); virtual;
end;

type IDirectionCell = interface(ICell) ['{1723F2C8-E280-44CE-AB27-F9D515066C30}']
  procedure setDirection(d:MovingDirection);
  function getDirection():MovingDirection;
  function getOldDirection():MovingDirection;
end;

type IEatableCell = interface(ICell) ['{48719CC1-3EBA-4C24-BFAE-49C829CE5D5F}']
end;

type AbstractEatableCell = class(AbstractCell, IEatableCell)
  private ateCmd:ICommand;
  private score:integer;
  public constructor create();
  public constructor create(_score:integer);
  public constructor create(_ateCmd:ICommand; _score:integer);
  public procedure notifyReplacedBy(event:IReplacementInfo); override;
  public function canBeReplacedBy(event:IReplacementInfo):boolean; override;
end;

type IEatableCellAteCommandFactory = specialize IParametrisedFactory<ICommand, AbstractEatableCell>;

type ILinkedDirectionCell = interface(IDirectionCell) ['{D622E815-A393-451D-A84D-9785CE1B31F0}']
  procedure setNext(next:ILinkedDirectionCell);
  function getNext():ILinkedDirectionCell;
  //function isFirst():boolean;
end;

type ILinkedDirectionCellFactory = interface ['{F943EBFB-BA46-4ED1-A842-33F7B34BC0B1}']
  function createInstance(dir:MovingDirection; next:ILinkedDirectionCell):ILinkedDirectionCell;
end;

function createCellGroupMoverTask(cgm:ISettableMover):ITask;

{private} type pint = ^integer;

type FoodManager = class(AbstractTask)
  private g:Grid;
  private foodf:IEatableCellAteCommandFactory;
  private max:integer;
  private curr:pint;
  private pval:ICellValidator;
  private decCmd:ICommand;
  public constructor create(_g:Grid; _foodf:IEatableCellAteCommandFactory; _max:integer);
  private procedure addCellIfPossible();
  private function createPos():IPosition;
  public destructor destroy(); override;
  public procedure runStep(); override;
end;

type IMovableCell = interface ['{4EC7823C-8E46-4663-B4C9-B9F20909BC85}']
end;

type AbstractStraightMovableCell = class(AbstractCell, IMovableCell)
  function canBeReplacedBy(event:IReplacementInfo):boolean; override;
end;

type AbstractPermareplCell = class(AbstractCell)
  private allowReplace:boolean;
  public constructor create(_allowReplace:boolean);
  public function canBeReplacedBy(event:IReplacementInfo):boolean; override;
end;

type AbstractUnreplacableCell = class(AbstractPermareplCell)
  public constructor create();
end;

type AbstractDirectionCell = class(AbstractUnreplacableCell, IDirectionCell)
  private direction:MovingDirection;
  private oldDir:MovingDirection;
  private oldDirSet:boolean;
  private repaintOnUpdate:boolean;
  public constructor create(_direction:MovingDirection; _repaintOnUpdate:boolean);
  public procedure setDirection(d:MovingDirection); virtual;
  public function getDirection():MovingDirection; virtual;
  public function getOldDirection():MovingDirection;
  protected function canMoveTo(c:ICell):boolean; virtual; abstract;
  protected function canBeMovedBy(c:ICellInfo):boolean; virtual; abstract;
  protected procedure resetOldDirection();
  //public procedure notifyMoved(event:IReplacementInfo); override;
  public function canBeReplacedBy(event:IReplacementInfo):boolean; override;
end;

type AbstractLinkedDirectionCell = class(AbstractDirectionCell, ILinkedDirectionCell)
  private next:ILinkedDirectionCell;
  private first:boolean;
  public constructor create(_direction:MovingDirection; _repaintOnUpdate:boolean; _next:ILinkedDirectionCell; _first:boolean);
  public procedure setNext(_next:ILinkedDirectionCell); virtual;
  public function getNext():ILinkedDirectionCell; virtual;
  public procedure notifyMoved(event:IReplacementInfo); override;
end;

type generic AbstractLinkedDirectionBodyCell<_T> = class(AbstractLinkedDirectionCell)
  public constructor create(_direction:MovingDirection; _repaintOnUpdate:boolean; _next:ILinkedDirectionCell);
  protected function canBeMovedBy(c:ICellInfo):boolean; override;
end;

type generic AbstractLinkedDirectionHeadCell<_T> = class(AbstractLinkedDirectionCell, IAddableScore)
  private score:integer;
  private sis:IIntSettable;
  public constructor create(_direction:MovingDirection; _sis:IIntSettable; _repaintOnUpdate:boolean);
  public procedure addScore(s:integer); virtual;
  protected function canBeMovedBy(c:ICellInfo):boolean; override;
  protected procedure ate(); virtual;
end;

{private}type MovingDirectionReference = specialize Reference<MovingDirection>;

type DirectionCellMover = class(StdClass, ISettableMover, ISettableCellFactory)
  private movedCommand:ICommand;
  private odr:MovingDirectionReference;
  private valid:pboolean;
  private head{, tail}:IDirectionCell;
  private tailMover:Mover;
  private ad:IAutoDisposer;
  private addedCellFactory:ICellFactory;
  private replacedCellValidator:ICellValidator;
  private deletionCmd:ICommand;
  //private crashCommand:ICommand;
  private g:Grid;
  private pdc:IPositionDirectionConverter;
  public constructor create(_g:Grid; _head:IDirectionCell; _headPos:IPosition; allowOverflow:boolean);
  public destructor destroy(); override;
  private function getTail():ILinkedDirectionCell;
  private property tail:ILinkedDirectionCell read getTail;
  //private procedure checkChainIntegrity();
  public function addCell(cell:ILinkedDirectionCell{; dir:MovingDirection - it is not neccessary because of info in the cell}):DirectionCellMover;
  public function setCrashCommand(cmd:ICommand):DirectionCellMover;
  public function addCell(cellFactory:ILinkedDirectionCellFactory; dir:MovingDirection):DirectionCellMover;
  public function setAddedCellFactory(cf:ICellFactory):DirectionCellMover;
  public function setReplacedCellValidator(cv:ICellValidator):DirectionCellMover;
  public function setMovedCommand(cmd:ICommand):DirectionCellMover;
  public function getDeletionCommand():ICommand;
  public function wrapCellFactory(f:ILinkedDirectionCellFactory):ICellFactory;
  public procedure move(); virtual;
  public procedure setValue(dir:MovingDirection); virtual;
  public procedure setValue(_cf:ICellFactory); virtual;
end;

{TODO: type BufferedSettableMover = class(StdClass, ISettableMover)
  private mover:ISettableMover;
  public constructor create(m:ISettableMover);
  public procedure move(); virtual;
  public procedure setValue(md:MovingDirection); virtual;
end;}

type AbstractScoreableCell = class(AbstractUnreplacableCell, IAddableScore)
  private score:integer;
  private sis:IIntSettable;
  public constructor create(_sis:IIntSettable);
  public procedure addScore(s:integer); virtual;
end;

implementation
uses crt, v6_debug;

procedure AbstractCell.notifyReplacedBy(event:IReplacementInfo);
begin
end;

procedure AbstractCell.notifyMoved(event:IReplacementInfo);
begin
end;

procedure AbstractCell.notifyReplacedSomething(event:IReplacementInfo);
begin
end;

function AbstractCell.canReplace(event:IReplacementInfo; dir:MovingDirection):boolean;
begin
  canReplace := true;
end;

constructor AbstractPermareplCell.create(_allowReplace:boolean);
begin
  inherited create();
  allowReplace := _allowReplace;
end;

function AbstractPermareplCell.canBeReplacedBy(event:IReplacementInfo):boolean;
begin
  //deb('cells: '+interfaceToStr(event.getReplacedInfo().getCell()) + ' -> ' + interfaceToStr(event.getReplacementInfo().getCell()));
  canBeReplacedBy := allowReplace;
end;

constructor AbstractUnreplacableCell.create();
begin
  inherited create(false);
end;

constructor AbstractScoreableCell.create(_sis:IIntSettable);
begin
  score := 0;
  sis := _sis;
end;

procedure AbstractScoreableCell.addScore(s:integer);
begin
  inc(score, s);
  sis.setValue(score);
end;

constructor AbstractEatableCell.create();
begin
  create(1);
end;

constructor AbstractEatableCell.create(_score:integer);
begin
  create(NIL, _score);
end;

constructor AbstractEatableCell.create(_ateCmd:ICommand; _score:integer);
begin
  inherited create();
  ateCmd := _ateCmd;
  score := _score;
end;

function AbstractEatableCell.canBeReplacedBy(event:IReplacementInfo):boolean;
begin
  canBeReplacedBy := supports(event.getReplacementInfo().getCell(), IAddableScore);
end;

procedure AbstractEatableCell.notifyReplacedBy(event:IReplacementInfo);
var another:ICell;
begin
  //deb('AbstractEatableCell.notifyReplacedBy(IReplacementInfo): enter');
  another := event.getReplacementInfo().getCell();
  if(supports(another, IAddableScore)) then begin
    (another as IAddableScore).addScore(score);
    if(ateCmd <> NIL)then begin
      ateCmd.execute();
    end;
  end;
end;

function AbstractStraightMovableCell.canBeReplacedBy(event:IReplacementInfo):boolean;
begin
  //if( supports(event.getReplacementInfo().getCell(), _T))then begin
  //raise ERequiredMoveException.create(event.getPositionDirectionConverter().calcDirectionFromPositions(event.getReplacementInfo().getPosition(), event.getReplacedInfo().getPosition()));
  raise ERequiredMoveException.create(event.getDirection());
  //end;
  canBeReplacedBy := false;
end;

constructor AbstractDirectionCell.create(_direction:MovingDirection; _repaintOnUpdate:boolean);
begin
  direction := _direction;
  oldDir := _direction;
  oldDirSet := false;
  repaintOnUpdate := _repaintOnUpdate;
end;

procedure AbstractDirectionCell.setDirection(d:MovingDirection);
begin
  if(not oldDirSet)then begin
    oldDirSet := true;
    oldDir := direction;
  end;
  direction := d;
end;

procedure AbstractDirectionCell.resetOldDirection();
begin
  oldDirSet := false;
  oldDir := direction;
end;

function AbstractDirectionCell.getDirection():MovingDirection;
begin
  getDirection := direction;
end;

{procedure AbstractDirectionCell.notifyMoved(event:IReplacementInfo);
var od:MovingDirection;
begin
  deb('AbstractDirectionCell/'+className()+'.notifyMoved(IReplacementInfo):start');
  od := getDirection();
  setDirection(next.getOldDirection());
  if(repaintOnUpdate and (od <> getDirection()) )then begin
    event.getReplacementInfo().repaint();
  end;
end;}

function AbstractDirectionCell.canBeReplacedBy(event:IReplacementInfo):boolean;
begin
  deb('--------------------------------------------');
  deb('event.getReplacementInfo().getCell()', event.getReplacementInfo().getCell());
  deb('event.getReplacedInfo().getCell()', event.getReplacedInfo().getCell());
  deb('canBeMovedBy(event.getReplacementInfo()): ', canBeMovedBy(event.getReplacementInfo()));
  //deb('//------------------------------------------');
  if( canBeMovedBy(event.getReplacementInfo()) and canMoveTo(event.getGrid().getCell(event.getPositionDirectionConverter().calcNewPosition(event.getReplacedInfo().getPosition(), getDirection()))) )then begin
    raise ERequiredMoveException.create(getDirection());
  end else begin
    canBeReplacedBy := false;
  end;
end;

function AbstractDirectionCell.getOldDirection():MovingDirection;
begin
  getOldDirection := oldDir;
end;

type MoverPositionFactory = class(StdClass, IPositionFactory)
  private m:Mover;
  public constructor create(_m:Mover);
  public function createInstance():IPosition;
end;

constructor MoverPositionFactory.create(_m:Mover);
begin
  m := _m;
end;

function MoverPositionFactory.createInstance():IPosition;
begin
  createInstance := m.getPosition();
end;

type DeletionCommand = class(StdClass, ICommand)
  private g:Grid;
  private pdc:IPositionDirectionConverter;
  private startFactory:IPositionFactory;
  private valid:pboolean;
  public constructor create(_g:Grid; _pdc:IPositionDirectionConverter; _startFactory:IPositionFactory; _valid:pboolean);
  public procedure execute(); virtual;
end;

constructor DeletionCommand.create(_g:Grid; _pdc:IPositionDirectionConverter; _startFactory:IPositionFactory; _valid:pboolean);
begin
  g := _g;
  pdc := _pdc;
  startFactory := _startFactory;
  valid := _valid;
end;

procedure DeletionCommand.execute();
var c:ILinkedDirectionCell;
  p:IPosition;
begin
  p := startFactory.createInstance();
  c := g.getCell(p) as ILinkedDirectionCell;
  while(c.getNext() <> NIL)do begin
    c := g.getCell(p) as ILinkedDirectionCell;
    g.setCell(p, NIL);
    deb('p:' + p);
    deb('c:' + c);
    p := pdc.calcNewPosition(p, c.getDirection());
  end;
  valid^ := false;
end;

constructor DirectionCellMover.create(_g:Grid; _head:IDirectionCell; _headPos:IPosition; allowOverflow:boolean);
begin
  inherited create();
  //crashCommand := NIL;
  //deb('');
  movedCommand := NIL;
  valid := new(pboolean);
  valid^ := true;
  g := _g;
  //deb('g:'+g);
  ad := AutoDisposer.create();
  g.setCell(_headPos, _head);
  head := _head;
  //headPos := _headPos;
  odr := MovingDirectionReference.create();
  ad.addRef(odr);
  tailMover := Mover.create(_g, _headPos, allowOverflow);
  ad.addRef(tailMover);
  //tail := head;
  pdc := createRectanglePositionDirectionConverter(_g.getSize(), allowOverflow);
  addedCellFactory := ConstantCellFactory.create(NIL);
  replacedCellValidator := NilCellValidator_getInstance();
  deletionCmd := DeletionCommand.create(g, pdc, MoverPositionFactory.create(tailMover), valid);
end;

destructor DirectionCellMover.destroy();
begin
  inherited destroy();
  dispose(valid);
end;

function DirectionCellMover.setMovedCommand(cmd:ICommand):DirectionCellMover;
begin
  movedCommand := cmd;
  setMovedCommand := self;
end;

procedure DirectionCellMover.setValue(_cf:ICellFactory);
begin
  tailMover.setValue(_cf);
end;

//type MovingDirectionReference = specialize Reference<MovingDirection>;

type DirectionCellMover_CellFactoryWrapper = class(StdClass, ICellFactory)
  private tailMover:Mover;
  private f:ILinkedDirectionCellFactory;
  private dir:MovingDirectionReference;
  public constructor create(_dir:MovingDirectionReference; _tailMover:Mover; _f:ILinkedDirectionCellFactory);
  public function createInstance():ICell; virtual;
end;

constructor DirectionCellMover_CellFactoryWrapper.create(_dir:MovingDirectionReference; _tailMover:Mover; _f:ILinkedDirectionCellFactory);
begin
  tailMover := _tailMover;
  f := _f;
  dir := _dir;
end;

function DirectionCellMover_CellFactoryWrapper.createInstance():ICell;
var tc:ILinkedDirectionCell;
begin
  tc := tailMover.getCell() as ILinkedDirectionCell;
  createInstance := f.createInstance(dir.get(), tc);
end;

function DirectionCellMover.wrapCellFactory(f:ILinkedDirectionCellFactory):ICellFactory;
begin
  wrapCellFactory := DirectionCellMover_CellFactoryWrapper.create(odr, tailMover, f);
end;

function DirectionCellMover.getTail():ILinkedDirectionCell;
begin
  getTail := tailMover.getCell() as ILinkedDirectionCell;
end;

function DirectionCellMover.getDeletionCommand():ICommand;
begin
  getDeletionCommand := deletionCmd;
end;

function DirectionCellMover.setCrashCommand(cmd:ICommand):DirectionCellMover;
begin
  //crashCommand := cmd;
  tailMover.setCrashCommand(cmd);
  setCrashCommand := self;
end;

function DirectionCellMover.setAddedCellFactory(cf:ICellFactory):DirectionCellMover;
begin
  addedCellFactory := cf;
  setAddedCellFactory := self;
end;

function DirectionCellMover.setReplacedCellValidator(cv:ICellValidator):DirectionCellMover;
begin
  replacedCellValidator := cv;
  setReplacedCellValidator := self;
end;

function DirectionCellMover.addCell(cell:ILinkedDirectionCell):DirectionCellMover;
var pos:IPosition;
begin
  pos := pdc.calcNewPosition(tailMover.getPosition(), MovingDirection_not(cell.getDirection()));
  tailMover.setPosition(pos);
  g.setCell(pos, cell);
  //tail := cell;
  addCell := self;
end;

procedure DirectionCellMover.setValue(dir:MovingDirection);
begin
  head.setDirection(dir);
end;

type DirectionUpdater = class(StdClass, ICommand)
  private dc:ILinkedDirectionCell;
  public constructor create(_dc:ILinkedDirectionCell);
  public procedure execute(); virtual;
end;

constructor DirectionUpdater.create(_dc:ILinkedDirectionCell);
begin
  dc := _dc;
end;

procedure DirectionUpdater.execute();
var c:ILinkedDirectionCell;
begin
  deb('dc:', interfaceToStr(dc));
  c := dc;
  while(c.getNext() <> NIL)do begin
    deb('c.getNext():', interfaceToStr(c.getNext()));
    c.setDirection(c.getNext().getDirection());
    //updateDirection(dc.getNext());
    c := c.getNext();
  end
end;

{function deb(p:IPosition):IPosition;
begin
  deb('pos', interfaceToStr(p));
  deb := p;
end;}

{procedure DirectionCellMover.checkChainIntegrity();
var c:ILinkedDirectionCell;
var p:IPosition;
begin
  c := tailMover.getCell() as ILinkedDirectionCell;
  p := tailMover.getPosition();
  while(c <> NIL)do begin
    deb('pos:'+p);
    deb('cell:' + c);
    deb('g.getCell(p):' + g.getCell(p));
    deb('c = g.getCell(p)', g.getCell(p) = c);
    if( (g.getCell(p) <> c) and (not supports(c, ISpecial))) then begin
      crt.readkey();
      raise Exception.create('g.getCell(p) <> c');
    end;
    p := pdc.calcNewPosition(p, c.getDirection());
    c := c.getNext();
  end;
end;
}
procedure DirectionCellMover.move();
var originalPosition:IPosition;
var newCell:ICell;
begin
  if(valid^)then begin
    //checkChainIntegrity();
    originalPosition := tailMover.getPosition();
    odr.setValue((tailMover.getCell() as ILinkedDirectionCell).getDirection());
    deb('dir', MovingDirection_toString(odr.get()));
    //deb('g:'+g);
    tailMover.move(tail.getDirection(), DirectionUpdater.create(g.getCell(tailMover.getPosition()) as ILinkedDirectionCell));
    //updateDirection(g.getCell(tailMover.getPosition()) as ILinkedDirectionCell);
    newCell := addedCellFactory.createInstance();
    if( newCell <> NIL ) then begin
      if(replacedCellValidator.isValid(g.getCell(originalPosition))) then begin
        g.setCell(originalPosition, newCell);
        tailMover.setPosition(originalPosition);
      end else begin
        deb('invalid cell');
      end;
    end;
    if( movedCommand <> NIL )then begin
      movedCommand.execute();
    end;
  end;
end;

constructor AbstractLinkedDirectionCell.create(_direction:MovingDirection; _repaintOnUpdate:boolean; _next:ILinkedDirectionCell; _first:boolean);
begin
  inherited create(_direction, _repaintOnUpdate);
  next := _next;
  first := _first;
end;

procedure AbstractLinkedDirectionCell.setNext(_next:ILinkedDirectionCell);
begin
  next := _next;
end;

function AbstractLinkedDirectionCell.getNext():ILinkedDirectionCell;
begin
  getNext := next;
end;

procedure AbstractLinkedDirectionCell.notifyMoved(event:IReplacementInfo);
begin
  //deb('AbstractLinkedDirectionCell/'+className()+'.notifyMoved(IReplacementInfo):start');
  {if( first )then begin
    if( next <> NIL )then begin
      next.setDirection(getOldDirection());
    end;
  end;
  if( next <> NIL ) then begin
    setDirection(next.getOldDirection());
  end;}
  resetOldDirection();
  {event.getReplacementInfo().repaint();}
  inherited notifyMoved(event);
end;

type CellGroupMoverTask = class(AbstractTask)
  private cgm:ISettableMover;
  public constructor create(_cgm:ISettableMover);
  public procedure runStep(); override;
end;

function createCellGroupMoverTask(cgm:ISettableMover):ITask;
begin
  createCellGroupMoverTask := CellGroupMoverTask.create(cgm);
end;

constructor CellGroupMoverTask.create(_cgm:ISettableMover);
begin
  cgm := _cgm;
end;

procedure CellGroupMoverTask.runStep();
begin
  cgm.move();
end;

constructor AbstractLinkedDirectionBodyCell.create(_direction:MovingDirection; _repaintOnUpdate:boolean; _next:ILinkedDirectionCell);
begin
  inherited create(_direction, _repaintOnUpdate, _next, false);
end;

function AbstractLinkedDirectionBodyCell.canBeMovedBy(c:ICellInfo):boolean;
begin
  deb('::::c.getCell()'+c.getCell());
  canBeMovedBy := supports(c.getCell(), _T);
end;

constructor AbstractLinkedDirectionHeadCell.create(_direction:MovingDirection; _sis:IIntSettable; _repaintOnUpdate:boolean);
begin
  inherited create(_direction, _repaintOnUpdate, NIL, true);
  sis := _sis;
  score := 0;
end;

function AbstractLinkedDirectionHeadCell.canBeMovedBy(c:ICellInfo):boolean;
begin
  deb('::::c.getCell()'+c.getCell());
  canBeMovedBy := supports(c.getCell(), _T);
end;

procedure AbstractLinkedDirectionHeadCell.ate();
begin
end;

procedure AbstractLinkedDirectionHeadCell.addScore(s:integer);
begin
  deb('AbstractLinkedDirectionHeadCell.addScore('+intToStr(s)+')');
  inc(score, s);
  sis.setValue(score);
  ate();
end;

function DirectionCellMover.addCell(cellFactory:ILinkedDirectionCellFactory; dir:MovingDirection):DirectionCellMover;
begin
  addCell(cellFactory.createInstance(dir, g.getCell(tailMover.getPosition()) as ILinkedDirectionCell));
  addCell := self;
end;

constructor FoodManager.create(_g:Grid; _foodf:IEatableCellAteCommandFactory; _max:integer);
begin
  g := _g;
  foodf := _foodf;
  max := _max;
  curr := new(pint);
  curr^ := 0;
  pval := NilCellValidator_getInstance();
  decCmd := IntDecreaseCommand.create(curr);
end;

destructor FoodManager.destroy();
begin
  inherited destroy();
  dispose(curr);
end;

procedure FoodManager.addCellIfPossible();
var pos:IPosition;
begin
  pos := createPos();
  if(pos <> NIL)then begin
    g.setCell(pos, foodf.createInstance(decCmd));
  end;
end;

function FoodManager.createPos():IPosition;
const MAX_TRIES = 5;// TODO: use a Strategy and Factory
var p:IPosition;
var i:integer;
var valid:boolean;
begin
  i := 0;
  repeat
    p := createPosition(random(g.getSize().getWidth()), random(g.getSize().getHeight()));
    i += 1;
    valid := pval.isValid(g.getCell(p));
    // FIXME: crowded
  until( ( i > MAX_TRIES ) or valid );
  if( valid )then begin
    createPos := p;
  end else begin
    createPos := NIL;
  end;
end;

procedure FoodManager.runStep();

begin
  while( curr^ < max ) do begin
    addCellIfPossible();
    inc(curr^);
  end;
end;

{constructor BufferedSettableMover.create(m:ISettableMover);
begin
  mover := m;
end;

procedure BufferedSettableMover.move(); virtual;
procedure BufferedSettableMover.setValue(md:MovingDirection); virtual;}

end.
