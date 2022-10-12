# Lab Deployment Script
## What does this script do?
The goal of this script is to deploy an entire lab environment given only stock Windows install ISOs.
End result should have no dependancy on internet tooling, and attempt to use only tools provided on the ISOs.

Conducts the following:
- Creates an internal and external vSwitch
- Modifies the stock ISOs so they don't require the user to press enter on boot
- Writes a custom autounattend answer file to automate the install process
- Deploys the following virtual machines:
    - DC01 (Creates the domain)
    - DC02 (via DC Promotion)
    - DC03 (via DC Cloning)
    - DHCP
    - GW01 (NAT Router)
    - FS01 (with DFSN)
    - WEB01
    - CL01 (Client with RSAT)
- Creates an OU structure
- Adds users and groups
- Configures drive mapping Group Policy
- Configures BitLocker with AD backup on all VM's

## How does it work?
```deploy.ps1``` sets up the environment on the host (configures ISOs, creates VM's), from there it calls a custom function ```Wait-VMResponse``` to wait for each VM to respond on PowerShell Direct. Once the VM is up, ```Invoke-Command``` is used to run VM specific powershell code remotely.
It's built like this because there are a number of commands (Like domain joins and role installs) that require restarts before further configuration can be completed.

## Windows Version
Tested on Server 2022 and Windows 10 22H1, but should work on WS16/19 and earlier versions of W10.
```AutoUnattend.xml``` targets Server Core for all server VM's.

## Network
All VM's are connected to a private vSwitch, and GW01 is also connected to an external vSwitch and acts as a router for the network.

## Configuration
The environment can be adjusted by editing ```Configuration.ps1```. The following can be modified:
- Company name and domain name
- Network settings (for VM's as well as DHCP scope)
- Ability to add more client machines as needed

## Requirements
- Hyper V installed on host machine (W10 or Server)
- An E:\ drive with ~120GB free
- 16GB free memory

## Restarting the environment
If you want to blow the lab away and start again, just turn off and delete all VM's, then delete all the folders the script made on the E:\ drive (May need to wait until the VHD's are finished being written to).