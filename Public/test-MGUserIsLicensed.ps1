# test-MGUserIsLicensed

#*----------v Function test-MGUserIsLicensed() v----------
function test-MGUserIsLicensed {
    <#
    .SYNOPSIS
    test-MGUserIsLicensed.ps1 - Evaluate IsLicensed status on a passed in MGUser [Microsoft.Graph.PowerShell.Models.MicrosoftGraphUser] object
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     :	http://www.toddomation.com
    Twitter     :	@tostka / http://twitter.com/tostka
    CreatedDate : 2022-03-22
    FileName    : 
    License     : MIT License
    Copyright   : (c) 2022 Todd Kadrie
    Github      : https://github.com/tostka/verb-XXX
    Tags        : Powershell
    REVISIONS
    * 2:17 PM 1/7/2026 roughed in, updated [type], "should" work;  WIP unupdated port from AADLicense -> MGUDLicense
    1:32 PM 3/23/2022 init; confirmed functional
    .DESCRIPTION
    test-MGUserIsLicensed.ps1 - Evaluate IsLicensed status on a passed in MGUser [Microsoft.Graph.PowerShell.Models.MicrosoftGraphUser] object
    (Evaluates AssignedLicenses.count -gt 0). 
    Emulates the lost get-MsolUser IsLicensed property
    .PARAMETER  User
    MGUser [Microsoft.Graph.PowerShell.Models.MicrosoftGraphUser] object
    .EXAMPLE
    PS> $isLicensed = test-MGUserIsLicensed -user $MGUser -verbose
    Evaluate IsLicensed status on passed MGUser object
    .LINK
    https://github.com/tostka/verb-MG
    #>
    #Requires -Version 3
    ##  Requires -Modules AzureAD, verb-Text
    ##Requires -RunasAdministrator
    # VALIDATORS: [ValidateNotNull()][ValidateNotNullOrEmpty()][ValidateLength(24,25)][ValidateLength(5)][ValidatePattern("some\sregex\sexpr")][ValidateSet("USEA","GBMK","AUSYD")][ValidateScript({Test-Path $_ -PathType 'Container'})][ValidateScript({Test-Path $_})][ValidateRange(21,65)][ValidateCount(1,3)]
    [CmdletBinding()]

     Param(
        [Parameter(Position=0,Mandatory=$True,HelpMessage="Either Msoluser object or UserPrincipalName for user[-User upn@domain.com|`$msoluserobj ]")]
        [Microsoft.Graph.PowerShell.Models.MicrosoftGraphUser]$User
    )
    BEGIN {
        #${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
        #$Verbose = ($VerbosePreference -eq 'Continue') ;
        #Connect-MG -Credential:$Credential -verbose:$($verbose) ;
        
        # check if using Pipeline input or explicit params:
        if ($PSCmdlet.MyInvocation.ExpectingInput) {
            #write-verbose "Data received from pipeline input: '$($InputObject)'" ;
        } else {
            # doesn't actually return an obj in the echo
            #write-verbose "Data received from parameter input: '$($InputObject)'" ;
        } ;
    } 
    PROCESS {
        
         [boolean]($User.AssignedLicenses.count -gt 0)

    }  # PROC-E
    END{} ;
} ; 
#*------^ END Function test-MGUserIsLicensed() ^------