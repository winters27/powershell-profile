# Ensure the script can run with elevated privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Please run this script as an Administrator!"
    break
}

function Set-PowerShellExecutionPolicy {
    try {
        Write-Host "Configuring PowerShell execution policy..." -ForegroundColor Cyan
        
        # Check current execution policy
        $currentPolicy = Get-ExecutionPolicy -Scope CurrentUser
        $machinePolicy = Get-ExecutionPolicy -Scope LocalMachine
        
        Write-Host "Current execution policies:" -ForegroundColor Yellow
        Write-Host "  CurrentUser: $currentPolicy" -ForegroundColor White
        Write-Host "  LocalMachine: $machinePolicy" -ForegroundColor White
        
        # Set execution policy for current user (safer approach)
        if ($currentPolicy -eq "Restricted" -or $currentPolicy -eq "Undefined") {
            Write-Host "Setting execution policy for CurrentUser to RemoteSigned..." -ForegroundColor Yellow
            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
            Write-Host "✓ CurrentUser execution policy set to RemoteSigned" -ForegroundColor Green
        } else {
            Write-Host "✓ CurrentUser execution policy is already configured ($currentPolicy)" -ForegroundColor Green
        }
        
        # Set for LocalMachine (system-wide) if admin and needed
        if ($machinePolicy -eq "Restricted" -or $machinePolicy -eq "Undefined") {
            Write-Host "Setting execution policy for LocalMachine to RemoteSigned..." -ForegroundColor Yellow
            try {
                Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine -Force
                Write-Host "✓ LocalMachine execution policy set to RemoteSigned" -ForegroundColor Green
            } catch {
                Write-Host "⚠ Could not set LocalMachine policy (may require higher privileges)" -ForegroundColor Yellow
                Write-Host "  CurrentUser policy should be sufficient for most scenarios" -ForegroundColor Cyan
            }
        } else {
            Write-Host "✓ LocalMachine execution policy is already configured ($machinePolicy)" -ForegroundColor Green
        }
        
        # Verify the changes
        $newCurrentPolicy = Get-ExecutionPolicy -Scope CurrentUser
        $newMachinePolicy = Get-ExecutionPolicy -Scope LocalMachine
        
        Write-Host "Updated execution policies:" -ForegroundColor Green
        Write-Host "  CurrentUser: $newCurrentPolicy" -ForegroundColor White
        Write-Host "  LocalMachine: $newMachinePolicy" -ForegroundColor White
        
        return $true
        
    } catch {
        Write-Error "Failed to configure execution policy. Error: $_"
        return $false
    }
}

# Automatically configure execution policy
Write-Host "`n═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "                 Execution Policy Configuration             " -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan

$policySuccess = Set-PowerShellExecutionPolicy
if (-not $policySuccess) {
    Write-Warning "Execution policy configuration failed. Some features may not work correctly."
} else {
    Write-Host "✓ Execution policy configuration completed!" -ForegroundColor Green
}

# Function to test internet connectivity
function Test-InternetConnection {
    try {
        $testConnection = Test-Connection -ComputerName www.google.com -Count 1 -ErrorAction Stop
        return $true
    }
    catch {
        Write-Warning "Internet connection is required but not available. Please check your connection."
        return $false
    }
}

