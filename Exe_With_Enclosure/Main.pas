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
[ Ici commence la partie r�serv�e � nos propres donn�es ]
- la taille du texte sauvegard�                              (ajout�)
- le texte lui-m�me                                          (ajout�)
- les coordonn�es de la Form (16 bytes)                      (ajout�)
- la position du d�but de nos donn�es dans le flux (8 bytes) (ajout�)
- une signature                                              (ajout�)
________________________________________________________________________________

La fermeture de cette application se d�roule en plusieurs temps :

- l'application originelle cr�era un fichier .exe temporaire qui contiendra
  le .exe et les derni�res donn�es � sauvegarder
- elle lancera cet .exe temporaire
- elle se fermera
- alors l'.exe temporaire d�truira l'.exe originelle
- et le remplacera par une copie de lui-m�me
- puis le lancera avant de se fermer de lui-m�me.
- le nouvel exe originel d�tectera la pr�sence de cet exe temporaire 
- et le d�truira avant d'enfin se fermer de lui-m�me.
  La boucle est boucl�e !
}

procedure TForm1.FormCreate( Sender: TObject );
  var
          DataStream : TMemoryStream; // Le TStream destin� � recevoir l'exe et nos donn�es.
          BytesCount : Integer;      //  Le nombre d'octets � copier dans le TStream.
          MemText    : string;      //   Le Texte du m�mo.
          FormBounds : TRect;      //    Les param�tres de la Form.

  begin
  DataStream := TMemoryStream.Create;
  try
    if InitializeEnclosure( DataStream ) then begin              // Voir l'unit� ExeEnclosure.
      DataStream.ReadBuffer( BytesCount, SizeOf( BytesCount ) ); // Lecture de nos donn�es depuis DataStream...
      SetLength( MemText, BytesCount );                          //             "
      DataStream.Read( MemText[1], BytesCount );                 //             "
      DataStream.ReadBuffer( FormBounds, SizeOf( FormBounds ) ); //             "
      memTest.Text     := MemText;                               // Assignation de nos donn�es...
      Form1.BoundsRect := FormBounds;                            //             "
    end;
  Finally  FreeAndNil( DataStream );   end;
  {Ici, votre code �ventuel.}
end;

procedure TForm1.FormCloseQuery( Sender: TObject; var CanClose: Boolean );
  var
          DataStream : TMemoryStream; // Le TStream destin� � recevoir l'exe et nos donn�es.
          BytesCount : Integer;      //  Le nombre d'octets � copier dans le TStream.
          MemText    : string;      //   Le texte � stocker du m�mo.
          Pos        : Int64;      //    La position dans le DataStream
          FormBounds : TRect;     //     Les param�tres � stocker de la Form.
          
  begin
  {Ici, votre code �ventuel.}
  DataStream := TMemoryStream.Create;
  try
    if FinalizeEnclosure( DataStream ) then begin                 // Voir l'unit� ExeEnclosure.
      Pos        := DataStream.Position;                          // On est juste � la fin des donn�es de l'.exe. On m�morise cette position pour l'�crire � la fin de DataStream.
      MemText    := memTest.Text;                                 // Pour sauvegarder nos donn�es...
      BytesCount := Length( MemText );                            //             "
      FormBounds := Form1.BoundsRect;                             //             "
      DataStream.WriteBuffer( BytesCount, SizeOf( BytesCount ) ); // Ecriture de nos donn�es dans DataStream...
      DataStream.WriteBuffer( MemText[1], BytesCount );           //             "
      DataStream.WriteBuffer( FormBounds, SizeOf( FormBounds ) ); //             "
      DataStream.WriteBuffer( Pos, SizeOf( Pos ) );               //             "
      SaveEnclosure( DataStream );                                // Voir l'unit� ExeEnclosure.
    end;
  Finally   FreeAndNil( DataStream );   end;
end;

END.

NB:
  Pour simplement une structure de donn�es de port�e globale, on pr�f�rera coder
  dans Initialization et Finalization. Ce sera plus rapide et plus logique.
