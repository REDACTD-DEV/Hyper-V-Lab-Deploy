#Install DCHP server role
Write-Host "Install DCHP server role" -ForegroundColor Blue -BackgroundColor Black
Install-WindowsFeature DHCP -IncludeManagementTools 

#Add required DHCP security groups on server and restart service
Write-Host "Add required DHCP security groups on server and restart service" -ForegroundColor Blue -BackgroundColor Black
netsh dhcp add securitygroups 
Restart-Service dhcpserver 

#Authorize DHCP Server in AD
Write-Host "Authorize DHCP Server in AD" -ForegroundColor Blue -BackgroundColor Black
$DNSName = $using:DHCP.Name + "." + $using:Domain
Add-DhcpServerInDC -DnsName $DNSName 

#Notify Server Manager that DCHP installation is complete, since it doesn't do this automatically
Write-Host "Notify Server Manager that DCHP installation is complete, since it doesn't do this automatically" -ForegroundColor Blue -BackgroundColor Black
$Params = @{
    Path = "registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\ServerManager\Roles\12"
    Name = "ConfigurationState"
    Value = "2"
}
Set-ItemProperty @Params 

#Configure DHCP Scope
Write-Host "Configure DHCP Scope" -ForegroundColor Blue -BackgroundColor Black
Add-DhcpServerv4Scope -name "Corpnet" -StartRange $using:DHCPStartRange -EndRange $using:DHCPEndRange -SubnetMask $using:SubnetMask -State Active 

#Exclude address range
Write-Host "Exclude address range" -ForegroundColor Blue -BackgroundColor Black
Add-DhcpServerv4ExclusionRange -ScopeID $using:NetworkID -StartRange $using:DHCPExcludeStart -EndRange $using:DHCPExcludeEnd 

#Specify default gateway 
Write-Host "Specify default gateway " -ForegroundColor Blue -BackgroundColor Black
Set-DhcpServerv4OptionValue -OptionID 3 -Value $using:GW01.IP -ScopeID $using:DHCPScopeID -ComputerName $DNSName 

#Specify DNS suffix 
Write-Host "Specify DNS suffix " -ForegroundColor Blue -BackgroundColor Black
Set-DhcpServerv4OptionValue -OptionID 15 -Value $using:Domain -ScopeID $using:DHCPScopeID -ComputerName $DNSName 

#Specify default DNS server
Write-Host "Specify default DNS server" -ForegroundColor Blue -BackgroundColor Black
Set-DhcpServerv4OptionValue -DnsDomain $using:Domain -DnsServer $using:DC01.IP,"1.1.1.1"