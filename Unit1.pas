unit Unit1;

interface

uses
  Classes, Graphics, Controls, Forms, ExtCtrls, watereffect;

type
  TForm1 = class(TForm)
    Timer1: TTimer;
    Image1: TImage;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Image1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure Timer1Timer(Sender: TObject);
    procedure Image1Click(Sender: TObject);
  private
    { Private declarations }
    Water: TWaterEffect;
    FrameBackground: TBitmap;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
begin
  Timer1.Enabled := true;
  //Load picture from file
  Image1.Picture.Bitmap.LoadFromFile('background.bmp');
  //Create FrameBackground and load bitmap from Image1
  FrameBackground := TBitmap.Create;
  FrameBackground.Assign(Image1.Picture.Graphic);
  //Size TImage and TForm according to loaded Bitmap
  Image1.Height := FrameBackground.Height;
  Image1.Width := FrameBackground.Width;
  Form1.ClientHeight := FrameBackground.Height;
  Form1.ClientWidth := FrameBackground.Width;
  //Create and size TWaterEffect
  Water := TWaterEffect.Create;
  Water.SetSize(FrameBackground.Width, FrameBackground.Height);
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  FrameBackground.Free;
  Water.Free;
end;

procedure TForm1.Image1Click(Sender: TObject);
begin
  Timer1.Enabled := not Timer1.Enabled;
end;

procedure TForm1.Image1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  if Timer1.Enabled then
    Water.Bubble(X, Y, 1, 100);
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  if Random(8) = 1 then   //Random(8) : increase for less droplets, decrease (or comment line) for more
    Water.Bubble(-1, -1, Random(1) + 1, Random(500) + 50); //X and Y = -1: Bubble will set random coordinates based on image size
  Water.Render(FrameBackground, Image1.Picture.Bitmap);
  Image1.Refresh;
end;

end.