# Function to configure Windows Terminal settings
function Set-WindowsTerminalSettings {
    try {
        Write-Host "Configuring Windows Terminal settings..." -ForegroundColor Cyan
        
        # Find Windows Terminal settings path
        $terminalSettingsPath = $null
        $possiblePaths = @(
            "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json",
            "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json",
            "$env:APPDATA\Microsoft\Windows Terminal\settings.json"
        )
        
        foreach ($path in $possiblePaths) {
            if (Test-Path (Split-Path $path -Parent)) {
                $terminalSettingsPath = $path
                Write-Host "Found Windows Terminal path: $(Split-Path $path -Parent)" -ForegroundColor Green
                break
            }
        }
        
        if (-not $terminalSettingsPath) {
            Write-Warning "Windows Terminal settings directory not found. Please ensure Windows Terminal is installed."
            return $false
        }
        
        # Create backup of existing settings
        if (Test-Path $terminalSettingsPath) {
            $backupPath = $terminalSettingsPath.Replace(".json", "_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').json")
            Copy-Item $terminalSettingsPath $backupPath -Force
            Write-Host "Existing settings backed up to: $backupPath" -ForegroundColor Yellow
        }
        
        # Create the optimized Windows Terminal settings (your updated configuration)
        $terminalSettings = @{
            '$help' = "https://aka.ms/terminal-documentation"
            '$schema' = "https://aka.ms/terminal-profiles-schema"
            actions = @(
                @{
                    command = @{
                        action = "copy"
                        singleLine = $false
                    }
                    id = "User.copy.644BA8F2"
                },
                @{
                    command = "paste"
                    id = "User.paste"
                },
                @{
                    command = @{
                        action = "splitPane"
                        split = "auto"
                        splitMode = "duplicate"
                    }
                    id = "User.splitPane.A6751878"
                },
                @{
                    command = "find"
                    id = "User.find"
                }
            )
            copyFormatting = "none"
            copyOnSelect = $false
            defaultProfile = "{574e775e-4f2a-5b96-ac1e-a2962a402336}"
            keybindings = @(
                @{
                    id = "User.copy.644BA8F2"
                    keys = "ctrl+c"
                },
                @{
                    id = "User.find"
                    keys = "ctrl+shift+f"
                },
                @{
                    id = "User.paste"
                    keys = "ctrl+v"
                },
                @{
                    id = "User.splitPane.A6751878"
                    keys = "alt+shift+d"
                }
            )
            newTabMenu = @(
                @{
                    type = "remainingProfiles"
                }
            )
            profiles = @{
                defaults = @{}
                list = @(
                    @{
                        commandline = "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
                        elevate = $true
                        guid = "{61c54bbd-c2c6-5271-96e7-009a87ff44bf}"
                        hidden = $false
                        name = "Windows PowerShell"
                        opacity = 25
                        useAcrylic = $true
                    },
                    @{
                        commandline = "%SystemRoot%\System32\cmd.exe"
                        elevate = $true
                        guid = "{0caa0dad-35be-5f56-a8ff-afceeeaa6101}"
                        hidden = $false
                        name = "Command Prompt"
                        opacity = 25
                        useAcrylic = $true
                    },
                    @{
                        guid = "{b453ae62-4e3d-5e58-b989-0a998ec441b8}"
                        hidden = $false
                        name = "Azure Cloud Shell"
                        source = "Windows.Terminal.Azure"
                    },
                    @{
                        colorScheme = "Tango Dark"
                        elevate = $true
                        font = @{
                            face = "CaskaydiaCove Nerd Font"
                            size = 15
                        }
                        guid = "{574e775e-4f2a-5b96-ac1e-a2962a402336}"
                        hidden = $false
                        name = "PowerShell"
                        opacity = 25
                        source = "Windows.Terminal.PowershellCore"
                        startingDirectory = $null
                        useAcrylic = $true
                    },
                    @{
                        guid = "{2ece5bfe-50ed-5f3a-ab87-5cd4baafed2b}"
                        hidden = $false
                        name = "Git Bash"
                        source = "Git"
                    }
                )
            }
            schemes = @()
            themes = @()
        }
        
        # Ensure the directory exists
        $settingsDir = Split-Path $terminalSettingsPath -Parent
        if (-not (Test-Path $settingsDir)) {
            New-Item -Path $settingsDir -ItemType Directory -Force | Out-Null
        }
        
        # Convert to JSON and save
        $jsonSettings = $terminalSettings | ConvertTo-Json -Depth 10
        $jsonSettings | Out-File -FilePath $terminalSettingsPath -Encoding UTF8 -Force
        
        Write-Host "✓ Windows Terminal settings configured successfully!" -ForegroundColor Green
        Write-Host "Settings saved to: $terminalSettingsPath" -ForegroundColor Cyan
        Write-Host "✓ All profiles now have transparent background (25% opacity)" -ForegroundColor Green
        Write-Host "✓ Windows PowerShell and Command Prompt set to auto-elevate" -ForegroundColor Green
        Write-Host "✓ PowerShell 7 set as default profile with Nerd Font" -ForegroundColor Green
        
        return $true
        
    } catch {
        Write-Error "Failed to configure Windows Terminal settings. Error: $_"
        return $false
    }
}

