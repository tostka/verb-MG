# get-MgUserFull.ps1

    #region GET_MGUSERFULL ; #*------v get-MgUserFull v------
    function get-MgUserFull{
        <#
        .SYNOPSIS
        get-MgUserFull.ps1 - Wrapper for get-MGUser that *forces* it to return a full set of user properties, to approx the get-AzureAdUser that they've taken away, wo less f'ing around retrying queries.
        .NOTES
        Version     : 0.0.
        Author      : Todd Kadrie
        Website     : http://www.toddomation.com
        Twitter     : @tostka / http://twitter.com/tostka
        CreatedDate : 2025-
        FileName    : get-MgUserFull.ps1
        License     : MIT License
        Copyright   : (c) 2025 Todd Kadrie
        Github      : https://github.com/tostka/verb-XXX
        Tags        : Powershell
        AddedCredit : REFERENCE
        AddedWebsite: URL
        AddedTwitter: URL
        REVISIONS
        * 5:26 PM 3/13/2026 -filter support is completely broken (throws error) ; replcd mg scaffold with simple test-mgconnection & connect-mg call; pulled in-loop connect-MG
        * 3:29 PM 1/6/2026 fixed mg ipmo ;  reworked $prpMGUser list, added items that are unpop'd propoerties, and pushed useful Additionalproperties from OnPrem, into expansion, updated CBH
        * 12:18 PM 12/10/2025 init
        .DESCRIPTION
        get-MgUserFull.ps1 - Wrapper for get-MGUser that *forces* it to return a full set of user properties, to approx the get-AzureAdUser that they've taken away, wo less f'ing around retrying queries.

        MS has lobotomized get-MgUser as compares to the long-standing functional get-AzureAdUser 
        and returning the full suite of user properties now requires a bunch of horse hockey to retrieve - in favor of their cheesball, money grubbing 'lean' property set. 
        fk-em! We're going to force a full property set return, *every time*
        For fancier filter & top use, use those to return an MGUser with a userid, and then recycle the user ID into this, to retrieve a fully populated user object

        Attempts to use -filter currently throw error:
        #-=-=-=-=-=-=-=-=
        WARNING: 17:25:29:
        PSMessageDetails      :
        Exception             : System.Exception: [-1, Microsoft.SharePoint.Client.InvalidClientQueryException] : The expression "id in ('4b0f0f19-5140-435c-92a4-4d3b45db1866')" is not valid.
        TargetObject          : { ConsistencyLevel = , Top = , Search = , Filter = UserPrincipalName eq 'aaaa.aaaaaa@aaaa.aaa', Count = , Sort = , Property = System.String[], ExpandProperty = , Headers =  }
        CategoryInfo          : InvalidOperation: ({ ConsistencyLe... , Headers =  }:<>f__AnonymousType48`9) [Get-MgUser_List], Exception
        FullyQualifiedErrorId : -1, Microsoft.SharePoint.Client.InvalidClientQueryException,Microsoft.Graph.PowerShell.Cmdlets.GetMgUser_List
        ErrorDetails          : The expression "id in ('4b0f0f19-5140-435c-92a4-4d3b45db1866')" is not valid.
                                Status: 400 (BadRequest)
                                ErrorCode: -1, Microsoft.SharePoint.Client.InvalidClientQueryException
                                Date: 2026-03-13T22:25:23
                                Headers:
                                Transfer-Encoding             : chunked
                                Vary                          : Accept-Encoding
                                Strict-Transport-Security     : max-age=31536000
                                request-id                    : 9a99a999-aaa9-99aa-aa99-9999aaa9a999
                                client-request-id             : 99a9a999-99a9-99a9-9999-a99a99999a99
                                x-ms-ags-diagnostic           : {"ServerInfo":{"DataCenter":"Central US","Slice":"E","Ring":"4","ScaleUnit":"006","RoleInstance":"DS1PEPF00040793"}}
                                x-ms-resource-unit            : 2
                                Cache-Control                 : max-age=0, private
                                Date                          : Fri, 13 Mar 2026 22:25:23 GMT
        InvocationInfo        : System.Management.Automation.InvocationInfo
        ScriptStackTrace      : at Get-MgUser<Process>, C:\Program Files\WindowsPowerShell\Modules\Microsoft.Graph.Users\2.33.0\exports\ProxyCmdletDefinitions.ps1: line 23102
                                at get-MgUserFull<Process>, D:\scripts\get-MgUserFull_func.ps1: line 269
                                at <ScriptBlock>, <No file>: line 1
        PipelineIterationInfo : {}
        #-=-=-=-=-=-=-=-=


        .PARAMETER  UserID
        Useridentifier (UPN, GUID etc) [-UserID UPN@DOMAIN.COM]
        .PARAMETER Filter
        Filter items by property values
        .INPUTS
        None. Does not accepted piped input.(.NET types, can add description)
        .OUTPUTS
        Microsoft.Graph.PowerShell.Models.MicrosoftGraphUser
        System.Boolean
        [| get-member the output to see what .NET obj TypeName is returned, to use here]
        .EXAMPLE
        PS> $mgu = get-MgUserFull -userid UPN@DOMAIN.COM ; 
        Typical call
        .LINK
        https://github.com/tostka/verb-MG
        #>
        [CmdletBinding()]
        PARAM(
            [Parameter(HelpMessage="Array of Useridentifiers (UPN, GUID etc) [-UserID UPN@DOMAIN.COM]")]
                #[ValidateNotNullOrEmpty()]
                [string[]]$UserID,
             [Parameter(HelpMessage="Filter items by property values[-Filter `"userType eq 'Guest'`"]")]
                [string]$Filter
        )
        BEGIN{
            # FORCE fully populated key user properties (overrides default return of subset garbage)
            $prpMGUser = @(
                # Identity
                'id','userPrincipalName','mail','mailNickname','proxyAddresses','otherMails','otherMails',
                # Display/profile
                'displayName','givenName','surname','jobTitle','department','companyName',
                'mobilePhone','businessPhones','preferredLanguage',
                'jobTitle',
                'department','companyName',
                'StreetAddress','city','state','PostalCode','country',
                'officeLocation','UsageLocation',
                # Account state
                'accountEnabled','userType',
                # Licensing
                'assignedLicenses','assignedPlans',
                # Hybrid / sync
                'onPremisesImmutableId','onPremisesDistinguishedName','onPremisesSecurityIdentifier',
                'OnPremisesUserPrincipalName','onPremisesSamAccountName','onPremisesDomainName',
                'onPremisesSyncEnabled','OnPremisesLastSyncDateTime','OnPremisesProvisioningErrors','onPremisesExtensionAttributes'
                # add prev missing sync data props
                # Misc often used
                'creationType', 'CreatedDateTime','DeletedDateTime','EmployeeHireDate','EmployeeId','EmployeeType','HireDate',  
                'Manager',
                'LicenseAssignmentStates','LicenseDetails','ProvisionedPlans',
                'MemberOf',
                # add AdditionalProperties pulls (should move to primary property, also accessible as .additionalproperties['xxx'] property      
                'mobilePhone','businessPhones',
                'preferredLanguage'
            ) | select -unique ; 

            #$isMgConn = [boolean]( (gcm get-mgcontext -ea 0) -AND (get-mgcontext -ea 0 )); if(-not $isMgConn ){connect-mg }else{write-verbose "MG connected"};
            if(-not (get-command  test-mgconnection)){
                if(-not (get-module -list Microsoft.Graph -ea 0)){
                    $smsg = "MISSING Microsoft.Graph!" ; 
                    $smsg += "`nUse: install-module Microsoft.Graph -scope CurrentUser" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent} 
                    else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                } ;             
            } ;
            $MGCntxt = test-mgconnection -Verbose:($VerbosePreference -eq 'Continue') ;
            if($MGCntxt.isConnected){}else {
                connect-mg ; 
            }
            <#
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
            #>
            if(-not (get-command Get-MgUser)){
                $smsg = "Missing Get-MgUser!" ; 
                $smsg += "`nPre-connect to Microsoft.Graph via:" ;
                $smsg += "`nConnect-MgGraph -Scopes 'User.Read.All', 'Directory.Read.All', 'Group.Read.All'" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent} 
                else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                BREAK ; 
            } ; 
            #region IS_PIPELINE ; #*------v IS_PIPELINE v------
            # check if using Pipeline input or explicit params:
            if ($PSCmdlet.MyInvocation.ExpectingInput) {
                $smsg = "Data received from pipeline input: '$($InputObject)'" ;
                if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
            } else {
                # doesn't actually return an obj in the echo
                #$smsg = "Data received from parameter input: '$($InputObject)'" ;
                #if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
                #else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
            } ;
            #endregion IS_PIPELINE ; #*------^ END IS_PIPELINE ^------
        } 
        PROCESS{
            if($userId){
                foreach($id in $userid){
                    TRY{
                        #connect-MG @pltCMG # mg dyn refreshes conn, doesn't need refresh
                        $smsg = "Get-MgUser -UserId $($id)" ; 
                        if($VerbosePreference -eq "Continue"){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
                        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
                        $MGUser = Get-MgUser -UserId $id -Property $prpMGUser -erroraction STOP ; 
                    } CATCH {$ErrTrapd=$Error[0] ;
                        write-host -foregroundcolor gray "TargetCatch:} CATCH [$($ErrTrapd.Exception.GetType().FullName)] {"  ;
                        $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent} 
                        else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                        CONTINUE
                     } ;
   
                    if($MGUser){
                        $MGUser | write-output ; 
                    } else{
                        $smsg = "UNABLE TO: Get-MgUser -UserId $($userid)" ; 
                        if(gcm Write-MyWarning -ea 0){Write-MyWarning $smsg } else {
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN} else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        } ;
                    }; 
                } # loop-E
            }elseif($filter){
                foreach($fltr in $filter){
                    TRY{
                        #connect-MG @pltCMG # mg dyn refreshes conn, doesn't need refresh
                        $smsg = "Get-MgUser -Filter  $($fltr)" ; 
                        if($VerbosePreference -eq "Continue"){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
                        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
                        $MGUser = Get-MgUser -Filter $fltr -Property $prpMGUser -erroraction STOP ; 
                    } CATCH {$ErrTrapd=$Error[0] ;
                        write-host -foregroundcolor gray "TargetCatch:} CATCH [$($ErrTrapd.Exception.GetType().FullName)] {"  ;
                        $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent} 
                        else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                        CONTINUE
                     } ;
   
                    if($MGUser){
                        $MGUser | write-output ; 
                    } else{
                        $smsg = "UNABLE TO: Get-MgUser -UserId $($userid)" ; 
                        if(gcm Write-MyWarning -ea 0){Write-MyWarning $smsg } else {
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN} else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        } ;
                    }; 
                } # loop-E
            }
        } ;  # PROC-E
    } ; 
    #endregion GET_MGUSERFULL ; #*------^ END get-MgUserFull ^------