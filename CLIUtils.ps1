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
        "Exit"
    )

    # Colors
    $highlightColor = "Cyan"  # Changed to Cyan since LightBlue is invalid
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

function Get-ProductKeyFromRegistry {
    # Registry path for the product key
    $path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform"
    
    try {
        # Get the BackupProductKeyDefault value from the registry
        $productKey = (Get-ItemProperty -Path $path).BackupProductKeyDefault
        if ($productKey) {
            return $productKey # Return the product key
        } else {
            return $null # If no product key is found, return null
        }
    }
    catch {
        Write-Host "Error retrieving product key from registry: $_"
        return $null # If there's an error, return null
    }
}

# Call this function when you need to get the product key
$productKey = Get-ProductKeyFromRegistry

if ($productKey) {
    Write-Host "`nProduct Key successfully retrieved: $productKey"
} else {
    Write-Host "`nFailed to retrieve product key."
}

function Convert-From-DigitalProductId {
    param (
        [byte[]]$digitalProductId
    )
    
    # Check if DigitalProductId has enough data
    if ($digitalProductId.Length -lt 52) {
        Write-Host "DigitalProductId is too short to extract a product key."
        return $null
    }

    $keyStart = 52
    $keyLength = 15
    $productKeyChars = "BCDFGHJKMPQRTVWXY2346789"
    $productKey = ""

    try {
        for ($i = $keyStart; $i -lt $keyStart + $keyLength; $i++) {
            $currentByte = $digitalProductId[$i]
            $productKey = $productKey + $productKeyChars[$currentByte % 24]
        }

        # Format the product key as XXXXX-XXXXX-XXXXX-XXXXX-XXXXX
        $formattedKey = $productKey.Substring(0, 5) + "-" + $productKey.Substring(5, 5) + "-" + $productKey.Substring(10, 5) + "-" + $productKey.Substring(15, 5) + "-" + $productKey.Substring(20, 5)
        return $formattedKey
    } catch {
        Write-Host "Error while converting DigitalProductId: $_"
        return $null
    }
}

# Function to run commands with admin privileges
function Run-AdminCommand {
    param (
        [string]$command
    )

    $arguments = @("powershell", "-Command", "$command")

    # Start the command as administrator
    Start-Process -FilePath "powershell.exe" -ArgumentList $arguments -Verb RunAs
}

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
                        $savedKey = Get-ProductKeyFromRegistry
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
                        $productKey = Get-ProductKeyFromRegistry
                        if ($productKey) {
                            Write-Host $productKey
                        } else {
                            Write-Host "Failed to retrieve product key."
                        }
                        Start-Sleep -Seconds 5
                    }
                    10 { 
                        Write-Host "`nExiting script..." 
                        return # This will exit the script
                    }
                }
            }
        }
    } while ($true)
}

Run-CLI
