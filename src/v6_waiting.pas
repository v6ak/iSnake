unit v6_waiting;
{$RANGECHECKS ON}

// I know that active waiting is messy. However, I do it in Pascal only. I use Pascal only for school project. If we're taught these messy algorithms instead of listeners, it's OK to use it for a school project. I didn't try to find API for better way because:
// 1) When I'm UTFSEing about Pascal, I usually find another things.
// 2) I needn't. (See above.)

interface
uses v6_classes, sysutils;
// I am using time() directly without a factory because I'm bored by writting object wrappers. I will not need use TimeFactory for the Dependency Injection Pattern (see http://en.wikipedia.org/wiki/Dependency_injection ).

type IWaitingStrategy = interface ['{DB096EC1-7CB5-42A5-9145-EF8B93AA4F66}']
    function haveToWait():boolean;// This is the ugly and messy design. (See above.)
  end;

type IWaitingStrategyFactory = interface ['{FB12F816-3B33-4CBD-BA4D-14E8F8235E5D}']
  function createWaitingStrategy():IWaitingStrategy;
end;

type TimeWaitingStrategy = class(StdClass, IWaitingStrategy)
  private timeUntil:TDateTime;
  public constructor create(_timeUntil:TDateTime);
  public function haveToWait():boolean; virtual;
end;

function createIntervalWaitingStrategyFactory(start:TDateTime; interval:integer):IWaitingStrategyFactory;

function createIntervalWaitingStrategyFactory(start:TDateTime; interval:real):IWaitingStrategyFactory;

function createIntervalWaitingStrategyFactory({start:TDateTime = now; }interval:real):IWaitingStrategyFactory;

function createIntervalWaitingStrategyFactory({start:TDateTime = now; }interval:integer):IWaitingStrategyFactory;

function createInfiniteWaitingStrategyFactory():IWaitingStrategyFactory;

implementation

type IntervalWaitingStrategyFactory = class(StdClass, IWaitingStrategyFactory)
  private curr:TDateTime;
  private interval:TDateTime;
  public constructor create(_start:TDateTime; _interval:real);
  public function createWaitingStrategy():IWaitingStrategy; virtual;
end;

constructor IntervalWaitingStrategyFactory.create(_start:TDateTime; _interval:real);
begin
  curr := _start;
  interval := _interval/24/60/60;
end;

function IntervalWaitingStrategyFactory.createWaitingStrategy():IWaitingStrategy;
begin
  curr := curr + interval;
  createWaitingStrategy := TimeWaitingStrategy.create(curr);
end;

function createIntervalWaitingStrategyFactory(start:TDateTime; interval:integer):IWaitingStrategyFactory;
begin
  createIntervalWaitingStrategyFactory := createIntervalWaitingStrategyFactory(start, interval/1000);
end;

function createIntervalWaitingStrategyFactory(start:TDateTime; interval:real):IWaitingStrategyFactory;
begin
  createIntervalWaitingStrategyFactory := IntervalWaitingStrategyFactory.create(start, interval);
end;

function createIntervalWaitingStrategyFactory({start:TDateTime = now; }interval:integer):IWaitingStrategyFactory;
begin
  createIntervalWaitingStrategyFactory := createIntervalWaitingStrategyFactory(interval/1000);
end;

function createIntervalWaitingStrategyFactory({start:TDateTime = now; }interval:real):IWaitingStrategyFactory;
begin
  createIntervalWaitingStrategyFactory := createIntervalWaitingStrategyFactory(time(), interval);
end;

constructor TimeWaitingStrategy.create(_timeUntil:TDateTime);
begin
  timeUntil := _timeUntil;
end;

function TimeWaitingStrategy.haveToWait():boolean;
begin
  //deb(time(), timeUntil);
  haveToWait := time() < timeUntil; 
end;

type ConstantWaitingStrategy = class(StdClass, IWaitingStrategy)
    private val:boolean;
    public constructor create(_val:boolean);
    public function haveToWait():boolean; virtual;
  end;

constructor ConstantWaitingStrategy.create(_val:boolean);
begin
  val := _val;
end;

function ConstantWaitingStrategy.haveToWait():boolean;
begin
  haveToWait := val;
end;

type InfiniteWaitingStrategyFactory = class(StdClass, IWaitingStrategyFactory)
    public constructor create();
    public function createWaitingStrategy():IWaitingStrategy; virtual;
  end;

constructor InfiniteWaitingStrategyFactory.create();
begin
end;

function InfiniteWaitingStrategyFactory.createWaitingStrategy():IWaitingStrategy;
begin
  createWaitingStrategy := ConstantWaitingStrategy.create(true);
end;

function createInfiniteWaitingStrategyFactory():IWaitingStrategyFactory;
begin
  createInfiniteWaitingStrategyFactory := InfiniteWaitingStrategyFactory.create();
end;

end.