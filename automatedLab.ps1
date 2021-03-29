

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

function createLab {
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
    $labPath = Join-Path -Path $vmDrive -ChildPath $labName
    if (-not (Test-Path $labPath)) { New-Item $labPath -ItemType Directory | Out-Null }

    New-LabDefinition -Path $labPath -VmPath $labPath -Name $labName -ReferenceDiskSizeInGB 50

    New-LabDefinition -Name $labName -DefaultVirtualizationEngine HyperV
    Add-LabVirtualNetworkDefinition -Name $labName -AddressSpace $labIP/$labMask
    Add-LabDomainDefinition -Name $domainName -AdminUser $nameAdmin-AdminPassword $passAdmin

    



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
Write-Host "2: Lab options"


$selection = Read-Host "Please make a selection"
     switch ($selection)
     {
         '1' {
            systeminfo
            
           
            $Global:fullDiskInfoSave = drivecheck
            $Global:fullDiskInfoSave |ft |Out-Host
            
            read-host " "
            
            
         } '2' {
            Write-host "1. Create lab"
            
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
       