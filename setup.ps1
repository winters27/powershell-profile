# Ensure the script can run with elevated privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Please run this script as an Administrator!"
    break
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


function New-PowerShellStartMenuShortcut {
    try {
        $pwshPath = "C:\Program Files\PowerShell\7\pwsh.exe"
        
        if (-not (Test-Path $pwshPath)) {
            Write-Warning "PowerShell 7 not found at $pwshPath. Skipping shortcut creation."
            return $false
        }

        $startMenuPath = [System.IO.Path]::Combine(
            [Environment]::GetFolderPath("CommonStartMenu"),
            "Programs",
            "PowerShell 7.lnk"
        )

        Write-Host "Creating PowerShell 7 shortcut at: $startMenuPath" -ForegroundColor Cyan

        $wshell = New-Object -ComObject WScript.Shell
        $shortcut = $wshell.CreateShortcut($startMenuPath)
        
        $shortcut.TargetPath = $pwshPath
        $shortcut.WorkingDirectory = [Environment]::GetFolderPath("UserProfile")
        $shortcut.Description = "PowerShell 7"
        $shortcut.IconLocation = "$pwshPath,0"
        
        $shortcut.Save()
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($wshell) | Out-Null
        Write-Host "✓ PowerShell 7 shortcut created successfully!" -ForegroundColor Green

        # ================== FIX ==================
        # Add a short pause to prevent a race condition where the shell crashes
        # when trying to pin a shortcut that it hasn't fully registered yet.
        Start-Sleep -Seconds 1
        # =========================================

        # --- Automatically Pin to Start ---
        try {
            Write-Host "Pinning shortcut to Start Menu..." -ForegroundColor Yellow
            $startMenuFolder = [System.IO.Path]::GetDirectoryName($startMenuPath)
            $shortcutName = [System.IO.Path]::GetFileName($startMenuPath)

            $shell = New-Object -ComObject Shell.Application
            $folder = $shell.Namespace($startMenuFolder)
            $shortcutItem = $folder.ParseName($shortcutName)
            
            $pinVerb = $shortcutItem.Verbs() | Where-Object { $_.Name -eq 'Pin to Start' }

            if ($pinVerb) {
                $pinVerb.DoIt()
                Write-Host "✓ Shortcut successfully pinned to Start Menu!" -ForegroundColor Green
            } else {
                Write-Warning "Could not find the 'Pin to Start' verb. This can happen on non-English versions of Windows or if disabled by policy."
            }
            [System.Runtime.Interopservices.Marshal]::ReleaseComObject($shell) | Out-Null
        } catch {
            Write-Error "Failed to pin shortcut to Start. Error: $_"
        }
        # --- End Pinning Logic ---

        return $true
    } catch {
        Write-Error "Failed to create PowerShell 7 shortcut. Error: $_"
        return $false
    }
}


function Prompt-CreateShortcut {
    Write-Host "`n" -NoNewline
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "                      Shortcut Creation                      " -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    
    do {
        # The question is now combined
        $response = Read-Host "`nWould you like to create a PowerShell 7 shortcut and pin it to the Start Menu? (Y/N)"
        $response = $response.Trim().ToUpper()
        
        switch ($response) {
            'Y' {  
                Write-Host "Creating and pinning shortcut..." -ForegroundColor Yellow
                # Call the function which now does both actions
                New-PowerShellStartMenuShortcut
                return
            }
            'N' {  
                Write-Host "Shortcut creation and pinning skipped." -ForegroundColor Yellow
                return
            }
            default {  
                Write-Host "Please enter 'Y' for Yes or 'N' for No." -ForegroundColor Red
            }
        }
    } while ($true)
}


# Final check and message to the user
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
$installedFonts = (New-Object System.Drawing.Text.InstalledFontCollection).Families.Name

if ((Test-Path -Path $PROFILE) -and (winget list --name "OhMyPosh" -e) -and ($installedFonts -contains "CaskaydiaCove NF") -and (Get-Command neofetch -ErrorAction SilentlyContinue)) {
    Write-Host "`nInitial setup completed successfully." -ForegroundColor Green
} else {
    Write-Warning "`nSetup completed with some errors. Please check the messages above."
}


# Prompt for shortcut creation and pinning
Prompt-CreateShortcut


Write-Host "`n" -NoNewline
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "                      Setup Complete!                        " -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "Please restart your PowerShell session to apply all changes." -ForegroundColor Yellow
