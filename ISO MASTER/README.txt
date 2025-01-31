- This folder should never change unless evaluation ISO requires updating - should be able to simply re-download and place here.
- Naming needs to match whats in the .txt files since it relies on that name for the powershell script


Autoinstall/Unattend ISO's:
- Dont touch the auto install ISO's. These are Unattend files that are used to basically be a one click option to skip all the BS GUI settings for a simple lab environment.
- If required, Unattend/Autoinstall ISO's can be mounted alongside the OS ISO which will automatically install the OS with little to no input.
- If manually using Autoinstall/Unattend - will likely require immediate manual input on start of VM (Press any key to boot.... screen). After that
- Windows Server 2022 install allows you to set custom password once the install is complete.
- Windows 10 Pro defaults to usual lab settings of: Username "user1", Password "Pa$$w0rd".
