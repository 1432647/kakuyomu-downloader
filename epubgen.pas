unit epubgen;

{$IFDEF FPC}
  {$MODE Delphi}
  {$codepage utf8}
{$ENDIF}

interface

uses
  {$IFDEF FPC}
  Classes, SysUtils, LazUTF8, zipper;
  {$ELSE}
  System.Classes, System.SysUtils, LazUTF8wrap, zipper;
  {$ENDIF}

type
  TEpubBuilder = class
  private
    FFilePath: string;
    FTitle: string;
    FAuthor: string;
    FPublisher: string;
    FDescription: string;
    FCoverImage: string;
    FChapterTitles: TStringList;
    FChapterContents: TStringList;
    FVolumes: TStringList;
    FVolumeStarts: TStringList;
    FStreams: TList;
    FUID: string;
    function GenerateUUID: string;
    function BuildContainerXML: string;
    function BuildOPF: string;
    function BuildNCX: string;
    function BuildXHTML(const title, body: string): string;
    procedure AddStringToZip(Z: TZipper; const ArchiveName, Data: string; Compress: Boolean);
    function EscapeXML(const S: string): string;
  public
    constructor Create(const AFilePath: string);
    destructor Destroy; override;
    procedure SetMetadata(const ATitle, AAuthor, APublisher, ADescription: string);
    procedure AddChapter(const ATitle, AContent: string);
    procedure AddVolumeChapter(const AVolTitle, AChTitle, AContent: string);
    procedure SetCover(const AImagePath: string);
    function ChapterCount: integer;
    property OutputPath: string read FFilePath;
    procedure Save;
  end;

implementation

constructor TEpubBuilder.Create(const AFilePath: string);
begin
  FFilePath := AFilePath;
  FTitle := '';
  FAuthor := '';
  FPublisher := '';
  FDescription := '';
  FCoverImage := '';
  FChapterTitles := TStringList.Create;
  FChapterContents := TStringList.Create;
  FVolumes := TStringList.Create;
  FVolumeStarts := TStringList.Create;
  FStreams := TList.Create;
  FUID := GenerateUUID;
end;

destructor TEpubBuilder.Destroy;
var
  i: integer;
begin
  for i := 0 to FStreams.Count - 1 do
    TStream(FStreams[i]).Free;
  FStreams.Free;
  FChapterTitles.Free;
  FChapterContents.Free;
  FVolumes.Free;
  FVolumeStarts.Free;
  inherited;
end;

function TEpubBuilder.GenerateUUID: string;
var
  g: TGuid;
begin
  CreateGUID(g);
  Result := 'urn:uuid:' + LowerCase(GUIDToString(g));
end;

procedure TEpubBuilder.SetMetadata(const ATitle, AAuthor, APublisher, ADescription: string);
begin
  FTitle := ATitle;
  FAuthor := AAuthor;
  FPublisher := APublisher;
  FDescription := ADescription;
end;

procedure TEpubBuilder.AddChapter(const ATitle, AContent: string);
begin
  FChapterTitles.Add(ATitle);
  FChapterContents.Add(AContent);
end;

procedure TEpubBuilder.AddVolumeChapter(const AVolTitle, AChTitle, AContent: string);
var
  idx: integer;
begin
  AddChapter(AChTitle, AContent);
  idx := FChapterTitles.Count - 1;
  if FVolumes.Count = 0 then
  begin
    FVolumes.Add(AVolTitle);
    FVolumeStarts.Add(IntToStr(idx));
  end
  else if FVolumes[FVolumes.Count - 1] <> AVolTitle then
  begin
    FVolumes.Add(AVolTitle);
    FVolumeStarts.Add(IntToStr(idx));
  end;
end;

procedure TEpubBuilder.SetCover(const AImagePath: string);
begin
  FCoverImage := AImagePath;
end;

function TEpubBuilder.ChapterCount: integer;
begin
  Result := FChapterTitles.Count;
end;

function TEpubBuilder.EscapeXML(const S: string): string;
begin
  Result := UTF8StringReplace(S, '&', '&amp;', [rfReplaceAll]);
  Result := UTF8StringReplace(Result, '<', '&lt;', [rfReplaceAll]);
  Result := UTF8StringReplace(Result, '>', '&gt;', [rfReplaceAll]);
  Result := UTF8StringReplace(Result, '"', '&quot;', [rfReplaceAll]);
