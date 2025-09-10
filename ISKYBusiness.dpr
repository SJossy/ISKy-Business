program ISKYBusiness;



{$R *.dres}

uses
  Vcl.Forms,
  Unit1 in 'Unit1.pas' {Form1},
  TransactionView in 'TransactionView.pas' {FormTransaction},
  Parser in 'Parser.pas',
  Downloader in 'Downloader.pas',
  FileUtils in 'FileUtils.pas',
  OrderAnalyzer in 'OrderAnalyzer.pas',
  RegionManager in 'RegionManager.pas',
  Logger in 'Logger.pas',
  CacheHelper in 'CacheHelper.pas',
  ESIClient in 'ESIClient.pas',
  Common in 'Common.pas' {$R *.res},
  Vcl.Themes,
  Vcl.Styles;

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Auric');
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TFormTransaction, FormTransaction);
  Application.Run;
end.
