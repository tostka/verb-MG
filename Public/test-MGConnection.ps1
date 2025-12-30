# test-MGConnectionTDOTDO.ps1

#*------v test-MGConnectionTDOTDO.ps1 v------
Function test-MGConnectionTDOTDO {
  <#
    .SYNOPSIS
    test-MGConnectionTDOTDO - Test Microsoft.Graph connection status. Wraps Microsoft.Graph\get-MGContext command to return properties of connection (or nothing if disconnected)
    .NOTES
    Version     : 0.0.1
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2025-12-30
    FileName    : test-MGConnectionTDO.ps1
    License     : MIT License
    Copyright   : (c) 2025 Todd Kadrie
    Github      : https://github.com/tostka/verb-MG
    Tags        : Powershell,MicrosoftGraph,Tenant,Connectivty,Test
    AddedCredit : REFERENCE
    AddedWebsite: URL
    AddedTwitter: URL    
    REVISIONS   :
    * 4:26 PM 12/30/2025 init
    .DESCRIPTION
    test-MGConnectionTDO - Test Microsoft.Graph connection status. Wraps Microsoft.Graph\get-MGContext command to return properties of connection (or nothing if disconnected). Returns summary object with status evaluated.
    
    Returns the following properties: 

    ClientId               : 99a99aaa-999a-9a9a-a9a9-999a99aaa99a
    TenantId               : 999999aa-a99a-99a9-9aaa-99a9a99aa99a
    Scopes                 : {Application.Read.All, Application.ReadWrite.All, AuditLog.Read.All, Chat.ReadWrite...}
    AuthType               : Delegated
    TokenCredentialType    : InteractiveBrowser
    CertificateThumbprint  : 
    CertificateSubjectName : 
    Account                : a-aaaa.aaaaaa@aaaa.aaa
    AppName                : Microsoft Graph Command Line Tools
    ContextScope           : CurrentUser
    Certificate            : 
    ManagedIdentityId      : 
    ClientSecret           : 
    Environment            : Global
    TenantAligned          : True
    isUser                 : True
    isAppOnly              : False
    isCBA                  : False
    hasRequiredScopes      : False
    missingScopes          : {User.Read.All, Group.Read.All, Domain.Read.All}
    isConnected            : True

    # Typical interactive connection returned by get-MGContext:

    ClientId               : 99a99aaa-999a-9a9a-a9a9-999a99aaa99a
    TenantId               : 999999aa-a99a-99a9-9aaa-99a9a99aa99a
    Scopes                 : {Application.Read.All, Application.ReadWrite.All, AuditLog.Read.All, Chat.ReadWrite...}
    AuthType               : Delegated
    TokenCredentialType    : InteractiveBrowser
    CertificateThumbprint  :
    CertificateSubjectName :
    SendCertificateChain   : False
    Account                : a-aaaa.aaaaaa@aaaa.aaa
    AppName                : Microsoft Graph Command Line Tools
    ContextScope           : CurrentUser
    Certificate            :
    PSHostVersion          : 5.1.14393.8688
    ManagedIdentityId      :
    ClientSecret           :
    Environment            : Global
  
    # Typical app-only session connection returned by get-MGContext:

    ClientId               : 99a99aaa-999a-9a9a-a9a9-999a99aaa99a
    TenantId               : 999999aa-a99a-99a9-9aaa-99a9a99aa99a
    Scopes                 : {Application.Read.All, Application.ReadWrite.All, AuditLog.Read.All, Chat.ReadWrite...}
    AuthType               : AppOnly
    TokenCredentialType    : ClientCertificate
    CertificateThumbprint  : 9A9A999A999A9A9999999A9A9AAA99AAA99AA9A9
    CertificateSubjectName :
    SendCertificateChain   : False
    Account                : 
    AppName                : Aaaaaaaaaaaa App
    ContextScope           : Process
    Certificate            :
    PSHostVersion          : 7.4.6
    ManagedIdentityId      :
    ClientSecret           :
    Environment            : Global

    .PARAMETER TenantID
    Target TenantID (used for confirmation matching)[-TenantID '999999aa-a99a-99a9-9aaa-99a9a99aa99a']
    .PARAMETER RequiredScopes
    Scopes required for planned cmdlets to be executed[-RequiredScopes @('User.Read.All', 'Group.Read.All', 'Domain.Read.All')]
    .INPUTS
    None. Does not accepted piped input.
    .OUTPUTS
    System.Object   Returns an object summarizing connection status and properties (evaluated trom get-MGContext output properties)
    .EXAMPLE
    PS> if(-not (test-MGConnectionTDO).isConnected){
    PS>     Connect-MgGraph -Scopes $ScopesNeeded -NoWelcome -ErrorAction Stop 
    PS> } ; 
    Demo usage to trigger connection as needed
    .EXAMPLE
    PS> if(-not (test-MGConnection -RequiredScopes @('User.Read.All', 'Group.Read.All', 'Domain.Read.All')).isConnected){
    PS>     Connect-MgGraph -Scopes $ScopesNeeded -NoWelcome -ErrorAction Stop 
    PS> } ; 
    Demo usage to trigger connection as needed, with scope testing
    .LINK
    https://github.com/tostka/verb-MG
    #>
    # #Requires -Modules Microsoft.Graph
    [CmdletBinding()]
    [Alias('tMGC','test-MGConnection')]
    Param(
        #[Parameter()]$Credential = $global:credo365TORSID
        # no supported cred param
        #[Parameter(Position=0,Mandatory=$True,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,HelpMessage="HELPMSG[-PARAM SAMPLEINPUT]")]
        [Parameter(Position=0,Mandatory=$false,HelpMessage="Target TenantID (used for confirmation matching)[-TenantID '999999aa-a99a-99a9-9aaa-99a9a99aa99a']")]
            $TenantID = $tormeta.o365_TenantID,
        [Parameter(Mandatory=$True,HelpMessage="Scopes required for planned cmdlets to be executed[-RequiredScopes @('User.Read.All', 'Group.Read.All', 'Domain.Read.All')]")]
            [array]$RequiredScopes
    ) ;
    BEGIN{
        $verbose = ($VerbosePreference -eq "Continue") ; 
        if(-not(get-command get-mgcontext)){
            $smsg = "missing get-mgcontext: " ; 
            $smsg += "`nuse: Install-Module Microsoft.Graph -Scope CurrentUser" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent} 
            else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
            $false | write-output ; 
        } 
        $oRet = [ordered]@{
            ClientId = $null ; 
            TenantId = $null; 
            Scopes = $null ; 
            AuthType = $null ; 
            TokenCredentialType = $null; 
            CertificateThumbprint = $null ; 
            CertificateSubjectName = $null ; 
            Account = $null ; 
            AppName = $null ; 
            ContextScope = $null ; 
            Certificate = $null ; 
            ManagedIdentityId = $null; 
            ClientSecret = $null; 
            Environment = $null ; 
            TenantAligned = $null ;
            isUser = $null ; 
            isAppOnly = $null ; 
            isCBA = $null ; 
            hasRequiredScopes = $null; 
            missingScopes = $null ; 
            isConnected = $false
        } ; 
    } ;
    PROCESS{
        #Connect-MgGraph -Scopes "Organization.Read.All" -NoWelcome # suppress the banner, or it dumps it into the pipeline!
        #$LastDirSyncTime = (Get-MsolCompanyInformation).LastDirSyncTime ;
        #$LastDirSyncTime = (Get-AzureADTenantDetail).CompanyLastDirSyncTime ;
        #$LastDirSyncTime = Get-MgOrganization | select -expand OnPremisesLastSyncDateTime=
        $mgCS = Get-MgContext -ErrorAction SilentlyContinue ;         
        if( $mgCS){
            #New-Object PSObject -Property @{
            #$oRet = [ordered]@{
            $oRet.ClientId = $mgCS.ClientId ; 
            $oRet.TenantId = $mgCS.TenantId ; 
            $oRet.Scopes = $mgCS.Scopes ; 
            $oRet.AuthType = $mgCS.AuthType ; 
            $oRet.TokenCredentialType = $mgCS.TokenCredentialType ; 
            $oRet.CertificateThumbprint = $mgCS.CertificateThumbprint ; 
            $oRet.CertificateSubjectName = $mgCS.CertificateSubjectName ; 
            $oRet.Account = $mgCS.Account ; 
            $oRet.AppName = $mgCS.AppName ; 
            $oRet.ContextScope = $mgCS.ContextScope ; 
            $oRet.Certificate = $mgCS.Certificate ; 
            $oRet.ManagedIdentityId = $mgCS.ManagedIdentityId ; 
            $oRet.ClientSecret = $mgCS.ClientSecret ; 
            $oRet.Environment = $mgCS.Environment ; 
            $oRet.TenantAligned = if($TenantID -AND ($mgCS.TenantId -eq $TenantID)){$true | write-output }else{$false | write-output } ; 
            $oRet.isUser = if($mgCS.ClientId -AND $mgCS.AuthType -eq 'Delegated' -AND $mgCS.Account -AND $mgCS.ContextScope -eq 'CurrentUser'){$true | write-output }else{$false | write-output }; 
            $oRet.isAppOnly = if($mgCS.ClientId -AND $mgCS.AuthType -eq 'AppOnly' -AND $mgCS.AppName -AND $mgCS.ContextScope -eq 'Process'){$true | write-output }else{$false | write-output }; 
            $oRet.isCBA= if($mgCS.CertificateThumbprint -AND $mgCS.TokenCredentialType -eq 'ClientCertificate' ){$true | write-output }else{$false | write-output };                 
            $oRet.hasRequiredScopes = $null; 
            $oRet.missingScopes = $null ; 
            $oRet.isConnected = $true
            #} ; 
            #} | write-output ;
            if($RequiredScopes){
                [array]$ScopesNotFound = @() ; 
                [array]$ScopesNeeded = @() ; 
                ForEach ($Scope in $RequiredScopes){If ($Scope -notin $Context.Scopes) {$ScopesNotFound += $Scope}}
                If ($ScopesNotFound){
                    $ScopesNeeded = $ScopesNotFound -join ", "
                    $smsg = ("The following scopes are not available: {0}" -f ($ScopesNeeded -join ", "))
                    <# reconn code that would add the missing
                    Try {
                        Connect-MgGraph -Scopes $ScopesNeeded -NoWelcome -ErrorAction Stop 
                        Write-Host "Successfully connected to Graph with required scopes"
                    } Catch {
                        Write-Host "Failed to connect to Graph with required scopes"
                        Break
                    }
                    #>
                    $smsg += "`nThe following command can be run to request the missing scopes:`n Connect-MgGraph -Scopes $(($ScopesNeeded -join ',')) -NoWelcome -ErrorAction Stop" ;
                    write-warning $smsg ; 
                    $oRet.hasRequiredScopes = $false
                    $oRet.missingScopes = $ScopesNeeded ; 
                }else{
                    $oRet.hasRequiredScopes = $true
                    $oRet.missingScopes = $null ; 
                }
            }
        }else{
            $oRet.isConnected = $false            
        }
    } ; 
    END{
        [pscustomobject]$oRet | write-output ; 
    } ; 
} ; 
#*------^ test-MGConnectionTDO.ps1 ^------