# Function to prompt user for Windows Terminal configuration
function Prompt-ConfigureTerminal {
    Write-Host "`n" -NoNewline
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "                Windows Terminal Configuration              " -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "This will configure Windows Terminal with:" -ForegroundColor White
    Write-Host "• PowerShell 7 as default profile" -ForegroundColor Cyan
    Write-Host "• CaskaydiaCove Nerd Font (size 15)" -ForegroundColor Cyan
    Write-Host "• 25% opacity with acrylic effect for all profiles" -ForegroundColor Cyan
    Write-Host "• Auto-elevation for PowerShell and Command Prompt" -ForegroundColor Cyan
    Write-Host "• Custom keybindings (Ctrl+C/V, Alt+Shift+D for split)" -ForegroundColor Cyan
    
    do {
        $response = Read-Host "`nWould you like to apply these Windows Terminal settings? (Y/N)"
        $response = $response.Trim().ToUpper()
        
        switch ($response) {
            'Y' { 
                Write-Host "Configuring Windows Terminal..." -ForegroundColor Yellow
                $success = Set-WindowsTerminalSettings
                if ($success) {
                    Write-Host "`nWindows Terminal configuration completed!" -ForegroundColor Green
                    Write-Host "Note: Restart Windows Terminal to see the changes." -ForegroundColor Yellow
                }
                return
            }
            'N' { 
                Write-Host "Windows Terminal configuration skipped." -ForegroundColor Yellow
                return
            }
            default { 
                Write-Host "Please enter 'Y' for Yes or 'N' for No." -ForegroundColor Red
            }
        }
    } while ($true)
}

