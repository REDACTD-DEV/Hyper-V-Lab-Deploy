. .\Configuration.ps1
. .\New-ISOFile.ps1
. .\Create-AutomatedISO.ps1
. .\New-CustomVM.ps1
. .\Wait-VMResponse.ps1
. .\Clone-DC.ps1

Create-AutomatedISO -ISOPath $WinServerISOPath | Out-Null
Create-AutomatedISO -ISOPath $WinClientISOPath | Out-Null

#Create folder for autounattend ISO
Write-Host "Create folder for autounattend ISO" -ForegroundColor Green -BackgroundColor Black
New-Item -Type Directory -Path "$UnattendFilePath\autounattend"  | Out-Null

#Create base  server-autounattend.xml file
Write-Host "Copy base server-autounattend.xml file" -ForegroundColor Green -BackgroundColor Black
Copy-Item -Path ".\server-autounattend.xml" -Destination "$UnattendFilePath\autounattend\server-autounattend.xml"  | Out-Null

#Create base client-autounattend.xml file
Write-Host "Copy base client-autounattend.xml file" -ForegroundColor Green -BackgroundColor Black
Copy-Item -Path ".\client-autounattend.xml" -Destination "$UnattendFilePath\autounattend\client-autounattend.xml"  | Out-Null

#Remove PrivateLabSwitch if it exists
Write-Host "Remove PrivateLabSwitch if it exists" -ForegroundColor Green -BackgroundColor Black
Get-VMSwitch | Where-Object Name -eq "PrivateLabSwitch" | Remove-VMSwitch -Force  | Out-Null

#Create PrivateLabSwitch
Write-Host "Create PrivateLabSwitch" -ForegroundColor Green -BackgroundColor Black
New-VMSwitch -Name "PrivateLabSwitch" -SwitchType "Private"  | Out-Null

#This will bring back the first physical network adapter with the default route of 0.0.0.0/0
$InternetNetAdapter = (Get-NetAdapter | where-Object Name -notmatch "vEthernet" | Where-Object ifindex -eq (Get-NetRoute -DestinationPrefix "0.0.0.0/0" | Select-Object -first 1).ifindex).Name

#Remove ExternalLabSwitch if it exists
Write-Host "Remove ExternalLabSwitch if it exists" -ForegroundColor Green -BackgroundColor Black
Get-VMSwitch | Where-Object Name -eq "ExternalLabSwitch" | Remove-VMSwitch -Force  | Out-Null

#Create ExternalLabSwitch
Write-Host "Create ExternalLabSwitch" -ForegroundColor Green -BackgroundColor Black
New-VMSwitch -Name "ExternalLabSwitch" -NetAdapterName $InternetNetAdapter -AllowManagementOs $true | Out-Null

foreach($VM in $VMConfigs){
    Write-Host "Deploy" $VM.Name -ForegroundColor Green -BackgroundColor Black
    New-CustomVM -VMName $VM.Name -Type $VM.Type 
}

$LocalAdmin = "Administrator"
$DomainAdmin = $DomainNetBIOSName + "\Administrator"
$Pass = ConvertTo-SecureString -String $Password -AsPlainText -Force
$LocalCred = New-Object System.Management.Automation.PSCredential($LocalAdmin, $Pass)
$DomainCred = New-Object System.Management.Automation.PSCredential($DomainAdmin, $Pass)

#DC01
Wait-VMResponse -VMName $DC01.Name -CredentialType "Local" -Password $Password
Write-Host "Networking and domain creation" $DC01.Name -ForegroundColor Green -BackgroundColor Black
Invoke-Command -VMName $DC01.Name -Credential $LocalCred -FilePath ".\DC01.ps1"
Start-Sleep -Seconds 30 #PSDirect will jump into a VM that's shutting down if we don't sleep between scripts
Wait-VMResponse -VMName $DC01.Name -CredentialType "Domain" -DomainNetBIOSName $DomainNetBIOSName -LogonUICheck -Password $Password
Write-Host $DC01.Name "post-install" -ForegroundColor Green -BackgroundColor Black
Invoke-Command -Credential $DomainCred -VMName $DC01.Name -FilePath ".\DC01-PostInstall.ps1"
Wait-VMResponse -VMName $DC01.Name -CredentialType "Domain" -DomainNetBIOSName $DomainNetBIOSName -LogonUICheck -Password $Password

#GW01
Wait-VMResponse -VMName $GW01.Name -CredentialType "Local" -Password $Password
Write-Host $GW01.Name "Networking and domain join" -ForegroundColor Green -BackgroundColor Black
Invoke-Command -Credential $LocalCred -VMName $GW01.Name -FilePath ".\GW01.ps1"
Start-Sleep -Seconds 30 #PSDirect will jump into a VM that's shutting down if we don't sleep between scripts
Wait-VMResponse -VMName $GW01.Name -CredentialType "Domain" -DomainNetBIOSName $DomainNetBIOSName -Password $Password
Write-Host $GW01.Name "post-install" -ForegroundColor Green -BackgroundColor Black
Invoke-Command -Credential $DomainCred -VMName $GW01.Name -FilePath ".\GW01-PostInstall.ps1"

