function Get-TargetResource 
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param 
    (
		[parameter(Mandatory = $true)]
		[System.String]
		$Manager
	)

	Write-Verbose "Gathering all permitted Managers"
	$Manager = [PSCustomObject](Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\services\SNMP\Parameters\PermittedManagers").psbase.properties | ? {
            $_.Name -match "[1-9]" 
         } | Select Name,Value

    $ReturnValue = @{
        Manager=$Managers.Value -join ','
    }
    $ReturnValue
}

function Set-TargetResource 
{
	[CmdletBinding()]
	param 
    (
		[parameter(Mandatory = $true)]
		[System.String]
		$Manager,

        [ValidateSet("Present","Absent")]
		[System.String]
		$Ensure

	)
    
    # Gather all registered permitted managers
    if (Test-Path HKLM:\SYSTEM\CurrentControlSet\services\SNMP\Parameters\PermittedManagers) {
        $Managers = [PSCustomObject](Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\services\SNMP\Parameters\PermittedManagers").psbase.properties | ? {
                    $_.Name -match "[1-9]" 
                } | Select Name,Value
        switch ($Ensure) {
            "Present" {
                if ($Manager -eq "Any") { 
                    $Managers | % {
                        $Name = $_.Name.Trim()
                        Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\services\SNMP\Parameters\PermittedManagers" -Name $_.Name
                    }
                } 
                else {
                    [Int]$LastNum = ($Managers |  Sort-Object Name | Select Name -Last 1).Name
                    $LastNum++
                    New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\services\SNMP\Parameters\PermittedManagers" -Name $LastNum -PropertyType String -Value $Manager
                }
                Write-Verbose "Adding new Manager to permitted list"
            }
            "Absent" {
                if ($Manager -eq "Any") {
                     $Managers | % {
                        $Name = $_.Name.Trim()
                        Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\services\SNMP\Parameters\PermittedManagers" -Name $_.Name
                    }
                }
                else {
                    $Managers | ? { $_.value -eq $Manager } | % {
                        $Name = $_.Name.Trim()
                        Remove-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\services\SNMP\Parameters\PermittedManagers" -Name $Name
                    }
                }
                Write-Verbose "Removing Manager of permitted list"
            }
        }
    }
    else {
        throw "Can't locate registry key for permitted managers"
    }
}


function Test-TargetResource 
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param 
    (
		[parameter(Mandatory = $true)]
        [System.String]
		$Manager,

        [ValidateSet("Present","Absent")]
		[System.String]
		$Ensure
	)

	
	Write-Verbose "Gathering all permitted Managers"
	$Managers = [PSCustomObject](Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\services\SNMP\Parameters\PermittedManagers").psbase.properties | ? {
            $_.Name -match "[1-9]" 
         } | Select Value


    

    Switch ($Ensure) {
        "Present" {
            if ($Manager -in $Managers.Value ) {
                $return = $true
            }
            else {
                $return = $false
            }
        }
        "Absent" {
            if ($Manager -in $Managers.Value) {
                $return = $false
            }
            else {
                $return = $true
            }
        }
    }
    $return
        
}


Export-ModuleMember -Function *-TargetResource

