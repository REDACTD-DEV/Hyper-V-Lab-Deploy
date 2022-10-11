    . .\Configuration.ps1
    
    Write-Host "Set DNS Forwarder to $DNSForwarder" -ForegroundColor Blue -BackgroundColor Black
    Set-DnsServerForwarder -IPAddress $DNSForwarder -PassThru | Out-Null
    #Create OU's
    Write-Host "Create OU's" -ForegroundColor Blue -BackgroundColor Black
    #Base OU
    New-ADOrganizationalUnit -Name $Company -Path $DN | Out-Null
    #Devices
    New-ADOrganizationalUnit -Name "Devices" -Path "OU=$Company,$DN" | Out-Null
    New-ADOrganizationalUnit -Name "Servers" -Path "OU=Devices,OU=$Company,$DN" | Out-Null
    New-ADOrganizationalUnit -Name "Workstations" -Path "OU=Devices,OU=$Company,$DN" | Out-Null
    #Users
    New-ADOrganizationalUnit -Name "Users" -Path "OU=$Company,$DN" | Out-Null
    New-ADOrganizationalUnit -Name "Admins" -Path "OU=Users,OU=$Company,$DN" | Out-Null
    New-ADOrganizationalUnit -Name "Employees" -Path "OU=Users,OU=$Company,$DN" | Out-Null
    #Groups
    New-ADOrganizationalUnit -Name "Groups" -Path "OU=$Company,$DN" | Out-Null
    New-ADOrganizationalUnit -Name "SecurityGroups" -Path "OU=Groups,OU=$Company,$DN" | Out-Null
    New-ADOrganizationalUnit -Name "DistributionLists" -Path "OU=Groups,OU=$Company,$DN" | Out-Null
    #New admin user
    Write-Host "New admin user" -ForegroundColor Blue -BackgroundColor Black
    $Params = @{
        Name = "Admin-John.Smith"
        AccountPassword = (ConvertTo-SecureString "1Password" -AsPlainText -Force)
        Enabled = $true
        ChangePasswordAtLogon = $true
        DisplayName = "John Smith - Admin"
        Path = "OU=Admins,OU=Users,OU=$Company,$DN"
    }
    New-ADUser @Params | Out-Null
    #Add admin to Domain Admins group
    Add-ADGroupMember -Identity "Domain Admins" -Members "Admin-John.Smith" | Out-Null

    #New domain user
    Write-Host "New domain user" -ForegroundColor Blue -BackgroundColor Black
    $Params = @{
        Name = "John.Smith"
        AccountPassword = (ConvertTo-SecureString "1Password" -AsPlainText -Force)
        Enabled = $true
        ChangePasswordAtLogon = $true
        DisplayName = "John Smith"
        Company = "$Company"
        Department = "Information Technology"
        Path = "OU=Employees,OU=Users,OU=$Company,$DN"
    }
    New-ADUser @Params | Out-Null
    #Will have issues logging in through Hyper-V Enhanced Session Mode if not in this group
    Add-ADGroupMember -Identity "Remote Desktop Users" -Members "John.Smith" | Out-Null

    #Add Company SGs and add members to it
    Write-Host "Add Company SGs and add members to it" -ForegroundColor Blue -BackgroundColor Black
    New-ADGroup -Name "All-Staff" -SamAccountName "All-Staff" -GroupCategory Security -GroupScope Global -DisplayName "All-Staff" -Path "OU=SecurityGroups,OU=Groups,$Company,$DN" -Description "Members of this group are employees of Contoso" | Out-Null
    Add-ADGroupMember -Identity "All-Staff" -Members "John.Smith" | Out-Null

    #Add to Cloneable Domain Controllers
    Write-Host "Add to Cloneable Domain Controllers" -ForegroundColor Blue -BackgroundColor Black
    Add-ADGroupMember -Identity "Cloneable Domain Controllers" -Members "CN="$DC01.Name",OU=Domain Controllers,$DN" | Out-Null
