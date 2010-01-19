program v6_geometricsTest;
{$ASSERTIONS ON}
{$RANGECHECKS ON}

uses v6_geometrics;

function deb(x:MovingDirection):MovingDirection;
begin
  case(x) of
  LEFT: writeln('LEFT');
  RIGHT: writeln('RIGHT');
  UP: writeln('UP');
  DOWN: writeln('DOWN');
  else writeln('err')
  end;
  deb := x;
end;

procedure assertInRange(allowOverflow:boolean);
var from:IPosition;
var pc:IPositionDirectionConverter;
begin
  pc := createRectanglePositionDirectionConverter(createSize(30, 30), allowOverflow);
  from := createPosition(15, 25);
  assert(pc.calcDirectionFromPositions(from, createPosition(14, 25)) = LEFT);
  assert(pc.calcDirectionFromPositions(from, createPosition(16, 25)) = RIGHT);
  assert(pc.calcDirectionFromPositions(from, createPosition(15, 26)) = DOWN);
  assert(pc.calcDirectionFromPositions(from, createPosition(15, 24)) = UP);
  try
    pc.calcDirectionFromPositions(from, createPosition(15, 25));
    assert(false);
  except on EPositionNotFoundException do
  end;
  try
    pc.calcDirectionFromPositions(from, createPosition(15, 23));
    assert(false);
  except on EPositionNotFoundException do
  end;
  try
    deb(pc.calcDirectionFromPositions(from, createPosition(15, 27)));
    assert(false);
  except on EPositionNotFoundException do
  end;
  try
    pc.calcDirectionFromPositions(from, createPosition(13, 25));
    assert(false);
  except on EPositionNotFoundException do
  end;
  try
    pc.calcDirectionFromPositions(from, createPosition(17, 25));
    assert(false);
  except on EPositionNotFoundException do
  end;
  try
    pc.calcDirectionFromPositions(from, createPosition(14, 24));
    assert(false);
  except on EPositionNotFoundException do
  end;
  try
    pc.calcDirectionFromPositions(from, createPosition(14, 26));
    assert(false);
  except on EPositionNotFoundException do
  end;
  try
    pc.calcDirectionFromPositions(from, createPosition(16, 24));
    assert(false);
  except on EPositionNotFoundException do
  end;
  try
    pc.calcDirectionFromPositions(from, createPosition(16, 26));
    assert(false);
  except on EPositionNotFoundException do
  end;
end;

begin
  assertInRange(false);
  assertInRange(true);
end.