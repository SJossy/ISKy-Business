unit Downloader;

interface

uses
  System.SysUtils, System.Classes, System.Net.HttpClient, System.DateUtils,
  System.StrUtils, System.IOUtils, Winapi.Windows, Winapi.ShellAPI, Vcl.Graphics, Vcl.Imaging.jpeg, Vcl.Imaging.pngimage,
  Logger;

type
  TLogProc = procedure(const Msg: string) of object;

  TDownloader = class
  private
    FLogger: TLogger;
  public
    constructor Create(aDebug: TLogger);
    function DownloadFile(const URL, LocalPath: string; const MaxAgeDays: Double; Force: Boolean = False): Boolean;
    function GetEveImageBitmap(const Category, ID, Variation, Size: string): TBitmap;

  end;

implementation

constructor TDownloader.Create(aDebug: TLogger);
begin
  inherited Create;
  FLogger := aDebug;
end;

function TDownloader.DownloadFile(const URL, LocalPath: string;
  const MaxAgeDays: Double; Force: Boolean): Boolean;
var
  Http: THTTPClient;
  FileTime: TDateTime;
begin
  Result := False;

  if FileExists(LocalPath) and not Force then
  begin
    FileTime := FileDateToDateTime(FileAge(LocalPath));
    if (Now - FileTime) < MaxAgeDays then
    begin
      FLogger.Log(Format('Cache hit for %s (age: %.1f hours)', [LocalPath, (Now - FileTime) * 24]));
      Exit(True);
    end;
  end;

  ForceDirectories(ExtractFileDir(LocalPath));
  FLogger.Log('Downloading: ' + URL);

  Http := THTTPClient.Create;
  try
    var Stream := TFileStream.Create(LocalPath, fmCreate);
    try
      Http.Get(URL, Stream);
    finally
      Stream.Free;
    end;
    Result := True;
  except
    on E: Exception do
    begin
      FLogger.Log('Download failed: ' + E.Message);
      if FileExists(LocalPath) then
        Result := True;
    end;
  end;
  Http.Free;
end;

function TDownloader.GetEveImageBitmap(const Category, ID, Variation, Size: string): TBitmap;
var
  URL: string;
  HttpClient: THttpClient;
  Stream: TMemoryStream;
  PngImg: TPngImage;
  JpegImg: TJPEGImage;
begin
  Result := TBitmap.Create;
  URL := Format('https://images.evetech.net/%s/%s/%s?size=%s', [Category, ID, Variation, Size]);

  HttpClient := THttpClient.Create;
  Stream := TMemoryStream.Create;
  try
    HttpClient.Get(URL, Stream);
    Stream.Position := 0;
    try
      PngImg := TPngImage.Create;
      try
        PngImg.LoadFromStream(Stream);
        Result.Assign(PngImg);
        Exit;
      finally
        PngImg.Free;
      end;
    except
      Stream.Position := 0; // Reset for JPEG attempt
      JpegImg := TJPEGImage.Create;
      try
        JpegImg.LoadFromStream(Stream);
        Result.Assign(JpegImg);
      finally
        JpegImg.Free;
      end;
    end;
  finally
    Stream.Free;
    HttpClient.Free;
  end;
end;


end.

