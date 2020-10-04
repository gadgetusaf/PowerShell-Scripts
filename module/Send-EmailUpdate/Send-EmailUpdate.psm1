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