$WinServerISO = "E:\ISO\WINSERVER-22.iso"
$WinClientISO = "E:\ISO\Windows.iso"

$Company = "Contoso"
$Domain = "ad.contoso.com"
$DN = "DN=ad,DN=contoso,DN=com"
$DomainNetBIOSName = "ad"


$localusr = "Administrator"
$domainusr = "ad\Administrator"
$password = ConvertTo-SecureString "1Password" -AsPlainText -Force
$LocalCred = new-object -typename System.Management.Automation.PSCredential -argumentlist $localusr, $password
$DomainCred = new-object -typename System.Management.Automation.PSCredential -argumentlist $domainusr, $password

$NetworkID = "192.168.10.0"
$SubnetMask = "255.255.255.0"
$Prefix = "24"
$DNSForwarder = "1.1.1.1"
$DHCPStartRange = "192.168.10.50"
$DHCPEndRange = "192.168.10.254"
$DHCPScopeID = "192.168.10.0"
$DHCPExcludeStart = "192.168.10.1"
$DHCPExcludeEnd = "192.168.10.49"

$GW01  = [PSCustomObject]@{Name = "GW01" ; Type = "Server"; IP= "192.168.10.1" }
$DC01  = [PSCustomObject]@{Name = "DC01" ; Type = "Server"; IP= "192.168.10.10"}
$DC02  = [PSCustomObject]@{Name = "DC02" ; Type = "Server"; IP= "192.168.10.11"}
$DHCP  = [PSCustomObject]@{Name = "DHCP" ; Type = "Server"; IP= "192.168.10.13"}
$FS01  = [PSCustomObject]@{Name = "FS01" ; Type = "Server"; IP= "192.168.10.14"}
$WEB01 = [PSCustomObject]@{Name = "WEB01"; Type = "Server"; IP= "192.168.10.15"}
$CL01  = [PSCustomObject]@{Name = "CL01" ; Type = "Client"; IP= "192.168.10.50"}
$VMConfigs = @($GW01, $DC01, $DC02, $DHCP, $FS01, $WEB01, $CL01)