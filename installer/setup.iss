#define MyAppName "Ultimate Downloader"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Johni12M"
#define MyAppURL "https://github.com/Johni12M/ultimate-downloader"

[Setup]
AppId={{B7C4D8F2-A193-4E6C-9D0F-2E3A4B5C6D8E}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}/issues
AppUpdatesURL={#MyAppURL}/releases
DefaultDirName={localappdata}\UltimateDownloader
DisableProgramGroupPage=yes
OutputDir=..\dist
OutputBaseFilename=ultimate-downloader-setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ChangesEnvironment=yes
PrivilegesRequired=lowest

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
Source: "..\src\*";              DestDir: "{app}\src";              Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\node_modules\*";    DestDir: "{app}\node_modules";    Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\d4sd\esm\*";        DestDir: "{app}\d4sd\esm";        Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\d4sd\cjs\*";        DestDir: "{app}\d4sd\cjs";        Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\d4sd\node_modules\*"; DestDir: "{app}\d4sd\node_modules"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\d4sd\package.json"; DestDir: "{app}\d4sd";            Flags: ignoreversion
Source: "..\package.json";      DestDir: "{app}";                 Flags: ignoreversion
Source: "..\unifont-15.0.01.ttf"; DestDir: "{app}";              Flags: ignoreversion
Source: "launcher.bat";         DestDir: "{app}\bin"; DestName: "ultimate-downloader.bat"; Flags: ignoreversion

[Registry]
Root: HKCU; Subkey: "Environment"; ValueType: expandsz; ValueName: "Path"; \
  ValueData: "{olddata};{app}\bin"; Check: NeedsAddPath('{app}\bin'); \
  Flags: preservestringtype uninsdeletevalue

[Code]
function NeedsAddPath(PathToAdd: string): Boolean;
var
  OrigPath: string;
begin
  if not RegQueryStringValue(HKCU, 'Environment', 'Path', OrigPath) then
  begin
    Result := True;
    exit;
  end;
  Result := Pos(';' + Lowercase(PathToAdd) + ';', ';' + Lowercase(OrigPath) + ';') = 0;
end;

function NodeInstalled: Boolean;
var
  ResultCode: Integer;
begin
  Result := Exec('node', '--version', '', SW_HIDE, ewWaitUntilTerminated, ResultCode)
            and (ResultCode = 0);
end;

function InitializeSetup: Boolean;
begin
  if not NodeInstalled then
  begin
    MsgBox(
      'Node.js v18 or higher is required to run Ultimate Downloader.' + #13#10 + #13#10 +
      'Please install it from https://nodejs.org/ and re-run this installer.',
      mbError, MB_OK);
    Result := False;
  end
  else
    Result := True;
end;
