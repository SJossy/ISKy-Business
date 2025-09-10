unit Logger;

interface

uses
  Winapi.Windows, Winapi.Messages, Vcl.ComCtrls, Vcl.StdCtrls, System.SysUtils, System.Classes, System.IOUtils, SyncObjs;

type
  TLogger = class
  private
    FStatusBar: TStatusBar;
    FProgressBar: TProgressBar;
    FMemo: TMemo;
    FLogCS: TCriticalSection;
    FLogFilePath: string;
    procedure InternalLogToFile(const Line: string);
  public
    constructor Create(aStatusBar: TStatusBar; aProgressBar: TProgressBar; aMemo: TMemo);
    destructor Destroy; override;

    procedure Status(const Msg: string);
    procedure Progress(Current, Total: Integer);
    procedure Log(const Msg: string); // Memo + File
  end;

implementation

constructor TLogger.Create(aStatusBar: TStatusBar; aProgressBar: TProgressBar; aMemo: TMemo);
begin
  FStatusBar := aStatusBar;
  FProgressBar := aProgressBar;
  FMemo := aMemo;
  FLogCS := TCriticalSection.Create;
  FLogFilePath := TPath.Combine(ExtractFilePath(ParamStr(0)), 'debug.log');
end;

destructor TLogger.Destroy;
begin
  FLogCS.Free;
  inherited;
end;

procedure TLogger.Status(const Msg: string);
begin
  if Assigned(FStatusBar) then
    FStatusBar.Panels[0].Text := Msg;
end;

procedure TLogger.Progress(Current, Total: Integer);
var
  Percent: Integer;
begin
  if Assigned(FProgressBar) then
  begin
    if Total > 0 then
      Percent := Round((Current / Total) * 100)
    else
      Percent := 0;
    FProgressBar.Visible := True;
    FProgressBar.Position := Percent;
    if Assigned(FStatusBar) and (FStatusBar.Panels.Count > 1) then
      FStatusBar.Panels[1].Text := Format('Download: %d / %d pages', [Current, Total]);
    if Current >= Total then
    begin
      FProgressBar.Visible := False;
      FStatusBar.Panels[1].Text := '';
    end;
  end;
end;

procedure TLogger.Log(const Msg: string);
var
  Line: string;
begin
  Line := FormatDateTime('yyyy-mm-dd hh:nn:ss  ', Now) + Msg;
  // Output to TMemo
  if Assigned(FMemo) then
  begin
    FMemo.Lines.Add(Line);
    FMemo.SelStart := Length(FMemo.Text);
    FMemo.SelLength := 0;
    FMemo.Perform(EM_SCROLLCARET, 0, 0);
  end;
  // Thread-safe logging to file
  InternalLogToFile(Line);
  // Optional: IDE debugger output
  {$IFDEF DEBUG}
  OutputDebugString(PChar(Line));
  {$ENDIF}
end;

procedure TLogger.InternalLogToFile(const Line: string);
var
  SL: TStringList;
begin
  FLogCS.Enter;
  try
    SL := TStringList.Create;
    try
      if FileExists(FLogFilePath) then
        SL.LoadFromFile(FLogFilePath);
      SL.Add(Line);
      SL.SaveToFile(FLogFilePath);
    finally
      SL.Free;
    end;
  finally
    FLogCS.Leave;
  end;
end;

end.

