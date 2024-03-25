function New-CustomVM {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)][String]$VMName,
        [Parameter(Mandatory=$true)][String]$Type
	)	
    process {
        #Create Folder Structures
        New-Item -ItemType Directory $VMConfigFolder\$VMName | Out-Null
        New-Item -ItemType Directory "$VMConfigFolder\$VMName\Hard Disks" | Out-Null
        New-Item -ItemType Directory "$VMConfigFolder\$VMName\autounattend" | Out-Null

        #Create New VM
        Write-Host "Running New-VM for $VMName" -ForegroundColor Magenta -BackgroundColor Black
        $Params = @{
            Name = $VMName
            MemoryStartupBytes = 2GB
            Path = "$VMConfigFolder\$VMName"
            Generation = 2
        }
        New-VM @Params | Out-Null

        #Edit VM
        Write-Host "Running Set-VM for $VMName" -ForegroundColor Magenta -BackgroundColor Black
        $Params = @{
            Name = $VMName
            ProcessorCount = 4
            DynamicMemory = $true
            MemoryMinimumBytes = 2GB
            MemoryMaximumBytes = 8GB
        }
        Set-VM @Params | Out-Null

        #Remove Existing Network Adapters
        Write-Host "Remove existing network adapters for $VMName" -ForegroundColor Magenta -BackgroundColor Black	
        Get-VMNetworkAdapter -VMName $VMName | Remove-VMNetworkAdapter

        #Add Network Adapter
        Write-Host "Add Network Adapter for $VMName" -ForegroundColor Magenta -BackgroundColor Black	
	    $Params = @{
            VMName = $VMName
            SwitchName = "ExternalLabSwitch"
            Name = "External"
        }
	    if($VMName -eq "GW01") {
            Add-VMNetworkAdapter @Params | Out-Null   
        }
	
	    $Params = @{
            VMName = $VMName
            SwitchName = "PrivateLabSwitch"
            Name = "Internal"
        }
	    Add-VMNetworkAdapter @Params
    
        #Turn network device naming on 
        Get-VMNetworkAdapter -VMName $VMName | Set-VMNetworkAdapter -DeviceNaming On
    
        #Specify CPU settings
        Write-Host "Running Set-VMProcessor for $VMName" -ForegroundColor Magenta -BackgroundColor Black
        $Params = @{
            VMName = $VMName
            Count = 8
            Maximum = 100
            RelativeWeight = 100
        }
        Set-VMProcessor @Params | Out-Null
	
        #Configure vTPM
        Write-Host "Configure vTPM for $VMName" -ForegroundColor Magenta -BackgroundColor Black
        Set-VMKeyProtector -VMName $VMName -NewLocalKeyProtector | Out-Null
        Enable-VMTPM -VMName $VMName | Out-Null
	
        #Add Installer ISO
        Write-Host "Setting Install ISO for $VMName" -ForegroundColor Magenta -BackgroundColor Black
        $Params = @{
            VMName = $VMName
        }
        if ($Type -eq "Client") {$Params['Path'] = $WinClientAutoISOPath}
        if ($Type -eq "Server") {$Params['Path'] = $WinServerAutoISOPath}
        Add-VMDvdDrive @Params | Out-Null

        #Copy autounattend.xml to VM Folder
        Write-Host "Copying autounattend.xml for $VMName" -ForegroundColor Magenta -BackgroundColor Black
        if ($Type -eq "Client") {
            Copy-Item -Path "$UnattendFilePath\client-autounattend.xml" -Destination "$VMConfigFolder\$VMName\autounattend\autounattend.xml" | Out-Null
        }
        if ($Type -eq "Server") {
            Copy-Item -Path "$UnattendFilePath\server-autounattend.xml" -Destination "$VMConfigFolder\$VMName\autounattend\autounattend.xml" | Out-Null
        }

        #Customize autounattend.xml for each VM
        Write-Host "Customizing autounattend.xml for $VMName" -ForegroundColor Magenta -BackgroundColor Black
        (Get-Content "$VMConfigFolder\$VMName\autounattend\autounattend.xml").replace("1ComputerName", $VMName) | Set-Content "$VMConfigFolder\$VMName\autounattend\autounattend.xml" | Out-Null

        #Create the ISO
        Write-Host "Creating autounattend ISO for $VMName" -ForegroundColor Magenta -BackgroundColor Black
        New-ISOFile -source $VMConfigFolder\$VMName\autounattend -destinationIso $VMConfigFolder\$VMName\autounattend.iso -title autounattend | Out-Null

        #Cleanup
        Remove-Item -Recurse -Path "$VMConfigFolder\$VMName\autounattend\" | Out-Null

        #Add autounattend ISO
        Write-Host "Attaching autounattend ISO to $VMName" -ForegroundColor Magenta -BackgroundColor Black
        $Params = @{
            VMName = $VMName
            Path = "$VMConfigFolder\$VMName\autounattend.iso"
        }
        Add-VMDvdDrive @Params | Out-Null

        #Create OS Drive
        Write-Host "Create OS disk for $VMName" -ForegroundColor Magenta -BackgroundColor Black
        $Params = @{
            Path = "$VMConfigFolder\$VMName\Hard Disks\$VMName-OS.vhdx"
            SizeBytes = 100GB
            Dynamic = $true
        }
        New-VHD @Params | Out-Null

        #Create Data Drive
        Write-Host "Create data disk for $VMName" -ForegroundColor Magenta -BackgroundColor Black
        $Params = @{
            Path = "$VMConfigFolder\$VMName\Hard Disks\$VMName-Data.vhdx"
            SizeBytes = 500GB
            Dynamic = $true
        }
        New-VHD @Params | Out-Null

        #Add OS Drive to VM
        Write-Host "Attach OS disk for $VMName" -ForegroundColor Magenta -BackgroundColor Black
        $Params = @{
            VMName = $VMName
            Path = "$VMConfigFolder\$VMName\Hard Disks\$VMName-OS.vhdx"
        }
        Add-VMHardDiskDrive @Params | Out-Null

        #Add Data Drive to VM
        Write-Host "Attach data disk for $VMName" -ForegroundColor Magenta -BackgroundColor Black
        $Params = @{
            VMName = $VMName
            Path = "$VMConfigFolder\$VMName\Hard Disks\$VMName-Data.vhdx"
        }
        Add-VMHardDiskDrive @Params | Out-Null
        
        #WSUS Pre-reqs ISO
        if ($VMName -eq "WSUS") {
            Copy-Item -Path "$UnattendFilePath\WSUS-prereq.iso" -Destination "$VMConfigFolder\$VMName\" -Force | Out-Null
            #Attach WSUS ISO to VM
            Write-Host "Attaching autounattend ISO to $VMName" -ForegroundColor Magenta -BackgroundColor Black
            $Params = @{
                VMName = $VMName
                Path = "$VMConfigFolder\$VMName\WSUS-prereq.iso"
            }
            Add-VMDvdDrive @Params | Out-Null

        }

        #Set boot priority
        Write-Host "Set boot priority for $VMName" -ForegroundColor Magenta -BackgroundColor Black
        $Order1 = Get-VMDvdDrive -VMName $VMName | Where-Object Path  -NotMatch "unattend"
        $Order2 = Get-VMHardDiskDrive -VMName $VMName | Where-Object Path -Match "OS.vhdx"
        $Order3 = Get-VMHardDiskDrive -VMName $VMName | Where-Object Path -Match "Data.vhdx"
        $Order4 = Get-VMDvdDrive -VMName $VMName | Where-Object Path  -Match "unattend"
        Set-VMFirmware -VMName $VMName -BootOrder $Order1, $Order2, $Order3, $Order4 | Out-Null
        
        Write-Host "Starting $VMName" -ForegroundColor Magenta -BackgroundColor Black
        Start-VM -Name $VMName | Out-Null
    }

}
