# get-MgUserFull.ps1

#region GET_MGUSERFULL ; #*------v get-MgUserFull v------
        function get-MgUserFull{
            <#
            .SYNOPSIS
            Wrapper for get-MGUser that *forces* it to return a full set of user properties, to approx the get-AzureAdUser that they've taken away, wo less f'ing around retrying queries.
            .EXAMPLE
            PS> $MGU = get-MgUserFul -userid xxx@yyy.com  ;             
            .NOTES
             MS has lobotomized get-MgUser as compares to the long-standing functional get-AzureAdUser 
             and returning the full suite of user properties now requires a bunch of horse hockey to retrieve - in favor of their cheesball, money grubbing 'lean' property set. 
             fk-em! We're going to force a full property set return, *every time*
             For fancier filter & top use, use those to return an MGUser with a userid, and then recycle the user ID into this, to retrieve a fully populated user object
            VERSION:
            * 12:18 PM 12/10/2025 init
            #>
            [CmdletBinding()]
            PARAM(
                [Parameter(HelpMessage="Source Profile Machine [-SourceProfileMachine CLIENT]")]
                    # if you want to default a value but ensure user doesn't override with null, don't use Mandetory, use...
                    [ValidateNotNullOrEmpty()]
                    [string]$UserID
            )
            $prpMGUser = @(
              # Identity
              'id','userPrincipalName','mail','mailNickname','proxyAddresses','otherMails',
              # Display/profile
              'displayName','givenName','surname','jobTitle','department','companyName',
              'mobilePhone','businessPhones','preferredLanguage',
              # Location
              'city','state','country','officeLocation',          # AzureAD's PhysicalDeliveryOfficeName maps to officeLocation
              # Account state
              'accountEnabled','userType',
              # Licensing
              'assignedLicenses','assignedPlans',
              # Hybrid / sync
              'onPremisesImmutableId','onPremisesDistinguishedName',
              'onPremisesSamAccountName','onPremisesSecurityIdentifier',
              'onPremisesSyncEnabled','onPremisesDomainName',
              # On‑prem extension attrs 1–15
              'onPremisesExtensionAttributes',
              # Misc often used
              'creationType'
            )
            # Retrieve one user with those properties
            if($MGUser = Get-MgUser -UserId "user@contoso.com" -Property $prpMGUser){
                $MGUser | write-output ; 
            } ; 
        } ; 
        #endregion GET_MGUSERFULL ; #*------^ END get-MgUserFull ^------