function Get-BitlockerKey{
<#
.SYNOPSIS
Find BitLocker keys assigned to a specified computer, or by the first eight characters of the key ID.
.DESCRIPTION
The functions queries AD for BitLocker keys assigned to the specified computer. There may be more keys than one; in such scenario, please use the newest one.
It may also find the BitLocker key details by the first eight characters of the key ID.
.EXAMPLE
Get-BitlockerKey -ComputerName MyComputerName
.EXAMPLE
Get-BitlockerKey -KeyID A1B3D517
.PARAMETER ComputerName
Please provide a valid computer name to be queried.
.PARAMETER KeyID
Please provide the first eight characters of the key ID.
#>
    Param (
    [parameter(ParameterSetName="Computer",
                mandatory=$true,
                position=0,
                HelpMessage="Please provide a computer name to query for BitLocker keys.")]
    [ValidateScript({
                if (get-adcomputer $_){
                    $true
                }
                else{
                    Throw "'$_' is an incorrect computer name."
                }
                })]
    [ValidateNotNullOrEmpty()]
    $ComputerName,
    [parameter(ParameterSetName="KeyID",
                mandatory=$true,
                position=1,
                HelpMessage="Please provide the first eight characters of the key's ID number.")]
    [ValidatePattern('\A([A-Z]|[a-z]|[0-9])([A-Z]|[a-z]|[0-9])([A-Z]|[a-z]|[0-9])([A-Z]|[a-z]|[0-9])([A-Z]|[a-z]|[0-9])([A-Z]|[a-z]|[0-9])([A-Z]|[a-z]|[0-9])([A-Z]|[a-z]|[0-9])\Z')]
    [ValidateNotNullOrEmpty()]
    $KeyID
    )
if (($ComputerName -ne $null) -and ($KeyID -eq $null)){
    try{
        $computer = Get-ADComputer -Filter {Name -eq $ComputerName}
    }
    catch{
        write-host "Cannot query Active Directory for the specified computer data." -ForegroundColor red -BackgroundColor black
        break
    }
    #get all bitLocker recovery keys for that computer
    try{
        $keydetails = Get-ADObject -Filter {objectclass -eq 'msFVE-RecoveryInformation'} -SearchBase $computer.DistinguishedName -Properties 'msFVE-RecoveryPassword' | select @{n="Computer";e={$computer.name}}, @{n="Bitlocker key value";e={$_.'msfve-recoverypassword'}}, @{n="Bitlocker key name";e={$_.name}}

            if($keydetails -eq $null){
                write-host "No BitLocker key information for computer $ComputerName." -ForegroundColor yellow -BackgroundColor black
            }
            else{
                $keydetails
            }
    }
    catch{
        write-host "Cannot get the BitLocker key details for $ComputerName." -ForegroundColor red -BackgroundColor black
    }
}
#get bitlocker key by first 8 characters of the key's name
elseif (($KeyID -ne $null) -and ($ComputerName -eq $null)){
    try{
        $filter = "*$KeyID*"
        $keydetails = get-adobject -filter {(objectclass -eq 'msFVE-RecoveryInformation') -and (name -like $filter)} -properties 'msFVE-RecoveryPassword' | select *
        if ($keydetails -eq $null){
            write-host "No BitLocker key information for key starting with ID $KeyID" -ForegroundColor red -back Black 
            break
        }
        else{
            $compname = $keydetails.DistinguishedName -split "cn" -split "," -replace "=",""
            $compname = $compname[3]
            $keydetails | select @{n="Computer";e={$compname}}, @{n="Bitlocker key value";e={$_.'msfve-recoverypassword'}}, @{n="Bitlocker key name";e={$_.name}}
        }
    }
    catch{
        write-host "Cannot get the BitLocker key details for key ID starting with $KeyID"
    }
}
} 
function Remove-ProfileWD {
<#   
.SYNOPSIS   
    Interactive menu that allows a user to connect to a local or remote computer and remove local profiles to the connected machine.
.DESCRIPTION 
    After making connection to the machine, the user is presented with all of the local profiles and then is asked to make a selection of which profile to delete. 
    This is only valid on Windows Vista OS and above for clients and Windows 2008 and above for server OS.           
.EXAMPLE  
Remove-ProfileWD
  
Description 
----------- 
Presents a text based menu for the user to interactively remove a local profile on local or remote machine.    
#> 

#Prompt for a computer to connect to 
(
    [Parameter(Mandatory=$true)]
    $Computer = $(Read-Host “Please enter a computer name”)
        )
#Test network connection before making connection 
If ($computer -ne $Env:Computername) { 
    If (!(Test-Connection -comp $computer -count 1 -quiet)) { 
        Write-Warning "$computer is not accessible, please try a different computer or verify it is powered on."
        Break
        } 
    }
Do {     
#Gather all of the user profiles on computer 
Try { 
    [array]$users = Get-WmiObject -ComputerName $computer Win32_UserProfile -filter "LocalPath Like 'C:\\Users\\%'" -ea stop

    } 
Catch { 
    Write-Warning "$($error[0]) "
    Break
    }     
#Cache the number of users 
$num_users = $users.count 
  
Write-Host -ForegroundColor Green "User profiles on $($computer):"
Write-Host -ForegroundColor Green "User profile          Last Use ate"
  
    #Begin iterating through all of the accounts to display 
    For ($i=0;$i -lt $num_users; $i++) { 
        Write-Host -ForegroundColor Green "$($i): $(($users[$i].localpath).replace('C:\Users\',''))      $(get-item \\$computer\C`$\users\$(($users[$i].localpath).replace('C:\Users\',''))|  Foreach {$_.LastWriteTime}) "
        } 
    Write-Host -ForegroundColor Green "q: Quit"
    #Prompt for user to select a profile to remove from computer 
    Do {     
        $account = Read-Host "Select a number to delete local profile or 'q' to quit"
        #Find out if user selected to quit, otherwise answer is an integer 
        If ($account -NotLike "q*") { 
            $account = $account -as [int]
            } 
        }         
    #Ensure that the selection is a number and within the valid range 
    Until (($account -lt $num_users -AND $account -match "\d") -OR $account -Like "q*") 
    If ($account -Like "q*") { 
        Break
        } 
    Write-Host -ForegroundColor Yellow "Deleting profile: $(($users[$account].localpath).replace('C:\Users\',''))"
    #Remove the local profile 
    ($users[$account]).Delete() 
    Write-Host -ForegroundColor Green "Profile:  $(($users[$account].localpath).replace('C:\Users\','')) has been deleted"
  
    #Configure yes choice 
    $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes","Remove another profile."
  
    #Configure no choice 
    $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No","Quit profile removal"
  
    #Determine Values for Choice 
    $choice = [System.Management.Automation.Host.ChoiceDescription[]] @($yes,$no) 
  
    #Determine Default Selection 
    [int]$default = 0 
  
    #Present choice option to user 
    $userchoice = $host.ui.PromptforChoice("","Remove Another Profile?",$choice,$default) 
    } 
#If user selects No, then quit the script     
Until ($userchoice -eq 1)
}
function Send-EmailUpdate {
<#
.SYNOPSIS
    Send Email using  smtp
         
.PARAMETER $credential
    Should be set from the calling script calling the encrypted certs
.PARAMETER $Server
    The hostname of thec smtp server

.PARAMETER $port
    The port to use to send should be 587 for gmail

.PARAMETER $from
    should be set to the the same as credential or an alias

.PARAMETER $to
    Who to send to

.EXAMPLE
 Send-EmailUpdate (Import-CliXml -Path "somepath) smtp.gmail.com 587 from@email.com to@email.com


#>
	Param (
		[parameter(Mandatory = $true)]
		[pscredential]$Credential,
        [parameter(Mandatory = $true)]
		[string]$Server,
		[parameter(Mandatory = $true)]
		[string]$port,
		[parameter(Mandatory = $true)]
		[string]$Body,
		[parameter(Mandatory = $true)]
		[string]$Subject,
		[parameter(Mandatory = $true)]
		[string]$from,
		[parameter(Mandatory = $true)]
		[string]$to
	)
    $SMTPServer = "$Server"
    $SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, $port)
    $SMTPClient.EnableSsl = $true
    $SMTPClient.Credentials = $Credential
    $EmailFrom = "$from"
    $EmailTo = "$to"
    $SMTPClient.Send( $EmailFrom, $EmailTo, $Subject, $Body )
}