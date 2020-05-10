unit WaterEffect;

interface

uses
  Windows, Graphics, Math;

const
  DampingConstant = 15;

type
  PIntArray = ^TIntArray;

  TIntArray = array[0..16777215] of Integer;

  PPIntArray = ^TPIntArray;

  TPIntArray = array[0..16777215] of PIntArray;

  PRGBArray = ^TRGBArray;

  TRGBArray = array[0..16777215] of TRGBTriple;

  PPRGBArray = ^TPRGBArray;

  TPRGBArray = array[0..16777215] of PRGBArray;

  TWaterDamping = 1..99;

  TWaterEffect = class(TObject)
  private
    { Private declarations }
    FrameWidth: Integer;
    FrameHeight: Integer;
    FrameBuffer01: Pointer;
    FrameBuffer02: Pointer;
    FrameLightModifier: Integer;
    FrameScanLine01: PPIntArray;
    FrameScanLine02: PPIntArray;
    FrameScanLineScreen: PPRGBArray;
    FrameDamping: TWaterDamping;
    procedure SetDamping(Value: TWaterDamping);
  protected
    { Protected declarations }
    procedure CalculateWater;
    procedure DrawWater(ALightModifier: Integer; Screen, Distance: TBitmap);
  public
    { Public declarations }
    constructor Create;
    destructor Destroy; override;
    procedure ClearWater;
    procedure SetSize(EffectBackgroundWidth, EffectBackgroundHeight: Integer);
    procedure Render(Screen, Distance: TBitmap);
    procedure Bubble(X, Y: Integer; BubbleRadius, EffectBackgroundHeight: Integer);
    property Damping: TWaterDamping read FrameDamping write SetDamping;
  end;

implementation

{ TWaterEffect }

const
  RandomConstant = $7FFF;

procedure TWaterEffect.Bubble(X, Y: Integer; BubbleRadius, EffectBackgroundHeight: Integer);
var
  Rquad: Integer;
  CX, CY, CYQ: Integer;
  Left, Top, Right, Bottom: Integer;
begin
  if (X < 0) or (X > FrameWidth - 1) then
    X := 1 + BubbleRadius + Random(RandomConstant) mod (FrameWidth - 2 * BubbleRadius - 1);
  if (Y < 0) or (Y > FrameHeight - 1) then
    Y := 1 + BubbleRadius + Random(RandomConstant) mod (FrameHeight - 2 * BubbleRadius - 1);
  Left := -Min(X, BubbleRadius);
  Right := Min(FrameWidth - 1 - X, BubbleRadius);
  Top := -Min(Y, BubbleRadius);
  Bottom := Min(FrameHeight - 1 - Y, BubbleRadius);
  Rquad := BubbleRadius * BubbleRadius;
  for CY := Top to Bottom do
  begin
    CYQ := CY * CY;
    for CX := Left to Right do
      if (CX * CX + CYQ <= Rquad) then
        Inc(FrameScanLine01[CY + Y][CX + X], EffectBackgroundHeight);
  end;
end;

procedure TWaterEffect.CalculateWater;
var
  X, Y, XL, XR: Integer;
  NewH: Integer;
  P1, P2, P3, P4: PIntArray;
  PT: Pointer;
  Rate: Integer;
begin
  Rate := (100 - FrameDamping) * 256 div 100;
  for Y := 0 to FrameHeight - 1 do
  begin
    P1 := FrameScanLine02[Y];
    P2 := FrameScanLine01[Max(Y - 1, 0)];
    P3 := FrameScanLine01[Y];
    P4 := FrameScanLine01[Min(Y + 1, FrameHeight - 1)];
    for X := 0 to FrameWidth - 1 do
    begin
      XL := Max(X - 1, 0);
      XR := Min(X + 1, FrameWidth - 1);
      NewH := (P2[XL] + P2[X] + P2[XR] + P3[XL] + P3[XR] + P4[XL] + P4[X] + P4[XR]) div 4 - P1[X];
      P1[X] := NewH * Rate div 256;
    end;
  end;
  PT := FrameBuffer01;
  FrameBuffer01 := FrameBuffer02;
  FrameBuffer02 := PT;
  PT := FrameScanLine01;
  FrameScanLine01 := FrameScanLine02;
  FrameScanLine02 := PT;
end;

procedure TWaterEffect.ClearWater;
begin
  if FrameBuffer01 <> nil then
    ZeroMemory(FrameBuffer01, (FrameWidth * FrameHeight) * SizeOf(Integer));
  if FrameBuffer02 <> nil then
    ZeroMemory(FrameBuffer02, (FrameWidth * FrameHeight) * SizeOf(Integer));
end;

constructor TWaterEffect.Create;
begin
  inherited;
  FrameLightModifier := 10;
  FrameDamping := DampingConstant;
end;

destructor TWaterEffect.Destroy;
begin
  if FrameBuffer01 <> nil then
    FreeMem(FrameBuffer01);
  if FrameBuffer02 <> nil then
    FreeMem(FrameBuffer02);
  if FrameScanLine01 <> nil then
    FreeMem(FrameScanLine01);
  if FrameScanLine02 <> nil then
    FreeMem(FrameScanLine02);
  if FrameScanLineScreen <> nil then
    FreeMem(FrameScanLineScreen);
  inherited;
