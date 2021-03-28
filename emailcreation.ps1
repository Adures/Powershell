Import-module ExchangeOnlineManagement

$path = "C:\Apps\adminemail.txt"
if (Test-Path $path) {
    $Adminemail = Get-Content $Path
   # Connect-MsolService 
     Connect-ExchangeOnline -userPrincipalNAme $Adminemail -ShowProgress $True
    
} else {
  $Adminemail = Read-Host "Please type your eol admin email, you see this line only because you are using this script from a new device"
  $Adminemail | out-file "C:\Apps\adminemail.txt"
   
    #Connect-MsolService 
     Connect-ExchangeOnline -userPrincipalNAme $Adminemail -ShowProgress $True
     
}


fucntion createmailbox ($mailbox) {

    $emailmaiblox = $mailbox



}

function displaynamechoice {

  Read-Host = "1. To display as Adrian Stefaniak"
  Read-Host = "2. To display as Adures"
  Read-Host = "To display as emai for example wordpress@lagit.pl displays as Wordpress"
  Read-Host = "test3"

}


function Main-Menu {
    param (
        [Parameter(Mandatory=$false)]
        [string]$Title = 'Menu'
    )
    changescreensize 30 60
    Clear-Host
    Start-Sleep -Milliseconds 200

    #add new menu entry, adjust switches + functions below menu section
Write-Host "================== $Title ==================="  -BackgroundColor DarkGreen
   
Write-Host "1: Check and change mfa status"
Write-Host "2: Generate report"


$selection = Read-Host "Please make a selection"
     switch ($selection)
     {
         '1' {

            $mailbox = read-host "Please provide an email address for the mailbox that you want to create"
            
            createmailbox $mailbox 
             
         } '2' {
           Main-Menu
         } 
      }



}
main-menu