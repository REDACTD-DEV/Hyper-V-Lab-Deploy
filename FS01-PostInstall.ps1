Start-Sleep -Seconds 10
#Bring data disk online
Write-Host "Bring data disk online" -ForegroundColor Blue -BackgroundColor Black
Initialize-Disk -Number 1 | Out-Null
Start-Sleep -Seconds 10
#Partition and format
Write-Host "Partition and format" -ForegroundColor Blue -BackgroundColor Black
New-Partition -DiskNumber 1 -UseMaximumSize | Format-Volume -FileSystem "NTFS" -NewFileSystemLabel "Data" | Out-Null

Start-Sleep -Seconds 10#Set drive letter 
Write-Host "Set drive letter" -ForegroundColor Blue -BackgroundColor Black
Set-Partition -DiskNumber 1 -PartitionNumber 2 -NewDriveLetter F | Out-Null
Start-Sleep -Seconds 10

Write-Host "Install FS Feature" -ForegroundColor Blue -BackgroundColor Black
Install-WindowsFeature FS-FileServer  | Out-Null

Write-Host "Create NetworkShare folder" -ForegroundColor Blue -BackgroundColor Black
New-Item "F:\Data\NetworkShare" -Type Directory | Out-Null

Write-Host "Create new SMB share" -ForegroundColor Blue -BackgroundColor Black
$Params = @{
    Name = "NetworkShare"
    Path = "F:\Data\NetworkShare"
    FullAccess = "Domain Admins"
    ReadAccess = "Domain Users"
    FolderEnumerationMode = "Unrestricted"
}
New-SmbShare @Params | Out-Null

Write-Host "Install and configure DFS Namespace" -ForegroundColor Blue -BackgroundColor Black
Install-WindowsFeature FS-DFS-Namespace -IncludeManagementTools | Out-Null
$DFSNTargetPath = "\\" + $using:FS01.Name + "." + $using:Domain + "\NetworkShare"
$DFSNPath = "\\" + $using:Domain + "\NetworkShare"
New-DfsnRoot -TargetPath $DFSNTargetPath -Type DomainV2 -Path $DFSNPath | Out-Null