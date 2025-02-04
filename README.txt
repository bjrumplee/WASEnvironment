#####################################################################################################################


WHAT DOES THIS DO
- Freaking cheat codes man.


#####################################################################################################################


WARNING
- Not meant for use before you understand and are proficient in setting up VM's
- VM's created are (currently) based off WASI topology and include "TEST-" before each of the VM's actual names to
  avoid accidentally overwriting or corrupting current topology
- VM's are set to install with 1x processor, 2xGB RAM (not dynamic), and 30GB of space. Make sure you have enough
  resources, or feel free to adjust (look at the bottom section on how)..


#####################################################################################################################


RESULTING VM'S (NAME, OS, Network Adapter Name, Network Connection Type)
- TEST-EDM-RTR, Windows Server 2022, EDM-Network, Private
- TEST-EDM-DC1, Windows Server 2022, EDM-Network, Private
- TEST-EDM-SVR1, Windows Server 2022, (EDM-Network, HAL-Network, MEX-Network, EXT-Network), Private
- TEST-EDM-CL1, Windows 10 Pro, EDM-Network, Private
- TEST-HAL-SVR1, Windows Server 2022, HAL-Network, Private
- TEST-HAL-CL1, Windows 10 Pro, HAL-Network, Private
- TEST-MEX-SVR1, Windows Server 2022, MEX-Network, Private
- TEST-MEX-CL1, Windows 10 Pro, MEX-Network, Private
- TEST-EXT-CL2, Windows 10 Pro, EXT-Network, Private


#####################################################################################################################


PREPARATION

Downloading and Placing Files:
1. If you download the files as a RELEASE, it will name the root folder something like "WASEnvironment-WASI". Just 
   rename it to "WASEnvironment" otherwise the scripts WILL NOT WORK.
2. Create a folder named "Powershell Scripts" in C: drive (C:\Powershell Scripts\)
3. Download this repo and place in "C:\Powershell Scripts\" - this avoids long commands.
4. End results should show a folder named "WASEnvironment" in the Powershell scripts folder (C:\Powershell Scripts\WASEnvironment\)
5. Download Windows Server 2022 and Windows 10 ISO's and place them in "C:\Powershell Scripts\WASEnvironment\ISO MASTER"


#####################################################################################################################


CREATING MASTERS

Run PowerShell Script:
1. Open PowerShell as administrator
2. Copy and paste this command "cd "C:\Powershell Scripts\WASEnvironment""
3. Copy and paste this command to be able to run the script "Unblock-File -Path "C:\Powershell Scripts\WASEnvironment\CreateMasters.ps1""
4. Copy and paste this command ".\createmasters.ps1"
5. Wait for VM's to setup in Hyper-V Manager. You will see a "All Master VMs created successfully" message


Windows 10 Pro MASTER:
1. Start VM
2. Immediately press any key when prompted
3. After install use password "Pa$$w0rd" for "user1"
4. Change password in windows if you want a different default password
5. Copy xml file from this repo "\WASEnvironment\masterskipoobe.xml" to the Desktop.
6. Open PowerShell as administrator
7. Run command "C:\Windows\System32\Sysprep\sysprep.exe /generalize /oobe /shutdown /unattend:C:\Users\user1\Desktop\masterskipoobe.xml"
8. Wait until VM fully shuts down. Do not start this VM at this point
9. Copy the master VHDX file for the VM and paste here "C:\Powershell Scripts\WASEnvironment\VHD MASTER\Windows10Pro_Master.vhdx"
Notes:
	- Windows 10 Master will hold user "user1" and password "Pa$$w0rd" unless changed in step 4.


