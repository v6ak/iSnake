unit v6_debug;

interface

uses v6_classes;

type IOutput = interface ['{90A0AF83-78A0-4260-BD26-D2D554035AC4}']
  procedure write(note, s:string);
end;

function deb(s:string):string;

function deb(note, s:string):string;

function deb(i:integer):integer;

function deb(note:string; i:integer):integer;

function deb(i:IInterface):IInterface;

function deb(note:string; i:IInterface):IInterface;

function deb(b:boolean):boolean;

function deb(note:string; b:boolean):boolean;

procedure setOutput(outp:IOutput);


function ScreenOutput_getInstance():IOutput;

type FileOutput = class(StdClass, IOutput)
  private out:text;
  public constructor create(f:string);
  public destructor destroy(); override;
  public procedure write(note, s:string); virtual;
end;

implementation

uses sysutils;

var o:IOutput;

function deb(note, s:string):string;
begin
  if(o<>NIL)then begin
    o.write(note, s);
  end;
  deb := s;
end;

function deb(s:string):string;
begin
  deb := deb('', s);
end;

function deb(b:boolean):boolean;
begin
  deb := deb('', b);
end;

function deb(note:string; b:boolean):boolean;
var s:string;
begin
  if( b = true )then begin
    s := 'true';
  end else if ( b = false )then begin
    s := 'false';
  end else begin
    s := '<UNKNOWN BOOLEAN>';
  end;
  deb(note, s);
  deb := b;
end;

function deb(i:integer):integer;
begin
  deb := deb('', i);
end;

function deb(note:string; i:integer):integer;
begin
  deb := i;
  deb(note, intToStr(i));
end;

function deb(i:IInterface):IInterface;
begin
  deb := deb('', i);
end;

function deb(note:string; i:IInterface):IInterface;
begin
  deb(note, interfaceToStr(i));
  deb := i;
end;

procedure setOutput(outp:IOutput);
begin
  o := outp;
end;

constructor FileOutput.create(f:string);
begin
  assign(out, f);
  rewrite(out);
  writeln(out, '------------------------------------------------------------------------------------');
end;

destructor FileOutput.destroy();
begin
  writeln(out, '-- the end');
  inherited destroy();
  close(out);
end;

procedure FileOutput.write(note, s:string);
var nstr:string;
begin
  nstr := '';
  if(note <> '')then begin
    nstr := note + ': ';
  end;
  writeln(out, nstr+s);
end;

var ScreenOutput_instance:IOutput;

type ScreenOutput = class(StdClass, IOutput)
  public procedure write(note, s:string); virtual;
end;

procedure ScreenOutput.write(note, s:string);
begin
  if(note <> '')then begin
    write(note, ': ');
  end;
  writeln(s);
end;

function ScreenOutput_getInstance():IOutput;
begin
  if(ScreenOutput_instance = NIL)then begin
    ScreenOutput_instance := ScreenOutput.create();
  end;
  ScreenOutput_getInstance := ScreenOutput_instance;
end;

begin
  ScreenOutput_instance := NIL;
  o := NIL;
end.