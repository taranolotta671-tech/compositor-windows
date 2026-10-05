; Compositor — the Windows community port, packaged for installation.
;
; The port itself lives in windows/ on the compositor_win branch (C#, .NET 10, Avalonia). This script
; turns its published output into an installer: the app in a program folder, a Start Menu entry, an
; optional desktop icon, and an entry in Apps & features that uninstalls it again.
;
; Build the payload first, from windows/:
;     dotnet publish src\Compositor.Desktop -c Release -o dist-slim
; then compile this script:
;     "C:\Users\<you>\AppData\Local\Programs\Inno Setup 6\ISCC.exe" installer\Compositor.iss

#define AppName        "Compositor"
#define AppVersion     "1.3.7"
#define AppExeName     "Compositor.Desktop.exe"
#define AppPublisher   "Wonder Assembly LLC (macOS original) and the Compositor Windows port"
#define AppURL         "https://github.com/robbietilton/Compositor"
#define PortURL        "https://github.com/chenguisen/Compositor/tree/compositor_win"

[Setup]
; A fixed AppId is what lets a later version upgrade this one rather than sit beside it.
AppId={{8B7C1E42-3F5A-4D19-9C6E-2A41B0D73F58}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppURL}
AppSupportURL={#PortURL}
VersionInfoVersion={#AppVersion}
VersionInfoDescription={#AppName} Setup — the open-source Photoshop alternative

; The default used to be {autopf}, which is Program Files for an all-users install and the per-user
; Programs folder otherwise — the system drive either way. A fresh install now defaults to D:\,
; because the system drive is not where a 64 MB application belongs. The directory page still shows,
; so anyone who wants somewhere else can say so. GetDefaultDir below decides it.
DefaultDirName={code:GetDefaultDir}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
; Per-user by default so no elevation is needed, with the choice offered on the way in.
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

OutputDir=output
OutputBaseFilename={#AppName}-{#AppVersion}-win-x64-setup
SetupIconFile=..\src\Compositor.Desktop\Assets\compositor.ico
UninstallDisplayIcon={app}\{#AppExeName}
UninstallDisplayName={#AppName} {#AppVersion}

Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern

; The repository root, one level up. This was ..\..\LICENSE, which is where it sat inside the
; upstream windows/ subtree; this repository is flat, so two levels up walks out of it and Inno
; Setup fails to compile. CI never caught it because nothing here compiles this script.
LicenseFile=..\LICENSE

[Languages]
; Compositor's own interface is English, and Inno Setup ships no Simplified Chinese translation
; (the unofficial set has none either), so the installer is English to match.
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; The published output, flat: the .NET 10 runtime is the machine's rather than a copy in here.
Source: "..\dist-slim\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; The MIT notice travels with the build — the licence asks for it, and the repository carries the same
; file at its root. It is shown during setup as well, through LicenseFile above.
Source: "..\LICENSE"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{group}\{cm:UninstallProgram,{#AppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(AppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]
{ Where a fresh install goes: D:\{#AppName} when there is a D: with room for it, and the old
  {autopf}\{#AppName} when there is not. Only the default is decided here — the directory page still
  appears, and an existing installation keeps its own directory because Inno Setup remembers it
  under the same AppId and upgrades it in place. }
function GetDefaultDir(Param: String): String;
var
  FreeMB: Cardinal;
  TotalMB: Cardinal;
begin
  if GetSpaceOnDisk(ExpandConstant('D:\'), True, FreeMB, TotalMB) and (FreeMB >= 1024) then
    Result := ExpandConstant('D:\{#AppName}')
  else
    Result := ExpandConstant('{autopf}\{#AppName}');
end;

{ Whether the .NET 10 desktop runtime is on the machine: the app is framework-dependent, so without it
  the shortcut would install and then do nothing. Both the machine-wide and the per-user place are
  looked in, since .NET installs to either. }
function HasDotNet10Desktop(): Boolean;
var
  FindRec: TFindRec;
  Root: String;
begin
  Result := False;
  Root := ExpandConstant('{commonpf}\dotnet\shared\Microsoft.WindowsDesktop.App');
  if FindFirst(Root + '\10.*', FindRec) then
  begin
    Result := True;
    FindClose(FindRec);
  end;
  if not Result then
  begin
    Root := ExpandConstant('{localappdata}\Microsoft\dotnet\shared\Microsoft.WindowsDesktop.App');
    if FindFirst(Root + '\10.*', FindRec) then
    begin
      Result := True;
      FindClose(FindRec);
    end;
  end;
end;

function InitializeSetup(): Boolean;
begin
  Result := True;
  if not HasDotNet10Desktop() then
  begin
    if MsgBox('Compositor needs the .NET 10 Desktop Runtime, and this machine does not have it.'
        + #13#10 + #13#10
        + 'It is a free download from Microsoft:' + #13#10
        + '    https://dotnet.microsoft.com/download/dotnet/10.0' + #13#10 + #13#10
        + 'Install it first, or continue and install Compositor anyway — it will start once the'
        + ' runtime is there.' + #13#10 + #13#10
        + 'Continue with the installation?',
        mbConfirmation, MB_YESNO) = IDNO then
      Result := False;
  end;
end;
