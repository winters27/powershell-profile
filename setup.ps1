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


# Function to create PowerShell Start Menu shortcut and pin to Start
function New-PowerShellStartMenuShortcut {
    param(
        [switch]$PinToStart
    )
    
    try {
        $pwshPath = "C:\Program Files\PowerShell\7\pwsh.exe"
        
        # Check if PowerShell 7 exists
        if (-not (Test-Path $pwshPath)) {
            Write-Warning "PowerShell 7 not found at $pwshPath. Skipping shortcut creation."
            return $false
        }

        # Create shortcut path (works for any user)
        $startMenuPath = [System.IO.Path]::Combine(
            [Environment]::GetFolderPath("StartMenu"),
            "Programs",
            "PowerShell 7.lnk"
        )

        Write-Host "Creating PowerShell 7 shortcut at: $startMenuPath" -ForegroundColor Cyan

        # Create WScript.Shell COM object to create shortcut
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($startMenuPath)
        
        # Set shortcut properties
        $shortcut.TargetPath = $pwshPath
        $shortcut.WorkingDirectory = [Environment]::GetFolderPath("UserProfile")
        $shortcut.Description = "PowerShell 7"
        $shortcut.IconLocation = "$pwshPath,0"
        
        # Save the shortcut
        $shortcut.Save()
        
        # Clean up COM object
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($shell) | Out-Null
        
        Write-Host "✓ PowerShell 7 shortcut created successfully!" -ForegroundColor Green
        
        # Try to pin to Start menu if requested
        if ($PinToStart) {
            Write-Host "Attempting to pin PowerShell 7 to Start menu..." -ForegroundColor Yellow
            
            $pinSuccess = $false
            
            # Method 1: Try using Shell.Application
            try {
                $shell = New-Object -ComObject Shell.Application
                $folder = $shell.Namespace([System.IO.Path]::GetDirectoryName($startMenuPath))
                $item = $folder.ParseName([System.IO.Path]::GetFileName($startMenuPath))
                
                # Get the "Pin to Start" verb (varies by Windows version and language)
                $pinVerbs = $item.Verbs() | Where-Object { 
                    $_.Name -match "Pin to Start|Pin to start|Épingler au menu Démarrer" 
                }
                
                if ($pinVerbs) {
                    $pinVerbs[0].DoIt()
                    Write-Host "✓ PowerShell 7 pinned to Start menu successfully!" -ForegroundColor Green
                    $pinSuccess = $true
                } else {
                    Write-Host "⚠ Could not find 'Pin to Start' option via Shell.Application" -ForegroundColor Yellow
                }
                
                [System.Runtime.Interopservices.Marshal]::ReleaseComObject($shell) | Out-Null
            } catch {
                Write-Host "⚠ Shell.Application method failed: $($_.Exception.Message)" -ForegroundColor Yellow
            }
            
            # Method 2: Try using PowerShell's Start-Process with verb
            if (-not $pinSuccess) {
                try {
                    # This method works on some Windows 10/11 versions
                    $verb = (New-Object -ComObject Shell.Application).Namespace([System.IO.Path]::GetDirectoryName($startMenuPath)).ParseName([System.IO.Path]::GetFileName($startMenuPath)).Verbs() | Where-Object {$_.Name -match 'Pin to Start'}
                    if ($verb) {
                        $verb.DoIt()
                        Write-Host "✓ PowerShell 7 pinned to Start menu successfully!" -ForegroundColor Green
                        $pinSuccess = $true
                    }
                } catch {
                    Write-Host "⚠ Alternative pinning method failed: $($_.Exception.Message)" -ForegroundColor Yellow
                }
            }
            
            # Method 3: Try PowerShell AppX method (Windows 10/11)
            if (-not $pinSuccess) {
                try {
                    # Create a temporary Start menu layout XML
                    $layoutXml = @"
<?xml version="1.0" encoding="utf-8"?>
<LayoutModificationTemplate xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout" 
                           xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout" 
                           Version="1" 
                           xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification">
  <LayoutOptions StartTileGroupCellWidth="6" />
  <DefaultLayoutOverride>
    <StartLayoutCollection>
      <defaultlayout:StartLayout GroupCellWidth="6">
        <start:Group Name="">
          <start:DesktopApplicationTile Size="2x2" Column="0" Row="0" DesktopApplicationLinkPath="$startMenuPath" />
        </start:Group>
      </defaultlayout:StartLayout>
    </StartLayoutCollection>
  </DefaultLayoutOverride>
</LayoutModificationTemplate>
"@
                    
                    $tempLayoutPath = "$env:TEMP\PowerShellStartLayout.xml"
                    $layoutXml | Out-File -FilePath $tempLayoutPath -Encoding UTF8
                    
                    # This is more complex and may require additional permissions
                    Write-Host "⚠ Advanced pinning method would require additional setup" -ForegroundColor Yellow
                    Remove-Item $tempLayoutPath -Force -ErrorAction SilentlyContinue
                    
                } catch {
                    Write-Host "⚠ XML layout method failed: $($_.Exception.Message)" -ForegroundColor Yellow
                }
            }
            
            # If all methods failed, provide manual instructions
            if (-not $pinSuccess) {
                Write-Host "`n" -NoNewline
                Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Yellow
                Write-Host "                Manual Pinning Instructions                " -ForegroundColor Yellow
                Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Yellow
                Write-Host "To manually pin PowerShell 7 to the Start menu:" -ForegroundColor White
                Write-Host "1. Press Windows key to open Start menu" -ForegroundColor Cyan
                Write-Host "2. Type 'PowerShell 7' to find the shortcut" -ForegroundColor Cyan
                Write-Host "3. Right-click on 'PowerShell 7'" -ForegroundColor Cyan
                Write-Host "4. Select 'Pin to Start'" -ForegroundColor Cyan
                Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Yellow
            }
        }
        
        return $true
        
    } catch {
        Write-Error "Failed to create PowerShell 7 shortcut. Error: $_"
        return $false
    }
}

# Updated function to prompt user for shortcut creation
function Prompt-CreateShortcut {
    Write-Host "`n" -NoNewline
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "                    Shortcut Creation                      " -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    
    do {
        $response = Read-Host "`nWould you like to create a PowerShell 7 shortcut in the Start Menu? (Y/N)"
        $response = $response.Trim().ToUpper()
        
        switch ($response) {
            'Y' { 
                # Ask about pinning to Start
                do {
                    $pinResponse = Read-Host "Would you also like to try pinning it to the Start menu? (Y/N)"
                    $pinResponse = $pinResponse.Trim().ToUpper()
                    
                    switch ($pinResponse) {
                        'Y' {
                            Write-Host "Creating shortcut and attempting to pin to Start..." -ForegroundColor Yellow
                            $success = New-PowerShellStartMenuShortcut -PinToStart
                            if ($success) {
                                Write-Host "Shortcut creation completed!" -ForegroundColor Green
                            }
                            return
                        }
                        'N' {
                            Write-Host "Creating shortcut without pinning..." -ForegroundColor Yellow
                            $success = New-PowerShellStartMenuShortcut
                            if ($success) {
                                Write-Host "Shortcut creation completed!" -ForegroundColor Green
                            }
                            return
                        }
                        default { 
                            Write-Host "Please enter 'Y' for Yes or 'N' for No." -ForegroundColor Red
                        }
                    }
                } while ($true)
            }
            'N' { 
                Write-Host "Shortcut creation skipped." -ForegroundColor Yellow
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
