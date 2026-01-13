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
    * 3:28 PM 1/6/2026 fixed ipmo mg ;  spliced in cmg scaff
    * 3:34 PM 1/5/2026 rpl AAD => EntraID strings
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
        #region cMG_SCAFFOLD ; #*------v cMG_SCAFFOLD v------
        if(-not (get-command  test-mgconnection)){
            if(-not (get-module -list Microsoft.Graph -ea 0)){
                $smsg = "MISSING Microsoft.Graph!" ; 
                $smsg += "`nUse: install-module Microsoft.Graph -scope CurrentUser" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent} 
                else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
            } ;             
        } ;
        $MGCntxt = test-mgconnection -Verbose:($VerbosePreference -eq 'Continue') ;
        $o365Cred = $null ;
        if($Credential -AND $MGCntxt.isConnected){
            $smsg = "Explicit -Credential:$($Credential.username) -AND `$MGCntxt.isConnected: running pre:Disconnect-MgGraph" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            # Dmg returns a get-mgcontext into pipe, if you don't cap it corrupts the pipe on your current flow
            $dOut = Disconnect-MgGraph -Verbose:($VerbosePreference -eq 'Continue')
            $MGCntxt = test-mgconnection -Verbose:($VerbosePreference -eq 'Continue') ;
        };
        if($Credential){
            $smsg = "`Credential:Explicit credentials specified, deferring to use..." ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            write-verbose "get-TenantCredentials() return format: (emulating)" ; 
            $o365Cred = [ordered]@{
                Cred=$Credential ;
                credType=$null ;
            } ;
            $uRoleReturn = resolve-UserNameToUserRole -UserName $Credential.username -verbose:$($VerbosePreference -eq "Continue") ; # Username
            write-verbose "w full cred opt: $uRoleReturn = resolve-UserNameToUserRole -Credential $Credential -verbose = $($VerbosePreference -eq 'Continue')"  ; 
            if($uRoleReturn.UserRole){
                $o365Cred.credType = $uRoleReturn.UserRole ;
            } else {
                $smsg = "Unable to resolve `$credential.username ($($credential.username))"
                $smsg += "`nto a usable 'UserRole' spec!" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
                else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                throw $smsg ;
                Break ;
            } ;
        } else {
            if($MGCntxt.isConnected){
                if($MgCntxt.isUser){
                    $TenantTag = $TenOrg = get-TenantTag -Credential $MgCntxt.Account ;
                    $uRoleReturn = resolve-UserNameToUserRole -UserName $MgCntxt.CertificateThumbprint -verbose:$($VerbosePreference -eq "Continue") ;
                    $credential = get-TenantCredentials -TenOrg $TenOrg -UserRole $uRoleReturn.UserRole -verbose:$($VerbosePreference -eq "Continue") ;
                } elseif($MgCntxt.isCBA -AND $MgCntxt.AppName -match 'CBACert-(\w{3})'){
                        #$MgCntxt.AppName.split('-')[-1]
                        $TenantTag = $TenOrg = $matches[1]
                        # also need credential
                        $uRoleReturn = resolve-UserNameToUserRole -UserName $MgCntxt.CertificateThumbprint -verbose:$($VerbosePreference -eq "Continue") ;
                        write-verbose "ret'd obj:$uRoleReturn = [ordered]@{     UserRole = $null ;     Service = $null ;     TenOrg = $null ; } " ;  
                        $credRet = get-TenantCredentials -TenOrg $TenOrg -UserRole $uRoleReturn.UserRole -verbose:$($VerbosePreference -eq "Continue")
                        $credential = $credRet.Cred ;
                }else{
                    $smsg = "UNABLE TO RESOLVE mgContext to a working TenOrg!" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent}
                    else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                }
            } ; 
            $pltGTCred=@{TenOrg=$TenOrg ; UserRole=$null; verbose=$($verbose)} ;
            if($UserRole){
                $smsg = "(`$UserRole specified:$($UserRole -join ','))" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                $pltGTCred.UserRole = $UserRole;
            } else {
                $smsg = "(No `$UserRole found, defaulting to:'CSVC','SID' " ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                $pltGTCred.UserRole = 'CSVC','SID' ;
            } ;
            $smsg = "get-TenantCredentials w`n$(($pltGTCred|out-string).trim())" ;
            if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level verbose }
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
            $o365Cred = get-TenantCredentials @pltGTCred
        } ;
        if($o365Cred.credType -AND $o365Cred.Cred -AND $o365Cred.Cred.gettype().fullname -eq 'System.Management.Automation.PSCredential'){
            $smsg = "(validated `$o365Cred contains .credType:$($o365Cred.credType) & `$o365Cred.Cred.username:$($o365Cred.Cred.username)" ;
            if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE }
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
            write-verbose "populate $credential with return, if not populated (may be required for follow-on calls that pass common $Credentials through)" ; 
            if((gv Credential) -AND $Credential -eq $null){
                $credential = $o365Cred.Cred ;
            }elseif($credential.gettype().fullname -eq 'System.Management.Automation.PSCredential'){
                $smsg = "(`$Credential is properly populated; explicit -Credential was in initial call)" ; 
                if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
            } else {
                $smsg = "`$Credential is `$NULL, AND $o365Cred.Cred is unusable to populate!" ;
                $smsg = "downstream commands will *not* properly pass through usable credentials!" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent}
                else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                throw $smsg ;
                break ;
            } ;
        } else {
            $smsg = "UNABLE TO RESOLVE FUNCTIONAL CredType/UserRole from specified explicit -Credential:$($Credential.username)!" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent}
            else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            break ;
        } ;         
        $pltCMG = [ordered]@{
            Credential = $Credential ;
            verbose = $($VerbosePreference -eq "Continue")  ;
        } ;
        if((get-command Connect-MG).Parameters.keys -contains 'silent'){
            $pltCMG.add('Silent',$silent) ;
        } ;
        #endregion cMG_SCAFFOLD ; #*------^ END cMG_SCAFFOLD ^------
        #Connect-MgGraph -Scopes "Organization.Read.All" -NoWelcome # suppress the banner, or it dumps it into the pipeline!
        $pltCMG.add('Scopes', "Organization.Read.All" ) ;
        #9:42 AM 1/12/2026 cmggraph has -scopes param, but connect-mg uses RequiredScopes - should Alias it

        #$LastDirSyncTime = (Get-MsolCompanyInformation).LastDirSyncTime ;
        #$LastDirSyncTime = (Get-AzureADTenantDetail).CompanyLastDirSyncTime ;
        connect-MG @pltCMG ; 
        $LastDirSyncTime = Get-MgOrganization | select -expand OnPremisesLastSyncDateTime
    }
    PROCESS{                
        write-host -foregroundcolor yellow "$((get-date).ToString('HH:mm:ss')):Waiting for next AD-> EntraID Dirsync:`n(prior:$($LastDirSyncTime.ToLocalTime()))`n[" ; 
        Do {Connect-MgGraph -Scopes "Organization.Read.All" -NoWelcome  ; write-host "." -NoNewLine ; Start-Sleep -m (1000 * 5) } Until ((Get-MgOrganization).OnPremisesLastSyncDateTime -ne $LastDirSyncTime) ;
    } ; 
    END{
        $LatestNewSync = (Get-MgOrganization).OnPremisesLastSyncDateTime ; 
        New-Object PSObject -Property @{
          TimeGMT   = $LatestNewSync   ;
          TimeLocal = $LatestNewSync.ToLocalTime() ;
        } | write-output ;
        write-host -foregroundcolor yellow "]`n$((get-date).ToString('HH:mm:ss')):AD->EntraID REPLICATED!" ; 
        write-host "`a" ; write-host "`a" ; write-host "`a" ;
    } ; 
} ; #*------^ END Function Wait-MGOPSync ^------
if(!(get-alias Wait-MSolSync -ea 0 )) {Set-Alias -Name 'wait-MSolSync' -Value 'Wait-MGOPSync' ; } ;

