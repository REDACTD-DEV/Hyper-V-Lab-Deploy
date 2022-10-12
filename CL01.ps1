#Even though we can PSRemote in, the VM is still booting. 
#This script runs too quick and won't join the domain unless we sleep it for a bit
Start-Sleep -Seconds 30

#Disable IPV6
Write-Host "Disable IPV6" -ForegroundColor Blue -BackgroundColor Black
Get-NetAdapterBinding | Where-Object ComponentID -eq 'ms_tcpip6' | Disable-NetAdapterBinding | Out-Null

#Rename network adapter inside VM
Write-Host "Rename network adapter inside VM" -ForegroundColor Blue -BackgroundColor Black
foreach ($NetworkAdapter in (Get-NetAdapterAdvancedProperty -DisplayName "Hyper-V Network Adapter Name" | Where-Object DisplayValue -NotLike "")) {
    $NetworkAdapter | Rename-NetAdapter -NewName $NetworkAdapter.DisplayValue -Verbose
} 

Write-Host "Get a new DHCP lease" -ForegroundColor Blue -BackgroundColor Black
ipconfig /release | Out-Null
ipconfig /renew | Out-Null

#Install RSAT
Write-Host "Install RSAT" -ForegroundColor Blue -BackgroundColor Black
Set-ItemProperty -Path HKLM:SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU -Name UseWUServer -Value 0
Restart-Service -Name wuauserv -Force
Get-WindowsCapability -Name RSAT* -Online | Add-WindowsCapability -Online | Out-Null

#Domain join and restart
Write-Host "Domain join and restart" -ForegroundColor Blue -BackgroundColor Black
$Params = @{
    DomainName = $using:Domain
    OUPath = "OU=Workstations,OU=Devices,OU=$using:Company,$using:DN"
    Credential = $using:DomainCred
    Force = $true
    Restart = $true
}
Add-Computer @Params | Out-Null