end;

function TEpubBuilder.BuildContainerXML: string;
begin
  Result := '<?xml version="1.0" encoding="UTF-8"?>' + #10 +
    '<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">' + #10 +
    '  <rootfiles>' + #10 +
    '    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>' + #10 +
    '  </rootfiles>' + #10 +
    '</container>';
end;

function TEpubBuilder.BuildOPF: string;
var
  i: integer;
  manifest, spine: string;
begin
  manifest := '';
  spine := '';

  if FCoverImage <> '' then
    manifest := manifest +
      '    <item id="cover-image" href="' + EscapeXML(FCoverImage) + '" media-type="image/jpeg"/>' + #10;

  manifest := manifest +
    '    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>' + #10;

  for i := 0 to FChapterTitles.Count - 1 do
  begin
    manifest := manifest +
      '    <item id="ch' + IntToStr(i + 1) + '" href="ch' + IntToStr(i + 1) + '.xhtml" media-type="application/xhtml+xml"/>' + #10;
    spine := spine +
      '    <itemref idref="ch' + IntToStr(i + 1) + '"/>' + #10;
  end;

  Result := '<?xml version="1.0" encoding="UTF-8"?>' + #10 +
    '<package version="2.0" xmlns="http://www.idpf.org/2007/opf" unique-identifier="BookId">' + #10 +
    '  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:opf="http://www.idpf.org/2007/opf">' + #10 +
    '    <dc:identifier id="BookId" opf:scheme="UUID">' + EscapeXML(FUID) + '</dc:identifier>' + #10 +
    '    <dc:title>' + EscapeXML(FTitle) + '</dc:title>' + #10 +
    '    <dc:creator opf:role="aut">' + EscapeXML(FAuthor) + '</dc:creator>' + #10 +
    '    <dc:publisher>' + EscapeXML(FPublisher) + '</dc:publisher>' + #10 +
    '    <dc:description>' + EscapeXML(FDescription) + '</dc:description>' + #10 +
    '    <dc:language>ja</dc:language>' + #10;

  if FCoverImage <> '' then
    Result := Result +
      '    <meta name="cover" content="cover-image"/>' + #10;

  Result := Result +
    '  </metadata>' + #10 +
    '  <manifest>' + #10 +
    manifest +
    '  </manifest>' + #10 +
    '  <spine toc="ncx">' + #10 +
    spine +
    '  </spine>' + #10 +
    '</package>';
end;

function TEpubBuilder.BuildNCX: string;
var
  i, vi, vs, ve, playOrder: integer;
  navMap: string;
  volTitle: string;
