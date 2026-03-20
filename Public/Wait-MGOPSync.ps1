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
    * 1:39 PM 3/20/2026 rem'd mid reconnect loop; updated the logic on mg_connect to lateest vers; ADD: -WaitSeconds, bumped from 5 to 30
    * 2:48 PM 3/19/2026 default $silent=$true ; 
    * 2:02 PM 1/16/2026 wasn't picking up default CBA creds -> pasted in latest begin block & scaffold from remove-exolicense()
    * 3:28 PM 1/6/2026 fixed ipmo mg ;  spliced in cmg scaff
    * 3:34 PM 1/5/2026 rpl AAD => EntraID strings
    * 11:03 AM 12/31/2025 port from verb-AAD\wait-AADSync to Microsoft.Graph (fu M$) -> verb-MG\Wait-MGOPSync()
    .DESCRIPTION
    Wait-MGOPSync - Dawdle loop for notifying on next AD-EntraID AD sync (Microsoft.Graph)
    .PARAMETER WaitSeconds
    Seconds to wait between checks (defaults to 30)[-WaitSeconds 60']
    .PARAMETER silent
    Switch to specify suppression of all but warn/error echos.(unimplemented, here for cross-compat)
    .INPUTS
    None. Does not accepted piped input.
    .OUTPUTS
    Returns an object with LastDirSyncTime, expressed as TimeGMT & TimeLocal
    .EXAMPLE
    PS> Wait-MGOPSync

        14:18:27:Waiting for next AD-> EntraID Dirsync:
        (prior:01/16/2026 14:09:25)
        [..]
        (01/16/2026 14:09:25):AD->EntraID REPLICATED

    .LINK
    https://github.com/tostka/verb-mg
    #>
    Param(
        [Parameter(Mandatory=$FALSE,HelpMessage="Seconds to wait between checks (defaults to 30)[-WaitSeconds 60']")]
            [Int]$WaitSeconds = 30,
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
        write-host -foregroundcolor yellow -nonewline "$((get-date).ToString('HH:mm:ss')):Waiting for next AD-> EntraID Dirsync:`n(prior:$($LastDirSyncTime.ToLocalTime()))`n[" ; 
        Do {
            # this is what's triggering the no cred connect, replace it
            #Connect-MgGraph -Scopes "Organization.Read.All" -NoWelcome  ; 
            #connect-MG @pltCMG ; # it autorefreshes once connected, doesn't need an explicit connect (also dumps status into the console)
            write-host "." -NoNewLine ; Start-Sleep -m (1000 * $WaitSeconds) 
        } Until ((Get-MgOrganization).OnPremisesLastSyncDateTime -ne $LastDirSyncTime) ;
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


