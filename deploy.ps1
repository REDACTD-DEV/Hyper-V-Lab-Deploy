﻿. .\Configuration.ps1
. .\New-ISOFile.ps1
. .\Create-AutomatedISO.ps1
. .\New-CustomVM.ps1
. .\Wait-VMResponse.ps1
. .\Clone-DC.ps1

Create-AutomatedISO -ISOPath $WinServerISO
Create-AutomatedISO -ISOPath $WinClientISO

#Create folder for autounattend ISO
Write-Host "Create folder for autounattend ISO" -ForegroundColor Green -BackgroundColor Black
New-Item -Type Directory -Path "E:\autounattend" | Out-Null

#Create base  server-autounattend.xml file
Write-Host "Copy base server-autounattend.xml file" -ForegroundColor Green -BackgroundColor Black
Copy-Item -Path ".\server-autounattend.xml" -Destination "E:\autounattend\server-autounattend.xml" | Out-Null

#Create base client-autounattend.xml file
Write-Host "Copy base client-autounattend.xml file" -ForegroundColor Green -BackgroundColor Black
Copy-Item -Path ".\client-autounattend.xml" -Destination "E:\autounattend\client-autounattend.xml" | Out-Null

#Remove vSwitch if it exists
Write-Host "Removing old vSwitch" -ForegroundColor Green -BackgroundColor Black
Get-VMSwitch | Where-Object Name -eq "PrivateLabSwitch" | Remove-VMSwitch -Force | Out-Null

#Create vSwitch
Write-Host "Adding new vSwitch" -ForegroundColor Green -BackgroundColor Black
New-VMSwitch -Name "PrivateLabSwitch" -SwitchType "Private" | Out-Null

foreach($VM in $VMConfigs){
    Write-Host "Deploy" $VM.Name -ForegroundColor Green -BackgroundColor Black
    New-CustomVM -VMName $VM.Name -Type $VM.Type | Out-Null
}

#DC01
Wait-VMResponse -VMWaitingOn $DC01.Name -CredentialType $LocalCred
Write-Host "Configure Networking and install AD DS on" $DC01.Name -ForegroundColor Green -BackgroundColor Black
Invoke-Command -VMName $DC01.Name -Credential $LocalCred -FilePath ".\DC01.ps1"
Wait-VMResponse -VMWaitingOn $DC01.Name -CredentialType $DomainCred -LogonUICheck
Write-Host $DC01.Name "postinstall script" -ForegroundColor Green -BackgroundColor Black
Invoke-Command -Credential $DomainCred -VMName $DC01.Name -FilePath ".\DC01-PostInstall.ps1"
Wait-VMResponse -VMWaitingOn $DC01.Name -CredentialType $DomainCred -LogonUICheck

#GW01
Wait-VMResponse -VMWaitingOn $GW01.Name -CredentialType $LocalCred
Write-Host $GW01.Name "Networking and domain join" -ForegroundColor Green -BackgroundColor Black
Invoke-Command -Credential $LocalCred -VMName $GW01.Name -FilePath ".\GW01.ps1"
Wait-VMResponse -VMWaitingOn $GW01.Name -CredentialType $DomainCred
Write-Host $GW01.Name "post-install" -ForegroundColor Green -BackgroundColor Black
Invoke-Command -Credential $DomainCred -VMName $GW01.Name -FilePath ".\GW01-PostInstall.ps1"

#DHCP
Wait-VMResponse -VMWaitingOn $DHCP.Name -CredentialType $LocalCred
Write-Host $DHCP.Name "Networking and domain join" -ForegroundColor Green -BackgroundColor Black
Invoke-Command -Credential $LocalCred -VMName $DHCP.Name -FilePath ".\DHCP.ps1"
Wait-VMResponse -VMWaitingOn $DHCP.Name -CredentialType $DomainCred
Write-Host $DHCP.Name "postinstall script" -ForegroundColor Green -BackgroundColor Black
Invoke-Command -Credential $DomainCred -VMName $DHCP.Name -FilePath ".\DHCP-PostInstall.ps1"

#FS01
Wait-VMResponse -VMWaitingOn $FS01.Name -CredentialType $LocalCred
Write-Host $FS01.Name "Networking and domain join" -ForegroundColor Green -BackgroundColor Black
Invoke-Command -Credential $LocalCred -VMName $FS01.Name -FilePath ".\FS01.ps1"
Wait-VMResponse -VMWaitingOn $FS01.Name -CredentialType $DomainCred
Write-Host $FS01.Name "post-install" -ForegroundColor Green -BackgroundColor Black
Invoke-Command -Credential $DomainCred -VMName $FS01.Name -FilePath ".\FS01-PostInstall.ps1"

#WEB01
Wait-VMResponse -VMWaitingOn $WEB01.Name -CredentialType $LocalCred
Write-Host $WEB01.Name "postinstall script" -ForegroundColor Green -BackgroundColor Black
Invoke-Command -Credential $LocalCred -VMName $WEB01.Name -FilePath ".\WEB01.ps1"
Wait-VMResponse -VMWaitingOn $WEB01.Name -CredentialType $DomainCred
Write-Host $WEB01.Name "post-install" -ForegroundColor Green -BackgroundColor Black
Invoke-Command -Credential $DomainCred -VMName $WEB01.Name -FilePath ".\WEB01-PostInstall.ps1"

#Group Policy script
Wait-VMResponse -VMWaitingOn $DC01.Name -CredentialType $DomainCred -LogonUICheck
Write-Host "Group Policy script" -ForegroundColor Green -BackgroundColor Black
Invoke-Command -Credential $DomainCred -VMName $DC01.Name -FilePath ".\GroupPolicy.ps1"

#DC02
Wait-VMResponse -VMWaitingOn $DC02.Name -CredentialType $LocalCred
Write-Host $DC02.Name "Networking and domain join" -ForegroundColor Green -BackgroundColor Black
Invoke-Command -Credential $LocalCred -VMName $DC02.Name -FilePath ".\DC02.ps1"

#CL01
Wait-VMResponse -VMWaitingOn $CL01.Name -CredentialType $LocalCred
Write-Host $CL01.Name "Networking and domain join" -ForegroundColor Green -BackgroundColor Black
Invoke-Command -Credential $LocalCred -VMName $CL01.Name -FilePath ".\CL01.ps1"

#Configure BitLocker on all VMs
.\Bitlocker.ps1