Function TranslateRight {
    param (
        [ValidateSet("None","Notify","ReadOnly","ReadWrite","ReadCreate")]
		[System.String]
		$Right
    )
    Switch ($Right) {
        "None" { return 1 }
        "Notify" { return 2 }
        "ReadOnly" { return 4 }
        "ReadWrite" { return 8 }
        "ReadCreate" { return 16 }
    }
}

function Get-TargetResource {
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param (
		[parameter(Mandatory = $true)]
		[System.String]
		$Community
	)

    $Communities = [PSCustomObject](Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\services\SNMP\Parameters\ValidCommunities").psbase.properties | ? { 
            $_.Name -notin @('PSDrive','PSProvider','PSCHildName','PSPath','PSParentPath') 
         } | Select Name,Value

    #Building the Hashtable
    $Script:CommunityList = ""
    $ofs = "="
    $Communities | % { $Script:CommunityList += ","+"$($_.Name,$_.Value)" }
    
    $ReturnValue = @{
        CommunityList=$Script:CommunityList.substring(1)
    }
    $ReturnValue
}


function Set-TargetResource {
	[CmdletBinding()]
	param (
		[parameter(Mandatory = $true)]
		[System.String]
		$Community,

		[ValidateSet("None","Notify","ReadOnly","ReadWrite","ReadCreate")]
		[System.String]
		$Right,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure
	)

    $RightNumber = TranslateRight -Right $Right
    switch ($Ensure) {
        "Present" { 
            Write-Verbose "Addind community to the allowed list"
            New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\services\SNMP\Parameters\ValidCommunities -Name $Community -Value $RightNumber -PropertyType DWORD
        }
        "Absent" {
            Write-Verbose "Removing community from the allowed list"
            Remove-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\services\SNMP\Parameters\ValidCommunities -Name $Community
        }
    
    }
}


function Test-TargetResource {
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param (
		[parameter(Mandatory = $true)]
		[System.String]
		$Community,

		[ValidateSet("None","Notify","ReadOnly","ReadWrite","ReadCreate")]
		[System.String]
		$Right,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure
	)

    $Communities = [PSCustomObject](Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\services\SNMP\Parameters\ValidCommunities").psbase.properties | ? { 
            $_.Name -notin @('PSDrive','PSProvider','PSCHildName','PSPath','PSParentPath') 
         } | Select Name,Value
    
    #Building the Hashtable
    
    $Communities | % { 
        $RightNumber = TranslateRight -Right $Right
        if ($Ensure -eq "Present") {
            if ( $_.Name -eq $Community ) {
                if ($_.Value -eq $RightNumber) { $Return = $true }
                else { $Return = $false }
            }
            else { $Return = $false }
        }
        elseif ($Ensure -eq "Absent") {
            if ( $_.Name -eq $Community ) {
                if ($_.Value -eq $RightNumber) { $Return = $false }
                else { $Return = $true }
            }
            else { $Return = $true }
        }
    }
    $Return
}


Export-ModuleMember -Function *-TargetResource

