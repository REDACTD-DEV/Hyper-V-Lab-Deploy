###############
## Variables ##
###############
 
##//INSTALLATION//##
 
# Do you want to install .NET FRAMEWORK 3.5? If true, provide a location for the Windows OS media in the next variable
    $DotNet = $True
# Location of Windows sxs for .Net Framework 3.5 installation
    $WindowsSXS = "D:\sources\sxs"
# Do you want to download and install MS Report Viewer 2008 SP1 (required for WSUS Reports)?
    $RepViewer = $True
# WSUS Installation Type.  Enter "WID" (for WIndows Internal Database), "SQLExpress" (to download and install a local SQLExpress), or "SQLRemote" (for an existing SQL Instance).
    $WSUSType = "WID"
# If using an existing SQL server, provide the Instance name below
    $SQLInstance = "MyServer\MyInstance"
# Location to store WSUS Updates (will be created if doesn't exist)
    $WSUSDir = "Z:\WSUS_Updates"
# Temporary location for installation files (will be created if doesn't exist)
    $TempDir = "Z:\temp"
 
##//CONFIGURATION//##
 
# Do you want to configure WSUS (equivalent of WSUS Configuration Wizard, plus some additional options)?  If $false, no further variables apply.
# You can customise the configurations, such as Products and Classifications etc, in the "Begin Initial Configuration of WSUS" section of the script.
    $ConfigureWSUS = $True
# Do you want to decline some unwanted updates?
    $DeclineUpdates = $True
# Do you want to configure and enable the Default Approval Rule?
    $DefaultApproval = $True
# Do you want to run the Default Approval Rule after configuring?
    $RunDefaultRule = $False
	
Install-WindowsFeature -name NET-Framework-Core

#Install SQLCLRTypes and Report Viewer from mounted ISO
#WSUS ISO Needs to be mounted at VM Creation time
#Get Drive letter where title -eq WSUS


# Install WSUS (WSUS Services, SQL Database, Management tools)
 
if ($WSUSType -eq 'WID')
{
write-host 'Installing WSUS for WID (Windows Internal Database)'
Install-WindowsFeature -Name UpdateServices -IncludeManagementTools
}
if ($WSUSType -eq 'SQLExpress' -Or $WSUSType -eq 'SQLRemote')
{
write-host 'Installing WSUS for SQL Database'
Install-WindowsFeature -Name UpdateServices-Services,UpdateServices-DB -IncludeManagementTools
}

# Run WSUS Post-Configuration
 
if ($WSUSType -eq 'WID')
{
sl "C:\Program Files\Update Services\Tools"
.\wsusutil.exe postinstall CONTENT_DIR=$WSUSDir
}
if ($WSUSType -eq 'SQLExpress')
{
sl "C:\Program Files\Update Services\Tools"
.\wsusutil.exe postinstall SQL_INSTANCE_NAME="%COMPUTERNAME%\SQLEXPRESS" CONTENT_DIR=$WSUSDir
}
if ($WSUSType -eq 'SQLRemote')
{
sl "C:\Program Files\Update Services\Tools"
.\wsusutil.exe postinstall SQL_INSTANCE_NAME=$SQLInstance CONTENT_DIR=$WSUSDir
}

# Get WSUS Server Object
$wsus = Get-WSUSServer
 
# Connect to WSUS server configuration
$wsusConfig = $wsus.GetConfiguration()
 
# Set to download updates from Microsoft Updates
Set-WsusServerSynchronization –SyncFromMU
 
# Set Update Languages to English and save configuration settings
$wsusConfig.AllUpdateLanguagesEnabled = $false
$wsusConfig.SetEnabledUpdateLanguages("en")
$wsusConfig.Save()

# Get WSUS Subscription and perform initial synchronization to get latest categories
$subscription = $wsus.GetSubscription()
$subscription.StartSynchronizationForCategoryOnly()
write-host 'Beginning first WSUS Sync to get available Products etc' -ForegroundColor Magenta
write-host 'Will take some time to complete'
While ($subscription.GetSynchronizationStatus() -ne 'NotProcessing') {
    Write-Host "." -NoNewline
    Start-Sleep -Seconds 5
}
write-host ' '
Write-Host "Sync is done." -ForegroundColor Green

# Configure the Platforms that we want WSUS to receive updates
write-host 'Setting WSUS Products'
Get-WsusProduct | where-Object {
    $_.Product.Title -in (
    'Exchange Server 2019',
    'Windows 10 Feature On Demand',
    'Windows 10, version 1903 and later',
    'Microsoft Server operating system-21H2',
    'Microsoft Server operating system-22H2',
    'Microsoft Server operating system-23H2')
} | Set-WsusProduct

