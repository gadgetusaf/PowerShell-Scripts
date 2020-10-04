################################
#                              #
#   DDNS Updater v2.5 public   #
# For use with  Google Domains #
#                              #
################################

<#
.SYNOPSIS
    This script will update Google DDNS using powershell
    
    You Must preinstall the powershell module GoogleDynamicDNSTools Please Note this command must be run with admin using the command below. if you can not run as admin you can download the source from the link below. 
    
    Install-Module -Name GoogleDynamicDNSTools
    https://github.com/drewfurgiuele/GoogleDynamicDNSTools/blob/master/Functions/Update-GoogleDynamicDNS.ps1
    
    Also you will need the Send-EmailUpdate function in my Github
         
.DESCRIPTION
    This script will build a list of hostnames to update when your WAN IP differs from the IP Google DNS has for a domain you monitor. 
    
    On first run this script will create a list of hostname to update when you want IP differs from the DNS record of the monitored hostname. 
    
    If you are planning on running this script as a scheduled task, you MUST select RUNAS and run as the same user that created the credentials . This is a requirement for powershell saved credentials. 

    You Must preinstall the powershell module GoogleDynamicDNSTools Please Note this command must be run with admin using the command below. if you can not run as admin you can download the source from the link below. 
    
    Install-Module -Name GoogleDynamicDNSTools
    https://github.com/drewfurgiuele/GoogleDynamicDNSTools/blob/master/Functions/Update-GoogleDynamicDNS.ps1
    
    Also you will need the Send-EmailUpdate function in my Github
    
.PARAMETER $Prompt

    Prompt allows you to call the script into different modes.

    prompt can be set to:
    add = add a host to the update list
    Force = Force an update

.EXAMPLE
    Google-DDNS-Update.ps1
        Used to run silently or on first run to add and create a hostname list.
    Google-DDNS-Update.ps1 add
        Add a domain in to the list
    Google-DDNS-Update.ps1 Force
        Note Force is case sensitive 

.NOTES
Edit the script and change the below values

$DomainChecked = A FQDN that is in the list to be updated
$rootdrive = C:\ or D:\ or C:\Users\person\documents\ipcheck\
$credfolder =  "creds\" Make sure to have the \ after
$dnsfolder = "ip\" Make sure to have the \ after
$FileName = "update.list.csv" file list of domains
.LINK


#>


param (
    [Parameter(Mandatory=$false)]
    $Prompt
    <#
    prompt can be set to:
    add = add a host to the update list
    silent = Runs update check
    Force = Force an update
    #> 
        )
function Send-EmailUpdate {
# This will be moved into a powershell module soon
    $SMTPServer = "smtp.gmail.com"
    $SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 587)
    $SMTPClient.EnableSsl = $true
    $SMTPClient.Credentials = New-Object System.Net.NetworkCredential("gmail-email", "app password");
    $EmailFrom = "email"
    $EmailTo = "email"
    $Subject = "WAN IP Change"
    $Body = "New WAN IP address found starting update. Old IP $GoogleIP  New IP $wanIP"
    $SMTPClient.Send( $EmailFrom, $EmailTo, $Subject, $Body )
}
$DomainChecked = "Monotor Domain"
$rootdrive = "D:\"
$credfolder =  "creds\"
$dnsfolder = "ip\"
$FileName = "update.list.csv"
# do no change nex 3 lines building folder paths.
$credpath = $rootdrive + $credfolder
$dnspath = $rootdrive + $dnsfolder
$DNSList = $dnspath + $FileName
if ((Test-Path  $credpath) -eq $false) { 
    New-Item -Path "$rootdrive" -ItemType directory -Name $credfolder
    }
if ((Test-Path $dnspath) -eq $false) {
    New-Item -Path $rootdrive -Type directory -Name $dnsfolder
    }