end;

procedure TWaterEffect.DrawWater(ALightModifier: Integer; Screen, Distance: TBitmap);
var
  DX, DY: Integer;
  I, C, X, Y: Integer;
  P1, P2, P3: PIntArray;
  PScreen, PDistance: PRGBArray;
  PScreenDot, PDistanceDot: PRGBTriple;
  BytesPerLine1, BytesPerLine2: Integer;
begin
  Screen.PixelFormat := pf24bit;
  Distance.PixelFormat := pf24bit;
  FrameScanLineScreen[0] := Screen.ScanLine[0];
  BytesPerLine1 := Integer(Screen.ScanLine[1]) - Integer(FrameScanLineScreen[0]);
  for I := 1 to FrameHeight - 1 do
    FrameScanLineScreen[I] := PRGBArray(Integer(FrameScanLineScreen[I - 1]) + BytesPerLine1);
  PDistance := Distance.ScanLine[0];
  BytesPerLine2 := Integer(Distance.ScanLine[1]) - Integer(PDistance);
  for Y := 0 to FrameHeight - 1 do
  begin
    PScreen := FrameScanLineScreen[Y];
    P1 := FrameScanLine01[Max(Y - 1, 0)];
    P2 := FrameScanLine01[Y];
    P3 := FrameScanLine01[Min(Y + 1, FrameHeight - 1)];
    for X := 0 to FrameWidth - 1 do
    begin
      DX := P2[Max(X - 1, 0)] - P2[Min(X + 1, FrameWidth - 1)];
      DY := P1[X] - P3[X];
      if (X + DX >= 0) and (X + DX < FrameWidth) and (Y + DY >= 0) and (Y + DY < FrameHeight) then
      begin
        PScreenDot := @FrameScanLineScreen[Y + DY][X + DX];
        PDistanceDot := @PDistance[X];
        C := PScreenDot.rgbtBlue - DX;
        if C < 0 then
          PDistanceDot.rgbtBlue := 0
        else if C > 255 then
          PDistanceDot.rgbtBlue := 255
        else
        begin
          PDistanceDot.rgbtBlue := C;
          C := PScreenDot.rgbtGreen - DX;
        end;
        if C < 0 then
          PDistanceDot.rgbtGreen := 0
        else if C > 255 then
          PDistanceDot.rgbtGreen := 255
        else
        begin
          PDistanceDot.rgbtGreen := C;
          C := PScreenDot.rgbtRed - DX;
        end;
        if C < 0 then
          PDistanceDot.rgbtRed := 0
        else if C > 255 then
          PDistanceDot.rgbtRed := 255
        else
        begin
          PDistanceDot.rgbtRed := C;
        end;
      end
      else
        PDistance[X] := PScreen[X]; //That's not in CnVcl code!?
    end;
    PDistance := PRGBArray(Integer(PDistance) + BytesPerLine2);
  end;
end;

procedure TWaterEffect.Render(Screen, Distance: TBitmap);
begin
//  if (FrameWidth > 0) and (FrameHeight > 0) then  //This test is in CnVcl but shouldn't be required here
//  begin
  CalculateWater;
  DrawWater(FrameLightModifier, Screen, Distance);
//  end;
end;

procedure TWaterEffect.SetDamping(Value: TWaterDamping);
begin
  if (Value >= Low(TWaterDamping)) and (Value <= High(TWaterDamping)) then
    FrameDamping := Value;
end;

procedure TWaterEffect.SetSize(EffectBackgroundWidth, EffectBackgroundHeight: Integer);
var
  I: Integer;
begin
  if (EffectBackgroundWidth <= 0) or (EffectBackgroundHeight <= 0) then
  begin
    EffectBackgroundWidth := 0;
    EffectBackgroundHeight := 0;
  end;
  FrameWidth := EffectBackgroundWidth;
  FrameHeight := EffectBackgroundHeight;
  ReallocMem(FrameBuffer01, FrameWidth * FrameHeight * SizeOf(Integer));
  ReallocMem(FrameBuffer02, FrameWidth * FrameHeight * SizeOf(Integer));
  ReallocMem(FrameScanLine01, FrameHeight * SizeOf(PIntArray));
  ReallocMem(FrameScanLine02, FrameHeight * SizeOf(PIntArray));
  ReallocMem(FrameScanLineScreen, FrameHeight * SizeOf(PRGBArray));
  ClearWater;
// This test shouldn't be required, otherwise Render will fail as well anyway
// Besides should test for FrameWidth as well as in original CnVcl code
//  if FrameHeight > 0 then
//  begin
  FrameScanLine01[0] := FrameBuffer01;
  FrameScanLine02[0] := FrameBuffer02;
  for I := 1 to FrameHeight - 1 do
  begin
    FrameScanLine01[I] := @FrameScanLine01[I - 1][FrameWidth];
    FrameScanLine02[I] := @FrameScanLine02[I - 1][FrameWidth];
  end;
//  end;
end;

end.

