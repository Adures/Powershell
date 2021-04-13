
Import-module AutomatedLab





function systeminfo {

    $ram = Get-WMIObject Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum
    $ramgb = $ram.sum/1073741824
    if ($ramgb -ge 16) {
        $global:ramflag = "true"
        $ramStatus = "OK"
    }else {
        $global:ramflag = "false"
        $ramStatus = "NO"
    }
    $virtualisation =  (Get-WmiObject Win32_Processor).VirtualizationFirmwareEnabled
       
    if ($virtualisation -eq $true) {
     
     $virtualisationStatus = "OK"
     }else {
     
     $virtualisationStatus = "NO"
     }



     $slat =  (Get-WmiObject Win32_Processor).SecondLevelAddressTranslationExtensions
    
        if ($slat -eq $true) {
         
         $slatStatus = "OK"
         }else {
         
         $slatStatus = "NO"
         }
         $wmf  = get-host |select-object Version
       
         $dotNet =  (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full").Release -ge 461308
          
         if ($dotNet -eq $true) {
         
            $dotNetStatus = "OK"
            }else {
            
            $dotNETStatus = "NO"
            }

    $systemname = (Get-WmiObject Win32_OperatingSystem).Caption 
    $ver = (Get-WmiObject Win32_OperatingSystem).Version
    if ([version]::Parse($ver) -gt [version]::Parse('6.0.0.0')) 
    
    { 
        $versionstatus = "OK"
                        } 
                        
else {
    $versionstatus = "NO"

           }

        $hyperv = Get-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V-All -Online

    if($hyperv.State -eq "Enabled") {
    
        $hypervstatus = "OK"
    } 
    else {
     $hypervstatus = "NO"
        }

            Write-Host "Memory: $ramgb GB -> $ramStatus"
            Write-Host "Virtualisation $virtualisation -> $virtualisationStatus"
            Write-Host "SLAT: $slat -> $slatStatus"
            Write-Host "Windows Management Framework: "$wmf.version" "
            Write-Host ".NET 4.7.1+ -> $dotNetStatus  "
            Write-Host "System: $systemname -> $versionstatus "
            Write-Host "Hyper-V -> $hypervstatus"
}


function drivecheck {

   $disk =  Get-PhysicalDisk | ForEach-Object {
             $physicalDisk = $_
            $physicalDisk | Get-Disk | Get-Partition |
            Where-Object DriveLetter |Select-Object DriveLetter, @{n='MediaType';e={
            $physicalDisk.MediaType }}
             }
#had to be done like this,, because get-psdrive can't be piped
  
$fullDiskInfo = @()
ForEach ($position in $disk) {
   
   $driveletter = $position.driveletter
    $freeDiskspace = Get-PSDrive $driveletter | select-object free
   $freeDiskspaceGb = $freeDiskspace.free/ 1GB
   $FreeDiskspaceGbRound = [math]::Round($freeDiskspaceGb)

   if ($position.mediatype -eq 'SSD' -And $freeDiskspaceGbRound -gt 170 ) {
    $driveStatus = $true

   }else {
       $driveStatus = $false
   }


   $fullDisk= [PSCustomObject]@{

    DriveLetter = $position.driveletter
    MediaType = $position.mediatype
    FreeDiskSpace = $FreeDiskspaceGbRound
    Suitable  = $driveStatus
    }
   
   
    $fullDiskInfo += $fullDisk 
   
 }

 
  
 return $fullDiskInfo 
    

}

function getinfo {
    $labName = Read-Host 'Please provide the name of your lab'
    $labIP = 'Please provide virtual lab subnet '
    $labMask = 'Please provide lab network mask'
    $driveLetter = Read-Host 'Please type the letter of the drive, where your lab sources will be kept, for example C: or H:'
    $path = Read-Host 'Please provide path to folder where ISO files are being kept '
    $domainName = Read-Host 'Please provide domain name'
    $nameAdmin = Read-Host 'Please provide username of Administrator account'
    $passAdmin = Read-Host 'Please provide password of Administrator account' -AsSecureString
    New-LabSourcesFolder -Drive H
    $vmDrive = $driveLetter #for now, add make selection if it should be the same as Lab sources or different
    $labPath = Join-Path -Path H: -ChildPath $labName
    if (-not (Test-Path $labPath)) { New-Item $labPath -ItemType Directory | Out-Null }

    

}


 function createlab {
    $labName = 'LabTemplate'

#create an empty lab template and define where the lab XML files and the VMs will be stored
New-LabDefinition -Name $labName -DefaultVirtualizationEngine HyperV -VMPath "H:\AutomatedLab-VMs\"
New-LabSourcesFolder -Drive H

Add-LabVirtualNetworkDefinition -Name $labName -AddressSpace 10.0.1.0/24


Set-LabInstallationCredential -Username Install -Password Somepass1

#and the domain definition with the domain admin account
Add-LabDomainDefinition -Name test2.net -AdminUser Install -AdminPassword Somepass1

$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:Network' = $labName
  
    'Add-LabMachineDefinition:DnsServer1'= '10.0.1.44'
    'Add-LabMachineDefinition:DnsServer2'= '10.0.1.46'
    
    'Add-LabMachineDefinition:DomainName'= 'test2.net'
}

    #New-LWHypervVM -Machine Kali 
    #Add-LWVMVHDX -VMName Kali -VhdxPath D:\SomeFile.vhdx

Add-LabMachineDefinition -Name RDC1 -Memory 1GB -Network $labName -DomainName test2.net -Roles RootDC `
     -OperatingSystem 'Windows Server 2019 Standard Evaluation' -IpAddress 10.0.1.44 

     Add-LabMachineDefinition -Name RDC2 -Memory 1GB -Network $labName -DomainName test2.net -Roles DC `
     -OperatingSystem 'Windows Server 2019 Standard Evaluation' -IpAddress 10.0.1.46


Add-LabMachineDefinition -Name WINSQL -Memory 4GB -Network $labName -DomainName test2.net -Roles SQLServer2019 `
     -OperatingSystem 'Windows Server 2019 Standard Evaluation (Desktop Experience)' -IpAddress 10.0.1.48


    
     Add-LabMachineDefinition -Name WinClient -Memory 2GB -Network $labName -DomainName test2.net -OperatingSystem 'Windows 10 Enterprise Evaluation' -IpAddress 10.0.1.50

Install-Lab -Verbose

Show-LabDeploymentSummary -Detailed

 }

 function CreateKaliLinuxVM {

    Import-VM -Path 'H:\KaliExport\KaliLinux\Virtual Machines\9EBF720B-2926-47FD-955F-D324F2CF6F57.vmcx' -Copy -GenerateNewId
    Write-host "Kali Linux VM created"
 }


 function deletelab {

    get-lab -List
            $labname = read-host "Please provide the name of lab you want to delete or press q to come back to main menu"

            if ($labname -eq 'q') {
                main-menu

            }else {

                remove-lab $labname 
                main-menu
 }
}



    


function main-menu {
    param (
        [Parameter(Mandatory=$false)]
        [string]$Title = 'Menu'
    )
    changescreensize 30 60
    Clear-Host
    Start-Sleep -Milliseconds 200

    #add new menu entry, adjust switches + functions below menu section
Write-Host "================== $Title ==================="  -BackgroundColor DarkGreen    
Write-Host "1: Check device comptilibity"
Write-Host "2: Create new lab"
Write-Host "3. Manage lab "
Write-Host "4. Delete lab "
Write-Host "5.Update module Automatedlab"

$selection = Read-Host "Please make a selection"
     switch ($selection)
     {
         '1' {
            systeminfo
            
           
            $Global:fullDiskInfoSave = drivecheck
            $Global:fullDiskInfoSave |ft |Out-Host
            
            read-host " "
            
            
         } '2' {
            
            
            createlab
            CreateKaliLinuxVM
            Write-host "Kali Linux VM created"
            Read-host " Lab created press any key to return to main menu"
            main-menu
         } 
         '3'{


         }
         '4'{
            deletelab
            }
         
         '5' {

            update-module Automatedlab
         }

      }



}

If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")){
    $arguments = "& '" + $myinvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    Break
    }
    Else {
    
         main-menu
       
       }
       