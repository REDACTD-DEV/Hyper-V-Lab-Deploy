#Install IIS role
Write-Host "Install IIS role" -ForegroundColor Blue -BackgroundColor Black
Install-WindowsFeature -name "Web-Server" -IncludeAllSubFeature -IncludeManagementTools