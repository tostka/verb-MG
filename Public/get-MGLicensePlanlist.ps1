# get-MGLicensePlanlist.ps1

#*------v get-MGLicensePlanlist.ps1 v------
function get-MGLicensePlanlist {
    <#
    .SYNOPSIS
    get-MGLicensePlanlist - Resolve Get-AzureADSubscribedSku into an indexed hash of Tenant License detailed specs
    .NOTES
    Version     : 1.0.0.1
    Author      : Todd Kadrie
    Website     :	http://www.toddomation.com
    Twitter     :	@tostka / http://twitter.com/tostka
    CreatedDate : 2020-08-10
    FileName    : get-MGLicensePlanlist
    License     : MIT License
    Copyright   : (c) 2020 Todd Kadrie
    Github      : https://github.com/tostka/
    REVISIONS
    * 12:01 PM 1/6/2026 CMG spliced in scaff
    * 3:39 PM 1/5/2026 port from vaad\get-AADLicensePlanList -> get-MGLicensePlanList    
    .DESCRIPTION
    get-MGLicensePlanlist - Resolve Get-AzureADSubscribedSku into an indexed hash of Tenant License detailed specs
    .PARAMETER Raw
    Switch specifies to return the raw get-MGLicensePlanlist properties, indexed on SkuID
    .PARAMETER IndexOnName
    Switch specifies to return the raw get-MGLicensePlanlist properties, indexed on Name (for name -> details/skuid lookups; default is indexed on SkuID for sku->details/name lookups)
     .PARAMETER  Credential
    Credential to use for this connection [-credential 'account@domain.com']
    .PARAMETER silent
    Switch to specify suppression of all but warn/error echos.
    .PARAMETER ShowDebug
    Parameter to display Debugging messages [-ShowDebug switch]
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .INPUTS
    None. Does not accepted piped input.
    .OUTPUTS
    [| get-member the output to see what .NET obj TypeName is returned, to use here]
    .EXAMPLE
    PS>  $pltGLPList=[ordered]@{
    PS>      TenOrg= $TenOrg;
    PS>      verbose=$($VerbosePreference -eq "Continue") ;
    PS>      credential= $pltRXO.credential ;
    PS>      #(Get-Variable -name cred$($tenorg) ).value ;
    PS>  } ;
    PS>  $smsg = "$($tenorg):get-MGLicensePlanlist w`n$(($pltGLPList|out-string).trim())" ;
    PS>  if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
    PS>  else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    PS>  $objRet = $null ;
    PS>  $objRet = get-MGLicensePlanlist @pltGLPList ;
    PS>  if( ($objRet|Measure-Object).count -AND $objRet.GetType().FullName -match $rgxHashTableTypeName ){
    PS>      $smsg = "get-MGLicensePlanlist:$($tenorg):returned populated LicensePlanList" ;
    PS>      if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
    PS>      else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    PS>      $licensePlanListHash = $objRet ;
    PS>  } else {
    PS>      $smsg = "get-MGLicensePlanlist:$($tenorg)FAILED TO RETURN populated [hashtable] LicensePlanList" ;
    PS>      if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error } 
    PS>      else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    PS>      THROW $SMSG ; 
    PS>      break ; 
    PS>  } ;
    PS>  $MGu = get-azureaduser -obj someuser@domain.com ; 
    PS>  $userList = $MGu | Select -ExpandProperty AssignedLicenses | Select SkuID  ;
    PS>  $userLicenses=@() ;
    PS>  $userList | ForEach {
    PS>     $sku=$_.SkuId ;
    PS>     $userLicenses+=$licensePlanListHash[$sku].SkuPartNumber ;
    PS>  } ;
    .EXAMPLE
    PS> PS> $lplist =  get-MGLicensePlanlist ;
    PS> $lplist['18181a46-0d4e-45cd-891e-60aabd171b4e']
        SkuId         : 18181a46-0d4e-45cd-891e-60aabd171b4e
        SkuPartNumber : STANDARDPACK
        Enabled       : 418
        Consumed      : 284
        Available     : 134
        Warning       : 0
        Suspended     : 0
    Demo indexed hash lookup of SkuID (to details) under default behavior (summary output table, and indexed on SKUID)
    .EXAMPLE
    PS> $lplist =  get-MGLicensePlanlist -raw ;
    PS> $lplist['18181a46-0d4e-45cd-891e-60aabd171b4e']
        ObjectId                                                                  SkuPartNumber PrepaidUnits                                               
        --------                                                                  ------------- ------------                                               
        549366ae-e80a-44b9-8adc-52d0c29ba08b_18181a46-0d4e-45cd-891e-60aabd171b4e STANDARDPACK  class LicenseUnitsDetail {...
    Demo indexed hash lookup of SkuID (to details) under -Raw behavior (raw object output, and indexed on SKUID)
    .EXAMPLE
    PS> $lplist =  get-MGLicensePlanlist -verbose -IndexOnName ;
    PS> $lplist['EXCHANGESTANDARD'] | ft -auto 
        SkuId                                SkuPartNumber    Enabled Consumed Available Warning Suspended
        -----                                -------------    ------- -------- --------- ------- ---------
        4b9405b0-7788-4568-add1-99614e613b69 EXCHANGESTANDARD      58       53         5       0         0
    Demo use of -IndexOnName, and indexed hash lookup of Name (to details) under Default behavior (summary output table, and indexed on SkuPartNumber)
    .LINK
    https://github.com/tostka
    #>
    ##ActiveDirectory, MSOnline, 
    #Requires -Version 3
    ##requires -PSEdition Desktop
    ## #Requires -Modules AzureAD, verb-Text # rem'd out
    ##Requires -RunasAdministrator
    # VALIDATORS: [ValidateNotNull()][ValidateNotNullOrEmpty()][ValidateLength(24,25)][ValidateLength(5)][ValidatePattern("some\sregex\sexpr")][ValidateSet("USEA","GBMK","AUSYD")][ValidateScript({Test-Path $_ -PathType 'Container'})][ValidateScript({Test-Path $_})][ValidateRange(21,65)][ValidateCount(1,3)]
    [CmdletBinding()]
    PARAM(
        [Parameter(HelpMessage="Switch specifies to return the raw get-MGLicensePlanlist properties, indexed on SkuID")]
            [switch]$Raw,
        [Parameter(HelpMessage="Switch specifies to return the raw get-MGLicensePlanlist properties, indexed on Name (for name -> details/skuid lookups; default is indexed on SkuID for sku->details/name lookups)")]
            [switch]$IndexOnName,
        [Parameter(HelpMessage="Tenant Tag to be processed[-PARAM 'TEN1']")]
            [ValidateNotNullOrEmpty()]
            [string]$TenOrg = $global:o365_TenOrgDefault,
        [Parameter( HelpMessage = "Use specific Credentials (defaults to Tenant-defined SvcAccount)[-Credentials [credential object]]")]
            [System.Management.Automation.PSCredential]$Credential,
        [Parameter(HelpMessage="Silent output (suppress status echos)[-silent]")]
            [switch] $silent,
        [Parameter(HelpMessage="Debugging Flag [-showDebug]")]
        [switch] $showDebug,
        [Parameter(HelpMessage="Whatif Flag  [-whatIf]")]
        [switch] $whatIf=$true
    ) ;
    BEGIN {
        #${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
        # Get parameters this function was invoked with
        #$PSParameters = New-Object -TypeName PSObject -Property $PSBoundParameters ;
        $Verbose = ($VerbosePreference -eq 'Continue') ;
        #$script:PassStatus = $null ;
        #if(!$GroupSpecifications ){$GroupSpecifications = "ENT-SEC-Guest-TargetUsers;AzureAD Guest User Population","ENT-SEC-Guest-BlockedUsers;AzureAD Guest Blocked Users","ENT-SEC-Guest-AlwaysUsers;AzureAD Guest Force-include Users" ; } ;
        # more useful summary table output (Better matches the *useful* get-MsolAccountSku output!)
        $propsMGL = 'SkuId',  'SkuPartNumber',  @{name='Enabled';Expression={$_.PrepaidUnits.enabled }},  
            @{name='Consumed';Expression={$_.ConsumedUnits} }, @{name='Available';Expression={$_.PrepaidUnits.enabled - $_.ConsumedUnits} }, 
            @{name='Warning';Expression={$_.PrepaidUnits.warning} }, @{name='Suspended';Expression={$_.PrepaidUnits.suspended} } ;
        
        #region cMG_SCAFFOLD ; #*------v cMG_SCAFFOLD v------
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

    } ; # BEG-E
    PROCESS {
        $Error.Clear() ;
        #$ObjReturn=@() ; 
        <#$hshRet=[ordered]@{
            Cred=$null ; 
            credType=$null ; 
        } ; 
        #>
        $smsg = "$($TenOrg):Retrieving licensePlanList..." ; 
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        $licensePlanList = $null ; 

        #Connect-MG @pltRXOC ; 
        connect-MG @pltCMG 

        $error.clear() ;
        TRY {
            if($Raw){
                $smsg = "(-raw: returning indexed-hash of raw Get-AzureADSubscribedSku properties)" ; 
                if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
                #$licensePlanList = Get-AzureADSubscribedSku ;
                $licensePlanList = Get-MgSubscribedSku 
            } else {
                $smsg = "(default: returning indexed-hash of summarized Get-AzureADSubscribedSku properties)" ; 
                if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
                #$licensePlanList = Get-AzureADSubscribedSku | select-object $propsMGL ;
                $licensePlanList = Get-MgSubscribedSku  | select-object $propsMGL ;
            } ; 
        } CATCH {
            $ErrTrapd=$Error[0] ;
            Start-Sleep -Seconds $RetrySleep ;
            $Exit ++ ;
            $smsg= "Failed to exec cmd because: $($ErrTrapd)" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error} ; #Error|Warn
            $smsg= "Try #: $($Exit)" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error} ; #Error|Warn
            $script:PassStatus += ";ERROR";
            $smsg= "Unable to exec cmd!" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error} ; #Error|Warn
            Exit ;#Continue/Exit/Stop
        } ; 

        $smsg = "(converting `$licensePlanList to `$licensePlanListHash indexed hash)..." ; 
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        # can't use convert-ObjectToIndexedHash as the key/index is a split version of a property, rather than the entire property
        $swMstr = [Diagnostics.Stopwatch]::StartNew();
        if($host.version.major -gt 2){$licensePlanListHash = [ordered]@{} } 
        else { $licensePlanListHash = @{} };
        if($IndexOnName){
            $smsg = "(IndexOnName indexing: returning indexed-hash keyed on 'Name' (SkuPartNumber))" ; 
            if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
        } else { 
            $smsg = "(default indexing: returning indexed-hash keyed on SkuID)" ; 
            if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
        } ; 
        foreach($lic in $licensePlanList) {
            # update the content with the friendly name
            $data=[ordered]@{
                SkuId = $lic.SkuId
                SkuPartNumber = $lic.SkuPartNumber
                SkuDesc = get-MGLicenseFullName -name $lic.SkuPartNumber ; 
                Enabled = $lic.Enabled ; 
                Consumed = $lic.Consumed ; 
                Available = $lic.Available ; 
                Warning = $lic.Warning ; 
                Suspended = $lic.Suspended ; 
            } ;
            if($IndexOnName){
                if($raw){
                    $licensePlanListHash[$lic.SkuPartNumber] = $lic ;
                } else { 
                    $licensePlanListHash[$lic.SkuPartNumber] = New-Object PSObject -Property $data ;
                } ; 
            } else { 
                if($raw){
                    $licensePlanListHash[$lic.skuid] = $lic ;    
                } else { 
                    $licensePlanListHash[$lic.skuid] = New-Object PSObject -Property $data ;
                } ;            
            } ; 
        } ;
    
        $swMstr.Stop() ;
        $smsg = "($(($licensePlanList|measure).count) records converted in $($swMstr.Elapsed.ToString()))" ; 
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        # purge the original (reduce mem)
        $licensePlanList = $null ; 
        #now can lookup user AssignedLicense.SKUID's eqiv licName as $licensePlanListHash[$skuid].skupartnumber

    } ;  # PROC-E
    END{
        $licensePlanListHash | write-output ; 
    } ;
}

#*------^ get-MGLicensePlanlist.ps1 ^------