Windows Server 2022 MASTER:
1. Start VM
2. Immediately press any key when prompted
3. After install use password "Pa$$w0rd" for "Administrator"
4. Copy xml file from this repo "\WASEnvironment\masterskipoobe.xml" to the Desktop.
5. Open PowerShell as administrator
6. Run command "C:\Windows\System32\Sysprep\sysprep.exe /generalize /oobe /shutdown /unattend:C:\Users\Administrator\Desktop\masterskipoobe.xml"
7. Wait until VM fully shuts down. Do not start this VM at this point
8. Copy the master VHDX file for the VM and paste here "C:\Powershell Scripts\WASEnvironment\VHD MASTER\WindowsServer2022_Master.vhdx"
Notes:
	- Windows Server 2022 will require you to change password on the new VM when logging in on other VM's. Pa$$w0rd can still be used.
	- Both master VM's can be deleted once the VHDX files have been copied to the VHD MASTER folder
	- If you stop here and choose to copy/paste VHD's yourself to create VM's manually just be aware if you dont mount it correctly you
	  may need to unmount, then remount the VHD before starting the VM. The common error if done incorrectly is something like
	  "Incorrect permissions" or not a unique ID... something to that affect.. Happened to me in the past lots (outside of this), but 
	  unmounting/remounting corrected the issue.

**Masters can now be referenced by the next script and/or copied manually to avoid installing the OS all over again**


#####################################################################################################################


CREATING WAS ENVIRONMENT

Run PowerShell Script:
1. Open PowerShell as administrator
2. Copy and paste this command "cd "C:\Powershell Scripts\WASEnvironment""
3. Copy and paste this command to be able to run the script "Unblock-File -Path "C:\Powershell Scripts\WASEnvironment\CreateWASEnvironment.ps1""
4. Copy and paste this command ".\createwasenvironment.ps1"
5. This takes a while.. You'll see "All VMs created successfully!" when its complete.
6. Good to go

What is happening?
PowerShell is now running a script that creates VM's with specific settings inside the "createwasenvironment.ps1" file. 
It is also copying master VHD's from your master folder into the default Hyper-V VHD folder on your system while matching 
each VM's name specified in the PowerShell script.

Can it be scaled/changed?
Yes. 

Inside the "createwasenvironment.ps1" file you'll see the VM's that will be created towards the top. This can be scaled as
much as you want, and changed however you like.

Some examples are below.

--------------------------------------------------------------------------------------------------------------------


Reference the below code:

	- TEST-EDM-SVR1 = VM Name (Not PC name, this has to be changed manually)

	- Windows Server 2022 = Just that.. the OS. There's only two options within the script. Either "Windows Server 2022" 
	or "Windows 10 Pro". You put one, the script will find the master VHD for you and copy it to the destination 
	based off the VM Name you set.

	- EDM-Network = Name of the network adapter you would like. The script will check to see if it already exists.. if 
	it doesn't, it will create it for you. 

	- Private = Connection type. External type has a trick within the script. If you're like me with 4x ports and some 
	are disabled it may go for default. If it doesn't work with the default, it will jump to the next adapter 
	available to make it succeed. If it doesn't, just add it manually within Hyper-V.

	- For "TEST-EDM-RTR" you'll see four different adapters.. Theoretically if you follow the same copy/paste method you 
	could do more, but you do you. Add or remove as you see fit.

VM Specs
$VMs = @{
    "TEST-EDM-SVR1" = @("Windows Server 2022", @("EDM-Network", "Private"))
    "TEST-EDM-RTR"  = @("Windows Server 2022", @("EDM-Network", "Private"), @("HAL-Network", "Private"), @("MEX-Network", "Private"), @("EXT-Network", "Private"))
    "TEST-EDM-DC1"  = @("Windows Server 2022", @("EDM-Network", "Private"))
    "TEST-EDM-CL1"  = @("Windows 10 Pro", @("EDM-Network", "Private"))
}


--------------------------------------------------------------------------------------------------------------------


Reference the below code: Changeable things.. Depending on what resources you have available or want to play with.


$RAM = 2GB  # RAM allocation per VM

$ProcessorCount = 1  # Number of virtual CPUs

# UNTESTED FOR GEN 1
New-VM -Name $VMName -MemoryStartupBytes $RAM -Generation 2 -Path $VMPath | Out-Null


#####################################################################################################################

















