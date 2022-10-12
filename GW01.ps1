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
    IPAddress = $using:GW01.IP
    DefaultGateway = $using:GW01.IP
    PrefixLength = $using:Prefix
}
Get-NetAdapter -Name "Internal" | New-NetIPAddress @Params | Out-Null

#Configure DNS Settings
Get-NetAdapter -Name "Internal" | Set-DNSClientServerAddress -ServerAddresses $using:DC01.IP | Out-Null  

#Install routing feature
Write-Host "Install routing feature" -ForegroundColor Blue -BackgroundColor Black
Install-WindowsFeature Routing -IncludeManagementTools | Out-Null

#Domain join
$DomainAdmin = $DomainNetBIOSName + "\Administrator"
$Pass = ConvertTo-SecureString -String $using:Password -AsPlainText -Force
$DomainCred = New-Object System.Management.Automation.PSCredential($DomainAdmin, $Pass)
Write-Host "Domain join and restart" -ForegroundColor Blue -BackgroundColor Black
ping $using:DC01.Name
$Params = @{
    DomainName = $using:Domain
    OUPath = "OU=Servers,OU=Devices,OU=$using:Company,$using:DN"
    Credential = $DomainCred
    Force = $true
    Restart = $true
}
Add-Computer @Params | Out-Null