#DHCP
Wait-VMResponse -VMName $DHCP.Name -CredentialType "Local" -Password $Password
Write-Host $DHCP.Name "Networking and domain join" -ForegroundColor Green -BackgroundColor Black
Invoke-Command -Credential $LocalCred -VMName $DHCP.Name -FilePath ".\DHCP.ps1"
Start-Sleep -Seconds 30 #PSDirect will jump into a VM that's shutting down if we don't sleep between scripts
Wait-VMResponse -VMName $DHCP.Name -CredentialType "Domain" -DomainNetBIOSName $DomainNetBIOSName -Password $Password
Write-Host $DHCP.Name "post-install" -ForegroundColor Green -BackgroundColor Black
Invoke-Command -Credential $DomainCred -VMName $DHCP.Name -FilePath ".\DHCP-PostInstall.ps1"

#FS01
Wait-VMResponse -VMName $FS01.Name -CredentialType "Local" -Password $Password
Write-Host $FS01.Name "Networking and domain join" -ForegroundColor Green -BackgroundColor Black
Invoke-Command -Credential $LocalCred -VMName $FS01.Name -FilePath ".\FS01.ps1"
Start-Sleep -Seconds 30 #PSDirect will jump into a VM that's shutting down if we don't sleep between scripts
Wait-VMResponse -VMName $FS01.Name -CredentialType "Domain" -DomainNetBIOSName $DomainNetBIOSName -Password $Password
Write-Host $FS01.Name "post-install" -ForegroundColor Green -BackgroundColor Black
Invoke-Command -Credential $DomainCred -VMName $FS01.Name -FilePath ".\FS01-PostInstall.ps1"

#WEB01
Wait-VMResponse -VMName $WEB01.Name -CredentialType "Local" -Password $Password
Write-Host $WEB01.Name "Networking and domain join" -ForegroundColor Green -BackgroundColor Black
Invoke-Command -Credential $LocalCred -VMName $WEB01.Name -FilePath ".\WEB01.ps1"
Start-Sleep -Seconds 30 #PSDirect will jump into a VM that's shutting down if we don't sleep between scripts
Wait-VMResponse -VMName $WEB01.Name -CredentialType "Domain" -DomainNetBIOSName $DomainNetBIOSName -Password $Password
Write-Host $WEB01.Name "post-install" -ForegroundColor Green -BackgroundColor Black
Invoke-Command -Credential $DomainCred -VMName $WEB01.Name -FilePath ".\WEB01-PostInstall.ps1"

#Group Policy script
Wait-VMResponse -VMName $DC01.Name -CredentialType "Domain" -DomainNetBIOSName $DomainNetBIOSName -Password $Password
Write-Host "Group Policy script" -ForegroundColor Green -BackgroundColor Black
Invoke-Command -Credential $DomainCred -VMName $DC01.Name -FilePath ".\GroupPolicy.ps1"

#CL01
Wait-VMResponse -VMName $CL01.Name -CredentialType "Local" -Password $Password
Write-Host $CL01.Name "Networking and domain join" -ForegroundColor Green -BackgroundColor Black
Invoke-Command -Credential $LocalCred -VMName $CL01.Name -FilePath ".\CL01.ps1"

#DC02
Wait-VMResponse -VMName $DC02.Name -CredentialType "Local" -Password $Password
Write-Host $DC02.Name "Networking and domain join" -ForegroundColor Green -BackgroundColor Black
Invoke-Command -Credential $LocalCred -VMName $DC02.Name -FilePath ".\DC02.ps1"
Start-Sleep -Seconds 30
Wait-VMResponse -VMName $DC02.Name -CredentialType "Domain" -DomainNetBIOSName $DomainNetBIOSName -LogonUICheck -Password $Password

#WSUS
Wait-VMResponse -VMName $WSUS.Name -CredentialType "Local" -Password $Password
Write-Host $WSUS.Name "Networking and domain join" -ForegroundColor Green -BackgroundColor Black
Invoke-Command -Credential $LocalCred -VMName $WSUS.Name -FilePath ".\WSUS.ps1"
Start-Sleep -Seconds 30 #PSDirect will jump into a VM that's shutting down if we don't sleep between scripts
Wait-VMResponse -VMName $WSUS.Name -CredentialType "Domain" -DomainNetBIOSName $DomainNetBIOSName -Password $Password
Write-Host $WSUS.Name "post-install" -ForegroundColor Green -BackgroundColor Black
Invoke-Command -Credential $DomainCred -VMName $WSUS.Name -FilePath ".\WSUS-PostInstall.ps1"

#Configure BitLocker on all VMs
.\Bitlocker.ps1
