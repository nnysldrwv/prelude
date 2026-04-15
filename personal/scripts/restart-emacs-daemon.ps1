param(
    [Parameter(Mandatory = $true)]
    [int]$OldPid,

    [Parameter(Mandatory = $true)]
    [string]$EmacsBinDir,

    [Parameter(Mandatory = $true)]
    [string]$ServerFile,

    [string]$ServerName = "server",

    [switch]$LaunchClient,

    [switch]$Launcher
)

$ErrorActionPreference = "Stop"

function Get-PowerShellExe {
    $candidates = @("pwsh", "pwsh.exe", "powershell.exe")
    foreach ($candidate in $candidates) {
        $command = Get-Command $candidate -ErrorAction SilentlyContinue
        if ($command) {
            return $command.Source
        }
    }

    throw "PowerShell executable not found."
}

if ($Launcher) {
    $argumentList = @(
        "-NoProfile",
        "-NonInteractive",
        "-ExecutionPolicy", "Bypass",
        "-File", $PSCommandPath,
        "-OldPid", $OldPid,
        "-EmacsBinDir", $EmacsBinDir,
        "-ServerFile", $ServerFile,
        "-ServerName", $ServerName
    )

    if ($LaunchClient) {
        $argumentList += "-LaunchClient"
    }

    Start-Process -FilePath (Get-PowerShellExe) `
        -ArgumentList $argumentList `
        -WindowStyle Hidden | Out-Null
    exit 0
}

$emacsClientExe = Join-Path $EmacsBinDir "emacsclient.exe"
$emacsClientwExe = Join-Path $EmacsBinDir "emacsclientw.exe"

if (-not (Test-Path $emacsClientExe)) {
    throw "emacsclient.exe not found at: $emacsClientExe"
}

if ($LaunchClient -and -not (Test-Path $emacsClientwExe)) {
    throw "emacsclientw.exe not found at: $emacsClientwExe"
}

$existingProcess = Get-Process -Id $OldPid -ErrorAction SilentlyContinue
if ($existingProcess) {
    Wait-Process -Id $OldPid
}

$startupArgs = @("-n", "--eval", "(emacs-pid)", "-f", $ServerFile, "--alternate-editor=")

Start-Process -FilePath $emacsClientExe `
    -ArgumentList $startupArgs `
    -WindowStyle Hidden | Out-Null

$probeArgs = @("-f", $ServerFile, "--eval", "(list (daemonp) window-system)")
$deadline = (Get-Date).AddSeconds(15)
$ready = $false
$windowSystem = $null

while ((Get-Date) -lt $deadline) {
    Start-Sleep -Milliseconds 250
    $probeOutput = & $emacsClientExe @probeArgs 2>$null
    if ($LASTEXITCODE -eq 0) {
        $ready = $true
        if ($probeOutput -match '\(t\s+([^)]+)\)') {
            $windowSystem = $matches[1]
        }
        break
    }
}

if (-not $ready) {
    throw "Emacs daemon did not become ready within 15 seconds."
}

if ($windowSystem -eq "nil") {
    throw "Emacs daemon started without a window system."
}

if (-not $LaunchClient) {
    exit 0
}

Start-Process -FilePath $emacsClientwExe `
    -ArgumentList @("-n", "-c", "-f", $ServerFile, "-F", "((my-restart-helper-frame . t))") `
    -WindowStyle Hidden | Out-Null
