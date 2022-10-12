#Install remote access
Write-Host "Install remote access" -ForegroundColor Blue -BackgroundColor Black
Install-RemoteAccess -VpnType RoutingOnly 

#Configure remote access
Write-Host "Configure remote access" -ForegroundColor Blue -BackgroundColor Black
$ExternalInterface="External"
$InternalInterface="Internal"

cmd.exe /c "netsh routing ip nat install" 
cmd.exe /c "netsh routing ip nat add interface $ExternalInterface" 
cmd.exe /c "netsh routing ip nat set interface $ExternalInterface mode=full" 
cmd.exe /c "netsh routing ip nat add interface $InternalInterface" 

Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\RemoteAccess\Parameters\IP' -Name InitialAddressPoolSize -Type DWORD -Value 0 
