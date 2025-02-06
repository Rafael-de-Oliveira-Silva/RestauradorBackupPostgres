program Restore_Backup;

uses
  ShareMem,
  Forms,
  Main in 'Main.pas' {FMain},
  ImportDLL in '..\Biblioteca ADO\ImportDLL.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFMain, FMain);
  Application.Run;
end.
