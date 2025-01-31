# Define Variables - Master VM Configuration
$MasterVMs = @{
    "WindowsServer2022_Master" = @("C:\Powershell Scripts\WASEnvironment\ISO MASTER\WindowsServer2022.iso", "C:\Powershell Scripts\WASEnvironment\ISO MASTER\Autoinstall_WS22.iso")
    "Windows10Pro_Master"      = @("C:\Powershell Scripts\WASEnvironment\ISO MASTER\Windows10.iso", "C:\Powershell Scripts\WASEnvironment\ISO MASTER\Autoinstall_Win10.iso")
}

$VMPath = "C:\ProgramData\Microsoft\Windows\Hyper-V\"  # Path to store VM files
$VHDPath = "C:\ProgramData\Microsoft\Windows\Virtual Hard Disks\"  # Path for virtual hard disks
$VHDSizeGB = 30  # Size of the virtual hard disk (in GB)
$RAM = 2GB  # RAM allocation per VM
$ProcessorCount = 1  # Number of virtual CPUs

# Ensure directories exist
New-Item -ItemType Directory -Path $VMPath -Force | Out-Null
New-Item -ItemType Directory -Path $VHDPath -Force | Out-Null

# Loop to create Master VMs
foreach ($VMName in $MasterVMs.Keys) {
    $ISOPaths = $MasterVMs[$VMName]  # Get all ISOs for this VM
    $VHDFile = "$VHDPath$VMName.vhdx"

    # Create a new fixed-size virtual hard disk (not dynamic)
    New-VHD -Path $VHDFile -SizeBytes ($VHDSizeGB * 1GB) -Fixed | Out-Null

    # Create the VM (Generation 2)
    New-VM -Name $VMName -MemoryStartupBytes $RAM -Generation 2 -Path $VMPath | Out-Null

    # Disable Dynamic Memory (sets RAM strictly to 2GB)
    Set-VMMemory -VMName $VMName -DynamicMemoryEnabled $false | Out-Null

    # Attach the virtual hard disk
    Add-VMHardDiskDrive -VMName $VMName -Path $VHDFile | Out-Null

    # Remove all existing DVD drives before adding new ones (fixes boot issues)
    Get-VMDvdDrive -VMName $VMName | Remove-VMDvdDrive -Confirm:$false

    # Attach all ISOs (primary OS + unattend)
    foreach ($ISO in $ISOPaths) {
        Add-VMDvdDrive -VMName $VMName -Path $ISO | Out-Null
        Write-Host " Attached ISO: $ISO to $VMName" -ForegroundColor Yellow
    }

    # Ensure Windows ISO is the first boot device
    $BootDVD = Get-VMDvdDrive -VMName $VMName | Where-Object { $_.Path -like "*.iso" } | Select-Object -First 1
    if ($BootDVD) {
        Set-VMFirmware -VMName $VMName -FirstBootDevice $BootDVD | Out-Null
    }

    # Enable Secure Boot with Microsoft Windows template (ensures proper booting)
    Set-VMFirmware -VMName $VMName -EnableSecureBoot On -SecureBootTemplate "MicrosoftWindows" | Out-Null

    # Set the number of CPUs
    Set-VMProcessor -VMName $VMName -Count $ProcessorCount | Out-Null

    # Generate a Test Key Protector for TPM
    Set-VMKeyProtector -VMName $VMName -NewLocalKeyProtector | Out-Null

    # Enable TPM
    Enable-VMTPM -VMName $VMName | Out-Null

    # Disable Checkpoints
    Set-VM -Name $VMName -CheckpointType Disabled | Out-Null

    Write-Host " Created Master VM: $VMName with TPM enabled and checkpoints disabled."
}

Write-Host " All Master VMs created successfully and will auto-boot from ISO!"
