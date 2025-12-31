# Wait-MGOPSync.ps1

#*------v Function Wait-MGOPSync v------
Function Wait-MGOPSync {
    <# 
    .SYNOPSIS
    Wait-MGOPSync - Dawdle loop for notifying on next AD-EntraID AD sync (Microsoft.Graph)
    .NOTES
    Updated By: : Todd Kadrie
    Website:	http://tinstoys.blogspot.com
    Twitter:	http://twitter.com/tostka
    REVISIONS   :
    * 11:03 AM 12/31/2025 port from verb-AAD\wait-AADSync to Microsoft.Graph (fu M$) -> verb-MG\Wait-MGOPSync()
    .DESCRIPTION
    Wait-MGOPSync - Dawdle loop for notifying on next AD-EntraID AD sync (Microsoft.Graph)
    .PARAMETER Credential
    Credential to be used for connection
    .INPUTS
    None. Does not accepted piped input.
    .OUTPUTS
    Returns an object with LastDirSyncTime, expressed as TimeGMT & TimeLocal
    .EXAMPLE
    Wait-MGOPSync
    .LINK
    #>
    Param(
        #[Parameter()]$Credential = $global:credo365TORSID
        # no supported cred param
    ) ; 
    BEGIN{
        Connect-MgGraph -Scopes "Organization.Read.All" -NoWelcome # suppress the banner, or it dumps it into the pipeline!
        #$LastDirSyncTime = (Get-MsolCompanyInformation).LastDirSyncTime ;
        #$LastDirSyncTime = (Get-AzureADTenantDetail).CompanyLastDirSyncTime ;
        $LastDirSyncTime = Get-MgOrganization | select -expand OnPremisesLastSyncDateTime
    }
    PROCESS{                
        write-host -foregroundcolor yellow "$((get-date).ToString('HH:mm:ss')):Waiting for next AAD Dirsync:`n(prior:$($LastDirSyncTime.ToLocalTime()))`n[" ; 
        Do {Connect-MgGraph -Scopes "Organization.Read.All" -NoWelcome  ; write-host "." -NoNewLine ; Start-Sleep -m (1000 * 5) } Until ((Get-MgOrganization).OnPremisesLastSyncDateTime -ne $LastDirSyncTime) ;
    } ; 
    END{
        $LatestNewSync = (Get-MgOrganization).OnPremisesLastSyncDateTime ; 
        New-Object PSObject -Property @{
          TimeGMT   = $LatestNewSync   ;
          TimeLocal = $LatestNewSync.ToLocalTime() ;
        } | write-output ;
        write-host -foregroundcolor yellow "]`n$((get-date).ToString('HH:mm:ss')):AD->AAD REPLICATED!" ; 
        write-host "`a" ; write-host "`a" ; write-host "`a" ;
    } ; 
} ; #*------^ END Function Wait-MGOPSync ^------
if(!(get-alias Wait-MSolSync -ea 0 )) {Set-Alias -Name 'wait-MSolSync' -Value 'Wait-MGOPSync' ; } ;

