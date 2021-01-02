param (
    [Parameter(Mandatory=$false)]
    $Prompt
    )
$SMTPserver = "smtp.gmail.com"
$Port = "587"
$from = "email"
$to = "email"
$urllistpath = "D:\ip\update.list.csv"
$scriptpath = "D:\ip\"
$wanIPm = (Invoke-RestMethod http://ipinfo.io/)
$wanIP = $wanIPm.ip
$credpath = "D:\creds\"
$list = (Import-Csv D:\ip\update.list.csv)
if ($Prompt -eq "testmail" ) {
    $Credential = Import-CliXml -Path ($scriptpath + "smtp.xml")
    $subject = "Test email"
    $body = "This is a test email."
    Send-EmailUpdate -Credential ($Credential) -Server $SMTPserver -port $Port -from $from -to $to -subject "$subject" -body "$body"
    exit
    }
if ((test-Path ($scriptpath + "smtp.xml")) -eq $false -or $prompt -eq "email") {
    DO {
        write-host "setup Email"
        write-host "Please enter you user name and password"  
        write-host "After configuring the the script"
        write-host "calling popup in 5 sec"
        sleep 5
        Get-Credential | Export-CliXml  -Path ($scriptpath + "smtp.xml")
        $Credential = Import-CliXml -Path ($scriptpath + "smtp.xml")
        $subject = "Test email"
        $body = "This is a test email from the DDNS update script."
        write-host "Sending a test email"
        Send-EmailUpdate -Credential ($Credential) -Server $SMTPserver -port $Port -from $from -to $to -subject "$subject" -body "$body"
        sleep 7
        $emailquestion = Read-host -prompt "Did you get and email y/N"
    } until ($emailquestion -eq "Y" -or $emailquestion -eq "y")
}
if ((Test-Path $DNSList ) -eq $false) {
"Domain,Sub,Creds,email" | Out-File -FilePath $urllistpath
 do { 
        $Domain = (Read-Host -Prompt "Domain")
        $Sub = (Read-Host -Prompt "Sub" )
        Get-Credential | Export-CliXml  -Path ($credpath + $Sub + ".XML")
        $credfile = $credpath + $Sub + "." + $domain +".xml"
        $email = (Read-host -prompt "email")
        $head = $Domain + "," + $Sub + "," + $credfile + "," $email
        $head | Out-File -FilePath $urllistpath -Append
        $another = Read-Host -Prompt "Add another host? [y/n]"
        } until ($another -eq "no" -or $another -eq "NO" -or $another -eq "n" -or $another -eq "N")
        Write-Host "setup complete"
        }
if ($Prompt -eq "Add" -or $Prompt -eq "add" -or $Prompt -eq "A" -or $Prompt -eq "a") {
   do { 
        $Domain = (Read-Host -Prompt "Domain")
        $Sub = (Read-Host -Prompt "Sub" )
        Get-Credential | Export-CliXml  -Path ($credpath + $Sub + ".XML")
        $credfile = $credpath + $Sub + "." + $domain +".xml"
        $email = (Read-host -prompt "email")
        $head = $Domain + "," + $Sub + "," + $credfile "," $email
        $head | Out-File -FilePath $urllistpath -Append
        $DNS_IP = (Resolve-DnsName  $subdomain -Type A -Server 8.8.8.8)
        $DNSip = $DNS_IP.IPAddress
        $importedcreds = (Import-CliXml -Path ($credpath + $Sub + ".XML"))
        Update-GoogleDynamicDNS -Credential $importedcreds -domainName $domain -subdomainName $Sub
        $another = Read-Host -Prompt "Add another host? [y/n]"
        } until ($another -eq "no" -or $another -eq "NO" -or $another -eq "n" -or $another -eq "N")   
}
foreach ($domain in $list) {
     $creds = $($domain.Creds)
     $sub = ($domain.Sub)
     $domain = ($domain.Domain)
     $subdomain ="$sub" + "." + "$domain"
     $email + $($domain.email)
     write-host $subdomain
     $DNS_IP = (Resolve-DnsName  $subdomain -Type A -Server 8.8.8.8)
     write-host $DNS_IP
     $DNSip = $DNS_IP.IPAddress
     if (!$Prompt) {
     if ($wanIP -eq $DNSip) {
         Write-Host pancake
         } else { 
         write-host $($_.Domain) 
         Write-Host "update needed"
         Write-Host "Updating IP Address to " + $wanIP
         $importedcreds = (Import-CliXml -Path $creds)
         Update-GoogleDynamicDNS -Credential $importedcreds -domainName $_.Domain -subdomainName $_.Sub
         Send-EmailUpdate -Credential ($Credential) -Server $SMTPserver -port $Port -from $from -to $email -subject "$subject" -body "$body"
    }}
    if ($Prompt -eq "Force" -or $Prompt -eq "force" -or $Prompt -eq "F" -or $Prompt -eq "f") {
         $importedcreds = (Import-CliXml -Path $creds)
         Update-GoogleDynamicDNS -Credential $importedcreds -domainName $_.Domain -subdomainName $_.Sub
}}
