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

#Set IP Address
Write-Host "Set IP Address" -ForegroundColor Blue -BackgroundColor Black
$Params = @{
    IPAddress = $using:DC02.IP
    DefaultGateway = $using:GW01.IP
    PrefixLength = $using:Prefix
}
Get-NetAdapter -Name "Internal" | New-NetIPAddress @Params | Out-Null

Write-Host "Set DNS" -ForegroundColor Blue -BackgroundColor Black
#Configure DNS Settings
Get-NetAdapter -Name "Internal" | Set-DNSClientServerAddress -ServerAddresses $using:DC01.IP | Out-Null  

Start-Sleep -Seconds 3

#Install AD DS server role
Write-Host "Install AD DS Server Role" -ForegroundColor Blue -BackgroundColor Black
Install-WindowsFeature -name AD-Domain-Services -IncludeManagementTools | Out-Null

#Promote to DC
Write-Host "Promote to DC" -ForegroundColor Blue -BackgroundColor Black
Install-ADDSDomainController -DomainName $using:Domain -InstallDns:$true -Credential $using:DomainCred -Force -SafeModeAdministratorPassword (ConvertTo-SecureString "1Password" -AsPlainText -Force) -WarningAction SilentlyContinue | Out-Null