# This is a rebuild section.
if ((Test-Path $DNSList ) -eq $false -and (Test-Path -Path "$credpath$DomainChecked.xml") -eq $true) {
    Write-Host "Configuration file not found,"
    do {
       $recover = ( Read-Host -Prompt "Attempt to recover from previous creds? y/n " )
        } until ( $recover -eq "y" -or $recover -eq "n" -or $recover -eq "Y" -or $recover -eq "N" )
        #Starting rebuild if y skipping if not
    if ( $recover -eq "y" -or $recover -eq "Y" ) {
         #$OutCSV = @() #Array for rebuild
         "Domain,Sub,Creds" | Out-File -FilePath $DNSList
        Get-ChildItem -Path $credpath -Filter *.xml | ForEach-Object {
            #$out = @()
            $hostname = $_.Name.TrimEnd("xml")
            $Hostn = $hostname.TrimEnd('.')
            $Sub,$Domain = $hostn.Split(".",2)
            $OutLine = $Domain + ',' + $Sub + ',' + $credpath + $Sub + '.' + $Domain + '.xml'
            
            #"Domain,Sub,Creds,error" | Out-File -FilePath $DNSList -Verbose 
            $OutLine | out-file -filepath $DNSList -Verbose -Append
            $OutLine | Write-Host
            $Prompt = "no"
     }
}
    }
# add domains to monitor
if ((Test-Path $DNSList ) -eq $false -and (Test-Path -Path "$credpath$DomainChecked.xml") -eq $false) {    
    Write-Host "You will be prompted now to create the file"
    Write-Host "Domain is you domain plus tld like google.com"
    Write-Host "SubDomain is like www or mail"
    Write-host "You will be prompted for the host creds"
    "Domain,Sub,Creds" | Out-File -FilePath $DNSList
   do { 
        $Domain = (Read-Host -Prompt "Domain")
        $Sub = (Read-Host -Prompt "Sub:" )
        Get-Credential | Export-CliXml  -Path ($credpath + $Sub + ".XML")
        $credfile = $credpath + $Sub + "." + $domain +".xml"
        $head = $Domain + "," + $Sub + "," + $credfile
        $head | Out-File -FilePath $DNSList -Append
        $Prompt = Read-Host -Prompt "Add another host? [y/n]"
        } until ($Prompt -eq "no" -or $Prompt -eq "NO" -or $Prompt -eq "n" -or $Prompt -eq "N")
        Write-Host "setup complete"
    }

if ($Prompt -eq "add") {
    do {
        $Domain = (Read-Host -Prompt 'Domain:')
        $Sub = (Read-Host -Prompt "Sub:" )
        Get-Credential | Export-CliXml  -Path ($credpath + $sub + "." + $domain + ".XML")
        $credfile = $credpath + $Sub + "." + $Domain + ".xml"
        $head = $Domain + "," + $Sub + "," + $credfile
        $head | Out-File -FilePath $DNSList -Append
        $Prompt = Read-Host -Prompt "Add another host? [y/n]"
        } until ($Prompt -eq "no" -or $Prompt -eq "NO" -or $Prompt -eq "n" -or $Prompt -eq "N")
        }
# Start of update chek
$DNS_IP = (Resolve-DnsName $DomainChecked -Type A -Server 8.8.8.8)
$DNSip = $DNS_IP.IPAddress
$wanIPm = (Invoke-RestMethod http://ipinfo.io/)
$wanIP = $wanIPm.ip
write-host "Current DDNs IP is $DNSip WAN IP is $wanIP" 
if ($wanIP -eq $DNSip -and $Prompt -ne "Force"){
    write-host "no update"
    } else { 
    Write-Host "update needed"
    Write-Host "Updating IP Address to " + $wanIP
    $csv = Import-Csv -Path $DNSList | ForEach-Object {
        $Creds = Import-CliXml -Path $_.Creds
        Update-GoogleDynamicDNS -Credential $Creds -domainName $_.Domain -subdomainName $_.Sub
        }
    Send-EmailUpdate 
}