### Pings VPN Router IP address 
### When ping fails, emails notification.
### When ping back online, emails notification.
### Restarts loop.
### IP address to monitor
### requires the Send-EmailUpdate module
$IPAddress = "IP of thnnel router"
$credpath = "D:\ip\smtp.xml"
$To = "Who to alert"
$from = "service account"
# Account information
if (Test-Path $credpath -eq $false ) {
    Write-Host "missing creds"
     Get-Credential | Export-CliXml  -Path ("$credpath")
     }
## Starting Script
$subject = "VPN Tunnel Alert Scipt Start"
$body = "Starting Script"
$Credential = Import-CliXml -Path ("$credpath")
Send-EmailUpdate -credential $Credential -Server smtp.gmail.com -port 587 -from $from -to $to -subject $subject -body "$body"
      


# Start of monitoring loop
Do {

    # Starts Test-NetConnection, looking for failed pings

    Do {

        $PingComputer1 = (Test-NetConnection $IPAddress).PingSucceeded
        $PingComputer2 = (Test-NetConnection $IPAddress).PingSucceeded

        $PingComputer1
        $PingComputer2

        Sleep 10
    }

    # When ping fails, it will send a notification email.
    Until (($PingComputer1 -eq $false) -and ($PingComputer2 -eq $false))

    # Send email notification that connection has been lost
       $Subject = "VPN DOWN ALERT"
       $Body = "The VPN HAS Failed"
       Send-EmailUpdate -credential $Credential -Server smtp.gmail.com -port 587 -from $from -to $to -subject $subject -body "$body"


    Do {
        $PingComputer1 = (Test-NetConnection $IPAddress).PingSucceeded
        $PingComputer2 = (Test-NetConnection $IPAddress).PingSucceeded

        $PingComputer1
        $PingComputer2

        Sleep 10
    }

    # When ping is successful, it will send a notification email.
    Until (($PingComputer1 -eq $true) -and ($PingComputer2 -eq $true))

    # Send email notification that connection is back online
       $Subject = "VPN RESTORED"
       $Body = "VPN has been restored"
       Send-EmailUpdate -credential $Credential -Server smtp.gmail.com -port 587 -from $from -to $to -subject $subject -body "$body"

}

Until (1 -eq 0) # end of monitoring loop, which never terminates.