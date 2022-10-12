function Wait-VMResponse {
	[CmdletBinding()]
	param(
        [Parameter(Mandatory=$true)][String]$VMName,
        [Parameter(Mandatory=$true)][String]$CredentialType,
        [Parameter(Mandatory=$true)][String]$Password,
        [Parameter()][String]$DomainNetBIOSName,
        [Parameter()][Switch]$LogonUICheck
	)	
    process {
        if ($CredentialType -eq "Domain") {
            $Username = $DomainNetBIOSName + "\Administrator"
            $SecurePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
            $Credential = New-Object System.Management.Automation.PSCredential($Username, $SecurePassword)
        }
        if ($CredentialType -eq "Local") {
            $Username = "Administrator"
            $SecurePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
            $Credential = New-Object System.Management.Automation.PSCredential($Username, $SecurePassword)
        }

        #Wait for $VM to respond to PowerShell Direct
        Write-Host "Wait for $VMName to respond to PowerShell Direct" -ForegroundColor Green -BackgroundColor Black
        while ((Invoke-Command -VMName $VMName -Credential $Credential {"Test"} -ea SilentlyContinue) -ne "Test") {
            Start-Sleep 5
            Write-Host "." -NoNewline -ForegroundColor Green -BackgroundColor Black
        }
        Write-Host "$VMName is up!" -ForegroundColor Green -BackgroundColor Black
        
        #For Domain Controllers, waiting for PSDirect is not a reliable method to check if the VM is ready.
        #This checks if LogonUI.exe is missing (In this case LogonUI will normally show "Applying Computer Settings")
        #If LogonUI.exe is missing, the VM has successfully logged in
        if ($LogonUICheck) {
            Invoke-Command -VMName $VMName -Credential $Credential -ScriptBlock {
            Write-Host $Using:VMName "LogonUI Check" -ForegroundColor Green -BackgroundColor Black
            while ($null -ne (Get-Process | Where-Object ProcessName -eq "LogonUI")) {
                Start-Sleep 5
                Write-Host "." -NoNewline -ForegroundColor Green -BackgroundColor Black
            }
            Write-host "LogonUI is down!" $using:VMName "is good to go!" -ForegroundColor Green -BackgroundColor Black
            }
        }
    }
}