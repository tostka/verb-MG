# get-MGOPLastSync.ps1

#*------v get-MGOPLastSync.ps1 v------
Function get-MGOPLastSync {
  <#
    .SYNOPSIS
    get-MGOPLastSync - Get-MgOrganization last AD-AAD sync (Microsoft.Graph)
    .NOTES
    Version     : 0.0.
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2025-12-29
    FileName    : get-MGOPLastSync.ps1
    License     : MIT License
    Copyright   : (c) 2025 Todd Kadrie
    Github      : https://github.com/tostka/verb-MG
    Tags        : Powershell,MicrosoftGraph,Tenant,ADSync,OnPremLastSync
    AddedCredit : REFERENCE
    AddedWebsite: URL
    AddedTwitter: URL    
    REVISIONS   :
    * 4:03 PM 12/29/2025 port to Microsoft.Graph, as AAD and Msol are now DEAD 🖕😠 WASTE MY TIME SOME MORE!
    * 3:50 PM 6/21/2022 as MicrosoftOnline MSOL module is wrecked/deprecated with MFA mandates, retool this to use AAD: (Get-AzureADTenantDetail).CompanyLastDirSyncTime
    * 4:08 PM 7/24/2020 added full multi-ten cred support
    * 1:03 PM 5/27/2020 moved alias: get-MsolLastSync win func
    * 9:51 AM 2/25/2020 condenced output
    * 8:50 PM 1/12/2020 expanded aliases
    * 9:17 AM 10/9/2018 get-MGOPLastSync:simplified the collection, and built a Cobj returned in GMT & local timezone
    * 12:30 PM 11/3/2017 initial version
    .DESCRIPTION
    get-MGOPLastSync - Get-MgOrganization last AD-AAD sync (Microsoft.Graph)    
    .INPUTS
    None. Does not accepted piped input.
    .OUTPUTS
    Returns an object with LastDirSyncTime, expressed as TimeGMT & TimeLocal
    .EXAMPLE
    PS> $lastsync = get-mgoplastsync
    PS> $lastsync ; 

            TimeGMT               TimeLocal            
            -------               ---------            
            12/29/2025 9:45:33 PM 12/29/2025 3:45:33 PM

    .LINK
    https://github.com/tostka/verb-MG
    #>
    # #Requires -Modules Microsoft.Graph
    [CmdletBinding()]
    #[Alias('get-MsolLastSync')]
    Param(
        #[Parameter()]$Credential = $global:credo365TORSID
        # no supported cred param
    ) ;
    $verbose = ($VerbosePreference -eq "Continue") ; 
    <#
    try { Get-MsolAccountSku -ErrorAction Stop | out-null }
    catch [Microsoft.Online.Administration.Automation.MicrosoftOnlineException] {
      "Not connected to MSOnline. Now connecting to $($credo365.username.split('@')[1])." ;
      $MFA = get-TenantMFARequirement -Credential $Credential ;
      if($MFA){ Connect-MsolService }
      else {Connect-MsolService -Credential $Credential ;}
    } ;
    #>
    Connect-MgGraph -Scopes "Organization.Read.All" -NoWelcome # suppress the banner, or it dumps it into the pipeline!
    #$LastDirSyncTime = (Get-MsolCompanyInformation).LastDirSyncTime ;
    #$LastDirSyncTime = (Get-AzureADTenantDetail).CompanyLastDirSyncTime ;
    $LastDirSyncTime = Get-MgOrganization | select -expand OnPremisesLastSyncDateTime
    New-Object PSObject -Property @{
      TimeGMT   = $LastDirSyncTime  ;
      TimeLocal = $LastDirSyncTime.ToLocalTime() ;
    } | write-output ;
}

#*------^ get-MGOPLastSync.ps1 ^------