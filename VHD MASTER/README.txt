In order to create the Master VHD:
1. Within the windows system open powershell as administrator
2. copy and paste the following: C:\Windows\System32\Sysprep\sysprep.exe /generalize /oobe /shutdown
3. System will automatically shutdown. You may need to click somewhere on the screen for it to shutdown (as if you were logging in). Do not restart it. 
4. Copy the VHDX file and place in "C:\Powershell Scripts\WASEnvironment\VHD Master"
5. Rename the files accordingly:
	Windows Server 2022 - "WindowsServer2022_Master.vhdx"
	Windows 10 Pro - "Windows10Pro_Master.vhdx"
6. These VHD's will now be used to make copies of each system

Notes:
- If required you can just copy these master VHD's when manually creating VM's. You just need to mount them manually.
- If you get a permissions error: either delete the DVD Drive entirely then re-add/re-mount, or you should be able to mount to another VHD (temporarily) then re-mount to your copied master.
- Make sure you rename your copied master to match the VM name to avoid confusion.
- You will likely have to still manually change the PC name when you log in.
