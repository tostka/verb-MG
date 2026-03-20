#*------v get-MGOPLastSync.ps1 v------
Function get-MGOPLastSync {
  <#
    .SYNOPSIS
    get-MGOPLastSync - Get specific Tenant/Org's last AD-MG sync (MGGraph)
    .NOTES
    Author      : Todd Kadrie
    Website     :	https://www.toddomation.com
    Twitter     :	@tostka
    REVISIONS   :
    * 2:48 PM 3/19/2026 default $silent=$true ; 
    * 2:05 PM 1/16/2026 port from verb-AAD\wait-AADSync to Microsoft.Graph (fu M$) -> verb-MG\Wait-MGOPSync()
    .DESCRIPTION
    get-MGOPLastSync - Get specific Tenant/Org's last AD-MG sync (MGGraph)
    .PARAMETER TenOrg
    TenantTag value, indicating Tenants to connect to[-TenOrg 'TOL']
    .PARAMETER useEXOv2
    Use EXOv2 (ExchangeOnlineManagement) over basic auth legacy connection [-useEXOv2]
    .PARAMETER Credential
    Use specific Credentials (defaults to Tenant-defined SvcAccount)[-Credentials [credential object]]
    .PARAMETER UserRole
    Credential User Role spec (SID|CSID|UID|B2BI|CSVC)[-UserRole SID]    
    .PARAMETER silent
    Switch to specify suppression of all but warn/error echos.(unimplemented, here for cross-compat)
    .INPUTS
    None. Does not accepted piped input.
    .OUTPUTS
    Returns an object with LastDirSyncTime, expressed as TimeGMT & TimeLocal
    .EXAMPLE
    get-MGOPLastSync
    .LINK
    https://github.com/tostka/verb-mg
    #>
    #Requires -Modules AzureAD
    [CmdletBinding()]
    # [Alias('get-MsolLastSync')]    
    Param(
        [Parameter(Mandatory=$FALSE,HelpMessage="TenantTag value, indicating Tenants to connect to[-TenOrg 'TOL']")]
            [ValidateNotNullOrEmpty()]
            #[ValidatePattern("^\w{3}$")]
            [string]$TenOrg = $global:o365_TenOrgDefault,
        [Parameter(HelpMessage="Use EXOv2 (ExchangeOnlineManagement) over basic auth legacy connection [-useEXOv2]")]
            [switch] $useEXOv2=$true,
        [Parameter(Mandatory = $false, HelpMessage = "Use specific Credentials (defaults to Tenant-defined SvcAccount)[-Credentials [credential object]]")]
            [System.Management.Automation.PSCredential]$Credential,
        [Parameter(Mandatory = $false, HelpMessage = "Credential User Role spec (SID|CSID|UID|B2BI|CSVC|ESVC|LSVC|ESvcCBA|CSvcCBA|SIDCBA)[-UserRole @('SIDCBA','SID','CSVC')]")]
            # sourced from get-admincred():#182: $targetRoles = 'SID', 'CSID', 'ESVC','CSVC','UID','ESvcCBA','CSvcCBA','SIDCBA' ; 
            #[ValidateSet("SID","CSID","UID","B2BI","CSVC","ESVC","LSVC","ESvcCBA","CSvcCBA","SIDCBA")]
            # pulling the pattern from global vari w friendly err
            [ValidateScript({
                if(-not $rgxPermittedUserRoles){$rgxPermittedUserRoles = '(SID|CSID|UID|B2BI|CSVC|ESVC|LSVC|ESvcCBA|CSvcCBA|SIDCBA)'} ;
                if(-not ($_ -match $rgxPermittedUserRoles)){throw "'$($_)' doesn't match `$rgxPermittedUserRoles:`n$($rgxPermittedUserRoles.tostring())" ; } ; 
                return $true ; 
            })]
            [string[]]$UserRole = @('ESvcCBA','CSvcCBA','SIDCBA','SID'),
        [Parameter(HelpMessage="Silent output (suppress status echos)[-silent]")]
            [switch] $silent = $true
    ) ; 
    BEGIN{
        #region CONSTANTS_AND_ENVIRO #*======v CONSTANTS-AND-ENVIRO v======
        # function self-name (equiv to script's: $MyInvocation.MyCommand.Path) ;
        ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
        $Verbose = ($VerbosePreference -eq 'Continue') ;
        # Get parameters this function was invoked with
        $PSParameters = New-Object -TypeName PSObject -Property $PSBoundParameters ;
        $smsg = "(ParameterSetName $($PSCmdlet.ParameterSetName) is in effect)" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

        #region LOCAL_CONSTANTS ; #*------v LOCAL_CONSTANTS v------

        #endregion LOCAL_CONSTANTS ; #*------^ END LOCAL_CONSTANTS ^------
         <#
        # recycling the inbound above into next call in the chain
        # downstream commands
        $pltRXO = [ordered]@{
            Credential = $Credential ;
            verbose = $($VerbosePreference -eq "Continue")  ;
        } ;
        #>
        # 9:26 AM 6/17/2024 this needs cred resolution splice over latest get-exomailboxlicenses
        $o365Cred = $null ;
        if($Credential){
            $smsg = "`Credential:Explicit credentials specified, deferring to use..." ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
                # get-TenantCredentials() return format: (emulating)
                $o365Cred = [ordered]@{
                Cred=$Credential ;
                credType=$null ;
            } ;
            $uRoleReturn = resolve-UserNameToUserRole -UserName $Credential.username -verbose:$($VerbosePreference -eq "Continue") ; # Username
            #$uRoleReturn = resolve-UserNameToUserRole -Credential $Credential -verbose = $($VerbosePreference -eq "Continue") ;   # full Credential support
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
                #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
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
            # 9:58 AM 6/13/2024 populate $credential with return, if not populated (may be required for follow-on calls that pass common $Credentials through)
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

        # downstream commands
        $pltRXO = [ordered]@{
            Credential = $Credential ;
            verbose = $($VerbosePreference -eq "Continue")  ;
        } ;
        if((get-command Reconnect-EXO).Parameters.keys -contains 'silent'){
            $pltRxo.add('Silent',$silent) ;
        } ;
        # default connectivity cmds - force silent false
        $pltRXOC = [ordered]@{} ; $pltRXO.GetEnumerator() | ?{ $_.Key -notmatch 'silent' }  | ForEach-Object { $pltRXOC.Add($_.Key, $_.Value) } ; $pltRXOC.Add('silent',$true) ; 
        if((get-command Reconnect-EXO).Parameters.keys -notcontains 'silent'){
            $pltRxo.remove('Silent') ;
        } ; 

        # 2:37 PM 1/7/2026 mg support
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
            
        $pltCMG = [ordered]@{
            Credential = $Credential ;
            verbose = $($VerbosePreference -eq "Continue")  ;
        } ;
        if((get-command Connect-MG).Parameters.keys -contains 'silent'){
            $pltCMG.add('Silent',$silent) ;
        } ;
        if((get-command Connect-MG).Parameters.keys -contains 'NoWelcome'){
            $pltCMG.add('NoWelcome',$true) ;
        } ;
        #endregion cMG_SCAFFOLD ; #*------^ END cMG_SCAFFOLD ^------
        #Connect-MgGraph -Scopes "Organization.Read.All" -NoWelcome # suppress the banner, or it dumps it into the pipeline!
        $pltCMG.add('Scopes', "Organization.Read.All" ) ;
        #9:42 AM 1/12/2026 cmggraph has -scopes param, but connect-mg uses RequiredScopes - should Alias it

        #$LastDirSyncTime = (Get-MsolCompanyInformation).LastDirSyncTime ;
        #$LastDirSyncTime = (Get-AzureADTenantDetail).CompanyLastDirSyncTime ;
        connect-MG @pltCMG ; 
        $pltCMG.silent = $true ; 
        $LastDirSyncTime = Get-MgOrganization | select -expand OnPremisesLastSyncDateTime
    }
    PROCESS{        
    } ; 
    END{
        New-Object PSObject -Property @{
          TimeGMT   = $LastDirSyncTime  ;
          TimeLocal = $LastDirSyncTime.ToLocalTime() ;
        } | write-output ;        
    } ; 

}

#*------^ get-MGOPLastSync.ps1 ^------