function Install-PowerShell7 {
    try {
        Write-Host "Checking PowerShell version..." -ForegroundColor Cyan
        
        # Check current PowerShell version
        $currentVersion = $PSVersionTable.PSVersion
        Write-Host "Current PowerShell version: $currentVersion" -ForegroundColor Yellow
        
        # Check if PowerShell 7 exists on the system (even if not currently running)
        $ps7Path = "$env:ProgramFiles\PowerShell\7\pwsh.exe"
        $ps7Installed = Test-Path $ps7Path
        
        if ($currentVersion.Major -ge 7) {
            Write-Host "✓ PowerShell 7+ is currently running!" -ForegroundColor Green
            return $true
        } elseif ($ps7Installed) {
            try {
                $ps7Version = & $ps7Path -NoProfile -Command '$PSVersionTable.PSVersion.ToString()' 2>$null
                Write-Host "✓ PowerShell 7 is already installed (version $ps7Version)" -ForegroundColor Green
                Write-Host "  But you're currently running Windows PowerShell 5.1" -ForegroundColor Cyan
                return $true
            } catch {
                Write-Host "✓ PowerShell 7 is installed but version check failed" -ForegroundColor Green
                return $true
            }
        }
        
        Write-Host "PowerShell 7 is required for optimal profile experience." -ForegroundColor Yellow
        Write-Host "Installing PowerShell 7..." -ForegroundColor Cyan
        
        # Try winget first (most reliable)
        try {
            $wingetResult = winget install --id Microsoft.PowerShell --accept-source-agreements --accept-package-agreements --silent
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✓ PowerShell 7 installed successfully via winget!" -ForegroundColor Green
                return $true
            } else {
                Write-Host "⚠ Winget installation returned exit code: $LASTEXITCODE" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "⚠ Winget installation failed: $($_.Exception.Message)" -ForegroundColor Yellow
        }
        
        # Fallback: Direct MSI download
        Write-Host "Trying direct MSI installation..." -ForegroundColor Yellow
        
        # Get latest PowerShell release
        $apiUrl = "https://api.github.com/repos/PowerShell/PowerShell/releases/latest"
        $latestRelease = Invoke-RestMethod -Uri $apiUrl
        $latestVersion = $latestRelease.tag_name.Trim('v')
        
        # Determine architecture
        $architecture = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
        $downloadUrl = $latestRelease.assets | Where-Object { 
            $_.name -like "*win-$architecture.msi" 
        } | Select-Object -First 1 -ExpandProperty browser_download_url
        
        if (-not $downloadUrl) {
            Write-Error "Could not find PowerShell MSI download URL for $architecture architecture."
            return $false
        }
        
        $fileName = Split-Path $downloadUrl -Leaf
        $msiPath = Join-Path $env:TEMP $fileName
        
        Write-Host "Downloading PowerShell $latestVersion..." -ForegroundColor Cyan
        Write-Host "From: $downloadUrl" -ForegroundColor Gray
        
        Invoke-WebRequest -Uri $downloadUrl -OutFile $msiPath -UseBasicParsing
        
        Write-Host "Installing PowerShell 7..." -ForegroundColor Yellow
        
        $arguments = @(
            "/i"
            "`"$msiPath`""
            "/quiet"
            "/norestart"
            "ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=1"
            "ADD_FILE_CONTEXT_MENU_RUNPOWERSHELL=1"
            "ENABLE_PSREMOTING=1"
            "REGISTER_MANIFEST=1"
            "ADD_PATH=1"
        )
        
        $process = Start-Process msiexec.exe -ArgumentList $arguments -Wait -PassThru -NoNewWindow
        
        # Clean up
        Remove-Item $msiPath -Force -ErrorAction SilentlyContinue
        
        if ($process.ExitCode -eq 0) {
            Write-Host "✓ PowerShell 7 installed successfully!" -ForegroundColor Green
            
            # Verify installation
            if (Test-Path $ps7Path) {
                try {
                    $installedVersion = & $ps7Path -NoProfile -Command '$PSVersionTable.PSVersion.ToString()' 2>$null
                    Write-Host "✓ Verified installation: PowerShell $installedVersion" -ForegroundColor Green
                } catch {
                    Write-Host "✓ PowerShell 7 installed (version verification skipped)" -ForegroundColor Green
                }
            }
            
            return $true
        } else {
            Write-Error "PowerShell 7 installation failed with exit code: $($process.ExitCode)"
            return $false
        }
        
    } catch {
        Write-Error "Failed to install PowerShell 7. Error: $_"
        return $false
    }
}

function Install-ProfileForPowerShell7 {
    try {
        Write-Host "Setting up profile for PowerShell 7..." -ForegroundColor Cyan
        
        $ps7Path = "$env:ProgramFiles\PowerShell\7\pwsh.exe"
        if (-not (Test-Path $ps7Path)) {
            Write-Warning "PowerShell 7 not found. Skipping profile setup."
            return $false
        }
        
        # Create PowerShell 7 profile directory
        $ps7ProfileDir = "$env:USERPROFILE\Documents\PowerShell"
        if (-not (Test-Path $ps7ProfileDir)) {
            New-Item -Path $ps7ProfileDir -ItemType Directory -Force | Out-Null
            Write-Host "✓ Created PowerShell 7 profile directory: $ps7ProfileDir" -ForegroundColor Green
        }
        
        # Download profile for PowerShell 7
        $ps7ProfilePath = "$ps7ProfileDir\Microsoft.PowerShell_profile.ps1"
        
        if (Test-Path $ps7ProfilePath) {
            $backupPath = "$ps7ProfilePath.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            Move-Item $ps7ProfilePath $backupPath -Force
            Write-Host "✓ Existing PowerShell 7 profile backed up to: $backupPath" -ForegroundColor Yellow
        }
        
        Write-Host "Downloading PowerShell 7 profile..." -ForegroundColor Yellow
        Invoke-RestMethod https://raw.githubusercontent.com/winters27/powershell-profile/main/Microsoft.PowerShell_profile.ps1 -OutFile $ps7ProfilePath
        
        Write-Host "✓ PowerShell 7 profile installed successfully!" -ForegroundColor Green
        Write-Host "Profile location: $ps7ProfilePath" -ForegroundColor Cyan
        
        return $true
        
    } catch {
        Write-Error "Failed to install PowerShell 7 profile. Error: $_"
        return $false
    }
}

function Prompt-PowerShell7Installation {
    Write-Host "`n" -NoNewline
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "                   PowerShell 7 Setup                      " -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    
    # Check PowerShell 7 status
    $ps7Path = "$env:ProgramFiles\PowerShell\7\pwsh.exe"
    $ps7Installed = Test-Path $ps7Path
    $currentVersion = $PSVersionTable.PSVersion
    
    if ($currentVersion.Major -ge 7) {
        Write-Host "✓ You're already running PowerShell 7!" -ForegroundColor Green
        Write-Host "Setting up profile for your current PowerShell 7 installation..." -ForegroundColor Cyan
        
        $profileSuccess = Install-ProfileForPowerShell7
        if ($profileSuccess) {
            Write-Host "`n✓ PowerShell 7 profile configured!" -ForegroundColor Green
        }
        return
        
    } elseif ($ps7Installed) {
        Write-Host "✓ PowerShell 7 is already installed on your system" -ForegroundColor Green
        Write-Host "  But you're currently running Windows PowerShell 5.1" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Setting up profile for your existing PowerShell 7..." -ForegroundColor Cyan
        
        $profileSuccess = Install-ProfileForPowerShell7
        if ($profileSuccess) {
            Write-Host "`n✓ PowerShell 7 profile configured!" -ForegroundColor Green
            Write-Host "`nTo use PowerShell 7 with your new profile:" -ForegroundColor Yellow
            Write-Host "1. Close this window" -ForegroundColor Cyan
            Write-Host "2. Open PowerShell 7 from the Start Menu" -ForegroundColor Cyan
            Write-Host "3. Or run 'pwsh' from any command line" -ForegroundColor Cyan
        }
        return
        
    } else {
        Write-Host "PowerShell 7 is required for the optimal profile experience." -ForegroundColor White
        Write-Host "Benefits include:" -ForegroundColor White
        Write-Host "• Enhanced performance and compatibility" -ForegroundColor Cyan
        Write-Host "• Modern PSReadLine features" -ForegroundColor Cyan
        Write-Host "• Cross-platform support" -ForegroundColor Cyan
        Write-Host "• Latest PowerShell features" -ForegroundColor Cyan
        
        do {
            $response = Read-Host "`nWould you like to install PowerShell 7? (Y/N)"
            $response = $response.Trim().ToUpper()
            
            switch ($response) {
                'Y' { 
                    $installSuccess = Install-PowerShell7
                    if ($installSuccess) {
                        Write-Host "`n✓ PowerShell 7 installation completed!" -ForegroundColor Green
                        
                        # Now install the profile specifically for PowerShell 7
                        $profileSuccess = Install-ProfileForPowerShell7
                        
                        if ($profileSuccess) {
                            Write-Host "`n✓ PowerShell 7 profile configured!" -ForegroundColor Green
                            Write-Host "`nSetup completed! To use PowerShell 7 with your new profile:" -ForegroundColor Yellow
                            Write-Host "1. Close this window" -ForegroundColor Cyan
                            Write-Host "2. Open PowerShell 7 from the Start Menu" -ForegroundColor Cyan
                            Write-Host "3. Or run 'pwsh' from any command line" -ForegroundColor Cyan
                            Write-Host "`nEnjoy your enhanced PowerShell experience! 🚀" -ForegroundColor Green
                        }
                    } else {
                        Write-Host "PowerShell 7 installation failed." -ForegroundColor Red
                    }
                    return
                }
                'N' { 
                    Write-Host "PowerShell 7 installation skipped." -ForegroundColor Yellow
                    Write-Host "Continuing with Windows PowerShell 5.1 profile setup..." -ForegroundColor Cyan
                    return
                }
                default { 
                    Write-Host "Please enter 'Y' for Yes or 'N' for No." -ForegroundColor Red
                }
            }
        } while ($true)
    }
}

Prompt-PowerShell7Installation

# Function to install Nerd Fonts
function Install-NerdFonts {
    param (
        [string]$FontName = "CascadiaCode",
        [string]$FontDisplayName = "CaskaydiaCove NF",
        [string]$Version = "3.2.1"
    )

    try {
        [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
        $fontFamilies = (New-Object System.Drawing.Text.InstalledFontCollection).Families.Name
        if ($fontFamilies -notcontains "${FontDisplayName}") {
            $fontZipUrl = "https://github.com/ryanoasis/nerd-fonts/releases/download/v${Version}/${FontName}.zip"
            $zipFilePath = "$env:TEMP\${FontName}.zip"
            $extractPath = "$env:TEMP\${FontName}"

            $webClient = New-Object System.Net.WebClient
            $webClient.DownloadFileAsync((New-Object System.Uri($fontZipUrl)), $zipFilePath)

            while ($webClient.IsBusy) {
                Start-Sleep -Seconds 2
            }

            Expand-Archive -Path $zipFilePath -DestinationPath $extractPath -Force
            $destination = (New-Object -ComObject Shell.Application).Namespace(0x14)
            Get-ChildItem -Path $extractPath -Recurse -Filter "*.ttf" | ForEach-Object {
                If (-not(Test-Path "C:\Windows\Fonts\$($_.Name)")) {
                    $destination.CopyHere($_.FullName, 0x10)
                }
            }

            Remove-Item -Path $extractPath -Recurse -Force
            Remove-Item -Path $zipFilePath -Force
        } else {
            Write-Host "Font ${FontDisplayName} already installed"
        }
    }
    catch {
        Write-Error "Failed to download or install ${FontDisplayName} font. Error: $_"
    }
}

# Check for internet connectivity before proceeding
if (-not (Test-InternetConnection)) {
    break
}

# Profile creation or update
if (!(Test-Path -Path $PROFILE -PathType Leaf)) {
    try {
        # Detect Version of PowerShell & Create Profile directories if they do not exist.
        $profilePath = ""
        if ($PSVersionTable.PSEdition -eq "Core") {
            $profilePath = "$env:userprofile\Documents\Powershell"
        }
        elseif ($PSVersionTable.PSEdition -eq "Desktop") {
            $profilePath = "$env:userprofile\Documents\WindowsPowerShell"
        }

        if (!(Test-Path -Path $profilePath)) {
            New-Item -Path $profilePath -ItemType "directory"
        }

        Invoke-RestMethod https://raw.githubusercontent.com/winters27/powershell-profile/main/Microsoft.PowerShell_profile.ps1 -OutFile $PROFILE
        Write-Host "The profile @ [$PROFILE] has been created."
        Write-Host "If you want to make any personal changes or customizations, please do so at [$profilePath\Profile.ps1] as there is an updater in the installed profile which uses the hash to update the profile and will lead to loss of changes"
    }
    catch {
        Write-Error "Failed to create or update the profile. Error: $_"
    }
}
else {
    try {
        Get-Item -Path $PROFILE | Move-Item -Destination "oldprofile.ps1" -Force
        Invoke-RestMethod https://raw.githubusercontent.com/winters27/powershell-profile/main/Microsoft.PowerShell_profile.ps1 -OutFile $PROFILE
        Write-Host "The profile @ [$PROFILE] has been created and old profile removed."
        Write-Host "Please back up any persistent components of your old profile to [$HOME\Documents\PowerShell\Profile.ps1] as there is an updater in the installed profile which uses the hash to update the profile and will lead to loss of changes"
    }
    catch {
        Write-Error "Failed to backup and update the profile. Error: $_"
    }
}

# OMP Install
try {
    winget install -e --accept-source-agreements --accept-package-agreements JanDeDobbeleer.OhMyPosh
}
catch {
    Write-Error "Failed to install Oh My Posh. Error: $_"
}

# Font Install
Install-NerdFonts -FontName "CascadiaCode" -FontDisplayName "CaskaydiaCove NF"

# Choco install
try {
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}
catch {
    Write-Error "Failed to install Chocolatey. Error: $_"
}

# Terminal Icons Install
try {
    Install-Module -Name Terminal-Icons -Repository PSGallery -Force
}
catch {
    Write-Error "Failed to install Terminal Icons module. Error: $_"
}

# Neofetch Install
try {
    winget install neofetch
    Write-Host "Neofetch installed successfully."
}
catch {
    Write-Error "Failed to install Neofetch. Error: $_"
}

# zoxide Install
try {
    winget install -e --id ajeetdsouza.zoxide
    Write-Host "zoxide installed successfully."
}
catch {
    Write-Error "Failed to install zoxide. Error: $_"
}

Prompt-ConfigureTerminal

# Final check and message to the user
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
$installedFonts = (New-Object System.Drawing.Text.InstalledFontCollection).Families.Name

if ((Test-Path -Path $PROFILE) -and (winget list --name "OhMyPosh" -e) -and ($installedFonts -contains "CaskaydiaCove NF") -and (Get-Command neofetch -ErrorAction SilentlyContinue)) {
    Write-Host "`nSetup completed successfully!" -ForegroundColor Green
} else {
    Write-Warning "`nSetup completed with some errors. Please check the messages above."
}

Write-Host "`n" -NoNewline
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "                      Setup Complete!                        " -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "Please restart your PowerShell session to apply all changes." -ForegroundColor Yellow
