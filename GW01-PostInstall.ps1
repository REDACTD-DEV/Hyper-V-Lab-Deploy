#Install remote access
Write-Host "Install remote access" -ForegroundColor Blue -BackgroundColor Black
Install-RemoteAccess -VpnType RoutingOnly  | Out-Null

#Configure remote access
Write-Host "Configure remote access" -ForegroundColor Blue -BackgroundColor Black
$ExternalInterface="External"
$InternalInterface="Internal"

cmd.exe /c "netsh routing ip nat install"  | Out-Null
cmd.exe /c "netsh routing ip nat add interface $ExternalInterface"  | Out-Null
cmd.exe /c "netsh routing ip nat set interface $ExternalInterface mode=full"  | Out-Null
cmd.exe /c "netsh routing ip nat add interface $InternalInterface" | Out-Null 

Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\RemoteAccess\Parameters\IP' -Name InitialAddressPoolSize -Type DWORD -Value 0  | Out-Null
