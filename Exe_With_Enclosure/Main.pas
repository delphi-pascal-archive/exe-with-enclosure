UNIT Main;                                                                      {
                        ALTERNATIVE AU FICHIER .INI

                       Fait sous D7 par Caribensila
                                Avril 2010                                      }
INTERFACE

uses
  Windows, Classes, Controls, StdCtrls, SysUtils, Forms, ExeEnclosure;

type
  TForm1 = class(TForm)
    memTest: TMemo;
    procedure FormCloseQuery( Sender: TObject; var CanClose: Boolean );
    procedure FormCreate    ( Sender: TObject );
  end;

var
  Form1: TForm1;

IMPLEMENTATION

{$R *.dfm}

{ Structure du nouvel .exe :

- les 2 Headers du .exe                                      (classique)
- le code du .exe                                            (classique)
- les data du .exe                                           (classique)
[ Ici commence la partie réservée à nos propres données ]
- la taille du texte sauvegardé                              (ajouté)
- le texte lui-même                                          (ajouté)
- les coordonnées de la Form (16 bytes)                      (ajouté)
- la position du début de nos données dans le flux (8 bytes) (ajouté)
- une signature                                              (ajouté)
________________________________________________________________________________

La fermeture de cette application se déroule en plusieurs temps :

- l'application originelle créera un fichier .exe temporaire qui contiendra
  le .exe et les dernières données à sauvegarder
- elle lancera cet .exe temporaire
- elle se fermera
- alors l'.exe temporaire détruira l'.exe originelle
- et le remplacera par une copie de lui-même
- puis le lancera avant de se fermer de lui-même.
- le nouvel exe originel détectera la présence de cet exe temporaire 
- et le détruira avant d'enfin se fermer de lui-même.
  La boucle est bouclée !
}

procedure TForm1.FormCreate( Sender: TObject );
  var
          DataStream : TMemoryStream; // Le TStream destiné à recevoir l'exe et nos données.
          BytesCount : Integer;      //  Le nombre d'octets à copier dans le TStream.
          MemText    : string;      //   Le Texte du mémo.
          FormBounds : TRect;      //    Les paramètres de la Form.

  begin
  DataStream := TMemoryStream.Create;
  try
    if InitializeEnclosure( DataStream ) then begin              // Voir l'unité ExeEnclosure.
      DataStream.ReadBuffer( BytesCount, SizeOf( BytesCount ) ); // Lecture de nos données depuis DataStream...
      SetLength( MemText, BytesCount );                          //             "
      DataStream.Read( MemText[1], BytesCount );                 //             "
      DataStream.ReadBuffer( FormBounds, SizeOf( FormBounds ) ); //             "
      memTest.Text     := MemText;                               // Assignation de nos données...
      Form1.BoundsRect := FormBounds;                            //             "
    end;
  Finally  FreeAndNil( DataStream );   end;
  {Ici, votre code éventuel.}
end;

procedure TForm1.FormCloseQuery( Sender: TObject; var CanClose: Boolean );
  var
          DataStream : TMemoryStream; // Le TStream destiné à recevoir l'exe et nos données.
          BytesCount : Integer;      //  Le nombre d'octets à copier dans le TStream.
          MemText    : string;      //   Le texte à stocker du mémo.
          Pos        : Int64;      //    La position dans le DataStream
          FormBounds : TRect;     //     Les paramètres à stocker de la Form.
          
  begin
  {Ici, votre code éventuel.}
  DataStream := TMemoryStream.Create;
  try
    if FinalizeEnclosure( DataStream ) then begin                 // Voir l'unité ExeEnclosure.
      Pos        := DataStream.Position;                          // On est juste à la fin des données de l'.exe. On mémorise cette position pour l'écrire à la fin de DataStream.
      MemText    := memTest.Text;                                 // Pour sauvegarder nos données...
      BytesCount := Length( MemText );                            //             "
      FormBounds := Form1.BoundsRect;                             //             "
      DataStream.WriteBuffer( BytesCount, SizeOf( BytesCount ) ); // Ecriture de nos données dans DataStream...
      DataStream.WriteBuffer( MemText[1], BytesCount );           //             "
      DataStream.WriteBuffer( FormBounds, SizeOf( FormBounds ) ); //             "
      DataStream.WriteBuffer( Pos, SizeOf( Pos ) );               //             "
      SaveEnclosure( DataStream );                                // Voir l'unité ExeEnclosure.
    end;
  Finally   FreeAndNil( DataStream );   end;
end;

END.

NB:
  Pour simplement une structure de données de portée globale, on préférera coder
  dans Initialization et Finalization. Ce sera plus rapide et plus logique.