begin
  navMap := '';
  playOrder := 1;

  // volumeFirst[vi] = index of first chapter in volume vi
  // volumeLast[vi]  = index after last chapter (or -1 for last volume = total)
  for vi := 0 to FVolumes.Count - 1 do
  begin
    vs := StrToInt(FVolumeStarts[vi]);
    if vi + 1 < FVolumes.Count then
      ve := StrToInt(FVolumeStarts[vi + 1]) - 1
    else
      ve := FChapterTitles.Count - 1;

    if vs > ve then Continue;

    volTitle := FVolumes[vi];

    if FVolumes.Count > 1 then
    begin
      // volume as parent navPoint
      navMap := navMap +
        '    <navPoint id="navVol-' + IntToStr(vi + 1) + '" playOrder="' + IntToStr(playOrder) + '">' + #10 +
        '      <navLabel>' + #10 +
        '        <text>' + EscapeXML(volTitle) + '</text>' + #10 +
        '      </navLabel>' + #10 +
        '      <content src="ch' + IntToStr(vs + 1) + '.xhtml"/>' + #10;
      Inc(playOrder);
    end;

    for i := vs to ve do
    begin
      navMap := navMap +
        '      <navPoint id="navPoint-' + IntToStr(i + 1) + '" playOrder="' + IntToStr(playOrder) + '">' + #10 +
        '        <navLabel>' + #10 +
        '          <text>' + EscapeXML(FChapterTitles[i]) + '</text>' + #10 +
        '        </navLabel>' + #10 +
        '        <content src="ch' + IntToStr(i + 1) + '.xhtml"/>' + #10 +
        '      </navPoint>' + #10;
      Inc(playOrder);
    end;

    if FVolumes.Count > 1 then
      navMap := navMap + '    </navPoint>' + #10;
  end;

  if FVolumes.Count <= 1 then
  begin
    // flat structure: no volumes or single volume
    for i := 0 to FChapterTitles.Count - 1 do
    begin
      navMap := navMap +
        '    <navPoint id="navPoint-' + IntToStr(i + 1) + '" playOrder="' + IntToStr(playOrder) + '">' + #10 +
        '      <navLabel>' + #10 +
        '        <text>' + EscapeXML(FChapterTitles[i]) + '</text>' + #10 +
        '      </navLabel>' + #10 +
        '        <content src="ch' + IntToStr(i + 1) + '.xhtml"/>' + #10 +
        '    </navPoint>' + #10;
      Inc(playOrder);
    end;
  end;

  Result := '<?xml version="1.0" encoding="UTF-8"?>' + #10 +
    '<!DOCTYPE ncx PUBLIC "-//NISO//DTD ncx 2005-1//EN" "http://www.daisy.org/z3986/2005/ncx-2005-1.dtd">' + #10 +
    '<ncx version="2005-1" xmlns="http://www.daisy.org/z3986/2005/ncx/">' + #10 +
    '  <head>' + #10 +
    '    <meta name="dtb:uid" content="' + EscapeXML(FUID) + '"/>' + #10 +
    '    <meta name="dtb:depth" content="2"/>' + #10 +
    '    <meta name="dtb:totalPageCount" content="0"/>' + #10 +
    '    <meta name="dtb:maxPageNumber" content="0"/>' + #10 +
    '  </head>' + #10 +
    '  <docTitle>' + #10 +
    '    <text>' + EscapeXML(FTitle) + '</text>' + #10 +
    '  </docTitle>' + #10 +
    '  <navMap>' + #10 +
    navMap +
    '  </navMap>' + #10 +
    '</ncx>';
end;

function TEpubBuilder.BuildXHTML(const title, body: string): string;
begin
  Result := '<?xml version="1.0" encoding="UTF-8"?>' + #10 +
    '<!DOCTYPE html>' + #10 +
    '<html xmlns="http://www.w3.org/1999/xhtml">' + #10 +
    '<head>' + #10 +
    '  <title>' + EscapeXML(title) + '</title>' + #10 +
    '</head>' + #10 +
    '<body>' + #10 +
    '<h2>' + EscapeXML(title) + '</h2>' + #10 +
    body + #10 +
    '</body>' + #10 +
    '</html>';
end;

procedure TEpubBuilder.AddStringToZip(Z: TZipper; const ArchiveName, Data: string; Compress: Boolean);
var
  Entry: TZipFileEntry;
  MS: TMemoryStream;
begin
  MS := TMemoryStream.Create;
  FStreams.Add(MS);
  if Length(Data) > 0 then
    MS.WriteBuffer(Data[1], Length(Data));
  MS.Position := 0;

  Entry := TZipFileEntry(Z.Entries.Add);
  Entry.ArchiveFileName := ArchiveName;
  Entry.Stream := MS;
end;

procedure TEpubBuilder.Save;
var
  Z: TZipper;
  i: integer;
  xhtml: string;
begin
  ForceDirectories(ExtractFilePath(FFilePath));

  Z := TZipper.Create;
  try
    Z.FileName := FFilePath;

    AddStringToZip(Z, 'mimetype', 'application/epub+zip', False);
    AddStringToZip(Z, 'META-INF/container.xml', BuildContainerXML, True);
    AddStringToZip(Z, 'OEBPS/content.opf', BuildOPF, True);
    AddStringToZip(Z, 'OEBPS/toc.ncx', BuildNCX, True);

    for i := 0 to FChapterTitles.Count - 1 do
    begin
      xhtml := BuildXHTML(FChapterTitles[i], FChapterContents[i]);
      AddStringToZip(Z, 'OEBPS/ch' + IntToStr(i + 1) + '.xhtml', xhtml, True);
    end;

    Z.ZipAllFiles;
  finally
    Z.Free;
  end;
end;

end.
