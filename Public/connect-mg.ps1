# connect-MG.ps1

#region CONNECT_MG ; #*------v connect-MG v------
Function connect-MG {
    <#
    .SYNOPSIS
    connect-MG - Establish authenticated session to Microsoft.Graph, also works as reconnect-MG (No need for separate self tests for connection, and reconnects if it's missing).
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     :	http://www.toddomation.com
    Twitter     :	@tostka / http://twitter.com/tostka
    CreatedDate : 2020-05-27
    FileName    : connect-MG.ps1
    License     : MIT License
    Copyright   : (c) 2020 Todd Kadrie
    Github      : https://github.com/tostka/verb-mg
    Tags        : Powershell,MicrosoftGraph,MGGraph,GraphAPI,AzureAD,Ported,Microsoft,verbMG
    AddedCredit : REFERENCE
    AddedWebsite:	URL
    AddedTwitter:	URL
    REVISIONS   :
    * 2:52 PM 3/13/2026 defaulted -silent true
    * 2:14 PM 1/16/2026 add -noWelcome support (as variant of -silent block)
    * 1:01 PM 1/12/2026 revised connect rpt to put key bits, and then details add: dyn get-mgcontext props expansion, for outputs (acct v cba, only relevent in output)
    * 3:24 PM 1/6/2026 fixed cbh, don't ipmo MG! ; WORKING, added CBH demo call scaffold for use in all calling dep scripts
    * 4:18 PM 12/31/2025 WIP, drating down in the end range ; port from connect-AAD()
    .DESCRIPTION
    connect-MG - Establish authenticated session to Microsoft.Graph, also works as reconnect-MG (No need for separate self tests for connection, and reconnects if it's missing).        
    .PARAMETER Credential
    Credential to use for this connection [-credential [credential obj variable]
    .PARAMETER UserRole
    Credential User Role spec for credential discovery (SID|CSID|UID|B2BI|CSVC|ESVC|LSVC|ESvcCBA|CSvcCBA|SIDCBA)[-UserRole @('SIDCBA','SID','CSVC')]
    .PARAMETER RequiredScopes
    Scopes required for planned cmdlets to be executed[-RequiredScopes @('User.Read.All', 'Group.Read.All', 'Domain.Read.All')]
    .PARAMETER DefaultScopes
    Fall-back Scopes for non-AppID, _Credential_ connections (defaults to working SID user/exo /domain/license mgmt roles)[-DefaultScopes @('User.Read.All', 'Group.Read.All', 'Domain.Read.All')]
    .PARAMETER RequiredScopes
    Scopes required for planned cmdlets to be executed[-RequiredScopes @('User.Read.All', 'Group.Read.All', 'Domain.Read.All')]
    .PARAMETER Path
    Path to script/module file to be parsed for matching cmdlets[-Path path-to\script.ps1]
    .PARAMETER scriptblock
    Scriptblock of code to be parsed for matching cmdlets[-scriptblock `$sbcode]
    .PARAMETER Cmdlets
    MGGraph cmdlet names to be Find-MgGraphCommand'd into delegated access -scope permissions (bypasses ASTParser discovery)[-Cmdlets @('get-MgDomain','get-MGContext')]
    .PARAMETER silent
    Silent output (suppress status echos)[-silent]
    .PARAMETER TenOrg
        Optional Tenant Tag (wo -Credential)[-TenOrg 'XYZ']
    .PARAMETER silent
    Switch to suppress all non-error echos
    .PARAMETER NoWelcome
        Hides the welcome message.
    .INPUTS
    None. Does not accepted piped input.
    .OUTPUTS
    None. Returns no objects or output.
    .EXAMPLE
    connect-MG
    Demo connect using defaulted config (default profile driven TenOrg & UserRole spec)
    .EXAMPLE
    connect-MG -Credential $cred
    Demo use of explicit credential object
    .EXAMPLE
    connect-MG -UserRole SIDCBA -TenOrg ABC -verbose  ; 
    Demo use of UserRole (specifying a CBA variant), AND TenOrg spec, to connect (autoresolves against preconfigured credentials in profile)
    .EXAMPLE
    PS> write-verbose "BEGIN{ ..." ; 
    PS>     #region cMG_SCAFFOLD ; #*------v cMG_SCAFFOLD v------
    PS> if(-not (get-command  test-mgconnection)){
    PS>     if(-not (get-module -list Microsoft.Graph -ea 0)){
    PS>         $smsg = "MISSING Microsoft.Graph!" ; 
    PS>         $smsg += "`nUse: install-module Microsoft.Graph -scope CurrentUser" ;
    PS>         if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent} 
    PS>         else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
    PS>     } ;             
    PS> } ;
    PS>     $MGCntxt = test-mgconnection -Verbose:($VerbosePreference -eq 'Continue') ;
    PS>     $o365Cred = $null ;
    PS>     if($Credential -AND $MGCntxt.isConnected){
    PS>         $smsg = "Explicit -Credential:$($Credential.username) -AND `$MGCntxt.isConnected: running pre:Disconnect-MgGraph" ; 
    PS>         if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
    PS>         else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    PS>         # Dmg returns a get-mgcontext into pipe, if you don't cap it corrupts the pipe on your current flow
    PS>         $dOut = Disconnect-MgGraph -Verbose:($VerbosePreference -eq 'Continue')
    PS>         $MGCntxt = test-mgconnection -Verbose:($VerbosePreference -eq 'Continue') ;
    PS>     };
    PS>     if($Credential){
    PS>         $smsg = "`Credential:Explicit credentials specified, deferring to use..." ;
    PS>         if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
    PS>         else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    PS>         write-verbose "get-TenantCredentials() return format: (emulating)" ; 
    PS>         $o365Cred = [ordered]@{
    PS>             Cred=$Credential ;
    PS>             credType=$null ;
    PS>         } ;
    PS>         $uRoleReturn = resolve-UserNameToUserRole -UserName $Credential.username -verbose:$($VerbosePreference -eq "Continue") ; # Username
    PS>         write-verbose "w full cred opt: $uRoleReturn = resolve-UserNameToUserRole -Credential $Credential -verbose = $($VerbosePreference -eq 'Continue')"  ; 
    PS>         if($uRoleReturn.UserRole){
    PS>             $o365Cred.credType = $uRoleReturn.UserRole ;
    PS>         } else {
    PS>             $smsg = "Unable to resolve `$credential.username ($($credential.username))"
    PS>             $smsg += "`nto a usable 'UserRole' spec!" ;
    PS>             if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
    PS>             else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    PS>             throw $smsg ;
    PS>             Break ;
    PS>         } ;
    PS>     } else {
    PS>         if($MGCntxt.isConnected){
    PS>             if($MgCntxt.isUser){
    PS>                 $TenantTag = $TenOrg = get-TenantTag -Credential $MgCntxt.Account ;
    PS>                 $uRoleReturn = resolve-UserNameToUserRole -UserName $MgCntxt.CertificateThumbprint -verbose:$($VerbosePreference -eq "Continue") ;
    PS>                 $credential = get-TenantCredentials -TenOrg $TenOrg -UserRole $uRoleReturn.UserRole -verbose:$($VerbosePreference -eq "Continue") ;
    PS>             } elseif($MgCntxt.isCBA -AND $MgCntxt.AppName -match 'CBACert-(\w{3})'){
    PS>                     #$MgCntxt.AppName.split('-')[-1]
    PS>                     $TenantTag = $TenOrg = $matches[1]
    PS>                     # also need credential
    PS>                     $uRoleReturn = resolve-UserNameToUserRole -UserName $MgCntxt.CertificateThumbprint -verbose:$($VerbosePreference -eq "Continue") ;
    PS>                     write-verbose "ret'd obj:$uRoleReturn = [ordered]@{     UserRole = $null ;     Service = $null ;     TenOrg = $null ; } " ;  
    PS>                     $credRet = get-TenantCredentials -TenOrg $TenOrg -UserRole $uRoleReturn.UserRole -verbose:$($VerbosePreference -eq "Continue")
    PS>                     $credential = $credRet.Cred ;
    PS>             }else{
    PS>                 $smsg = "UNABLE TO RESOLVE mgContext to a working TenOrg!" ;
    PS>                 if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent}
    PS>                 else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    PS>             }
    PS>         } ; 
    PS>         $pltGTCred=@{TenOrg=$TenOrg ; UserRole=$null; verbose=$($verbose)} ;
    PS>         if($UserRole){
    PS>             $smsg = "(`$UserRole specified:$($UserRole -join ','))" ;
    PS>             if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
    PS>             else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    PS>             $pltGTCred.UserRole = $UserRole;
    PS>         } else {
    PS>             $smsg = "(No `$UserRole found, defaulting to:'CSVC','SID' " ;
    PS>             if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
    PS>             else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    PS>             $pltGTCred.UserRole = 'CSVC','SID' ;
    PS>         } ;
    PS>         $smsg = "get-TenantCredentials w`n$(($pltGTCred|out-string).trim())" ;
    PS>         if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level verbose }
    PS>         else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
    PS>         $o365Cred = get-TenantCredentials @pltGTCred
    PS>     } ;
    PS>     if($o365Cred.credType -AND $o365Cred.Cred -AND $o365Cred.Cred.gettype().fullname -eq 'System.Management.Automation.PSCredential'){
    PS>         $smsg = "(validated `$o365Cred contains .credType:$($o365Cred.credType) & `$o365Cred.Cred.username:$($o365Cred.Cred.username)" ;
    PS>         if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE }
    PS>         else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
    PS>         write-verbose "populate $credential with return, if not populated (may be required for follow-on calls that pass common $Credentials through)" ; 
    PS>         if((gv Credential) -AND $Credential -eq $null){
    PS>             $credential = $o365Cred.Cred ;
    PS>         }elseif($credential.gettype().fullname -eq 'System.Management.Automation.PSCredential'){
    PS>             $smsg = "(`$Credential is properly populated; explicit -Credential was in initial call)" ; 
    PS>             if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
    PS>             else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
    PS>         } else {
    PS>             $smsg = "`$Credential is `$NULL, AND $o365Cred.Cred is unusable to populate!" ;
    PS>             $smsg = "downstream commands will *not* properly pass through usable credentials!" ;
    PS>             if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent}
    PS>             else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    PS>             throw $smsg ;
    PS>             break ;
    PS>         } ;
    PS>     } else {
    PS>         $smsg = "UNABLE TO RESOLVE FUNCTIONAL CredType/UserRole from specified explicit -Credential:$($Credential.username)!" ;
    PS>         if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent}
    PS>         else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    PS>         break ;
    PS>     } ;         
    PS>     $pltCMG = [ordered]@{
    PS>         Credential = $Credential ;
    PS>         verbose = $($VerbosePreference -eq "Continue")  ;
    PS>     } ;
    PS>     if((get-command Connect-MG).Parameters.keys -contains 'silent'){
    PS>         $pltCMG.add('Silent',$silent) ;
    PS>     } ;
    PS>     #endregion  ; #*------^ END cMG_SCAFFOLD ^------
    PS> } #  # BEG-E        
    PS> write-verbose "PROCESS{..." ; 
    PS>     connect-MG @pltCMG 
    Demo full scaffolded call, collects dep $TenOrg, $UserRole and $Cred to drive connect-mg() calls.
    .LINK
    https://github.com/tostka/verb-mg
    #>
    # DONT DO THIS, IT HANGS TRYING TO LOAD THE ENTIRE MASSIVE LIBRARY! ALSO NEVER IPMO Microsoft.Graph, ITS MASSIVE! LET PSV3+ CALLS RESOLVE PROPER SUBMOD & DYN LOAD
    ## #Requires -Modules Microsoft.Graph
    [CmdletBinding()]
    [Alias('cMG','rMG','reconnect-MG')]
    PARAM(        
        [Parameter(HelpMessage="Credential to use for this connection [-credential [credential obj variable]")]
            [System.Management.Automation.PSCredential]$Credential,
            # = $global:credo365TORSID, # defer to TenOrg & UserRole resolution
        [Parameter(Mandatory=$False,HelpMessage="Scopes required for planned cmdlets to be executed[-RequiredScopes @('User.Read.All', 'Group.Read.All', 'Domain.Read.All')]")]
            [Alias('scopes')] # alias the connect-mggraph underlying param, for passthru
            [array]$RequiredScopes,
        [Parameter(Mandatory = $false, HelpMessage = "Credential User Role spec (SID|CSID|UID|B2BI|CSVC|ESVC|LSVC|ESvcCBA|CSvcCBA|SIDCBA)[-UserRole @('SIDCBA','SID','CSVC')]")]
            # sourced from get-admincred():#182: $targetRoles = 'SID', 'CSID', 'ESVC','CSVC','UID','ESvcCBA','CSvcCBA','SIDCBA' ; 
            #[ValidateSet("SID","CSID","UID","B2BI","CSVC","ESVC","LSVC","ESvcCBA","CSvcCBA","SIDCBA")]
            # pulling the pattern from global vari w friendly err
            [ValidateScript({
                if(-not $rgxPermittedUserRoles){$rgxPermittedUserRoles = '(SID|CSID|UID|B2BI|CSVC|ESVC|LSVC|ESvcCBA|CSvcCBA|SIDCBA)'} ;
                if(-not ($_ -match $rgxPermittedUserRoles)){throw "'$($_)' doesn't match `$rgxPermittedUserRoles:`n$($rgxPermittedUserRoles.tostring())" ; } ; 
                return $true ; 
            })]
            [string[]]$UserRole = @('SIDCBA','SID','CSVC'),
        [Parameter(Mandatory=$FALSE,HelpMessage="TenantTag value, indicating Tenants to connect to[-TenOrg 'TOL']")]
            [ValidateNotNullOrEmpty()]
            #[ValidatePattern("^\w{3}$")]
            [string]$TenOrg = $global:o365_TenOrgDefault,
        # as -scopes are mandated, splice over proxyable get-MGCodeCmdletPermissionsTDO inputs (which will be passed through in a call)
        # note -scopes don't work with AppID conns, which have static scope perms built into the appreg
        [Parameter(HelpMessage = "Path to script/module file to be parsed for matching cmdlets[-Path path-to\script.ps1]")]
            #[ValidateScript( {Test-Path $_})][ValidatePattern( "\.(ps1|psm1|txt)$")]
            [Alias('PSPath','File')]
            #[system.io.fileinfo]
            $Path,
        [Parameter(HelpMessage = "Scriptblock of code to be parsed for matching cmdlets[-scriptblock `$sbcode]")]
            [Alias('code')]
            $scriptblock,    
        [Parameter(HelpMessage = "MGGraph cmdlet names to be Find-MgGraphCommand'd into delegated access -scope permissions (bypasses ASTParser discovery)[-Cmdlets @('get-MgDomain','get-MGContext')]")]
            [string[]]$Cmdlets,
        [Parameter(Mandatory=$False,HelpMessage="Fall-back Scopes for non-AppID, _Credential_ connections (defaults to working SID user/exo /domain/license mgmt roles)[-DefaultScopes @('User.Read.All', 'Group.Read.All', 'Domain.Read.All')]")]
            [array]$DefaultScopes = @('Application.Read.All','Application.ReadWrite.All','AuditLog.Read.All','Chat.ReadWrite','DeviceManagementApps.Read.All','DeviceManagementApps.ReadWrite.All','DeviceManagementConfiguration.Read.All','DeviceManagementConfiguration.ReadWrite.All','DeviceManagementManagedDevices.Read.All','DeviceManagementManagedDevices.ReadWrite.All','DeviceManagementServiceConfig.Read.All','DeviceManagementServiceConfig.ReadWrite.All','Directory.Read.All','Directory.ReadWrite.All','Domain.Read.All','email','Group.Read.All','Group.ReadWrite.All','GroupMember.Read.All','GroupMember.ReadWrite.All','LicenseAssignment.Read.All','Mail.Send','openid','Organization.Read.All','Organization.ReadWrite.All','profile','RoleManagement.Read.Directory','User.Read','User.Read.All','User.ReadBasic.All','User.ReadWrite.All'),
        [Parameter(HelpMessage="Hides the welcome message.[-NoWelcome]")]
            [switch] $NoWelcome,
        [Parameter(HelpMessage="Silent output (suppress status echos)[-silent]")]
            [switch] $silent = $true 
    ) ;
    BEGIN {        
        #region PUSH_TLSLATEST ; #*------v push-TLSLatest v------
        if(-not(gi function:push-TLSLatest -ea 0)){
            function push-TLSLatest{
                <#
                .SYNOPSIS
                push-TLSLatest - Elevates TLS on Powershell connections to highest available local version
                .NOTES
            
                REVISIONS
                * 4:41 PM 5/29/2025 init (replace scriptblock in psparamt)
            
                #>
                [CmdletBinding()]
                PARAM() ; 
                $CurrentVersionTlsLabel = [Net.ServicePointManager]::SecurityProtocol ; # Tls, Tls11, Tls12 ('Tls' == TLS1.0)  ;
                write-verbose "PRE: `$CurrentVersionTlsLabel : $($CurrentVersionTlsLabel )" ;
                # psv6+ already covers, test via the SslProtocol parameter presense
                if ('SslProtocol' -notin (Get-Command Invoke-RestMethod).Parameters.Keys) {
                    $currentMaxTlsValue = [Math]::Max([Net.ServicePointManager]::SecurityProtocol.value__,[Net.SecurityProtocolType]::Tls.value__) ;
                    write-verbose "`$currentMaxTlsValue : $($currentMaxTlsValue )" ;
                    $newerTlsTypeEnums = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -gt $currentMaxTlsValue }
                    if($newerTlsTypeEnums){
                        write-verbose "Appending upgraded/missing TLS `$enums:`n$(($newerTlsTypeEnums -join ','|out-string).trim())" ;
                    } else {
                        write-verbose "Current TLS `$enums are up to date with max rev available on this machine" ;
                    };
                    $newerTlsTypeEnums | ForEach-Object {
                        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $_
                    } ;
                } ;
            } ; 
        } ; 
        #endregion PUSH_TLSLATEST ; #*------^ END push-TLSLatest ^------
        
        
        push-TLSLatest
        $Verbose = [boolean]($VerbosePreference -eq 'Continue') ;
        #region CONSTANTS_AND_ENVIRO ; #*======v CONSTANTS_AND_ENVIRO v======

        if(-not $Retries){$Retries = 4 };
        if(-not $RetrySleep){$RetrySleep = 5};


        #region LOCAL_CONSTANTS ; #*------v LOCAL_CONSTANTS v------
        #endregion LOCAL_CONSTANTS ; #*------^ END LOCAL_CONSTANTS ^------         

        #if(-not (get-variable rgxCertFNameSuffix -ea 0)){$rgxCertFNameSuffix = '-([A-Z]{3})$' ; } ; 
        if(-not $rgxCertThumbprint){$rgxCertThumbprint = '[0-9a-fA-F]{40}' } ; # if it's a 40char hex string -> cert thumbprint  
        if(-not $rgxSmtpAddr){$rgxSmtpAddr = "^([0-9a-zA-Z]+[-._+&'])*[0-9a-zA-Z]+@([-0-9a-zA-Z]+[.])+[a-zA-Z]{2,63}$" ; } ; # email addr/UPN
        if(-not $rgxDomainLogon){$rgxDomainLogon = '^[a-zA-Z][a-zA-Z0-9\-\.]{0,61}[a-zA-Z]\\\w[\w\.\- ]+$' } ; # DOMAIN\samaccountname 

        # 10:28 AM 1/12/2026 used by $psprppopd to dyn return only the populated of the below - run before each write-log call.
        $prpGMGCTargets = 'TenantId','ClientId','Scopes','AuthType','TokenCredentialType','CertificateThumbprint','Account','AppName','ContextScope' ; 
        #endregion CONSTANTS_AND_ENVIRO ; #*======^ CONSTANTS_AND_ENVIRO ^======
        #-=-=-=-=-=-=-=-=
        
    } ;
    PROCESS {

        $modname = 'Microsoft.Graph' ; 

        # it's failing on initial, force retries
        $Exit = 0 ;
        Do {

            if(-not (get-command  test-mgconnection)){
                TRY{
                    ipmo -fo -verb verb-mg -verbose 
                } CATCH {$ErrTrapd=$Error[0] ;
                    write-host -foregroundcolor gray "TargetCatch:} CATCH [$($ErrTrapd.Exception.GetType().FullName)] {"  ;
                    $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
                    write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" ;
                    BREAK ; 
                } ;
            
            } ;
            $MGCntxt = test-mgconnection -Verbose:($VerbosePreference -eq 'Continue') ;
            if($Credential -AND $MGCntxt.isConnected){
                $smsg = "Explicit -Credential:$($Credential.username) -AND `$MGCntxt.isConnected: running pre:Disconnect-MgGraph" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                # Dmg returns a get-mgcontext into pipe, if you don't cap it corrupts the pipe on your current flow
                $dOut = Disconnect-MgGraph -Verbose:($VerbosePreference -eq 'Continue')
                $MGCntxt = test-mgconnection -Verbose:($VerbosePreference -eq 'Continue') ;
            };
            if(-not $Credential){
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
                }ELSE{ ; 
                    if($UserRole){
                        $smsg = "Using specified -UserRole:$( $UserRole -join ',' )" ;
                        if($silent){}elseif($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
                        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
                    } else { $UserRole = @('SID','CSVC') } ;
                } ; 
                if($TenOrg){
                    $smsg = "Using explicit -TenOrg:$($TenOrg)" ;
                } else {
                    switch -regex ($env:USERDOMAIN){
                        ([regex]('(' + (( @($TORMeta.legacyDomain,$CMWMeta.legacyDomain)  |foreach-object{[regex]::escape($_)}) -join '|') + ')')).tostring() {$TenOrg = $env:USERDOMAIN.substring(0,3).toupper() } ;
                        $TOLMeta.legacyDomain {$TenOrg = 'TOL' }
                        default {throw "UNRECOGNIZED `$env:USERDOMAIN!:$($env:USERDOMAIN)" ; exit ; } ;
                    } ;
                    $smsg = "Imputed `$TenOrg from logged on USERDOMAIN:$($TenOrg)" ;
                } ;
                if($silent){}elseif($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
                $o365Cred = $null ;
                $pltGTCred=@{TenOrg=$TenOrg ; UserRole= $UserRole; verbose=$($verbose)} ;
                $smsg = "get-TenantCredentials w`n$(($pltGTCred|out-string).trim())" ;
                if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level verbose }
                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
                $o365Cred = get-TenantCredentials @pltGTCred ;
                if($o365Cred.credType -AND $o365Cred.Cred -AND $o365Cred.Cred.gettype().fullname -eq 'System.Management.Automation.PSCredential'){
                    $smsg = "(validated `$o365Cred contains .credType:$($o365Cred.credType) & `$o365Cred.Cred.username:$($o365Cred.Cred.username)" ;
                    if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE }
                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
                    $Credential = $o365Cred.Cred ;
                } else {
                    $smsg = "UNABLE TO RESOLVE FUNCTIONAL CredType/UserRole from specified explicit -Credential:$($Credential.username)!" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent}
                    else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    break ;
                } ;
            } else {
                # test-exotoken only applies if $UseConnEXO  $false
                $TenOrg = get-TenantTag -Credential $Credential ;
            } ;
            # build the cred etc once, for all below:
            $pltCMG=[ordered]@{
                #Credential = $Credential ;
                verbose = $($verbose) ;
                erroraction = 'STOP' ;
                ErrorVariable = 'Err_CMG' ;
            } ;
            <#if((gcm connect-MgGraph).Parameters.keys -contains 'silent'){
                $pltCMG.add('Silent',$false) ;
            } ;
            #>
            if($Silent){
                $smsg = "-Silent: Adding -NoWelcome to connect-mggraph splat" ; 
                if($VerbosePreference -eq "Continue"){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
                $pltCMG.add('NoWelcome',$true) ; 
            }elseif($NoWelcome){
                $smsg = "-NoWelcome: Adding -NoWelcome to connect-mggraph splat" ; 
                if($VerbosePreference -eq "Continue"){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
                $pltCMG.add('NoWelcome',$true) ; 
            } ; 
            # defer to resolve-UserNameToUserRole -Credential $Credential
            $uRoleReturn = resolve-UserNameToUserRole -Credential $Credential ;
            if($credential.username -match $rgxCertThumbprint){
                $certTag = $uRoleReturn.TenOrg ;
            } ; 
            #-=-=-=-=-=-=-=-=

            $smsg = "EXEC:get-TenantMFARequirement -Credential $($Credential.username)" ; 
            if($silent){} else { 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            } ; 
            $MFA = get-TenantMFARequirement -Credential $Credential ;
            $smsg = "EXEC:get-TenantTag -Credential $($Credential.username)" ; 
            if($silent){} else { 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            } ;         
            $TenantTag = $TenOrg = get-TenantTag -Credential $Credential ; 
            $sTitleBarTag = @("MG") ;
            $sTitleBarTag += $TenantTag ;
            $TenantID = get-TenantID -Credential $Credential ;

        
            TRY { 

                if(-not $uRoleReturn){
                    $smsg = "resolve-UserNameToUserRole -UserName $($Credential.username)..." ; 
                    if($silent){}elseif($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
                    $uRoleReturn = resolve-UserNameToUserRole -UserName $Credential.username -verbose:$($VerbosePreference -eq "Continue") ; 
                    #$uRoleReturn = resolve-UserNameToUserRole -Credential $Credential -verbose = $($VerbosePreference -eq "Continue") ; 
                } ; 
                #$smsg = "get-AADToken..." ; 
                # closest is get-mgcontext
                $smsg = "test-mgconnection..." ; 
                if($silent){}elseif($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
                #$token = get-AADToken -verbose:$($verbose) ;
                $MGCntxt = test-mgconnection -Verbose:($VerbosePreference -eq 'Continue');            
                $smsg = "convert-TenantIdToTag -TenantId $($MGCntxt.TenantId) `$MGCntxt.tenantid)" ; 
                if($silent){}elseif($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
                # convert token.tenantid to the 3-letter TenOrg
                $mgCtxtTag = convert-TenantIdToTag -TenantId $MGCntxt.TenantId -verbose:$($verbose) ; 
                #$Tenantdomain = convert-TenantIdToDomainName -TenantId $MGCntxt.TenantId ;
                #if( ($null -eq $MGCntxt) -OR ($MGCntxt.count -eq 0)){
                if($MGCntxt.isconnected -eq $false){
                    # not connected/authenticated
                    #Connect-MgGraph -TenantId $TenantID -Credential $Credential ; 
                    throw "" # gen an error to dump into generic CATCH block
                }elseif($MGCntxt.count -gt 1){
                    #$smsg = "MULTIPLE CONTEXTS RETURNED!`n$(( ($MGCntxt) | ft -a  TenantId,UserId,LoginType |out-string).trim())" ; 
                    $tobj = $MGCntxt ; $tprops = $prpGMGCTargets ; $prpPopd = @() ; 
                    $tprops | %{   $thisprop = $_ ;    if($tobj| select -expand $thisprop){$prpPopd+=$thisprop }else{write-verbose "$($thisprop):N"} } ; 
                    $smsg = "MULTIPLE CONTEXTS RETURNED!`n$(($MGCntxt | fl $prpPopd|out-string).trim())" ;  
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent} 
                    else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    # 12:57 PM 1/12/2026 loop the multis
                    foreach($MGCntxtX in $MGCntxt){
                        $smsg = "`n$($urolereturn.TenOrg):$($urolereturn.UserRole)" ;
                        $tobj = $MGCntxtX ; $tprops = $prpGMGCTargets ; $prpPopd = @() ;
                        $tprops | %{   $thisprop = $_ ;    if($tobj| select -expand $thisprop){$prpPopd+=$thisprop }else{write-verbose "$($thisprop):N"} } ;
                        $smsg += "Connected to:`n$(($MGCntxtX | fl $prpPopd|out-string).trim())"  ;
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        $smsg = "`nScopes:$($MGCntxtX.scopes -join ', ')" ; 
                        if($VerbosePreference -eq "Continue"){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
                        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
                    }
                    # want to see if this winds up with a stack of parallel tokens
                } else {
                    #$smsg = "Connected to Tenant:`n$((($MGCntxt) | fl TenantId,UserId,AuthType|out-string).trim())" ;  
                    $smsg = "`n$($urolereturn.TenOrg):$($urolereturn.UserRole)" ;
                    $tobj = $MGCntxt ; $tprops = $prpGMGCTargets ; $prpPopd = @() ;
                    $tprops | %{   $thisprop = $_ ;    if($tobj| select -expand $thisprop){$prpPopd+=$thisprop }else{write-verbose "$($thisprop):N"} } ;
                    $smsg += "Connected to:`n$(($MGCntxt | fl $prpPopd|out-string).trim())"  ;
                    if($silent){} else { 
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    } ;
                    $smsg = "`nScopes:$($MGCntxt.scopes -join ', ')" ; 
                    if($VerbosePreference -eq "Continue"){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
                    # flip to resolve-UserNameToUserRole & direct eval the $MGCntxt values:
                    if( $mgCtxtTag  -eq $uRoleReturn.TenOrg){
                        if($credential.username -match $rgxCertThumbprint){
                            $smsg = "(Authenticated to MG:$($uRoleReturn.TenOrg) as $($uRoleReturn.FriendlyName))" ; 
                        } else { 
                            $smsg = "(Authenticated to MG:$($uRoleReturn.TenOrg) as $(($MGCntxt).userid))" ; 
                        } ; 
                        if($silent){} else { 
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        } ;   
                    } else { 
                        if($credential.username -match $rgxCertThumbprint){
                            $smsg = "(Disconnecting from $($($mgCtxtTag)) to reconn to -Credential Tenant as $($uRoleReturn.FriendlyName)" ; 
                        } else { 
                            $smsg = "(Disconnecting from $($($mgCtxtTag)) to reconn to -Credential Tenant:$($Credential.username.split('@')[1].tostring()))" ; 
                        } ; 
                        if($silent){} else { 
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        } ;                    
                        $dout = Disconnect-MgGraph ; 
                        throw "AUTHENTICATED TO WRONG TENANT FOR SPECIFIED CREDENTIAL" 
                    } ; 
                } ; 

            }CATCH {

                if($credential.username -match $rgxCertThumbprint){
                    # RequiredScopes is ignored
                    $smsg =  "(UserName:Certificate Thumbprint detected)"
                    if($silent){}elseif($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
                    $pltCMG.Add("CertificateThumbprint", [string]$Credential.UserName);                    
                    $pltCMG.Add("ClientId", [string]$Credential.GetNetworkCredential().Password);
                    # resolve TenantID (guid) from Credential
                    if($TenantID = get-TenantID -Credential $Credential){
                        $pltCMG.Add("TenantId", [string]$TenantID);
                    } else { 
                        $smsg = "UNABLE TO RESOLVE `$TENORG:$($TenOrg) TO FUNCTIONAL `$$($TenOrg)meta.o365_TenantDomain!" ;
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } 
                        else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                        throw $smsg ; 
                        Break ; 
                    } ; 
                    if($uRoleReturn.TenOrg){
                        $TenOrg = $uRoleReturn.TenOrg  ; 
                        $smsg = "(using CBA:cred:$($TenOrg):$([string]$uRoleReturn.FriendlyName))" ; 
                        if($silent){}elseif($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
                    } else {
                        $smsg = "Unable to resolve `$credential.username ($($credential.username))"
                        $smsg += "`nto a usable 'UserRole' spec!" ;
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
                        else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        throw $smsg ;
                        Break ;
                    } ; 
                 } else { 
                    <# there's no interactive cred support with modern auth/mg, not even spec'ing the UPN
                    if ($Credential){
                        $pltCMG.Add("AccountId", [string]$Credential.username);
                        $smsg = "(using cred:$($credential.username))" ; 
                        if($silent){}elseif($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
                    } else {
                        $smsg = "Missing dependant -Credential!" ; 
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent} 
                        else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                        Break ; 
                    } ; 
                    #>
                    $pltgMGCP = [ordered]@{                    
                        Verbose = $($VerbosePreference -eq 'Continue')
                    }
                    if(-not $RequiredScopes -OR $Path -OR $scriptblock -OR $Cmdlets){
                        $smsg = "Interactive User Logon spec, with neither -RequiredScopes, nor Scope-discovery params (-Path, -scriptblock, -Cmdlets) specified" ; 
                        $smsg += "`nPlease specify either -RequiredScopes, or a spec to discovery same, when running this command" ; 
                        write-warning $smsg ;
                        #break ; 
                        # 12:53 PM 1/13/2026 drop the break, this might be why retries don't work
                    }elseif($RequiredScopes){
                    
                    }elseif($Path){
                        $pltgMGCP.add('Path',$Path) ; 
                    }elseif($scriptblock){
                        $pltgMGCP.add('scriptblock',$scriptblock) ; 
                    }elseif($Cmdlets){
                        $pltgMGCP.add('Cmdlets',$Cmdlets) ; 
                    }else{
                        $smsg = "invalid parameter combo!" ; 
                        write-warning $smsg ;
                        break ;
                    }
                    if($Path -OR $scriptblock -OR $Cmdlets){
                        if(get-command get-MGCodeCmdletPermissionsTDO -ea STOP){
                            $RequiredScopes = get-MGCodeCmdletPermissionsTDO @pltgMGCP ; 
                        }else{
                            $smsg = "missing dep:get-MGCodeCmdletPermissionsTDO()!" ; 
                            $smsg += "`nPlease specify either -RequiredScopes, or a spec to discovery same, when running this command" ; 
                            write-warning $smsg ;
                            break ; 
                        }
                    }
                    if($RequiredScopes){
                        $pltCMG.Add('Scopes',$RequiredScopes) ; 
                    }else{
                        $smsg = "Unresolved -RequiredScopes!" ; 
                        write-warning $smsg ;
                        break ;
                    } 
                } 
                if($uRoleReturn.UserRole -match 'CBA'){ $smsg = "Authenticating to MG:$($uRoleReturn.TenOrg), w CBA cred:$($uRoleReturn.FriendlyName)"  }
                else {$smsg = "Authenticating to MG:$($uRoleReturn.TenOrg), w $($Credential.username)..."  ;} ; 
                if($silent){} else { 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                } ; 
            
                if($TenantID -AND ($pltCMG.keys -notcontains 'TenantID')){
                    $smsg = "Forcing TenantID:$($TenantID)" ; 
                    if($silent){} else { 
                        $smsg = "`n$($urolereturn.TenOrg):$($urolereturn.UserRole)" ;
                        $tobj = $MGCntxt ; $tprops = $prpGMGCTargets ; $prpPopd = @() ;
                        $tprops | %{   $thisprop = $_ ;    if($tobj| select -expand $thisprop){$prpPopd+=$thisprop }else{write-verbose "$($thisprop):N"} } ;
                        $smsg += "Connected to:`n$(($MGCntxt | fl $prpPopd|out-string).trim())"  ;
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        $smsg = "`nScopes:$($MGCntxt.scopes -join ', ')" ; 
                        if($VerbosePreference -eq "Continue"){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
                        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
                    } ;                
                    $pltCMG.add('TenantID',[string]$TenantID) ;
                } 
                if(-not $MFA){
                    $smsg = "EXEC:Connect-MgGraph -Credential $($Credential.username) (no MFA, full credential)" ; 
                    if($silent){} else { 
                        $smsg = "`n$($urolereturn.TenOrg):$($urolereturn.UserRole)" ;
                        $tobj = $MGCntxt ; $tprops = $prpGMGCTargets ; $prpPopd = @() ;
                        $tprops | %{   $thisprop = $_ ;    if($tobj| select -expand $thisprop){$prpPopd+=$thisprop }else{write-verbose "$($thisprop):N"} } ;
                        $smsg += "Connected to:`n$(($MGCntxt | fl $prpPopd|out-string).trim())"  ;
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        $smsg = "`nScopes:$($MGCntxt.scopes -join ', ')" ; 
                        if($VerbosePreference -eq "Continue"){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
                        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
                    } ;                
                    if($Credential.username){$pltCMG.add('Credential',$Credential)} ;
                } else {
                    if($mgcntxt.isConnected){
                        if($silent){} else { 
                            $smsg = "`n$($urolereturn.TenOrg):$($urolereturn.UserRole)" ;
                            $tobj = $MGCntxt ; $tprops = $prpGMGCTargets ; $prpPopd = @() ;
                            $tprops | %{   $thisprop = $_ ;    if($tobj| select -expand $thisprop){$prpPopd+=$thisprop }else{write-verbose "$($thisprop):N"} } ;
                            $smsg += "Connected to:`n$(($MGCntxt | fl $prpPopd|out-string).trim())"  ;
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                            $smsg = "`nScopes:$($MGCntxt.scopes -join ', ')" ; 
                            if($VerbosePreference -eq "Continue"){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
                            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
                        } ;                
                    } ; 
                    if($pltCMG.keys -notcontains 'ClientId' -AND $pltCMG.keys -notcontains 'CertificateThumbprint' -AND $pltCMG.keys -notcontains 'AccountId'){
                        # add UPN AccountID logon, if missing and non-CBA
                        if($Credential.username -AND ($pltCMG.keys -notcontains 'AccountId') ){$pltCMG.add('AccountId',$Credential.username)} ;
                    } 
                } ;

                $smsg = "Connect-MgGraph w`n$(($pltCMG|out-string).trim())" ; 
                if($silent){} else { 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                } ;             

                TRY {
                    $MGConnection = Connect-MgGraph @pltCMG ; 
                    if($MGConnection -is [system.array]){
                        $smsg = "MULTIPLE TENANT CONNECTIONS RETURNED BY connect-MgGraph!" ; 
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error } #Error|Warn|Debug 
                        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        throw "MULTIPLE TENANT CONNECTIONS RETURNED BY connect-MgGraph!"
                
                    } else {
                        if($silent){} else { 
                            $smsg = "(single Tenant connection returned)" 
                            # need to reqry the token for updated status
                            #$MGCntxt = [Microsoft.Open.Azure.AD.CommonLibrary.AzureSession]::AccessTokens ; # direct call option
                            $MGCntxt = test-mgconnection -Verbose:($VerbosePreference -eq 'Continue') ;
                            $mgCtxtTag = convert-TenantIdToTag -TenantId $MGCntxt.TenantId -verbose:$($verbose) ; 
                            if($MGCntxt.isconnected){
                                if($silent){} else { 
                                    $smsg = "`n$($urolereturn.TenOrg):$($urolereturn.UserRole)" ;
                                    $tobj = $MGCntxt ; $tprops = $prpGMGCTargets ; $prpPopd = @() ;
                                    $tprops | %{   $thisprop = $_ ;    if($tobj| select -expand $thisprop){$prpPopd+=$thisprop }else{write-verbose "$($thisprop):N"} } ;
                                    $smsg += "Connected to:`n$(($MGCntxt | fl $prpPopd|out-string).trim())"  ;
                                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                                    $smsg = "`nScopes:$($MGCntxt.scopes -join ', ')" ; 
                                    if($VerbosePreference -eq "Continue"){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
                                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
                                } ;
                            } ; 
                        } ; 
                    } ; 
                } CATCH {
                    $ErrTrapd=$Error[0] ;
                    $smsg = "Failed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: $($ErrTrapd)" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    #-=-record a STATUSWARN=-=-=-=-=-=-=
                    $statusdelta = ";WARN"; # CHANGE|INCOMPLETE|ERROR|WARN|FAIL ;
                    if(gv passstatus -scope Script -ea 0){$script:PassStatus += $statusdelta } ;
                    if(gv -Name PassStatus_$($tenorg) -scope Script -ea 0){set-Variable -Name PassStatus_$($tenorg) -scope Script -Value ((get-Variable -Name PassStatus_$($tenorg)).value + $statusdelta)} ; 
                    #-=-=-=-=-=-=-=-=
                    $smsg = "FULL ERROR TRAPPED (EXPLICIT CATCH BLOCK WOULD LOOK LIKE): } catch[$($ErrTrapd.Exception.GetType().FullName)]{" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level ERROR } #Error|Warn|Debug 
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    Break #Opts: STOP(debug)|EXIT(close)|CONTINUE(move on in loop cycle)|BREAK(exit loop iteration)|THROW $_/'CustomMsg'(end script with Err output)
                } ; 
            
                if($silent){} else { 
                    $smsg = "`n$(($MGConnection |ft -a|out-string).trim())" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-host -foregroundcolor white "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                } ; 
                # can still detect status of last command with $? ($true = success, $false = $failed), and use the $error[0] to examine any errors
                if ($?) { 
                    #write-verbose -verbose:$true  "(connected to MgGraph ver2)" ; 
                    Remove-PSTitlebar 'MG' -verbose:$($VerbosePreference -eq "Continue") 
                    # work with the current AzureSession $mgCtxt instead - shift into END{}
                } ;
            
            } ; # CATCH-E # err indicates no authenticated connection

            # former end{} block
            $smsg = "test-mgconnection ..." ;
            if($silent){}elseif($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
            #$MGCntxt = get-mgContext -verbose:$($verbose) ;
            $MGCntxt = test-mgconnection -Verbose:($VerbosePreference -eq 'Continue') ;
            $smsg = "convert-TenantIdToTag -TenantId $($MGCntxt.TenantId) (`$MGCntxt).tenantid)" ;
            if($silent){}elseif($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
            # convert token.tenantid to the 3-letter TenOrg
            $mgCtxtTag = convert-TenantIdToTag -TenantId $MGCntxt.TenantId -verbose:$($verbose) ;
            $Tenantdomain = convert-TenantIdToDomainName -TenantId $MGCntxt.TenantId ;
            #if( ($null -eq $MGCntxt) -OR ($MGCntxt.count -eq 0)){
            if($MGCntxt.isConnected -eq $false){
                $smsg = "NOT authenticated to any o365 Tenant MgGraph!" ; 
                if($credential.username -match $rgxCertThumbprint){
                    $smsg = "Connecting to -Credential Tenant as $($uRoleReturn.FriendlyName)" ;
                } else {
                    $smsg = "Connecting to -Credential Tenant:$($Credential.username.split('@')[1].tostring()))" ;
                } ;
                if($silent){} else {
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                } ;
                Disconnect-MgGraph ;
                connect-MG -verbose:$($verbose) ; 
                $MGCntxt = test-mgconnection -Verbose:($VerbosePreference -eq 'Continue') ;
                if($MGCntxt.isConnected){
                    $Exit = $Retries ;
                }else{
                    $Exit ++ ;
                }
            } else {
                if($silent){} else {
                    $smsg = "`n$($urolereturn.TenOrg):$($urolereturn.UserRole)" ;
                    $tobj = $MGCntxt ; $tprops = $prpGMGCTargets ; $prpPopd = @() ;
                    $tprops | %{   $thisprop = $_ ;    if($tobj| select -expand $thisprop){$prpPopd+=$thisprop }else{write-verbose "$($thisprop):N"} } ;
                    $smsg += "Connected to:`n$(($MGCntxt | fl $prpPopd|out-string).trim())"  ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
                    $smsg = "`nScopes:$($MGCntxt.scopes -join ', ')" ; 
                    if($VerbosePreference -eq "Continue"){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
                } ;
                # flip to resolve-UserNameToUserRole & direct eval the $MGCntxt values:
                if( $mgCtxtTag  -eq $uRoleReturn.TenOrg){
                    if($credential.username -match $rgxCertThumbprint){
                        $smsg = "(Authenticated to MG:$($uRoleReturn.TenOrg) as $($uRoleReturn.FriendlyName))" ;
                    } else {
                        $smsg = "(Authenticated to MG:$($uRoleReturn.TenOrg) as $(($MGCntxt).userid))" ;
                    } ;
                    if($silent){} else {
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    } ;
                } else {
                    if($credential.username -match $rgxCertThumbprint){
                        $smsg = "(Disconnecting from $($($mgCtxtTag)) to reconn to -Credential Tenant as $($uRoleReturn.FriendlyName)" ;
                    } else {
                        $smsg = "(Disconnecting from $($($mgCtxtTag)) to reconn to -Credential Tenant:$($Credential.username.split('@')[1].tostring()))" ;
                    } ;
                    if($silent){} else {
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;;
                    } ;
                    $dout = Disconnect-MgGraph ;
                    throw "AUTHENTICATED TO WRONG TENANT FOR SPECIFIED CREDENTIAL" ;
                    BREAK
                } ;
                if($MGCntxt.isConnected){
                    $Exit = $Retries ;
                }else{
                    $Exit ++ ;
                }
            } ; 

        } Until ($Exit -eq $Retries) ; 
    } ;  # PROC-E
    END {
        # moved into retry loop

    } ; # END-E
}
#endregion CONNECT_MG ; #*------^ END connect-MG ^------
