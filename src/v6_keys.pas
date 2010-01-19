unit v6_keys;
{$RANGECHECKS ON}
interface
uses v6_classes, v6_multitasking, v6_waiting, v6_cmds, v6_keyAcc, v6_debug;

type ArrowKey = (LEFT, RIGHT, UP, DOWN);

type SimpleKeyManager = class(StdClass, ICommand)
    private keys:array[#0..#255] of ICommand;
    private ad:AutoDisposer;
    private ka:IKeyAccess;
    public constructor create(_ka:IKeyAccess);
    public destructor destroy(); override;
    protected procedure disposeOnExit(o:StdClass);
    //protected procedure decRefOnExit(o:IInterface);
    public procedure execute(); virtual;
    public procedure setKey(key:char; cmd:ICommand);
  end;


type KeyManager = class(SimpleKeyManager, ITask)
    private arrowsManager:SimpleKeyManager;
    private wsf:IWaitingStrategyFactory;
    private interrupted:boolean;
    public constructor create(_wsf:IWaitingStrategyFactory; _ka:IKeyAccess);
    private function isInterrupted():boolean;
    public procedure setArrowKey(key:ArrowKey; cmd:ICommand);
    public procedure runStep(); virtual;
    public procedure interrupt(); virtual;
  end;

implementation

var arrows2keys:array[ArrowKey] of char;


constructor SimpleKeyManager.create(_ka:IKeyAccess);
var i:char;
begin
  ka := _ka;
  ad := AutoDisposer.create();
  // init array
  for i := #0 to #255 do begin
    keys[i] := NIL;
  end;
end;

destructor SimpleKeyManager.destroy();
begin
  ad.free();
  inherited destroy();
  // FIXME: order
end;

procedure SimpleKeyManager.disposeOnExit(o:StdClass);
begin
  ad.add(o);
end;

{procedure SimpleKeyManager.decRefOnExit(o:IInterface);
begin
  ad.addInterface(o);
end;}

procedure SimpleKeyManager.setKey(key:char; cmd:ICommand);
begin
  keys[key] := cmd;
end;

procedure SimpleKeyManager.execute();
var cmd:ICommand;
begin
  cmd := keys[ka.readPressedKey()];
  if(cmd <> NIL) then begin
    cmd.execute();
  end;
end;

constructor KeyManager.create(_wsf:IWaitingStrategyFactory; _ka:IKeyAccess);
begin
  inherited create(_ka);
  wsf := _wsf;
  arrowsManager := SimpleKeyManager.create(_ka);
  //decRefOnExit(arrowsManager);
  setKey(#0, arrowsManager);
  interrupted := false;
end;

function KeyManager.isInterrupted():boolean;
begin
  isInterrupted := interrupted;
end;

procedure KeyManager.interrupt();
begin
  interrupted := true;
end;

procedure KeyManager.runStep();
var ws:IWaitingStrategy;
begin
  ws := wsf.createWaitingStrategy();
  //ws._addRef();
  while( (not isInterrupted()) and (ws.haveToWait()) )do begin
    if( ka.isKeyPressed() ) then begin
      execute();
    end;
  end;
  deb('KeyManager.runStep(): exit');
  //ws._release();
  //TObject(ws).free();
end;


procedure KeyManager.setArrowKey(key:ArrowKey; cmd:ICommand);
begin
  arrowsManager.setKey(arrows2keys[key], cmd);
end;

initialization
  arrows2keys[UP] := #72;
  arrows2keys[LEFT] := #75;
  arrows2keys[RIGHT] := #77;
  arrows2keys[DOWN] := #80;
end.