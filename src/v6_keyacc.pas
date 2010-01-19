unit v6_keyacc;
// Provides Crt/Wincrt keyPressed() and readKey() object wrapper so you can use late binding. You can write a library that can work with keyPressed() and readKey() function prom both of them or maybe a Mock (see http://en.wikipedia.org/wiki/Mock_object )!
// This wrapper does not wrap ecsaped keys (e.g. arrow keys).
{$RANGECHECKS ON}

interface
uses v6_classes;

type IKeyAccess = interface ['{1F9FA0B8-2219-40E4-B924-DB4F9652568D}']
    function isKeyPressed():boolean;
    function readPressedKey():char;
  end;

function CrtKeyAccess_getInstance():IKeyAccess;
function WinCrtKeyAccess_getInstance():IKeyAccess;

implementation
uses crt, wincrt;
var cka, wcka:IKeyAccess;

type CrtKeyAccess = class(StdClass, IKeyAccess)
    public constructor create();
    public function isKeyPressed():boolean; virtual;
    public function readPressedKey():char; virtual;
  end;
  
type WinCrtKeyAccess = class(StdClass, IKeyAccess)
    public constructor create();
    public function isKeyPressed():boolean; virtual;
    public function readPressedKey():char; virtual;
  end;

constructor CrtKeyAccess.create();
begin
end;

constructor WinCrtKeyAccess.create();
begin
end;

function CrtKeyAccess.isKeyPressed():boolean;
begin
  isKeyPressed := crt.keyPressed();
end;

function WinCrtKeyAccess.isKeyPressed():boolean;
begin
  isKeyPressed := winCrt.keyPressed();
end;

function CrtKeyAccess.readPressedKey():char;
begin
  readPressedKey := crt.readKey();
end;

function WinCrtKeyAccess.readPressedKey():char;
begin
  readPressedKey := winCrt.readKey();
end;

function CrtKeyAccess_getInstance():IKeyAccess;
begin
  CrtKeyAccess_getInstance := cka;
end;
function WinCrtKeyAccess_getInstance():IKeyAccess;
begin
  WinCrtKeyAccess_getInstance := wcka;
end;

initialization
  cka := CrtKeyAccess.create();
  wcka := WinCrtKeyAccess.create();
end.