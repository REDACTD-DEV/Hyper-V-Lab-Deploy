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
    IPAddress = $DC02.IP
    DefaultGateway = $GW01.IP
    PrefixLength = $Prefix
}
Get-NetAdapter -Name "Internal" | New-NetIPAddress @Params | Out-Null

Write-Host "Set DNS" -ForegroundColor Blue -BackgroundColor Black
#Configure DNS Settings
Get-NetAdapter -Name "Internal" | Set-DNSClientServerAddress -ServerAddresses $DC01.IP | Out-Null  

#Install AD DS server role
Write-Host "Install AD DS Server Role" -ForegroundColor Blue -BackgroundColor Black
Install-WindowsFeature -name AD-Domain-Services -IncludeManagementTools | Out-Null

#Promote to DC
Write-Host "Promote to DC" -ForegroundColor Blue -BackgroundColor Black
Install-ADDSDomainController -DomainName $Domain -InstallDns:$true -Credential $DomainCred -Force -SafeModeAdministratorPassword (ConvertTo-SecureString "1Password" -AsPlainText -Force) -WarningAction SilentlyContinue | Out-Null