unit FileUtils;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections, Vcl.Imaging.pngimage, Vcl.ExtCtrls;

function LoadIconsFromBin(const BinFile: string): TDictionary<Integer, TBytes>;
procedure ShowIconFromBin(Icons: TDictionary<Integer, TBytes>; typeID: Integer; img: TImage);

implementation

function LoadIconsFromBin(const BinFile: string): TDictionary<Integer, TBytes>;
var
  FileStream: TFileStream;
  NumIcons, i, ImgLen, typeID: Integer;
  ImgData: TBytes;
  Icons: TDictionary<Integer, TBytes>;
begin
  Icons := TDictionary<Integer, TBytes>.Create;
  FileStream := TFileStream.Create(BinFile, fmOpenRead or fmShareDenyWrite);
  try
    if FileStream.Size < SizeOf(NumIcons) then
      raise Exception.Create('Bin file too small (no icon count header)');
    FileStream.ReadBuffer(NumIcons, SizeOf(NumIcons));
    for i := 1 to NumIcons do
    begin
      // Defensive: verify enough bytes for typeID
      if FileStream.Position + SizeOf(typeID) > FileStream.Size then
        raise Exception.CreateFmt('Missing typeID at entry %d', [i]);
      FileStream.ReadBuffer(typeID, SizeOf(typeID));

      // Defensive: verify enough bytes for ImgLen
      if FileStream.Position + SizeOf(ImgLen) > FileStream.Size then
        raise Exception.CreateFmt('Missing ImgLen at entry %d (typeID %d)', [i, typeID]);
      FileStream.ReadBuffer(ImgLen, SizeOf(ImgLen));

      // Defensive: verify enough bytes for image itself
      if FileStream.Position + ImgLen > FileStream.Size then
        raise Exception.CreateFmt(
          'Missing image data at entry %d (typeID %d, ImgLen %d)', [i, typeID, ImgLen]);
      SetLength(ImgData, ImgLen);
      if ImgLen > 0 then
        FileStream.ReadBuffer(ImgData[0], ImgLen);

      Icons.Add(typeID, ImgData);
    end;
  finally
    FileStream.Free;
  end;
  Result := Icons;
end;


procedure ShowIconFromBin(Icons: TDictionary<Integer, TBytes>; typeID: Integer; img: TImage);
var
  PNG: TPNGImage;
  MemStream: TMemoryStream;
begin
  if Icons.ContainsKey(typeID) then
  begin
    MemStream := TMemoryStream.Create;
    PNG := TPNGImage.Create;
    try
      MemStream.WriteBuffer(Icons[typeID][0], Length(Icons[typeID]));
      MemStream.Position := 0;
      PNG.LoadFromStream(MemStream);
      img.Picture.Graphic := PNG;
    finally
      PNG.Free;
      MemStream.Free;
    end;
  end
  else
    img.Picture := nil; // No icon found
end;

end.

