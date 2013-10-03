$ProgamFiles_x86 = "$env:ProgramFiles (x86)"

#configure GacUtil environment
set-alias gacutil "$ProgamFiles_x86\Microsoft SDKs\Windows\v7.0A\bin\GacUtil.exe"

# un-install the old version of the assembly
Gacutil /u "DirectEnergy.OAM, Version=1.0.0.0, Culture=neutral, PublicKeyToken=b6a416a3e4d1c768"

# Install new version of the assembly
Gacutil /i "C:\mywork\scm\DirectEnergy.OAM\Development\R1\DirectEnergy.OAM\bin\Debug\DirectEnergy.OAM.dll"