UNIT ExeEnclosure;                                                              {
                        UNITE PERMETTANT LA SAUVEGARDE ET LA LECTURE
                        DE DONNEES BINAIRES DANS UN .EXE EN RUNTIME

                               Fait sous D7 par Caribensila
                                        Avril 2010                              }
INTERFACE

uses
  Windows, Controls, SysUtils, Forms, StrUtils, Classes, Dialogs, ShellAPI;

  function  InitializeEnclosure( var DataStream: TMemoryStream ): Boolean;
  function  FinalizeEnclosure  ( var DataStream: TMemoryStream ): Boolean;
  procedure SaveEnclosure      ( var DataStream: TMemoryStream );

IMPLEMENTATION



 ///////////////////////////////////////////////////////////////////////////////
//  METHODES LOCALES  /////////////////////////////////////////////////////////



  {Renvoie le chemin du fichier .exe originel.}
function OriginalExeName: TFileName;
  var
         S : string;
         
  begin
  Result := Application.ExeName;
  if LeftStr( ExtractFileName( Application.ExeName ), 6 )<>'CopyOf' then Exit;
  S := ExtractFileName( Application.ExeName );
  Delete( S, 1, 6 );
  Result := ExtractFilePath( Application.ExeName ) + S;
end;



  {Renvoie le chemin du fichier .exe temporaire.}
function TempExeName: TFileName;
  begin
  Result := Application.ExeName;
  if LeftStr( ExtractFileName( Application.ExeName ), 6)='CopyOf' then Exit;
  Result :=   ExtractFilePath( Application.ExeName ) + 'CopyOf'
            + ExtractFileName( Application.ExeName );
end;



  {Renvoie une signature unique de fin de fichier pour identifier un *.exe
   contenant des donn�es binaires jointes.}
function EndSignOff: string;
  begin
  Result := 'EnclosureFor' + ExtractFileName( OriginalExeName );
end;



  {Permet de d�truire un fichier .exe dans un certain d�lai, r�it�rable (5 sec. ici).}
function TryAndDelete( FileName: TFileName ): Boolean;
  var
         i : Integer;

  begin
  Result := false;
  if not FileExists( FileName ) then begin
    Result := true;
    Exit;
  end;
  for i := 1 to 50 do begin
    Sleep( 100 );
    if DeleteFile( FileName ) then begin
      Result := true;
      break;
    end;
  end;
  if not Result then begin
    if MessageDlg(  'Le fichier ' + ExtractFileName( FileName )
                  + ' n''a pas pu �tre d�truit.',
                     mtWarning, [mbRetry,mbAbort], 0 ) =  mrRetry
    then TryAndDelete( FileName );
  end;
end;



 ///////////////////////////////////////////////////////////////////////////////
//  METHODES PARTAGEES  ///////////////////////////////////////////////////////



  {Renvoie un TStream positionn� au d�but de nos donn�es binaires afin de les
   lire ou effectue diverses op�rations de sauvegarde et de nettoyage.}
function InitializeEnclosure( var DataStream: TMemoryStream ): Boolean;
  var
         Sign : string; // La signature de l'.exe.
         Pos  : Int64; //  La position dans le DataStream.

  begin
  Result := false;

  if ( Application.ExeName=TempExeName ) and ( FileExists( OriginalExeName ) )     // Si cette fonction est appel�e par l'.exe temporaire...
    then begin
    TryAndDelete( OriginalExeName );                                               // ... on d�truit l'.exe originel...
    DataStream.LoadFromFile( Application.ExeName );                                // ... et on le remplace par celui...
    DataStream.SaveToFile( OriginalExeName );                                      // ... contenant nos derni�res donn�es (= l'.exe temporaire en cours).
    ShellExecute( 0, nil, PChar( OriginalExeName ), nil, nil, SW_HIDE );           // On lance ce nouvel .exe originel afin qu'il puisse d�truire l'.exe temporaire actuellement en cours...
    Halt;                                                                          // ... (voir ci-dessous) et on quitte l'.exe temporaire en cours.
  end;

  if ( Application.ExeName=OriginalExeName ) and ( FileExists( TempExeName ) )     // Si cette fonction est appel�e par l'.exe originel mais que l'.exe temporaire est encore pr�sent...
    then begin
    TryAndDelete( TempExeName );                                                   // ... on d�truit l'.exe temporaire et...
    Halt;                                                                          // ... on quitte l'.exe en cours.
  end;
                                                                                   // S'il n'existe plus de copie temporaire de l'.exe, c'est donc un lancement 'normal'.
  DataStream.LoadFromFile( Application.ExeName );                                  // On r�cup�re le TStream global : exe + nos donn�es.
  DataStream.Position := DataStream.Size - Length( EndSignOff );                   // V�rification d'une �ventuelle signature � la fin du flux...
  SetLength( Sign, Length( EndSignOff ) );                                         //                   "
  DataStream.ReadBuffer( Sign[1], Length( EndSignOff ) );                          //                   "
  if Sign = EndSignOff then begin                                                  // S'il s'agit bien d'un TStream contenant nos donn�es binaires...
    Result := true;
    DataStream.Position := DataStream.Size - Length( EndSignOff ) - SizeOf( Pos ); // ... on lit la position du d�but de nos donn�es...
    DataStream.ReadBuffer( Pos, SizeOf( Pos ) );                                   //                   "
    DataStream.Position := Pos;                                                    // ... et on s'y positionne.
  end;
