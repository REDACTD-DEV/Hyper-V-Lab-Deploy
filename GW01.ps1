#Even though we can PSRemote in, the VM is still booting. 
#This script runs too quick and won't join the domain unless we sleep it for a bit
Start-Sleep -Seconds 30

#Rename network adapter inside VM
Write-Host "Rename network adapter inside VM" -ForegroundColor Blue -BackgroundColor Black
foreach ($NetworkAdapter in (Get-NetAdapterAdvancedProperty -DisplayName "Hyper-V Network Adapter Name" | Where-Object DisplayValue -NotLike "")) {
    $NetworkAdapter | Rename-NetAdapter -NewName $NetworkAdapter.DisplayValue -Verbose
} 
Start-Sleep -Seconds 1

#Disable IPV6
Write-Host "Disable IPV6" -ForegroundColor Blue -BackgroundColor Black
Get-NetAdapterBinding | Where-Object ComponentID -eq 'ms_tcpip6' | Disable-NetAdapterBinding  | Out-Null
Start-Sleep -Seconds 1

#Set static IP
Write-Host "Set static IP for External NIC" -ForegroundColor Blue -BackgroundColor Black
$Params = @{
    IPAddress = "10.138.42.88"
    DefaultGateway = "10.138.42.1"
    PrefixLength = "24"
}
Get-NetAdapter -Name "External" | New-NetIPAddress @Params | Out-Null
Start-Sleep -Seconds 1

#Set routing metric
Write-Host "Set routing metric" -ForegroundColor Blue -BackgroundColor Black
Set-NetRoute -InterfaceAlias "External" -RouteMetric 1

#Adjust firewall to allow pinging other hosts
Write-Host "Adjust firewall to allow pinging other hosts" -ForegroundColor Blue -BackgroundColor Black
netsh advfirewall firewall add rule name="Allow ICMPv4" protocol=icmpv4:8,any dir=in action=allow

#Set IP Address
Write-Host "Set IP Address for Internal NIC" -ForegroundColor Blue -BackgroundColor Black
$Params = @{
    IPAddress = $using:GW01.IP
    DefaultGateway = $using:GW01.IP
    PrefixLength = $using:Prefix
}
Get-NetAdapter -Name "Internal" | New-NetIPAddress @Params | Out-Null
Start-Sleep -Seconds 1

#Configure DNS Settings
Get-NetAdapter -Name "Internal" | Set-DNSClientServerAddress -ServerAddresses $using:DC01.IP   | Out-Null
Start-Sleep -Seconds 1 

#Install routing feature
Write-Host "Install routing feature" -ForegroundColor Blue -BackgroundColor Black
Install-WindowsFeature Routing -IncludeManagementTools  | Out-Null
Start-Sleep -Seconds 1

#Domain join
$DomainAdmin = $DomainNetBIOSName + "\Administrator"
$Pass = ConvertTo-SecureString -String $using:Password -AsPlainText -Force
$DomainCred = New-Object System.Management.Automation.PSCredential($DomainAdmin, $Pass)
Write-Host "Domain join and restart" -ForegroundColor Blue -BackgroundColor Black
$Params = @{
    DomainName = $using:Domain
    OUPath = "OU=Servers,OU=Devices,OU=$using:Company,$using:DN"
    Credential = $DomainCred
    Force = $true
    Restart = $true
}
Add-Computer @Params | Out-Null
