program ExeWithEnclosureDemo;

uses
  Windows,
  Forms,
  Dialogs,
  SysUtils,
  Main in 'Main.pas' {Form1},
  ExeEnclosure in 'ExeEnclosure.pas';

{$R *.res}

begin
  {Pour ne pouvoir lancer qu'une seule application à la fois.}
  SetLastError(NO_ERROR);
  if CreateMutex(Nil,true,pChar('MutexFor' + ExtractFileName(Application.ExeName))) = 0 then Halt;//La création du Mutex a échoué.
  if GetLastError = ERROR_ALREADY_EXISTS then begin//Le Mutex existe déjà.
    ShowMessage('Cette application est déjà lancée !');
    Halt;
  end;

  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
