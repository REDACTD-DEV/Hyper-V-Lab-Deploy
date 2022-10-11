function Create-AutomatedISO {
	[CmdletBinding()]
	param(
		[Parameter()][String]$ISOPath
	)	
    process {
        Write-Host "Working on $ISOPath" -ForegroundColor Green -BackgroundColor Black

        $AutoISODirectory = (Get-Item -Path $ISOPath).DirectoryName + "\" 
        $AutoISOFileName = (Get-Item -Path $ISOPath).basename + "-auto.iso"
        $AutoISOFullPath = $AutoISODirectory + $AutoISOFileName 
        $BuildPath = "E:\" + (Get-Item -Path $ISOPath).basename + "ISOBuild"

        #Test if an automated ISO already exists
        if ((Test-Path $AutoISOFullPath) -eq $true){
            Write-Host "ISO already exists, skipping" -ForegroundColor Green -BackgroundColor Black
        }
        else{
            #Mount WinServer ISO
            Write-Host "Mount ISO" -ForegroundColor Green -BackgroundColor Black
            Mount-DiskImage -ImagePath $ISOPath | Out-Null

            #Copy WinServer ISO
            Write-Host "Copy ISO" -ForegroundColor Green -BackgroundColor Black
            $Path = (Get-DiskImage -ImagePath $ISOPath | Get-Volume).DriveLetter + ":\"
            New-Item -Type Directory -Path $BuildPath | Out-Null
            Copy-Item -Path $Path* -Destination $BuildPath -Recurse | Out-Null

            #Create WinServer ISO
            Write-Host "Create WinServer ISO" -ForegroundColor Green -BackgroundColor Black
            New-ISOFile -source $BuildPath -destinationISO $AutoISOFullPath -bootfile "$BuildPath\efi\microsoft\boot\efisys_noprompt.bin" -title "WINSERVER-22-Auto" | Out-Null

            #Cleanup
            Write-Host "Dismount ISO" -ForegroundColor Green -BackgroundColor Black
            Dismount-DiskImage -ImagePath $ISOPath | Out-Null
            Start-Sleep -Seconds 20
            #Remove-Item -Recurse -Path $BuildPath -Force
        }  
    }
}
