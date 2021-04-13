Import-module ExchangeOnlineManagement
Import-module PnP.PowerShell

$path = "C:\Apps\adminemail.txt"
if (Test-Path $path) {
    $Adminemail = Get-Content $Path
   #Connect-MsolService 
    Connect-PnPOnline https://onlinelagit.sharepoint.com/sites/lagit -interactive

     Connect-ExchangeOnline -userPrincipalNAme $Adminemail -ShowProgress $True
    
} else {
  $Adminemail = Read-Host "Please type your eol admin email, you see this line only because you are using this script from a new device"
  $Adminemail | out-file "C:\Apps\adminemail.txt"
   
    #Connect-MsolService 
   Connect-SPOService -url https://onlinelagit-admin.sharepoint.com
     Connect-ExchangeOnline -userPrincipalNAme $Adminemail -ShowProgress $True
     
}


function createmailbox ($mailbox, $displayname, $primarysmtp) {
  $adrian = "adrian.stefaniak@lagit.pl"
  

  New-Mailbox -Name $mailbox -displayname $displayname -Shared -PrimarySmtpAddress $primarysmtp
  
  Add-RecipientPermission -Identity $primarysmtp -Trustee $adrian -AccessRights SendAs
  Set-Mailbox -Identity $primarysmtp -DeliverToMailboxAndForward $true -ForwardingSMTPAddress $adrian

 return $primarysmtp

}

function createprimarysmtp ($mailbox) {

  $lagit  = "@lagit.pl"
  $lowLetterMailbox = $mailbox.ToLower()
  $primarysmtp = $lowLetterMailbox + $lagit
  return $primarysmtp
}

function createnewlistrecord ($mailbox, $displayname, $primarysmtp, $date) {

  $updateditem = Add-PnPListItem -List "Email List" -Values @{"Title" = $primarysmtp; "Name" = $mailbox; "DisplayName" = $displayname; "Creationdate" = $date}

}

function displaynamechoice {

  Write-Host = "1. To display as Adrian Stefaniak"
  Write-Host = "2. To display as Adures"
  Write-Host = "3. Custom"
  

  $selection = Read-Host "Please make a selection"
     switch ($selection)
     {
         '1' {

            $displayname = "Adrian Stefaniak"
             
             
         } '2' {
          $displayname = "Adures"


         }
         '3' {
            $displayname = Read-Host "Please provide custom display name "

         } 
      }

      return $displayname
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
   
Write-Host "1: Create new shared mailbox with forwarding"
Write-Host "2: Placeholder for future options"


$selection = Read-Host "Please make a selection"
     switch ($selection)
     {
         '1' {

            $mailbox = read-host "Please provide an email address for the mailbox that you want to create (without @lagit.pl)"
            $primarysmtp =  createprimarysmtp $mailbox
            $displayname = displaynamechoice
            createmailbox $mailbox $displayname $primarysmtp
            $date = date
           
            createnewlistrecord $mailbox $displayname $primarysmtp $date
            
            $selection2 =  Read-host "Mailbox created, click 1 to come back to main menu and 2 to finish the script" 
            switch ($selection2){
              
              '1'{
              main-menu

              }

              '2' {
                Disconnect-ExchangeOnline
                Disconnect-PnPOnline

              }

            }

            
             
         } '2' {
          Disconnect-ExchangeOnline
          Disconnect-PnPOnline
         } 
      }



}
main-menu