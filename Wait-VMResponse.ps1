function Wait-VMResponse {
	[CmdletBinding()]
	param(
        [Parameter()][String]$VMWaitingOn,
        [Parameter()][String]$CredentialType,
        [Parameter()][Switch]$LogonUICheck
	)	
    process {
        #Wait for $VM to respond to PowerShell Direct
        Write-Host "Wait for $VMWaitingOn to respond to PowerShell Direct" -ForegroundColor Green -BackgroundColor Black
        while ((Invoke-Command -VMName $VMWaitingOn -Credential $CredentialType {"Test"} -ea SilentlyContinue) -ne "Test") {
            Write-Host "Still waiting on $VMWaitingOn..." -ForegroundColor Green -BackgroundColor Black
            Start-Sleep -Seconds 5
        }
        Write-Host "$VMWaitingOn is up!" -ForegroundColor Green -BackgroundColor Black

        if ($LogonUICheck) {
            Invoke-Command -VMName $VMWaitingOn -Credential $CredentialType -ScriptBlock {
            while ((Get-Process | Where-Object ProcessName -eq "LogonUI") -ne $null) {
                Start-Sleep 5
                Write-Host "$VMWaitingOn LogonUI still processing..." -ForegroundColor Green -BackgroundColor Black
            }
            Write-host "LogonUI is down! $VMWaitingOn is good to go!" -ForegroundColor Green -BackgroundColor Black
            }
        }
    }
}