unit v6_graph;

{$COPERATORS ON}
{$RANGECHECKS ON}

interface
uses v6_classes, v6_vars, graph, v6_geometrics, v6_debug;

type IPaintable = interface ['{C2843D50-1D4C-417C-B2E0-BA9318162523}']
  function isPaintingEnabled():boolean;
  procedure setPaint(_paint:boolean);
end;

type ISpaceDrawer = interface ['{BBDCC612-C9BA-419B-B564-07E5AFFF9587}']
  procedure drawSpace(area:IRectangle);
end;

type ColorSpaceDrawer = class (StdClass, ISpaceDrawer)
  private color:word;
  public constructor create(_color:word);
  public procedure drawSpace(area:IRectangle);
end;

type AbstractPaintable = class(StdClass, IPaintable)
  private paint:boolean;
  public constructor create();
  public function isPaintingEnabled():boolean; virtual;
  public procedure setPaint(_paint:boolean); virtual;
  protected procedure repaint(); virtual; abstract;
  protected procedure notifyModiffied();// You have not to call it. However, if you do not call it, you have to handle to repaint modiffied parts! 
end;

type MultiPaintable = class(AbstractPaintable)
  private e:array of IPaintable;
  private p:integer;
  public constructor create();
  public procedure add(pa:IPaintable);
  public procedure setPaint(v:boolean); override;
  protected procedure repaint(); override;
end;

type TextDrawer = class(AbstractPaintable, IStringSettable)
  private bgcolor:word; // I know that this is not very universal...
  private s:string;
  private cfg:TextSettingsType;
  private left, top:integer;
  private color:word;
  private lastWidth, lastHeight:integer;
  public constructor create(_bgcolor, _color:word; _left, _top:integer; _cfg:TextSettingsType; _s:string);
  public procedure setValue(_s:string);
  protected procedure repaint(); override;
end;

function createTextSettingsType(font, direction, charSize, horiz, vert:word):TextSettingsType;

procedure useTextSettingsType(cfg:TextSettingsType);

procedure openGraph();

procedure openGraph(ad:IAutoDisposer);

procedure bar(rect:IRectangle);

implementation

procedure openGraph();
var gd, gm:smallint;
begin
  detectGraph(gd, gm);
  initGraph(gd, gm, '');
end;

type Dgc = class(StdClass)
  public destructor destroy(); override;
end;

destructor Dgc.destroy();
begin
  inherited destroy();
  closeGraph();
end;

procedure openGraph(ad:IAutoDisposer);
begin
  openGraph();
  ad.addRef(Dgc.create());
end;

function createTextSettingsType(font, direction, charSize, horiz, vert:word):TextSettingsType;
begin
  createTextSettingsType.font := font;
  createTextSettingsType.direction := direction;
  createTextSettingsType.charSize := charSize;
  createTextSettingsType.horiz := horiz;
  createTextSettingsType.vert := vert;
end;

constructor AbstractPaintable.create();
begin
  paint := false;
end;

function AbstractPaintable.isPaintingEnabled():boolean;
begin
  isPaintingEnabled := paint;
end;

procedure AbstractPaintable.setPaint(_paint:boolean);
var rp:boolean;
begin
  rp := (_paint) and (not paint); // I had not to paint but I have to paint now.
  paint := _paint;
  if(rp)then begin
    repaint();
  end;
end;

procedure AbstractPaintable.notifyModiffied();
begin
  if( isPaintingEnabled() )then begin
    repaint();
  end;
end;

constructor TextDrawer.create(_bgcolor, _color:word; _left, _top:integer; _cfg:TextSettingsType; _s:string);
begin
  bgcolor := _bgcolor;
  color := _color;
  s := _s;
  left := _left;
  top := _top;
  cfg := _cfg;
  lastWidth := 0;
  lastHeight := 0;
end;

procedure TextDrawer.setValue(_s:string);
begin
  s := _s;
  deb('TextDrawer.setValue('+_s+')');
  notifyModiffied();
end;

procedure TextDrawer.repaint();
begin
  setFillStyle(1, bgcolor);
  setBkColor(bgcolor);
  graph.bar(left, top, left+lastWidth, top+lastHeight);
  setColor(color);
  useTextSettingsType(cfg);
  outTextXY(left, top, s);
  lastHeight := textHeight(s);
  lastWidth := textWidth(s);
end;

constructor ColorSpaceDrawer.create(_color:word);
begin
  color := _color;
end;

procedure ColorSpaceDrawer.drawSpace(area:IRectangle);
begin
  setFillStyle(1, color);
  setBkColor(color);
  bar(area{.getX1(), area.getY1(), area.getX2(), area.getY2()});
end;

constructor MultiPaintable.create();
begin
  paint := false;
  setLength(e, 50);
  p := 0;
  // FIXME: infinite
end;

procedure MultiPaintable.add(pa:IPaintable);
begin
  //setLength(e, length(e)+1);
  p += 1;
  e[p] := pa;
end;

procedure MultiPaintable.setPaint(v:boolean);
var i:integer;
begin
  inherited setPaint(v);
  for i := 0 to high(e) do begin
    if(e[i] <> NIL )then begin
      deb('e[i]'+interfaceToStr(e[i]));
      e[i].setPaint(v);
    end;
  end;
end;

procedure MultiPaintable.repaint();
begin
end;

procedure bar(rect:IRectangle);
begin
  graph.bar(rect.getX1(), rect.getY1(), rect.getX2(), rect.getY2());
end;

procedure useTextSettingsType(cfg:TextSettingsType);
begin
  setTextStyle(cfg.font, cfg.direction, cfg.charSize);
  setTextJustify(cfg.horiz, cfg.vert);
end;

end.