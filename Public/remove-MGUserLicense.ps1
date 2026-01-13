# remove-MGUserLicense.ps1

#*----------v Function remove-MGUserLicense() v----------
function remove-MGUserLicense {
    <#
    .SYNOPSIS
    remove-MGUserLicense.ps1 - remove a single license from an array of MGUsers
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     :	http://www.toddomation.com
    Twitter     :	@tostka / http://twitter.com/tostka
    CreatedDate : 2022-03-22
    FileName    : remove-MGUserLicense.ps1
    License     : MIT License
    Copyright   : (c) 2022 Todd Kadrie
    Github      : https://github.com/tostka/verb-MG
    Tags        : Powershell
    AddedCredit : 
    AddedWebsite:	
    AddedTwitter:	
    REVISIONS
    * 2:02 PM 1/13/2026 wip port from vaad\remove-aadUserLicense() -> vmg\remove-mguserlicense()
    * 3:25 PM 5/24/2023 rem'd purge; flip the set echo to wlt
    * 3:52 PM 5/23/2023 implemented @rxo @rxoc split, (silence all connectivity, non-silent feedback of functions); flipped all r|cxo to @pltrxoC, and left all function calls as @pltrxo; 
    4:48 PM 5/17/2023rounded out params for $pltRXO passthru ; $TenOrg = $global:o365_TenOrgDefault, ; fixed half-written port from add-aaduserlic (record removals vs adds) ; 
    * 10:30 AM 3/24/2022 add pipeline support
    * 4:08 PM 3/22/2022 init; simple conversion of add-AADUserLicense; verified functional
    .DESCRIPTION
    remove-MGUserLicense.ps1 - remove a single license from an array of MGUsers
    .PARAMETER  Users
    Array of User Userprincipal/Guids to have the specified license applied
    .PARAMETER  skuid
    Azure LicensePlan SkuID for the license to be applied to the users.
    .PARAMETER Credential
    Use specific Credentials (defaults to Tenant-defined SvcAccount)[-Credentials [credential object]]
    .PARAMETER silent
    Switch to specify suppression of all but warn/error echos.(unimplemented, here for cross-compat)
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .EXAMPLE
    PS> $lplistn = get-MGlicensePlanList -IndexOnName ; 
    PS> $skuid = $lplistn['EXCHANGESTANDARD'].skuid ; 
    PS> $bRet = remove-MGUserLicense -users 'upn@domain.com','upn2@domain.com' -skuid $skuid -verbose -whatif ; 
    PS> $bRet | %{if($_.Success){write-host "$($_.MGUser.userprincipalname):Success"} else { write-warning "$($_.MGUser.userprincipalname):FAILURE" } ; 
    Leverage verb-MG:get-MGlicensplanList() to return an SkuPartNumber-indexed hash of current Tenant LicensePlans; 
    Lookup the SKUId value for the ExchangeStandardLicense in the returned indexed hash; 
    Then remove the specified license from the array of user UPNs specified in -users. 
    .EXAMPLE
    PS> $bRet = $MGUser.userprincipalname | remove-MGUserLicense -skuid $skuid -verbose -whatif ; 
    PS> $bRet | %{if($_.Success){write-host "$($_.MGUser.userprincipalname):Success"} else { write-warning "$($_.MGUser.userprincipalname):FAILURE" } ; 
    Pipeline example
    .LINK
    https://github.com/tostka/verb-MG
    #>
    #Requires -Version 3
    # #Requires -Modules MG, verb-Text
    ##Requires -RunasAdministrator
    # VALIDATORS: [ValidateNotNull()][ValidateNotNullOrEmpty()][ValidateLength(24,25)][ValidateLength(5)][ValidatePattern("some\sregex\sexpr")][ValidateSet("USEA","GBMK","AUSYD")][ValidateScript({Test-Path $_ -PathType 'Container'})][ValidateScript({Test-Path $_})][ValidateRange(21,65)][ValidateCount(1,3)]
    [CmdletBinding()]
    PARAM (
        # ValueFromPipeline: will cause params to match on matching type, [array] input -> [array]$param
        [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Users, 
        [string]$skuid,
        [Parameter(Mandatory=$false,HelpMessage="Tenant Tag to be processed[-PARAM 'TEN1']")]
        [ValidateNotNullOrEmpty()]
        [string]$TenOrg = $global:o365_TenOrgDefault,
        [Parameter(Mandatory=$False,HelpMessage="Credentials [-Credentials [credential object]")]
            [System.Management.Automation.PSCredential]$Credential = $global:credo365TORSID,
        [Parameter(HelpMessage="Silent output (suppress status echos)[-silent]")]
            [switch] $silent,
        [Parameter(HelpMessage="Whatif Flag  [-whatIf]")]
            [switch] $whatIf
    ) ;
    BEGIN {
        ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
        $Verbose = ($VerbosePreference -eq 'Continue') ;
        
        # downstream commands
        $pltRXO = [ordered]@{
            Credential = $Credential ;
            verbose = $($VerbosePreference -eq "Continue")  ;
        } ;
        if((gcm Reconnect-EXO).Parameters.keys -contains 'silent'){
            $pltRxo.add('Silent',$silent) ;
        } ;
        # default connectivity cmds - force silent false
        $pltRXOC = [ordered]@{} ; $pltRXO.GetEnumerator() | ?{ $_.Key -notmatch 'silent' }  | ForEach-Object { $pltRXOC.Add($_.Key, $_.Value) } ; $pltRXOC.Add('silent',$true) ;
        if((gcm Reconnect-EXO).Parameters.keys -notcontains 'silent'){ $pltRxo.remove('Silent') } ; 
        #Connect-AAD -Credential:$Credential -verbose:$($verbose) ;
        #Connect-AAD @pltRXOC ; 
        
        # check if using Pipeline input or explicit params:
        if ($PSCmdlet.MyInvocation.ExpectingInput) {
            write-verbose "Data received from pipeline input: '$($InputObject)'" ;
        } else {
            # doesn't actually return an obj in the echo
            write-verbose "Data received from parameter input: " # '$($InputObject)'" ;
        } ;
    } 
    PROCESS {
        $Error.Clear() ;
        $ttl = ($users|  measure ).count ;  
        $procd = 0 ; 
        foreach ($user in $users) {
            $procd ++ ; 
            $sBnrS="`n#*------v $(${CmdletName}): PROCESSING ($($procd)/$($ttl)): $($user):$($skuid) v------" ; 
            $smsg = $sBnrS ; 
            if($silent){} elseif ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

            $Report = @{
                MGUser = $null ; 
                AddedLicenses = @(); 
                RemovedLicenses = @(); 
                FixedUsageLocation = $false ; 
                Success = $false ; 
            } ; 
            $error.clear() ;
            TRY {
                
                $pltGMGU=[ordered]@{ userid = $user ; ErrorAction = 'STOP' ; verbose = ($VerbosePreference -eq "Continue") ; } ; 
                $smsg = "Get-MGUser w`n$(($pltGMGU|out-string).trim())" ; 
                $MGUser = $null ; 
                if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;                      
                $MGUser = Get-MGUser @pltGMGU ;   
                      
                if ($MGUser) {
                    $report.MGUser = $MGUser ; 
                    if (-not $MGUser.UsageLocation) {
                        $smsg = "MGUser: MISSING USAGELOCATION, FORCING" ;
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                        else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

                        $spltSMGUUL = [ordered]@{ 
                            userid = $MGUser.UserPrincipalName ;
                            UsageLocation = "US" ;
                            Credential = $pltRXO.Credential ; 
                            verbose = $pltRXO.verbose  ; 
                            silent = $false ; 
                            whatif = $($whatif) ;
                        } ;
                        $smsg = "set-MGUserUsageLocationw`n$(($spltSMGUUL|out-string).trim())" ; 
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success

                        $bRet = set-MGUserUsageLocation @spltSMGUUL ; 
                        if($bRet.Success){
                            $smsg = "set-MGUserUsageLocation updated UsageLocation:$($bRet.MGuser.UsageLocation)" ; 
                            if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
                            # update the local MGUser to reflect the updated MGU returned
                            $MGUser = $bRet.MGuser ; 
                            $Report.FixedUsageLocation = $true ; 
                        } else { 
                            $smsg = "set-MGUserUsageLocation: FAILED TO UPDATE USAGELOCATION!" ;
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                            else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                            $Report.FixedUsageLocation = $false ; 
                            if(-not $whatif){
                                BREAK; 
                            } 
                        } ; 
                    } ;    
                    
                    # check lic avail
                    $pltGLPList=[ordered]@{ 
                        TenOrg= $TenOrg; 
                        verbose=$($VerbosePreference -eq "Continue") ; 
                        credential= $Credential ;
                        #$pltRXO.credential ; 
                        erroraction = 'STOP' ;
                    } ;
                    $smsg = "get-MGlicensePlanList w`n$(($pltGLPList|out-string).trim())" ; 
                    if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
                    $skus = get-MGlicensePlanList @pltGLPList ;
                    
                    if($tsku = $skus[$skuid]){
                        $smsg = "($($skuid):$($tsku.SkuPartNumber) is present in Tenant SKUs)" ;
                        if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
                    } else { 
                        $smsg = "($($skuid):$($tsku.SkuPartNumber) is NOT PRESENT in Tenant SKUs)" ;
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } 
                        else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                        
                    } ; 
                    
                    if($MGUser.Assignedlicenses.skuid -contains $tsku.SkuId){
                        
                        $licenses = $MGUser.Assignedlicenses.skuid |?{$_ -eq $skuid} ; 

                        $smsg = "Removing license SKUID ($($skuid)) from user:$($user)" ; 
                        if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
                        <# AADU stuct
                        $AssignedLicenses = @{
                            addLicenses = @()
                            removeLicenses= @($licenses)
                        } ; 
                        #>
                        $pltSMGUL=[ordered]@{
                            userid = $MGUser.userid ;
                            #AssignedLicenses = $AssignedLicenses ;
                            removeLicenses= @($licenses) ; 
                            addLicenses = @()
                            erroraction = 'STOP' ;
                            verbose = $($VerbosePreference -eq "Continue") ;
                        } ;
                        $smsg = "Set-MGUserLicense w`n$(($pltSMGUL|out-string).trim())" ; 
                        $smsg += "`naddLicenses:$(($pltSMGUL.AssignedLicenses.addLicenses|out-string).trim())" ; 
                        $smsg += "`nremoveLicenses:$(($pltSMGUL.AssignedLicenses.removeLicenses|out-string).trim())" ; 
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
                        if (-not $whatif) {
                            Set-MGUserLicense @pltSMGUL ;
                                
                            $Report.RemovedLicenses += "$($tsku.SkuPartNumber):$($tsku.SkuId)" ; 
                            $Report.Success = $true ; 
                        } else {
                            $Report.Success = $false ; 
                            $smsg = "(-whatif: skipping exec (set-AureADUser lacks proper -whatif support))" ; ;
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        }  ;
                        # refreshing MGu, but for some reason when returned, it's not up to date (replication latency?)
                        start-sleep -Milliseconds 500 ; 
                        $MGUser = Get-MGUser @pltGMGU ; 
                        $report.MGUser = $MGUser ; 
                        $usrPlans = $usrLics=@() ; 
                        foreach($pLic in $MGUser.AssignedLicenses.skuid){
                            $usrLics += $skus[$plic].SkuPartNumber ; 
                        } ; 
                        foreach($pPlan in $MGUser.assignedplans){
                            $usrPlans += $_.service ; 
                        } ; 
                        $smsg = "POST:`n$(($MGUser|ft -a UserPrincipalName,DisplayName| out-string).trim())" ;
                        $smsg += "`nLicenses: $(($usrLics -join ','|out-string).trim())" ;  
                        $smsg += "`nPlans: $(( ($usrPlan | select -unique) -join ','|out-string).trim())" ; 
                        if($silent){} elseif ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
                        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                                
                        #[PSCustomObject]$Report | write-output ;
                        New-Object PSObject -Property $Report | write-output ;

                    } else {
                        $smsg = "$($MGUser.userprincipalname) does not have AssignedLicense:$($tsku.SkuPartNumber)" ; 
                        if($silent){} elseif ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        $report.Success = $true ; 
                        #[PSCustomObject]$Report | write-output ;
                        New-Object PSObject -Property $Report | write-output ;
                    } ;
                        
                } else {
                    $smsg = "Unable to locate MGUser" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } 
                    else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                    $report.Success = $false ; 
                    #[PSCustomObject]$Report | write-output ;
                    New-Object PSObject -Property $Report | write-output ;
                    Break ; 
                } ;
            } CATCH {
                $ErrTrapd=$Error[0] ;
                $smsg = "$('*'*5)`nFailed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: `n$(($ErrTrapd|out-string).trim())`n$('-'*5)" ;
                $smsg += "`n$($ErrTrapd.Exception.Message)" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent} 
                else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                BREAK ;
            } ; 

            $smsg = $sBnrS.replace('-v','-^').replace('v-','^-')
            if($silent){} elseif ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        } ; # loop-E
    }  # PROC-E
    END{
        $smsg = "(processed $($procd) users)" ; 
        if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;         
    } ;
} ; 
#*------^ END Function remove-MGUserLicense() ^------
