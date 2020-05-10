object Form1: TForm1
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  Caption = 'Water effect demo'
  ClientHeight = 158
  ClientWidth = 281
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 120
  TextHeight = 16
  object Image1: TImage
    Left = 0
    Top = 0
    Width = 169
    Height = 105
    OnClick = Image1Click
    OnMouseMove = Image1MouseMove
  end
  object Timer1: TTimer
    Interval = 25
    OnTimer = Timer1Timer
    Left = 16
    Top = 16
  end
end
