# Function to check if the script is running as administrator
function Test-IsAdministrator {
    $currentIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($currentIdentity)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to run commands with elevated privileges (if needed) in cmd
function Run-AdminCommand {
    param (
        [string]$command
    )

    if (-not (Test-IsAdministrator)) {
        # If not running as admin, prompt for elevation
        $arguments = "/c $command"
        Start-Process cmd -ArgumentList "/c start /min cmd.exe /c $command" -Verb RunAs
        return
    }

    # Start the elevated command in an invisible window
    $process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c $command" `
                              -WindowStyle Hidden -PassThru `
                              -RedirectStandardOutput "output.txt" `
                              -RedirectStandardError "error.txt"

    # Wait for process to complete
    $process.WaitForExit()

    # Display output and errors in the main window
    if (Test-Path "output.txt") {
        $output = Get-Content "output.txt" -Raw
        Write-Host "`n$output"
    }

    if (Test-Path "error.txt") {
        $error = Get-Content "error.txt" -Raw
        Write-Host "`n$error" -ForegroundColor Red
    }

    # Clean up the output files
    Remove-Item "output.txt", "error.txt" -Force
}

# Function to run System File Checker with elevation
function Run-SystemFileChecker {
    Write-Host "`nRunning System File Checker (sfc /scannow)..."
    Run-AdminCommand -command "sfc /scannow"
    Start-Sleep -Seconds 5
}

# Function to get the saved product key from registry (BackupProductKeyDefault)
function Get-BackupProductKeyFromRegistry {
    try {
        # Correct registry path for BackupProductKeyDefault
        $Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform"
        $key = (Get-ItemProperty -Path $Path).BackupProductKeyDefault
        if ($key) {
            return $key
        }
        else {
            Write-Host "`nNo backup product key found in registry." -ForegroundColor Red
        }
    } catch {
        Write-Host "`nError retrieving backup product key." -ForegroundColor Red
    }
}

# Function to install software using winget
function Install-WithWinget {
    param (
        [string]$package
    )
    Write-Host "`nSearching and Installing $package via winget..."
    Run-AdminCommand -command "winget install $package"
    Start-Sleep -Seconds 3
}

# Function to install software using Invoke-RestMethod (IRM) for downloading and installing from URL
function Install-WithIRM {
    param (
        [string]$url
    )
    Write-Host "`nDownloading and Installing from URL..."
    $file = "$env:TEMP\software_installer.exe"
    Invoke-RestMethod -Uri $url -OutFile $file
    Start-Process -FilePath $file
    Start-Sleep -Seconds 3
}

# Function to install WizTree using winget
function Install-WizTree {
    Write-Host "`nInstalling WizTree using winget..."
    Run-AdminCommand -command "winget install WizTree"
    Start-Sleep -Seconds 3
}

# Function to show menu
function Show-Menu {
    param (
        [int]$SelectedIndex
    )
    
    # Clear the screen and print the menu
    Clear-Host

    # Ensure the header is visible
    Write-Host "===========================================" -ForegroundColor Magenta
    Write-Host "===== Command-Line Utilities by Sarim =====" -ForegroundColor Magenta
    Write-Host "===========================================" -ForegroundColor Magenta

    $menuItems = @(
        "Say Hello",
        "Show Date and Time",
        "Get System Info",
        "Create a New Folder",
        "List Files in a Directory",
        "Check Windows Activation Status",
        "Enroll and Activate Product Key",
        "Free KMS Activate",
        "Reactivate with Saved Key",
        "Get Product Key",
        "Run System File Checker (sfc /scannow)",
        "Install Software via winget",
        "Install Software via URL (IRM)",
        "Install WizTree",
        "Exit"
    )

    # Colors
    $highlightColor = "Cyan"
    $normalColor = "White"

    for ($i = 0; $i -lt $menuItems.Length; $i++) {
        if ($i -eq $SelectedIndex) {
            # Highlight selected option with cursor
            Write-Host "-> $($menuItems[$i])" -ForegroundColor $highlightColor
        } else {
            Write-Host "   $($menuItems[$i])" -ForegroundColor $normalColor
        }
    }
}

# Function to run CLI
function Run-CLI {
    $selectedIndex = 0
    $menuItems = @(
        "Say Hello",
        "Show Date and Time",
        "Get System Info",
        "Create a New Folder",
        "List Files in a Directory",
        "Check Windows Activation Status",
        "Enroll and Activate Product Key",
        "Free KMS Activate",
        "Reactivate with Saved Key",
        "Get Product Key",
        "Run System File Checker (sfc /scannow)",
        "Install Software via winget",
        "Install Software via URL (IRM)",
        "Install WizTree",
        "Exit"
    )

    do {
        Show-Menu -SelectedIndex $selectedIndex

        # Capture key input
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").VirtualKeyCode

        switch ($key) {
            38 { if ($selectedIndex -gt 0) { $selectedIndex-- } } # Up Arrow
            40 { if ($selectedIndex -lt ($menuItems.Length - 1)) { $selectedIndex++ } } # Down Arrow
            13 { # Enter Key
                switch ($selectedIndex) {
                    0 { Write-Host "`nHello, User!"; Start-Sleep -Seconds 2 }
                    1 { Write-Host "`nCurrent Date and Time: $(Get-Date)"; Start-Sleep -Seconds 2 }
                    2 { 
                        Write-Host "`nSystem Info:"
                        Get-ComputerInfo | Select-Object CsName, WindowsVersion, OsArchitecture
                        Start-Sleep -Seconds 5 
                    }
                    3 { 
                        $folderName = Read-Host "Enter folder name"
                        New-Item -ItemType Directory -Path "./$folderName"
                        Write-Host "`nFolder '$folderName' created successfully!"
                        Start-Sleep -Seconds 2
                    }
                    4 {
                        $directory = Read-Host "Enter directory path"
                        Get-ChildItem -Path $directory | ForEach-Object { $_.Name }
                        Start-Sleep -Seconds 5
                    }
                    5 {
                        Write-Host "`nChecking Windows Activation Status..."
                        Run-AdminCommand -command "slmgr /dli"
                        Start-Sleep -Seconds 5
                    }
                    6 {
                        $productKey = Read-Host "Enter product key"
                        Write-Host "`nEnrolling and activating product key..."
                        Run-AdminCommand -command "slmgr /ipk $productKey; slmgr /ato"
                        Start-Sleep -Seconds 5
                    }
                    7 {
                        Write-Host "`nActivating Windows with free KMS..."
                        Run-AdminCommand -command "slmgr /skms kms.digiboy.ir; slmgr /ato"
                        Start-Sleep -Seconds 5
                    }
                    8 {
                        Write-Host "`nReactivating with saved product key..."
                        $savedKey = Get-BackupProductKeyFromRegistry
                        if ($savedKey) {
                            Run-AdminCommand -command "slmgr /ipk $savedKey; slmgr /ato"
                        } else {
                            Write-Host "No saved product key found. Would you like to save a new key? (Y/N)"
                            $userResponse = Read-Host
                            if ($userResponse -eq 'Y' -or $userResponse -eq 'y') {
                                $newKey = Read-Host "Enter the new product key"
                                Set-Content "$env:USERPROFILE\savedProductKey.txt" $newKey
                                Write-Host "New product key saved."
                            }
                        }
                        Start-Sleep -Seconds 5
                    }
                    9 {
                        Write-Host "`nYour Windows Product Key is: "
                        $productKey = Get-BackupProductKeyFromRegistry
                        if ($productKey) {
                            Write-Host $productKey
                        } else {
                            Write-Host "Failed to retrieve product key."
                        }
                        Start-Sleep -Seconds 5
                    }
                    10 {
                        Write-Host "`nRunning System File Checker..."
                        Run-SystemFileChecker
                    }
                    11 {
                        $package = Read-Host "Enter software name to install via winget"
                        Install-WithWinget -package $package
                    }
                    12 {
                        $url = Read-Host "Enter URL to download software via IRM"
                        Install-WithIRM -url $url
                    }
                    13 {
                        Install-WizTree
                    }
                    14 {
                        Write-Host "`nExiting..."
                        exit
                    }
                }
            }
        }
    } while ($true)
}

# Start the command-line interface
Run-CLI
