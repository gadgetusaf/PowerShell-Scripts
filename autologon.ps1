#Add-Type for password generator
Add-Type -AssemblyName 'System.Web'

#Check of required modules are installed, otherwise install them
If (Get-Module -ListAvailable -Name ActiveDirectory) {
    Write-Host "AD Module installed" 
    } Else {
        Import-Module ServerManager
        Install-WindowsFeature RSAT-AD-PowerShell
        Write-Host "Installed prerequisites" 
        }

#Read CSV file containing the hosts and corresponding users to update
#CSV file requires headers Hostname,Username
$pathtocsv = Read-Host "Enter full path to CSV file, without quotes"
$csv = Import-Csv -Path $pathtocsv
$csv | ForEach-Object {
    if ((Test-NetConnection -ComputerName $_.Hostname -Port 445  ) -eq $false) {
    Write-Host "firewall issue"
    pause
    } else {
    #Check if destination path is correct. Copy the Autologon64.exe tool the destination host
    $DestinationFolderPath = "\\" + $_.Hostname + "\admin$\temp"
    $DestinationFilePath = "\\" + $_.Hostname + "\admin$\temp\Autologon64.exe"
    $FileExists = Test-Path -Path $DestinationFilePath
    $FolderExists = Test-Path -Path $DestinationFolderPath
    #Generate a random password with a minimum and maximum length, and a minimum amount of special chars
    $minLength = 16
    $maxLength = 32
    $length = Get-Random -Minimum $minLength -Maximum $maxLength
    $nonAlphaChars = 8
    $password = [System.Web.Security.Membership]::GeneratePassword($length, $nonAlphaChars)

    Write-Host "Username:`t`t"$_.Username
    Write-Host "New password:`t" $password

    #Update AD account with newly generated password
    Set-ADAccountPassword -Identity $_.Username -Reset -NewPassword (ConvertTo-SecureString -AsPlainText $password -Force)

    If ($FolderExist -eq $False) {
        New-Item -ItemType Directory $DestinationFolderPath
    }
    Copy-Item -Path "\\SharePath\Autologon64.exe" -Destination $DestinationFolderPath -Force

    #Run the Autologon64.exe tool on the remote host
    Invoke-Command -ComputerName $_.Hostname -ArgumentList $_.Username, $password {
        param($Username, $Pass)
        Unblock-File "C:\Windows\temp\Autologon64.exe"
        $args = $Username + " AD FQDN ad.domain.com " + $Pass + " /accepteula"
        Start-Process 'C:\Windows\temp\Autologon64.exe' -ArgumentList $args -Wait -Verb RunAs
    }

    #Cleanup
    Remove-Item $DestinationFilePath -Force
    }
}