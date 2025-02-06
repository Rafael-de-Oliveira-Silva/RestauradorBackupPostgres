unit Main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Buttons, ZAbstractConnection, ZConnection, StrUtils,
  FileCtrl, ZDataset, ImportDLL;

type
  TFMain = class(TForm)
    Panel1: TPanel;
    GroupBox1: TGroupBox;
    edtUsuario: TEdit;
    Label4: TLabel;
    Label3: TLabel;
    edtSenha: TEdit;
    edtPorta: TEdit;
    Label2: TLabel;
    edtHost: TEdit;
    Label1: TLabel;
    BitBtn1: TBitBtn;
    GroupBox2: TGroupBox;
    BitBtn2: TBitBtn;
    edtNomeBanco: TEdit;
    Label6: TLabel;
    BitBtn3: TBitBtn;
    DB: TZConnection;
    OpenDialog1: TOpenDialog;
    lblArquivo: TMemo;
    edtBin: TEdit;
    SpeedButton1: TSpeedButton;
    Label5: TLabel;
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure BitBtn3Click(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
  private
    { Private declarations }
    mPathArquivoBackup: string;
    function TestarConexao: Boolean;
    procedure EncerrarConexao;
    procedure IniciarRestauracao;
    function WinExecAndWait(const Path: PChar; const Visibility: Word; const Wait: Boolean): Boolean;
    procedure LimparCampos;
  public
    { Public declarations }
  end;

var
  FMain: TFMain;

implementation

{$R *.dfm}

{------------------------------------------------------------------------------}
function TFMain.TestarConexao: Boolean;
begin
  Result := False;
  with DB do
  try
    HostName := Trim(edtHost.Text);
    User := Trim(edtUsuario.Text);
    Port := StrToInt( IfThen(Trim(edtPorta.Text) = '', '0', Trim(edtPorta.Text) ));
    Password := Trim(edtSenha.Text);
    Database := 'postgres';
    LibraryLocation := ExtractFilePath(Application.ExeName)+'libpq.dll';
    Connected := True;
    Result := Connected;
  except end;
end;
{------------------------------------------------------------------------------}
procedure TFMain.BitBtn1Click(Sender: TObject);
begin
  if Trim(edtHost.Text) = '' then
  begin
    edtHost.SetFocus;
    raise Exception.Create('Informe o endereço do servidor.');
  end;

  if Trim(edtPorta.Text) = '' then
  begin
    edtPorta.SetFocus;
    raise Exception.Create('Informe o número da porta de conexão.');
  end;

  if Trim(edtSenha.Text) = '' then
  begin
    edtSenha.SetFocus;
    raise Exception.Create('Informe a senha de conexão do banco de dados.');
  end;

  if Trim(edtUsuario.Text) = '' then
  begin
    edtUsuario.SetFocus;
    raise Exception.Create('Informe o usuário de conexão.');
  end;

  if Trim(edtBin.Text) = '' then
  begin
    edtBin.SetFocus;
    raise Exception.Create('Selecione o diretório bin do postgres.');
  end;

  if Trim(edtNomeBanco.Text) = '' then
  begin
    edtNomeBanco.SetFocus;
    raise Exception.Create('Informe o nome do banco de dados.');
  end;

  if TestarConexao then
    Application.MessageBox('Conexão realizada com sucesso','Conexão', MB_ICONINFORMATION + MB_OK)
  else
    Application.MessageBox('Falha na conexão com o banco de dados','Conexão', MB_ICONERROR + MB_OK);

end;
{------------------------------------------------------------------------------}
procedure TFMain.EncerrarConexao;
begin
  DB.Connected := False;
end;
{------------------------------------------------------------------------------}
procedure TFMain.BitBtn2Click(Sender: TObject);
begin
  OpenDialog1.InitialDir := 'C:\';

  if OpenDialog1.Execute then
  begin
    mPathArquivoBackup := OpenDialog1.FileName;
    lblArquivo.Lines.Clear;
    lblArquivo.Lines.Add(mPathArquivoBackup);
  end;
end;
{------------------------------------------------------------------------------}
procedure TFMain.BitBtn3Click(Sender: TObject);
begin
  if mPathArquivoBackup = '' then
  begin
    BitBtn3.SetFocus;
    raise Exception.Create('Selecione o arquivo de backup.');
  end;

  if not TestarConexao then
  begin
    Application.MessageBox('Falha na conexão com o banco de dados','Conexão', MB_ICONERROR + MB_OK);
    Exit;
  end
  else
  begin
    IniciarRestauracao;
  end;
end;
{------------------------------------------------------------------------------}
procedure TFMain.SpeedButton1Click(Sender: TObject);
var
  caminho: string;
begin
  caminho := '';
  if SelectDirectory(caminho, [sdAllowCreate, sdPerformCreate, sdPrompt],0) then
  begin
    edtBin.Text := caminho;
  end;
end;
{------------------------------------------------------------------------------}
procedure TFMain.IniciarRestauracao;
var
  ArquivoLote: string;
  ArquivoBkp: string;
  ArquivoZip: string;

  {****************************************************************************}
  function CriarScriptDB: Boolean;
  var
    F: TextFile;
    linha: string;
    UsuarioDB, SenhaDB, ServidorDB, PortaDB, NomeDB: string;
  begin
    Result := False;

    ArquivoZip := mPathArquivoBackup;
    ArquivoBkp := ExtractFilePath(ArquivoZip) + Copy(ExtractFileName(ArquivoZip),1, Length(ExtractFileName(ArquivoZip))-4)+'.bkp';

    if FileExists(ArquivoZip) then
    begin
      if DirectoryExists(Trim(edtBin.Text)) then
      begin
        try
          UsuarioDB := Trim(edtUsuario.Text);
          SenhaDB := Trim(edtSenha.Text);
          ServidorDB := Trim(edtHost.Text);
          PortaDB := Trim(edtPorta.Text);
          NomeDB := Trim(edtNomeBanco.Text);
          ArquivoLote := ExtractFilePath(Application.ExeName)+'CreateDB.bat';

          if FileExists(ArquivoLote) then
          begin
            try
              DeleteFile(ArquivoLote);
            except
              on E: Exception do
              begin
                ShowMessage(E.Message);
              end;
            end;
          end;

          AssignFile(F, ArquivoLote); //Crio o arquivo bat
          Rewrite(F); //Abro o arquivo para rescrever

          linha := '@echo off';
          Writeln(F, linha);

          linha := 'SET PGUSER='+UsuarioDB;
          Writeln(F, linha);

          linha := 'SET PGPASSWORD='+SenhaDB;
          Writeln(F, linha);

          linha := 'for /f "tokens=1,2,3,4 delims=/" %%a in (''DATE /T'') do set Date=%%a_%%b_%%c';
          Writeln(F, linha);

          linha := 'cd ' +Trim(edtBin.Text);
          Writeln(F, linha);

          linha := 'pg_restore.exe --host '+ServidorDB+' --port '+PortaDB+' --username '+UsuarioDB+' --dbname '+NomeDB+' "'+(ArquivoBkp)+'"';
          Writeln(F, linha);

          CloseFile(F); //Fecho o arquivo

          Result := True;
        except
          on E: Exception do
          begin
            ShowMessage('Erro ao criar o arquivo... '+E.Message);
          end;
        end;
      end
      else
        ShowMessage('Diretório BIN do banco de dados não existe...');
    end
    else
      ShowMessage('O arquivo de origem do backup não existe...');
  end;
  {****************************************************************************}
  procedure ApagarScriptBackup;
  begin
    if FileExists(ArquivoLote) then
    begin
      try
        DeleteFile(ArquivoLote);
      except
        on E: Exception do
        begin
          ShowMessage(E.Message);
        end;
      end;
    end;
  end;
  {****************************************************************************}
  procedure ExecutarScriptBackup;
  begin
    //Antes de executar o script, devo descompactar o arquivo...
    DescompactarArquivo(ArquivoZip, ArquivoBkp);

    if FileExists(ArquivoBkp) then
    begin
      if FileExists(ArquivoLote) then
        WinExecAndWait(PChar(ArquivoLote), SW_HIDE, True);
    end
    else
      ShowMessage('Arquivo de script não localizado.');
  end;
  {****************************************************************************}
  function CriarBancoDados(nomeDB: string): Boolean;
  begin
    Result := False;

    with TZQuery.Create(nil) do
    try
      Connection := DB;
      Close;
      SQL.Clear;

      SQL.Add('SELECT * FROM pg_database WHERE datname = :dbName ');
      Params.ParamByName('dbName').Value := nomeDB;
      Open;

      if RecordCount > 0 then
      begin
        Close;
        SQL.Clear;
        SQL.Add('DROP DATABASE '+nomeDB);
        try
          ExecSQL;
        except
          on e: Exception do
          begin
            ShowMessage(e.Message);
          end;
        end;
      end;

      Close;
      SQL.Clear;
      SQL.Add('CREATE DATABASE '+Trim(nomeDB)                );
      SQL.Add('WITH OWNER = '+Trim(edtUsuario.Text)          );
      SQL.Add('     TEMPLATE = template0                    ');
      SQL.Add('     ENCODING = ''WIN1252''                  ');
      SQL.Add('     TABLESPACE = pg_default                 ');
      SQL.Add('     LC_COLLATE = ''Portuguese_Brazil.1252'' ');
      SQL.Add('     LC_CTYPE = ''Portuguese_Brazil.1252''   ');
      SQL.Add('     CONNECTION LIMIT = -1;                  ');
      try
        ExecSQL;
        Result := True;
      except
        on e: Exception do
        begin
          ShowMessage(e.Message);
        end;
      end;
    finally
      Free;
    end;
  end;
  {****************************************************************************}
begin
  try
    Screen.Cursor := crHourGlass;

    if not CriarBancoDados(edtNomeBanco.Text) then
      Application.MessageBox('Falha ao criar banco de dados','Restore', MB_ICONERROR + MB_OK)
    else
    begin
      CriarScriptDB;
      ExecutarScriptBackup;
      ApagarScriptBackup;
      Application.MessageBox('Restauração concluida','Restore', MB_ICONINFORMATION + MB_OK);
      LimparCampos;
    end;
  finally
    Screen.Cursor := crDefault;
  end;
end;
{------------------------------------------------------------------------------}
function TFMain.WinExecAndWait(const Path: PChar; const Visibility: Word; const Wait: Boolean): Boolean;
var
  ProcessInformation: TProcessInformation;
  StartupInfo: TStartupInfo;
begin
  FillChar(StartupInfo, SizeOf(TStartupInfo), 0);
  with StartupInfo do
  begin
    cb            := SizeOf(TStartupInfo);
    lpReserved    := nil;
    lpDesktop     := nil;
    lpTitle       := nil;
    dwFlags       := STARTF_USESHOWWINDOW;
    wShowWindow   := Visibility;
    cbReserved2   := 0;
    lpReserved2   := nil;
  end;
  Result := CreateProcess(nil,
                          Path,
                          nil,
                          nil,
                          False,
                          NORMAL_PRIORITY_CLASS,
                          nil,
                          nil,
                          StartupInfo,
                          ProcessInformation);

  if Result then
  begin
    with ProcessInformation do
    begin
      if Wait then
      WaitForSingleObject(hProcess, INFINITE);
      CloseHandle(hThread);
      CloseHandle(hProcess);
    end;
  end;
end;
{------------------------------------------------------------------------------}
procedure TFMain.LimparCampos;
begin
  edtHost.Clear;
  edtPorta.Clear;
  edtSenha.Clear;
  edtUsuario.Clear;
  edtBin.Clear;
  lblArquivo.Clear;
  mPathArquivoBackup := '';
  edtNomeBanco.Clear;
end;
{------------------------------------------------------------------------------}

end.
