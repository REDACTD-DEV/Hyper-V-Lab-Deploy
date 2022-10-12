#Install IIS role
Write-Host "Install IIS role" -ForegroundColor Blue -BackgroundColor Black | Out-Null
Install-WindowsFeature -name "Web-Server" -IncludeAllSubFeature -IncludeManagementTools | Out-Null
