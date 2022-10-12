#Clone $ExistingDCName to $NewDCName
function Clone-DC {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)][String]$ExistingDCName,
        [Parameter(Mandatory=$true)][String]$NewDCName,
        [Parameter(Mandatory=$true)][String]$NewDCStaticIPAddress
	)	
    process {
        Write-Host "Ensure" $ExistingDCName "is up before starting the cloning process" -ForegroundColor Green -BackgroundColor Black
        Wait-VMResponse -VMName $ExistingDCName -CredentialType "Domain" -DomainNetBIOSName $DomainNetBIOSName -Password $Password -LogonUICheck

        Write-Host $ExistingDCName "cloning to" $NewDCName -ForegroundColor Green -BackgroundColor Black
        Invoke-Command -Credential $domaincred -VMName $ExistingDCName -ScriptBlock{
            #Force a domain sync
            Write-Host "Force a domain sync" -ForegroundColor Blue -BackgroundColor Black
            repadmin /syncall /AdeP | out-null

            #Wait for $ExistingDCName to show up in the Cloneable Domain Controllers group on $ExistingDCName
            Write-Host "Wait for" $using:ExistingDCName "to show up in the Cloneable Domain Controllers group on" $using:ExistingDCName -ForegroundColor Green -BackgroundColor Black
            while ((Get-ADGroupMember -Server $using:ExistingDCName -Identity "Cloneable Domain Controllers").name -NotMatch $using:ExistingDCName) {
                Write-Host "Still waiting..." -ForegroundColor Blue -BackgroundColor Black
                Start-Sleep -Seconds 5
            } 
            Write-Host $using:ExistingDCName "found in Cloneable Domain Controllers on" $using:ExistingDCName -ForegroundColor Blue -BackgroundColor Black
            Start-Sleep 5

            #List of applications that won't be cloned
            Write-Host "List of applications that won't be cloned" -ForegroundColor Blue -BackgroundColor Black
            Start-Sleep -Seconds 2
            Get-ADDCCloningExcludedApplicationList -GenerateXML | Out-Null
            Start-Sleep 5

            #Create clone config file
            Write-Host "Create clone config file" -ForegroundColor Blue -BackgroundColor Black
            $Params = @{
            CloneComputerName   =   $using:NewDCName
            Static              =   $true
            IPv4Address         =   $using:NewDCStaticIPAddress
            IPv4SubnetMask      =   $using:SubnetMask
            IPv4DefaultGateway  =   $using:GW01.IP
            IPv4DNSResolver     =   $using:DC01.IP
            }
            New-ADDCCloneConfigFile @Params -ea SilentlyContinue | Out-Null

            #Check the config file was created
            while ((Test-Path -Path C:\Windows\NTDS\DCCloneConfig.xml) -eq $false) {
                Write-Host "Config file not created, trying again..." -ForegroundColor Blue -BackgroundColor Black
                New-ADDCCloneConfigFile @Params -ea SilentlyContinue | Out-Null
                Start-Sleep 5
            }

            #Shutdown $ExistingDCName
            Write-Host "Shutdown" $using:ExistingDCName -ForegroundColor Blue -BackgroundColor Black
            Stop-Computer -Force | Out-Null
        }

        #Check $ExistingDCName is shutdown
        while ((Get-VM $ExistingDCName).State -ne "Off") {
            Write-Host "Waiting for" $ExistingDCName "to shutdown..." -ForegroundColor Green -BackgroundColor Black
            Start-Sleep -Seconds 2
        }
        Write-Host $ExistingDCName "is down, moving on" -ForegroundColor Green -BackgroundColor Black

        #Export VM
        Write-Host "Export VM" -ForegroundColor Green -BackgroundColor Black
        Export-VM -Name $ExistingDCName -Path E:\Export | Out-Null

        #Start $ExistingDCName
        Write-Host "Start $ExistingDCName" -ForegroundColor Green -BackgroundColor Black
        Start-VM -Name "$ExistingDCName" | Out-Null

        #New directory for $NewDCName
        Write-Host "New directory for" $NewDCName -ForegroundColor Green -BackgroundColor Black
        $guid = (Get-VM $ExistingDCName).vmid.guid.ToUpper()
        New-Item -Type Directory -Path "E:\$NewDCName" | Out-Null

        #Import $ExistingDCName
        Write-Host "Import $ExistingDCName" -ForegroundColor Green -BackgroundColor Black
        $Params = @{
            Path                =   "E:\Export\$ExistingDCName\Virtual Machines\$guid.vmcx"
            VirtualMachinePath  =   "E:\$NewDCName"
            VhdDestinationPath  =   "E:\$NewDCName\Virtual Hard Disks"
            SnapshotFilePath    =   "E:\$NewDCName"
            SmartPagingFilePath =   "E:\$NewDCName"
            Copy                =   $true
            GenerateNewId       =   $true
        }
        Import-VM @Params | Out-Null

        #Rename $ExistingDCName to $NewDCName
        Write-Host "Rename" $ExistingDCName "to" $NewDCName -ForegroundColor Green -BackgroundColor Black
        Get-VM $ExistingDCName | Where-Object State -eq "Off" | Rename-VM -NewName $NewDCName | Out-Null

        Write-Host "Ensure both domain controllers are up before bringing" $NewDCName "up" -ForegroundColor Green -BackgroundColor Black
        Wait-VMResponse -VMName $ExistingDCName  -CredentialType "Domain" -DomainNetBIOSName $DomainNetBIOSName -Password $Password -LogonUICheck
        Wait-VMResponse -VMName $DC02.Name  -CredentialType "Domain" -DomainNetBIOSName $DomainNetBIOSName -Password $Password -LogonUICheck

        #Start $NewDCName
        Write-Host "Start" $NewDCName -ForegroundColor Green -BackgroundColor Black
        Start-VM -Name $NewDCName | Out-Null

        #Cleanup export folder
        Write-Host "Cleanup export folder" -ForegroundColor Green -BackgroundColor Black
        Remove-Item -Recurse E:\Export\ | Out-Null
    }
}
