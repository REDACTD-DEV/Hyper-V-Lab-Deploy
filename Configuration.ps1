#ISO Locations
$WinServerISOPath = "C:\Users\Administrator\Downloads\WINSERVER.iso"
$WinClientISOPath = "C:\Users\Administrator\Downloads\Windows.iso"

#Hyper-V Location
$VMConfigFolder = "C:\ProgramData\Microsoft\Windows\Hyper-V"

#Unattend Location
$UnattendFilePath = "C:\Users\Administrator\Downloads\Hyper-V-Lab-Deploy-main\Hyper-V-Lab-Deploy-main"

#ISO Build Location
$ISOBuildPath = "C:\Users\Administrator\Downloads\Hyper-V-Lab-Deploy-main\Hyper-V-Lab-Deploy-main"

#Active Directory Settings
$Company = "Contoso"
$Domain = "ad.contoso.com"
$DN = "DC=ad,DC=contoso,DC=com"
$DomainNetBIOSName = "ad"

#Default Password
$Password = "1Password"

#Network Settings
$NetworkID = "192.168.10.0"
$SubnetMask = "255.255.255.0"
$Prefix = "24"
$DNSForwarder = "1.1.1.1"
$DHCPStartRange = "192.168.10.50"
$DHCPEndRange = "192.168.10.254"
$DHCPScopeID = "192.168.10.0"
$DHCPExcludeStart = "192.168.10.1"
$DHCPExcludeEnd = "192.168.10.49"

#Virtual Machines
$GW01  = [PSCustomObject]@{Name = "GW01" ; Type = "Server"; IP= "192.168.10.1" }
$DC01  = [PSCustomObject]@{Name = "DC01" ; Type = "Server"; IP= "192.168.10.10"}
$DC02  = [PSCustomObject]@{Name = "DC02" ; Type = "Server"; IP= "192.168.10.11"}
$DC03  = [PSCustomObject]@{Name = "DC03" ; Type = "Server"; IP= "192.168.10.12"}
$DHCP  = [PSCustomObject]@{Name = "DHCP" ; Type = "Server"; IP= "192.168.10.13"}
$FS01  = [PSCustomObject]@{Name = "FS01" ; Type = "Server"; IP= "192.168.10.14"}
$WEB01 = [PSCustomObject]@{Name = "WEB01"; Type = "Server"; IP= "192.168.10.15"}
$CL01  = [PSCustomObject]@{Name = "CL01" ; Type = "Client"; IP= "192.168.10.50"}
$VMConfigs = @($GW01, $DC01, $DC02, $DHCP, $FS01, $WEB01, $CL01) #DC03 left out as it's cloned from DC01