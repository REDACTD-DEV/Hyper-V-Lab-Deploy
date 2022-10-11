. .\Configuration.ps1

#Install DCHP server role
Write-Host "Install DCHP server role" -ForegroundColor Blue -BackgroundColor Black
Install-WindowsFeature DHCP -IncludeManagementTools | Out-Null

#Add required DHCP security groups on server and restart service
Write-Host "Add required DHCP security groups on server and restart service" -ForegroundColor Blue -BackgroundColor Black
netsh dhcp add securitygroups | Out-Null
Restart-Service dhcpserver | Out-Null

#Authorize DHCP Server in AD
Write-Host "Authorize DHCP Server in AD" -ForegroundColor Blue -BackgroundColor Black
$DNSName = $DHCP.Name + "." + $Domain
Add-DhcpServerInDC -DnsName $DNSName | Out-Null

#Notify Server Manager that DCHP installation is complete, since it doesn't do this automatically
Write-Host "Notify Server Manager that DCHP installation is complete, since it doesn't do this automatically" -ForegroundColor Blue -BackgroundColor Black
$Params = @{
    Path = "registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\ServerManager\Roles\12"
    Name = "ConfigurationState"
    Value = "2"
}
Set-ItemProperty @Params | Out-Null

#Configure DHCP Scope
Write-Host "Configure DHCP Scope" -ForegroundColor Blue -BackgroundColor Black
Add-DhcpServerv4Scope -name "Corpnet" -StartRange $DHCPStartRange -EndRange $DHCPEndRange -SubnetMask $SubnetMask -State Active | Out-Null

#Exclude address range
Write-Host "Exclude address range" -ForegroundColor Blue -BackgroundColor Black
Add-DhcpServerv4ExclusionRange -ScopeID $NetworkID -StartRange $DHCPExcludeStart -EndRange $DHCPExcludeEnd | Out-Null

#Specify default gateway 
Write-Host "Specify default gateway " -ForegroundColor Blue -BackgroundColor Black
Set-DhcpServerv4OptionValue -OptionID 3 -Value $GW01.IP -ScopeID $DHCPScopeID -ComputerName $DNSName | Out-Null

#Specify default DNS server
Write-Host "Specify default DNS server" -ForegroundColor Blue -BackgroundColor Black
Set-DhcpServerv4OptionValue -DnsDomain $Domain -DnsServer $DC01.IP | Out-Null