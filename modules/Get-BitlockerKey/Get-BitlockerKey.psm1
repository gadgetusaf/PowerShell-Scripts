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