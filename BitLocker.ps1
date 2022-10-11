. .\Configuration.ps1

#BitLocker requires DVD drives to be removed from VM
Write-Host "Eject DVD drives from all VMs" -ForegroundColor Green -BackgroundColor Black
Get-VM | Get-VMDvdDrive | Set-VMDvdDrive -Path $null | Out-Null

#Make sure all the computers are up before we remote in and configure BitLocker
$Computers = $DC01.Name, $DC02.Name, $DC03.Name, $GW01.Name, $DHCP.Name, $FS01.Name, $WEB01.Name #CL01 already has Bitlocker installed. Just the servers need this
foreach ($Computer in $Computers) {Wait-VMResponse -VMName "$Computer" -CredentialType $DomainCred}

Invoke-Command -VMName $Computers -Credential $DomainCred -ScriptBlock {
    Enable-WindowsOptionalFeature -Online -FeatureName BitLocker -All -NoRestart
    Restart-Computer -Force
}

#Make sure all the computers are up before we remote in and start encrypting
$Computers = $DC01.Name, $DC02.Name, $DC03.Name, $GW01.Name, $DHCP.Name, $FS01.Name, $WEB01.Name, $CL01.Name
foreach ($Computer in $Computers) {Wait-VMResponse -VMName "$Computer" -CredentialType $DomainCred}

Invoke-Command -VMName $Computers -Credential $DomainCred -ScriptBlock {
    gpupdate /force
    Enable-BitLocker -MountPoint "C:" -RecoveryPasswordProtector -UsedSpaceOnly
    if ($ENV:COMPUTERNAME -eq $FS01.Name) {Enable-BitLocker -MountPoint "F:" -RecoveryPasswordProtector -UsedSpaceOnly}
    Start-Sleep -Seconds 60
    Restart-Computer -Force
}