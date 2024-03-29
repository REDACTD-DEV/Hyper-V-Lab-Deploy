#Even though we can PSRemote in, the VM is still booting. 
#This script runs too quick and won't join the domain unless we sleep it for a bit
Start-Sleep -Seconds 30

#Disable IPV6
Write-Host "Disable IPV6" -ForegroundColor Blue -BackgroundColor Black
Get-NetAdapterBinding | Where-Object ComponentID -eq 'ms_tcpip6' | Disable-NetAdapterBinding | Out-Null

#Adjust firewall to allow pinging other hosts
netsh advfirewall firewall add rule name="Allow ICMPv4" protocol=icmpv4:8,any dir=in action=allow

#Rename network adapter inside VM
Write-Host "Rename network adapter inside VM" -ForegroundColor Blue -BackgroundColor Black
foreach ($NetworkAdapter in (Get-NetAdapterAdvancedProperty -DisplayName "Hyper-V Network Adapter Name" | Where-Object DisplayValue -NotLike "")) {
    $NetworkAdapter | Rename-NetAdapter -NewName $NetworkAdapter.DisplayValue -Verbose
} 

Write-Host "Get a new DHCP lease" -ForegroundColor Blue -BackgroundColor Black
ipconfig /release | Out-Null
ipconfig /renew | Out-Null

#Configure DNS Settings
Get-NetAdapter -Name "Internal" | Set-DNSClientServerAddress -ServerAddresses $using:DC01.IP    | Out-Null

Start-Sleep -Seconds 3

#Install .NET 3.5 as it's a pre-req for RSAT
Write-Host "Install .NET 3.5 from install DVD" -ForegroundColor Blue -BackgroundColor Black
dism.exe /online /enable-feature /featurename:NetFX3 /source:D:\sources\sxs /LimitAccess

#Install RSAT
Write-Host "Install RSAT" -ForegroundColor Blue -BackgroundColor Black
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