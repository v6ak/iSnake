unit v6_cmds;
{$RANGECHECKS ON}

interface
uses v6_classes;

type ICommand = interface ['{1A732E50-A104-4587-A281-F19FBE6DA1D9}']
  procedure execute();
end;
  
type ProceduralCommand = class(StdClass, ICommand)
  private proc:procedure;
  public constructor create(_proc:SimpleProcedure);
  public procedure execute(); virtual;
end;  

{private} type pint = ^integer;

type IntDecreaseCommand = class(StdClass, ICommand)
  private val:pint;
  public constructor create(_val:pint);
  public procedure execute(); virtual;
end;
  
implementation

constructor ProceduralCommand.create(_proc:SimpleProcedure);
begin
  proc := _proc;
end;

procedure ProceduralCommand.execute();
begin
  proc();
end;


constructor IntDecreaseCommand.create(_val:pint);
begin
  val := _val;
end;

procedure IntDecreaseCommand.execute();
begin
  dec(val^);
end;

end.