. .\Configuration.ps1
    
#Disable IPV6
Write-Host "Disable IPV6" -ForegroundColor Blue -BackgroundColor Black
Get-NetAdapterBinding | Where-Object ComponentID -eq 'ms_tcpip6' | Disable-NetAdapterBinding | Out-Null

#Rename network adapter inside VM
Write-Host "Rename network adapter inside VM" -ForegroundColor Blue -BackgroundColor Black
foreach ($NetworkAdapter in (Get-NetAdapterAdvancedProperty -DisplayName "Hyper-V Network Adapter Name" | Where-Object DisplayValue -NotLike "")) {
    $NetworkAdapter | Rename-NetAdapter -NewName $NetworkAdapter.DisplayValue -Verbose
} 

#Set IP Address
Write-Host "Set IP Address" -ForegroundColor Blue -BackgroundColor Black
$Params = @{
    IPAddress = $FS01.IP
    DefaultGateway = $GW01.IP
    PrefixLength = $Prefix
}
Get-NetAdapter -Name "Internal" | New-NetIPAddress @Params | Out-Null

#Configure DNS Settings
Get-NetAdapter -Name "Internal" | Set-DNSClientServerAddress -ServerAddresses $DC01.IP | Out-Null

#Domain join
Write-Host "Domain join and restart" -ForegroundColor Blue -BackgroundColor Black
$Params = @{
    DomainName = $Domain
    OUPath = "OU=Servers,OU=Devices,OU=$Company,$DN"
    Credential = $DomainCred
    Force = $true
    Restart = $true
}
Add-Computer @Params | Out-Null