    # Function to show menu with a cool title
    function Show-Menu {
        param (
            [int]$SelectedIndex
        )
        
        # Clear the screen and print the menu
        Clear-Host

        Write-Host @"
    ____ _     ___   _   _ _   _ _
    / ___| |   |_ _| | | | | |_(_) |___
    | |   | |    | |  | | | | __| | / __|
    | |___| |___ | |  | |_| | |_| | \__ \
    \____|_____|___|  \___/ \__|_|_|___/        

"@ -ForegroundColor Magenta
        Write-Host "      Command Line Utilities, made by Sarim Sharif`n" -ForegroundColor Cyan

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
            "Install WSL (Windows Subsystem for Linux)",
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

    # Function to handle key input and loop menu interaction
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
            "Install WSL (Windows Subsystem for Linux)",
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
                            Write-Host "`nInstalling WSL..."
                            Install-WSL
                        }
                        15 {
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