end;



  {Renvoie un TStream ne contenant que le code de l'.exe et positionn� � la fin
   afin de pouvoir y ajouter nos propres donn�es binaires.}                               { Ne renverra un TStream que s'il s'agit d'un lancement 'normal'.         }
function FinalizeEnclosure( var DataStream: TMemoryStream ): Boolean;                     { Cependant elle peut �tre appel�e lors du tout premier lancement         }
  var                                                                                     { de l'application (sans aucunes donn�es ni signature),                   }
         TempStream : TMemoryStream; // Un flux temporaire pour manipuler le DataStream.  { ou lors des lancements suivants (avec des donn�es ajout�es).            }
         BytesCount : Int64;        //  Le nombre d'octets � copier dans le TStream.      { Dans ces 2 cas, il s'agit donc de renvoyer un TStream                   }
         Sign       : string;      //   La signature de l'.exe.                           { ne contenant que le code de l'.exe.                                     }
         Pos        : Int64;      //    La position dans le DataStream.                   { On utilisera un flux temporaire pour faire cette op�ration classique.   }

  begin
  Result := false;
  if ( Application.ExeName=OriginalExeName ) and ( not FileExists( TempExeName ) ) // S'il s'agit d'un lancement 'normal'...
    then begin
    DataStream.LoadFromFile( Application.ExeName );                                // ... on r�cup�re le TStream global : exe + nos donn�es, ou exe seul.
    DataStream.Position := DataStream.Size - Length( EndSignOff );                 // V�rification d'une �ventuelle signature � la fin du Flux...
    SetLength( Sign, Length( EndSignOff ) );                                       //                   "
    DataStream.ReadBuffer( Sign[1], Length( EndSignOff ) );                        //                   "
    if Sign = EndSignOff then begin                                                // S'il s'agit bien d'un TStream contenant des donn�es binaires ajout�es...
      DataStream.Position := DataStream.Size - Length( EndSignOff )-SizeOf( Pos ); // ... on lit la position du d�but de nos donn�es...
      DataStream.ReadBuffer( Pos, SizeOf( Pos ) );                                 //                   "
    end;                                                                           // ... qui est en fait la taille du flux ne contenant que le code de l'exe.
    TempStream  := TMemoryStream.Create;                                           // On supprime alors du flux les �ventuelles donn�es ajout�es...
    try                                                                            //                   "
      BytesCount := DataStream.Position;                                           //                   "
      DataStream.Position := 0;                                                    //                   "
      TempStream.CopyFrom( DataStream, BytesCount );                               //                   "
      DataStream.Clear;                                                            //                   "
      TempStream.Position := 0;                                                    //                   "
      DataStream.CopyFrom( TempStream, BytesCount );                               //                   "
    Finally FreeAndNil( TempStream ); end;                                         //                   "
    Result := true;
  end;
end;



  {Sauvegarde le .exe originel suivi de nos donn�es binaires dans un
   .exe temporaire.}
procedure SaveEnclosure( var DataStream: TMemoryStream );
  begin
  DataStream.WriteBuffer( EndSignOff[1], Length( EndSignOff ) );                   // On ajoute la signature...
  DataStream.SaveToFile( TempExeName );                                            // ... avant de sauvegarder l'.exe temporaire...
  ShellExecute( 0, nil, PChar( TempExeName ), nil, nil, SW_HIDE );                 // ... et de le lancer.
end;



END.
