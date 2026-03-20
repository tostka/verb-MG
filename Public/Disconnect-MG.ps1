# Disconnect-MG.ps1

#*------v Disconnect-MG.ps1 v------
Function Disconnect-MG {
    <#
    .SYNOPSIS
    Disconnect-MG - Simple short wrapper for disconnect-mggraph
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     :	http://www.toddomation.com
    Twitter     :	@tostka / http://twitter.com/tostka
    CreatedDate : 2020-03-03
    FileName    : 
    License     : 
    Copyright   : 
    Github      : https://github.com/tostka/verb-MG
    Tags        : Powershell,ExchangeOnline,Exchange,RemotePowershell,Connection,MFA
    AddedCredit : ExactMike Perficient
    AddedWebsite:	https://social.technet.microsoft.com/Forums/msonline/en-US/f3292898-9b8c-482a-86f0-3caccc0bd3e5/exchange-powershell-monitoring-remote-sessions?forum=onlineservicesexchange
    AddedTwitter:	
    REVISIONS   :
    * 1:46 PM 3/20/2026 add alias: dmg
    * 4:52 PM 3/19/2026
    .DESCRIPTION
    Disconnect-MG - Simple short wrapper for disconnect-mggraph    
    .PARAMETER silent
    Switch to suppress all non-error echos
    .INPUTS
    None. Does not accepted piped input.
    .OUTPUTS
    None. Returns no objects or output.
    .EXAMPLE
    Disconnect-MG;
    Disconnect all MGgraph connections
    .EXAMPLE
    Disconnect-MG -silent;
    Demos use of the silent parameter to suppress output of details
    .LINK
    Github      : https://github.com/tostka/verb-exo
    #>
    [CmdletBinding()]
    [Alias('dmg')]
    Param(
        [Parameter(HelpMessage="Silent output (suppress status echos)[-silent]")]
            [switch] $silent
    ) 
    $verbose = ($VerbosePreference -eq "Continue") ; 
    $dMGConn = disconnect-mggraph ; 
    if($silent){} else {
        write-host "$(($dMGConn |out-string).trim())" ;    
    }
    
} ; 

#*------^ Disconnect-MG.ps1 ^------