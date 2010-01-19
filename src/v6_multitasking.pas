unit v6_multitasking;
{$RANGECHECKS ON}

interface

uses v6_classes, v6_cmds;

type ITask = interface ['{ABB67DB7-4E9C-493A-BAA8-7973C5B133F1}'] // one task for task manager
  procedure runStep();// Runs one step. This method shoudn't block for a long time. Calling this method is atomic operation for TaskManager.
  procedure interrupt();
end;

type AbstractTask = class(StdClass, ITask)
  private interrupted:boolean;
  public constructor create();
  public procedure interrupt(); virtual;
  public procedure runStep(); virtual; abstract;
  protected function isInterrupted():boolean;
end;

{private} type PTaskElement = ^TaskElement;
  TaskElement = record
    next:PTaskElement;
    t:ITask;
  end;

// Manages more tasks using cooperative multitasking. The methods aren't thread-safe. However, they can be called from any subtask in a step because the task cannot "pause" executing.
type TaskManager = class (StdClass)// TODO: Task?
  private ad:AutoDisposer;
  private first, last:^TaskElement;
  private running:^boolean;
  private runningTask:^ITask;
  private stopCmd:ICommand;
  //private disposeTasks:boolean;
  public constructor create();
  //public destructor done(disposeTasks:boolean); virtual;
  //public destructor done(); virtual;
  //public destructor disposeTasks(); virtual;
  public destructor destroy(); override;
  public procedure add(t:ITask);// adds new task
  //public procedure setDisposeTasks(val:boolean);
  public procedure run();// runs all tasks and blocks until interrupted by stop()
  public function getStopCommand():ICommand;
  public procedure stop();// Interrupts all tasks - one step will be finished. There is currently no way to finish other tasks like InterruptedException in Java. The TaskManager can be reused - TaskManager.run() can be called.
  public function isRunning():boolean;  // Returns whether the tasks are running.
end;

implementation

uses sysutils;

type pboolean = ^boolean;
type PITask = ^ITask;

type StopCommand = class(StdClass, ICommand)
  private running:^boolean;
  private runningTask:^ITask;
  public constructor create(_running:pboolean; _runningTask:PITask);
  public procedure execute(); virtual;
end;

constructor StopCommand.create(_running:pboolean; _runningTask:PITask);
begin
  running := _running;
  runningTask := _runningTask;
end;

procedure StopCommand.execute();
begin
  if( not running^ )then begin
    raise Exception.create('The tasks are not running!');
  end;
  running^ := false;
  runningTask^.interrupt();
end;

constructor TaskManager.create();
begin
  ad := AutoDisposer.create();
  running := new(pboolean);
  runningTask := new(PITask);
  runningTask^ := NIL;
  stopCmd := StopCommand.create(running, runningTask);
  //ad.addInterface(stopCmd);
  first := NIL;
  last := NIL;
  running^ := false;
  //disposeTasks := false;
end;

{destructor TaskManager.done();
begin
  done(false);
end;

destructor TaskManager.disposeTasks();
begin
  done(true);
end;}

destructor TaskManager.destroy();
var next:^TaskElement;
begin
  inherited destroy();
  if( isRunning() ) then begin
    stop();
  end;
  // clear all tasks
  while( first <> NIL ) do begin
    next := first^.next; // backup the pointer
    // first^.t._release();
    {if(disposeTasks) then begin
      TObject(first^.t).free();
    end;}
    dispose(first);
    first := next;// move to the next element
  end;
  ad.destroy();
  dispose(running);
  dispose(runningTask);
end;

function TaskManager.isRunning():boolean;
begin
  isRunning := running^;
end;
 
procedure TaskManager.run();
var p:^TaskElement;
begin
  if( isRunning() ) then begin
    raise Exception.create('The tasks are already running!');
  end;
  running^ := true;
  p := NIL;
  while( isRunning() ) do begin
    if( p = NIL )then begin
      p := first;
    end else begin
      runningTask^ := p^.t;
      //deb('TaskManager.run(): run '+interfaceToStr(runningTask^));
      runningTask^.runStep();
      runningTask^ := NIL;
      p := p^.next;
    end;
  end;
end;

procedure TaskManager.add(t:ITask);
var te:^TaskElement;
begin
  // create new TaskElement
  te := new(PTaskElement);
  te^.next := NIL;
  te^.t := t;
  // put it to the end
  if( last = NIL )then begin
    // it will bw the only element
    last := te;
    first := te;
  end else begin
    last^.next := te;
    // "last" is not the last
    last := te;
  end;
  //t._addRef();
end;

procedure TaskManager.stop();
begin
  getStopCommand().execute();
end;

function TaskManager.getStopCommand():ICommand;
begin
  getStopCommand := stopCmd;
end;

{procedure TaskManager.setDisposeTasks(val:boolean);
begin
  disposeTasks := val;
end;}

constructor AbstractTask.create();
begin
  interrupted := false;
end;

function AbstractTask.isInterrupted():boolean;
begin
  isInterrupted := interrupted;
end;

procedure AbstractTask.interrupt();
begin
  interrupted := true;
end;

end.
