#Disable IPV6
Get-NetAdapterBinding | Where-Object ComponentID -eq 'ms_tcpip6' | Disable-NetAdapterBinding | Out-Null

#Rename network adapter inside VM
Write-Host "Rename network adapter inside VM" -ForegroundColor Blue -BackgroundColor Black
foreach ($NetworkAdapter in (Get-NetAdapterAdvancedProperty -DisplayName "Hyper-V Network Adapter Name" | Where-Object DisplayValue -NotLike "")) {
    $NetworkAdapter | Rename-NetAdapter -NewName $NetworkAdapter.DisplayValue -Verbose
} 

#Set IP Address
Write-Host "Set IP Address" -ForegroundColor Blue -BackgroundColor Black
$Params = @{
    IPAddress = $using:DC01.IP
    DefaultGateway = $using:GW01.IP
    PrefixLength = $using:Prefix
}
Get-NetAdapter -Name "Internal" | New-NetIPAddress @Params | Out-Null

Write-Host "Set DNS" -ForegroundColor Blue -BackgroundColor Black
#Configure DNS Settings
Get-NetAdapter -Name "Internal" | Set-DNSClientServerAddress -ServerAddresses $using:DC01.IP  | Out-Null  

#Install AD DS server role
Write-Host "Install AD DS Server Role" -ForegroundColor Blue -BackgroundColor Black
Install-WindowsFeature -name AD-Domain-Services -IncludeManagementTools  | Out-Null

#Configure server as a domain controller
Write-Host "Configure server as a domain controller" -ForegroundColor Blue -BackgroundColor Black
Install-ADDSForest -DomainName $using:Domain -DomainNetBIOSName $using:DomainNetBIOSName -InstallDNS -Force -SafeModeAdministratorPassword (ConvertTo-SecureString $using:Password -AsPlainText -Force) -WarningAction SilentlyContinue  | Out-Null