# Configure the Classifications
write-host 'Setting WSUS Classifications'
Get-WsusClassification | Where-Object {
    $_.Classification.Title -in (
    'Critical Updates',
    'Definition Updates',
    'Feature Packs',
    'Security Updates',
    'Service Packs',
    'Update Rollups',
    'Updates')
} | Set-WsusClassification

# Configure Synchronizations
write-host 'Enabling WSUS Automatic Synchronisation'
$subscription.SynchronizeAutomatically=$true
 
# Set synchronization scheduled for midnight each night
$subscription.SynchronizeAutomaticallyTimeOfDay= (New-TimeSpan -Hours 0)
$subscription.NumberOfSynchronizationsPerDay=1
$subscription.Save()
 
# Kick off a synchronization
$subscription.StartSynchronization()

# Monitor Progress of Synchronisation
 
write-host 'Starting WSUS Sync, will take some time' -ForegroundColor Magenta
Start-Sleep -Seconds 60 # Wait for sync to start before monitoring
while ($subscription.GetSynchronizationProgress().ProcessedItems -ne $subscription.GetSynchronizationProgress().TotalItems) {
    Write-Progress -PercentComplete (
    $subscription.GetSynchronizationProgress().ProcessedItems*100/($subscription.GetSynchronizationProgress().TotalItems)
    ) -Activity "WSUS Sync Progress"
}
Write-Host "Sync is done." -ForegroundColor Green

# Decline Unwanted Updates
 
if ($DeclineUpdates -eq $True)
{
write-host 'Declining Unwanted Updates'
$approveState = 'Microsoft.UpdateServices.Administration.ApprovedStates' -as [type]
 
# Declining All Internet Explorer 10
$updateScope = New-Object Microsoft.UpdateServices.Administration.UpdateScope -Property @{
    TextIncludes = '2718695'
    ApprovedStates = $approveState::Any
}
$wsus.GetUpdates($updateScope) | ForEach {
    Write-Verbose ("Declining {0}" -f $_.Title) -Verbose
    $_.Decline()
}
 
# Declining Microsoft Browser Choice EU
$updateScope = New-Object Microsoft.UpdateServices.Administration.UpdateScope -Property @{
    TextIncludes = '976002'
    ApprovedStates = $approveState::Any
}
$wsus.GetUpdates($updateScope) | ForEach {
    Write-Verbose ("Declining {0}" -f $_.Title) -Verbose
    $_.Decline()
}
 
# Declining all Itanium Update
$updateScope = New-Object Microsoft.UpdateServices.Administration.UpdateScope -Property @{
    TextIncludes = 'itanium'
    ApprovedStates = $approveState::Any
}
$wsus.GetUpdates($updateScope) | ForEach {
    Write-Verbose ("Declining {0}" -f $_.Title) -Verbose
    $_.Decline()
}
}

# Configure Default Approval Rule
 
if ($DefaultApproval -eq $True)
{
write-host 'Configuring default automatic approval rule'
[void][reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration")
$rule = $wsus.GetInstallApprovalRules() | Where {
    $_.Name -eq "Default Automatic Approval Rule"}
$class = $wsus.GetUpdateClassifications() | ? {$_.Title -In (
    'Critical Updates',
    'Definition Updates',
    'Feature Packs',
    'Security Updates',
    'Service Packs',
    'Update Rollups',
    'Updates')}
$class_coll = New-Object Microsoft.UpdateServices.Administration.UpdateClassificationCollection
$class_coll.AddRange($class)
$rule.SetUpdateClassifications($class_coll)
$rule.Enabled = $True
$rule.Save()
}

# Run Default Approval Rule
 
if ($RunDefaultRule -eq $True)
{
write-host 'Running Default Approval Rule'
write-host ' >This step may timeout, but the rule will be applied and the script will continue' -ForegroundColor Yellow
try {
$Apply = $rule.ApplyRule()
}
catch {
write-warning $_
}
Finally {
# Cleaning Up TempDir
 
write-host 'Cleaning temp directory'
if (Test-Path $TempDir\ReportViewer.exe)
{Remove-Item $TempDir\ReportViewer.exe -Force}
if (Test-Path $TempDir\SQLEXPRWT_x64_ENU.exe)
{Remove-Item $TempDir\SQLEXPRWT_x64_ENU.exe -Force}
If ($Tempfolder -eq "No")
{Remove-Item $TempDir -Force}
 
write-host 'WSUS log files can be found here: %ProgramFiles%\Update Services\LogFiles'
write-host 'Done!' -foregroundcolor Green
}
}

