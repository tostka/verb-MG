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
        * 10:46 AM 12/11/2025 reworked $prpMGUser list, added items that are unpop'd propoerties, and pushed useful Additionalproperties from OnPrem, into expansion, updated CBH
        * 12:18 PM 12/10/2025 init
        .DESCRIPTION
        get-MgUserFull.ps1 - Wrapper for get-MGUser that *forces* it to return a full set of user properties, to approx the get-AzureAdUser that they've taken away, wo less f'ing around retrying queries.

        MS has lobotomized get-MgUser as compares to the long-standing functional get-AzureAdUser 
        and returning the full suite of user properties now requires a bunch of horse hockey to retrieve - in favor of their cheesball, money grubbing 'lean' property set. 
        fk-em! We're going to force a full property set return, *every time*
        For fancier filter & top use, use those to return an MGUser with a userid, and then recycle the user ID into this, to retrieve a fully populated user object

        .PARAMETER  UserID
        Useridentifier (UPN, GUID etc) [-UserID UPN@DOMAIN.COM]
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
                [ValidateNotNullOrEmpty()]
                [string[]]$UserID
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
            foreach($id in $userid){
                TRY{
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
        } ;  # PROC-E
    } ; 
    #endregion GET_MGUSERFULL ; #*------^ END get-MgUserFull ^------