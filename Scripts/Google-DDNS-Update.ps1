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
    Add = add a host to the update list
    Force = Force an update

.EXAMPLE
    Google-DDNS-Update.ps1
        Used to run silently or on first run to add and create a hostname list.
    Google-DDNS-Update.ps1 add
        Add a domain in to the list
    Google-DDNS-Update.ps1 Force
        Note Force is case sensitive 
    #>
    param (
        [Parameter(Mandatory=$false)]
        $Prompt
        <#
        can be set to  
        F or Force = Force all domains to be updates
        A or Add = Add new host to the list
        #>
        )
    $SMTPserver = "smtp.gmail.com"
    $Port = "587"
    $from = "ddr@gadgetusaf.com"
    $to = "chris.burton@chrisgburton.com"
    $urllistpath = "D:\ip\update.list.csv"
    $wanIPm = (Invoke-RestMethod http://ipinfo.io/)
    $wanIP = $wanIPm.ip
    $credpath = "D:\creds\"
    $list = (Import-Csv D:\ip\update.list.csv)
    if ((Test-Path $urllistpath ) -eq $false) {
    "Domain,Sub,Creds" | Out-File -FilePath $urllistpath
    do { 
            $Domain = (Read-Host -Prompt "Domain")
            $Sub = (Read-Host -Prompt "Sub:" )
            Get-Credential | Export-CliXml  -Path ($credpath + $Sub + "." + $Domain + ".XML")
            $credfile = $credpath + $Sub + "." + $domain +".xml"
            $head = $Domain + "," + $Sub + "," + $credfile
            $head | Out-File -FilePath $urllistpath -Append
            $another = Read-Host -Prompt "Add another host? [y/n]"
            } until ($another -eq "no" -or $another -eq "NO" -or $another -eq "n" -or $another -eq "N")}
    if ($Prompt -eq "Add" -or $Prompt -eq "add" -or $Prompt -eq "A" -or $Prompt -eq "a") {
    do { 
            $Domain = (Read-Host -Prompt "Domain")
            $Sub = (Read-Host -Prompt "Sub:" )
            Get-Credential | Export-CliXml  -Path ($credpath + $Sub + "." + $Domain + ".XML")
            $credfile = $credpath + $Sub + "." + $domain +".xml"
            $head = $Domain + "," + $Sub + "," + $credfile
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
        $DNS_IP = (Resolve-DnsName  $subdomain -Type A -Server 8.8.8.8)
        $DNSip = $DNS_IP.IPAddress
        if (!$Prompt) {
        if ($wanIP -eq $DNSip) {} else { 
            $importedcreds = (Import-CliXml -Path $creds)
            Update-GoogleDynamicDNS -Credential $importedcreds -domainName $domain -subdomainName $sub
        }}
        if ($Prompt -eq "Force" -or $Prompt -eq "force" -or $Prompt -eq "F" -or $Prompt -eq "f") {
            $importedcreds = (Import-CliXml -Path $creds)
            Update-GoogleDynamicDNS -Credential $importedcreds -domainName $domain -subdomainName $sub
    }}
