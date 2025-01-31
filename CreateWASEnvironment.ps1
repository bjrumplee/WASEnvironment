# Define Variables - VM to Master VHD Mapping
$VMs = @{
	"TEST-EDM-RTR"  = @("Windows Server 2022", @("EDM-Network", "Private"), @("HAL-Network", "Private"), @("MEX-Network", "Private"), @("EXT-Network", "Private"))
    "TEST-EDM-DC1" = @("Windows Server 2022", @("EDM-Network", "Private"))
    "TEST-EDM-SVR1" = @("Windows Server 2022", @("EDM-Network", "Private"))
    "TEST-EDM-CL1"  = @("Windows 10 Pro", @("EDM-Network", "Private"))
    "TEST-HAL-SVR1"  = @("Windows Server 2022", @("HAL-Network", "Private"))
    "TEST-HAL-CL1"  = @("Windows 10 Pro", @("HAL-Network", "Private"))
    "TEST-MEX-SVR1"  = @("Windows Server 2022", @("MEX-Network", "Private"))
    "TEST-MEX-CL1"  = @("Windows 10 Pro", @("MEX-Network", "Private"))
    "TEST-EXT-CL2"  = @("Windows 10 Pro", @("EXT-Network", "Private"))
}

$MasterVHDs = @{
    "Windows Server 2022" = "C:\Powershell Scripts\WASEnvironment\VHD MASTER\WindowsServer2022_Master.vhdx"
    "Windows 10 Pro"      = "C:\Powershell Scripts\WASEnvironment\VHD MASTER\Windows10Pro_Master.vhdx"
}

$VMPath = "C:\ProgramData\Microsoft\Windows\Hyper-V\"  # Path to store VM files
$VHDPath = "C:\ProgramData\Microsoft\Windows\Virtual Hard Disks\"  # Path for virtual hard disks
$RAM = 2GB  # RAM allocation per VM
$ProcessorCount = 1  # Number of virtual CPUs

# Ensure directories exist
New-Item -ItemType Directory -Path $VMPath -Force | Out-Null
New-Item -ItemType Directory -Path $VHDPath -Force | Out-Null

# Function to get the first available external network adapter
function Get-AvailableExternalAdapter {
    $AvailableAdapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.InterfaceDescription -notlike "*Virtual*" }
    return $AvailableAdapters[0].Name
}

# Loop to create VMs with copied master VHDs
foreach ($VMName in $VMs.Keys) {
    # Get the OS Type and Network Adapters
    $OSType = $VMs[$VMName][0]
    $NetworkAdapters = $VMs[$VMName][1..($VMs[$VMName].Count - 1)] # Extract all network adapters
    $MasterVHD = $MasterVHDs[$OSType]

    # Destination path for the copied VHD
    $VHDFile = "$VHDPath$VMName.vhdx"

    # Copy master VHD to the VM's location (Overwrite if exists)
    Copy-Item -Path $MasterVHD -Destination $VHDFile -Force
    Write-Host "Copied Master VHD: $MasterVHD → $VHDFile" -ForegroundColor Green

    # Create the VM (Generation 2)
    New-VM -Name $VMName -MemoryStartupBytes $RAM -Generation 2 -Path $VMPath | Out-Null

    # Attach the copied VHD
    Add-VMHardDiskDrive -VMName $VMName -Path $VHDFile | Out-Null

    # Enable Secure Boot with Microsoft Windows template
    Set-VMFirmware -VMName $VMName -EnableSecureBoot On -SecureBootTemplate "MicrosoftWindows" | Out-Null

    # Remove any existing network adapter to avoid conflicts
    Get-VMNetworkAdapter -VMName $VMName | Remove-VMNetworkAdapter -Confirm:$false

    # Store adapter names for output
    $AdapterNames = @()

    # Loop through all network adapters and add them to the VM
    foreach ($Adapter in $NetworkAdapters) {
        $VMSwitch = $Adapter[0]
        $SwitchType = $Adapter[1]

        # Validate switch type
        if ($SwitchType -notin @("Internal", "Private", "External")) {
            Write-Host "Invalid switch type '$SwitchType' for '$VMSwitch'. Skipping..." -ForegroundColor Red
            continue
        }

        # Check if the network switch exists, create it if not
        if (-not (Get-VMSwitch | Where-Object { $_.Name -eq $VMSwitch })) {
            Write-Host "Creating network switch '$VMSwitch' as $SwitchType in Hyper-V..." -ForegroundColor Yellow

            if ($SwitchType -eq "External") {
                # Get the first available external adapter
                $SelectedAdapter = Get-AvailableExternalAdapter

                if (-not $SelectedAdapter) {
                    Write-Host "Error: No available external network adapters found for External switch '$VMSwitch'." -ForegroundColor Red
                    continue
                }

                Write-Host "Using network adapter '$SelectedAdapter' for External switch '$VMSwitch'." -ForegroundColor Cyan
                
                try {
                    New-VMSwitch -Name $VMSwitch -NetAdapterName $SelectedAdapter -AllowManagementOS $true -ErrorAction Stop | Out-Null
                } catch {
                    Write-Host "Failed to create External switch '$VMSwitch': $_" -ForegroundColor Red
                    continue
                }
            }
            else {
                New-VMSwitch -Name $VMSwitch -SwitchType $SwitchType | Out-Null
            }
        }

        # Add the network adapter to the VM
        Add-VMNetworkAdapter -VMName $VMName -SwitchName $VMSwitch | Out-Null
        $AdapterNames += "$VMSwitch ($SwitchType)"
    }

    # Set the number of CPUs
    Set-VMProcessor -VMName $VMName -Count $ProcessorCount | Out-Null

    # Generate a Test Key Protector for TPM
    Set-VMKeyProtector -VMName $VMName -NewLocalKeyProtector | Out-Null

    # Enable TPM
    Enable-VMTPM -VMName $VMName | Out-Null

    # Disable Checkpoints
    Set-VM -Name $VMName -CheckpointType Disabled | Out-Null

    Write-Host "Created VM: $VMName ($OSType) with TPM enabled, checkpoints disabled, and network adapters: $($AdapterNames -join ', ')" -ForegroundColor Cyan
}

Write-Host "All VMs created successfully and will boot from pre-installed VHDs!" -ForegroundColor Green
