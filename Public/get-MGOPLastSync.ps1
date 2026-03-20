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
    * 1:39 PM 3/20/2026 rem'd mid reconnect loop; updated the logic on mg_connect to lateest vers; ADD: -WaitSeconds, bumped from 5 to 30; default $silent=$true ; 
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
        #region MG_CONNECT ; #*------v MG_CONNECT v------
        #$isMgConn = [boolean]( (gcm get-mgcontext -ea 0) -AND (get-mgcontext -ea 0 )); if(-not $isMgConn ){connect-mg }else{write-verbose "MG connected"};
        #$RequiredScopes = "Directory.AccessAsUser.All",'Directory.ReadWrite.All','User.ReadWrite.All','AuditLog.Read.All','openid','profile','User.Read','User.Read.All','email' ;
        if(-not (get-command  test-mgconnection)){
            if(-not (get-module -list Microsoft.Graph -ea 0)){
                $smsg = "MISSING Microsoft.Graph!" ;
                $smsg += "`nUse: install-module Microsoft.Graph -scope CurrentUser" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent}
                else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            } ;
        } ;
        $MGConn = test-mgconnection -Verbose:($VerbosePreference -eq 'Continue') ;
        if($RequiredScopes){$addScopes = @() ;$RequiredScopes |foreach-object{ $thisPerm = $_ ;if($mgconn.scopes -contains $thisPerm){write-verbose "has scope: $($thisPerm)"} else{$addScopes += @($thisPerm) ; write-verbose "ADD scope: $($thisPerm)"} } ;} ;
        $pltCcMG = [ordered]@{NoWelcome=$true; ErrorAction = 'STOP'}
        if($addScopes){ $pltCcMG.add('RequiredScopes',$addscopes); $pltCcMG.add('ContextScope','Process'); $pltCCMG.add('silent',$false) ; write-verbose "Adding non-default Scopes, setting non-persistant single-process ContextScope"  } ; 
        if($MGConn.isConnected -AND $addScopes -AND $mgconn.CertificateThumbprint){
            $smsg = "CBA cert lacking scopes :$($addscopes -join ',')!"  ;  $smsg += "`nDisconnecting to use interactive connection: connect-mg -RequiredScopoes `"'$($addscopes -join "','")'`"" ; $smsg += "`n(alt: : connect-mggraph -Scopes `"'$($addscopes -join "','")'`" )" ; write-warning $smsg ; 
            disconnect-mggraph ; 
        }elseif($MGConn.isConnected -AND $addScopes -and -not ($mgconn.CertificateThumbprint)){
        }elseif(-NOT ($MGConn.isConnected) -AND $addScopes -and -not ($mgconn.CertificateThumbprint)){$pltCCMG.add('Credential',$credO365TORSID)            
        }else {write-verbose "(currently connected with any specifically specified required Scopes)"
            $pltCcMG = $null ; 
        }
        if($pltCcMG){
            $smsg = "connect-mg w`n$(($pltCCMG.getenumerator() | ?{$_.name -notmatch 'requiredscopes'} | ft -a | out-string|out-string).trim())" ;
            $smsg += "`n`n-requiredscopes:`n$(($pltCCMG.requiredscopes|out-string).trim())`n" ;
            if($silent){} else {
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            } ; 
            connect-mg @pltCCMG ;
        } ; 
        if(-not (get-command Get-MgUser)){
            $smsg = "Missing Get-MgUser!" ;
            $smsg += "`nPre-connect to Microsoft.Graph via:" ;
            $smsg += "`nConnect-MgGraph -Scopes `'$($requiredscopes -join "','")`'" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent}
            else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            BREAK ;
        } ;
        #endregion MG_CONNECT ; #*------^ END MG_CONNECT ^------

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
