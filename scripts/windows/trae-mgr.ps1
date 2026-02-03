<#
.SYNOPSIS
TRAE Manager for Windows (PowerShell Version)

.DESCRIPTION
Switch between multiple TRAE IDE accounts on Windows.
Inspired by Antigravity Manager.

.EXAMPLE
.\trae-mgr.ps1 save my_account
.\trae-mgr.ps1 switch my_account
#>

param (
    [string]$Command,
    [string]$Name
)

$ErrorActionPreference = "Stop"

# Configuration
$AppData = $env:APPDATA
$TraePath = Join-Path $AppData "Trae"
$MgrRoot = Join-Path $env:USERPROFILE ".trae-manager"
$ProfilesDir = Join-Path $MgrRoot "profiles"
$CurrentFile = Join-Path $MgrRoot "current_profile"

# Colors
function Write-Success ($msg) { Write-Host "✓ $msg" -ForegroundColor Green }
function Write-ErrorMsg ($msg) { Write-Host "✗ $msg" -ForegroundColor Red }
function Write-Info ($msg) { Write-Host "ℹ $msg" -ForegroundColor Cyan }
function Write-Warn ($msg) { Write-Host "! $msg" -ForegroundColor Yellow }

# Init
if (!(Test-Path $ProfilesDir)) { New-Item -ItemType Directory -Path $ProfilesDir | Out-Null }

# Helper: Check if TRAE is running
function Test-TraeRunning {
    return (Get-Process -Name "Trae" -ErrorAction SilentlyContinue)
}

# Helper: Stop TRAE
function Stop-Trae {
    if (Test-TraeRunning) {
        Write-Info "Stopping TRAE..."
        Stop-Process -Name "Trae" -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        if (Test-TraeRunning) {
            Write-ErrorMsg "Failed to stop TRAE. Please close it manually."
            exit 1
        }
        Write-Success "TRAE stopped"
    }
}

# Helper: Get Current Profile
function Get-CurrentProfile {
    if (Test-Path $TraePath -PathType Container) {
        $item = Get-Item $TraePath
        if ($item.LinkType -eq "Junction" -or $item.LinkType -eq "SymbolicLink") {
            return ($item.Target -split "\\")[-1]
        }
        return "(original)"
    }
    return "(none)"
}

# Commands

function Show-Help {
    Write-Host ""
    Write-Host "TRAE Manager (Windows)" -ForegroundColor Cyan
    Write-Host "Usage: .\trae-mgr.ps1 <command> [name]"
    Write-Host ""
    Write-Host "Commands:"
    Write-Host "  list              List all profiles"
    Write-Host "  save <name>       Save current session"
    Write-Host "  create <name>     Create empty profile"
    Write-Host "  switch <name>     Switch profile"
    Write-Host "  delete <name>     Delete profile"
    Write-Host "  current           Show active profile"
    Write-Host ""
}

function List-Profiles {
    Write-Host "Saved Profiles:"
    $current = Get-CurrentProfile
    $items = Get-ChildItem $ProfilesDir -Directory
    
    if ($items.Count -eq 0) {
        Write-Warn "No profiles found."
    } else {
        foreach ($item in $items) {
            if ($item.Name -eq $current) {
                Write-Host "  ● $($item.Name) (active)" -ForegroundColor Green
            } else {
                Write-Host "  ○ $($item.Name)" -ForegroundColor Blue
            }
        }
    }
    Write-Host ""
    Write-Host "Current: $current"
}

function Save-Profile ($pName) {
    if ([string]::IsNullOrWhiteSpace($pName)) { Write-ErrorMsg "Name required"; exit 1 }
    
    $dest = Join-Path $ProfilesDir $pName
    
    if (Test-Path $dest) {
        Write-Warn "Profile '$pName' exists. Overwrite? (y/n)"
        $confirm = Read-Host
        if ($confirm -ne "y") { exit }
        Remove-Item $dest -Recurse -Force
    }
    
    # Get source
    $source = $TraePath
    if (Test-Path $TraePath) {
        $item = Get-Item $TraePath
        if ($item.LinkType -eq "Junction" -or $item.LinkType -eq "SymbolicLink") {
            $source = $item.Target
        }
    } else {
        Write-ErrorMsg "No TRAE data found"
        exit 1
    }
    
    Write-Info "Copying data to '$pName'..."
    Copy-Item -Path $source -Destination $dest -Recurse
    Write-Success "Saved profile '$pName'"
}

function Create-Profile ($pName) {
    if ([string]::IsNullOrWhiteSpace($pName)) { Write-ErrorMsg "Name required"; exit 1 }
    $dest = Join-Path $ProfilesDir $pName
    if (Test-Path $dest) { Write-ErrorMsg "Profile exists"; exit 1 }
    New-Item -ItemType Directory -Path $dest | Out-Null
    Write-Success "Created empty profile '$pName'"
}

function Switch-Profile ($pName) {
    if ([string]::IsNullOrWhiteSpace($pName)) { Write-ErrorMsg "Name required"; exit 1 }
    $source = Join-Path $ProfilesDir $pName
    if (!(Test-Path $source)) { Write-ErrorMsg "Profile not found"; exit 1 }
    
    Stop-Trae
    
    # Backup original if needed
    if ((Test-Path $TraePath) -and !((Get-Item $TraePath).LinkType)) {
        Write-Info "Backing up original to 'default'..."
        $def = Join-Path $ProfilesDir "default"
        Move-Item $TraePath $def
    } elseif (Test-Path $TraePath) {
        Remove-Item $TraePath -Force
    }
    
    # Create Junction (safer than Symlink on Windows without Admin)
    # Using cmd /c mklink /J because PowerShell New-Item -Type Junction can be finicky on some versions
    $cmd = "mklink /J `"$TraePath`" `"$source`""
    cmd /c $cmd | Out-Null
    
    $pName | Out-File $CurrentFile -Encoding utf8
    
    Write-Success "Switched to '$pName'"
    
    Write-Info "Starting TRAE..."
    Start-Process -FilePath "$env:LOCALAPPDATA\Programs\Trae\Trae.exe" -ErrorAction SilentlyContinue
}

# Main Dispatch
switch ($Command) {
    "list" { List-Profiles }
    "save" { Save-Profile $Name }
    "create" { Create-Profile $Name }
    "switch" { Switch-Profile $Name }
    "delete" { 
        if ([string]::IsNullOrWhiteSpace($Name)) { Write-ErrorMsg "Name required"; exit 1 }
        Remove-Item (Join-Path $ProfilesDir $Name) -Recurse -Force
        Write-Success "Deleted $Name"
    }
    "current" { Write-Host (Get-CurrentProfile) }
    "help" { Show-Help }
    Default { Show-Help }
}
