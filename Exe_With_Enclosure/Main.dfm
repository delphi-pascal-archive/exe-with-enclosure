object Form1: TForm1
  Left = 224
  Top = 124
  Width = 421
  Height = 224
  Caption = 'Exe With Enclosure'
  Color = 6381921
  Constraints.MinHeight = 198
  Constraints.MinWidth = 347
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -14
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  DesignSize = (
    413
    196)
  PixelsPerInch = 120
  TextHeight = 16
  object memTest: TMemo
    Left = 8
    Top = 7
    Width = 396
    Height = 180
    Anchors = []
    Color = clSilver
    Font.Charset = ANSI_CHARSET
    Font.Color = clBlack
    Font.Height = -15
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    Lines.Strings = (
      'Pour tester cette demonstration, changer la position '
      'et les dimensions de cette fiche sur votre ecran et '
      'entrer un texte quelconque dans ce Memo. '
      ''
      'L'#39'application les memorisera dans son fichier  *.exe et '
      'les restituera au prochain lancement.')
    ParentFont = False
    TabOrder = 0
  end
end
