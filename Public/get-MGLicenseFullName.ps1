# get-MGLicenseFullName.ps1


#*------v Function get-MGLicenseFullName v------
function get-MGLicenseFullName {
<#
    .SYNOPSIS
    get-MGLicenseFullName - Resolve an AzureAD License object's 'SkuPartNumber' to a friendly name ('Full Name')
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     :	http://www.toddomation.com
    Twitter     :	@tostka / http://twitter.com/tostka
    CreatedDate : 2022-
    FileName    : 
    License     : MIT License
    Copyright   : (c) 2022 Todd Kadrie
    Github      : https://github.com/tostka/verb-XXX
    Tags        : Powershell
    AddedCredit : Robert Prust (powershellpr0mpt)
    AddedWebsite: https://powershellpr0mpt.com
    AddedTwitter:
    REVISIONS    
    * 9:16 AM 1/6/2026 port from vaad\get-AADLicenseFullName() -> vmg\get-MGLicenseFullName
    * 12:56 PM 3/24/2022 flipped unresolved items to notation in verbose - there's too many on a regular basis to throw visible errors in outputs ; 
      spliced in some missing in our Tenant (where could document) ; init
    .DESCRIPTION
    get-MGLicenseFullName - Resolve an AzureAD License object's 'SkuPartNumber' to a friendly name ('Full Name')
    Simple indexed hash of AzureAD 'SkuPartNumber's mapping to a more lengthy common description of the license purpose
    .PARAMETER Name
    'Name' or 'SkuPartNumber' of an AzureAD License object (as returned by AzureAD: Get-AzureADSubscribedSku cmdlet)[-Name EXCHANGESTANDARD]
    .EXAMPLE
    PS> get-MGLicenseFullName -Name 'VISIOCLIENT'
    Resolve the SkuPartNumber 'VISIOCLIENT' to the equivelent descriptive name
    .LINK
    https://github.com/powershellpr0mpt/PSP-Office365/blob/master/PSP-Office365/public/Get-Office365License.ps1
    https://github.com/tostka/verb-MG
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [Alias('SkuPartNumber')]
        [string[]]$Name
    )
    BEGIN{
        ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
        $verbose = ($VerbosePreference -eq "Continue") ; 
        
        # https://docs.microsoft.com/en-us/azure/active-directory/users-groups-roles/licensing-service-plan-reference
        # [Product names and service plan identifiers for licensing in Azure Active Directory | Microsoft Docs](https://docs.microsoft.com/en-us/azure/active-directory/users-groups-roles/licensing-service-plan-reference)

        <# whatis an F1 lic: Office 365 F1 is designed to enable Firstline Workers to do their best work.
        Office 365 F1 provides easy-to-use tools and services to help these workers
        easily create, update, and manage schedules and tasks, communicate and work
        together, train and onboard, and quickly receive company news and announcements.
        #>

        # updating sort via text: gc c:\tmp\list.txt | sort ;
        $Skus = [ordered]@{
            "AAD_BASIC"                          = "Azure Active Directory Basic"
            "AAD_PREMIUM"                        = "Azure Active Directory Premium"
            "ATA"                                = "Advanced Threat Analytics"
            "ATP_ENTERPRISE"                     = "Exchange Online Advanced Threat Protection"
            "BI_AZURE_P1"                        = "Power BI Reporting and Analytics"
            "CRMIUR"                             = "CMRIUR"
            "CRMPLAN2"                           = "MICROSOFT DYNAMICS CRM ONLINE BASIC"
            "CRMSTANDARD"                        = "Microsoft Dynamics CRM Online Professional"
            "DEFENDER_ENDPOINT_P1" =  ""
            "DESKLESSPACK"                       = "Office 365 (Plan K1)"
            "DESKLESSPACK_GOV"                   = "Microsoft Office 365 (Plan K1) for Government"
            "DESKLESSWOFFPACK"                   = "Office 365 (Plan K2)"
            "DEVELOPERPACK"                      = "OFFICE 365 ENTERPRISE E3 DEVELOPER"
            "DYN365_CUSTOMER_INSIGHTS_ATTACH" =  ""
            "DYN365_CUSTOMER_INSIGHTS_BASE" = ""
            "DYN365_ENTERPRISE_CUSTOMER_SERVICE" = "DYNAMICS 365 FOR CUSTOMER SERVICE ENTERPRISE EDITION"
            "DYN365_ENTERPRISE_P1_IW"            = "Dynamics 365 P1 Trial for Information Workers"
            "DYN365_ENTERPRISE_PLAN1"            = "Dynamics 365 Customer Engagement Plan Enterprise Edition"
            "DYN365_ENTERPRISE_SALES"            = "Dynamics Office 365 Enterprise Sales"
            "DYN365_ENTERPRISE_SALES_CUSTOMERSERVICE" = "DYNAMICS 365 FOR SALES AND CUSTOMER SERVICE ENTERPRISE EDITION"
            "DYN365_ENTERPRISE_TEAM_MEMBERS"     = "Dynamics 365 For Team Members Enterprise Edition"
            "DYN365_FINANCIALS_BUSINESS_SKU"     = "Dynamics 365 for Financials Business Edition"
            "DYN365_FINANCIALS_TEAM_MEMBERS_SKU" = "Dynamics 365 for Team Members Business Edition"
            "DYNAMICS_365_FOR_OPERATIONS"        = "DYNAMICS 365 UNF OPS PLAN ENT EDITION"
            "ECAL_SERVICES"                      = "ECAL"
            "EMS"                                = "Enterprise Mobility Suite"
            "EMSPREMIUM"                         = "ENTERPRISE MOBILITY + SECURITY E5"
            "ENTERPRISEPACK"                     = "Enterprise Plan E3"
            "ENTERPRISEPACK_B_PILOT"             = "Office 365 (Enterprise Preview)"
            "ENTERPRISEPACK_FACULTY"             = "Office 365 (Plan A3) for Faculty"
            "ENTERPRISEPACK_GOV"                 = "Microsoft Office 365 (Plan G3) for Government"
            "ENTERPRISEPACK_STUDENT"             = "Office 365 (Plan A3) for Students"
            "ENTERPRISEPACK_USGOV_DOD"           = "Office 365 E3_USGOV_DOD"
            "ENTERPRISEPACK_USGOV_GCCHIGH"       = "Office 365 E3_USGOV_GCCHIGH"
            "ENTERPRISEPACKLRG"                  = "Enterprise Plan E3"
            "ENTERPRISEPREMIUM"                  = "Enterprise E5 (with Audio Conferencing)"
            "ENTERPRISEPREMIUM_NOPSTNCONF"       = "Enterprise E5 (without Audio Conferencing)"
            "ENTERPRISEWITHSCAL"                 = "Enterprise Plan E4"
            "ENTERPRISEWITHSCAL_FACULTY"         = "Office 365 (Plan A4) for Faculty"
            "ENTERPRISEWITHSCAL_GOV"             = "Microsoft Office 365 (Plan G4) for Government"
            "ENTERPRISEWITHSCAL_STUDENT"         = "Office 365 (Plan A4) for Students"
            "EOP_ENTERPRISE_FACULTY"             = "Exchange Online Protection for Faculty"
            "EQUIVIO_ANALYTICS"                  = "Office 365 Advanced eDiscovery"
            "ESKLESSWOFFPACK_GOV"                = "Microsoft Office 365 (Plan K2) for Government"
            "EXCHANGE_L_STANDARD"                = "Exchange Online (Plan 1)"
            "EXCHANGE_S_ARCHIVE_ADDON_GOV"       = "Exchange Online Archiving"
            "EXCHANGE_S_DESKLESS"                = "Exchange Online Kiosk"
            "EXCHANGE_S_DESKLESS_GOV"            = "Exchange Kiosk"
            "EXCHANGE_S_ENTERPRISE_GOV"          = "Exchange Plan 2G"
            "EXCHANGE_S_ESSENTIALS"              = "Exchange Online Essentials   "
            "EXCHANGE_S_STANDARD_MIDMARKET"      = "Exchange Online (Plan 1)"
            "EXCHANGEARCHIVE"                    = "EXCHANGE ONLINE ARCHIVING FOR EXCHANGE SERVER"
            "EXCHANGEARCHIVE_ADDON"              = "Exchange Online Archiving For Exchange Online"
            "EXCHANGEDESKLESS"                   = "Exchange Online Kiosk"
            "EXCHANGEENTERPRISE"                 = "Exchange Online Plan 2"
            "EXCHANGEENTERPRISE_GOV"             = "Microsoft Office 365 Exchange Online (Plan 2) only for Government"
            "EXCHANGEESSENTIALS"                 = "Exchange Online Essentials"
            "EXCHANGESTANDARD"                   = "Office 365 Exchange Online Only"
            "EXCHANGESTANDARD_GOV"               = "Microsoft Office 365 Exchange Online (Plan 1) only for Government"
            "EXCHANGESTANDARD_STUDENT"           = "Exchange Online (Plan 1) for Students"
            "EXCHANGETELCO"                      = "EXCHANGE ONLINE POP"
            "FLOW_FREE"                          = "Microsoft Flow Free"
            "FLOW_P1"                            = "Microsoft Flow Plan 1"
            "FLOW_P2"                            = "Microsoft Flow Plan 2"
            "FLOW_PER_USER" = "Power Automate per user plan"
            "FORMS_PRO" =  "Dynamics 365 Customer Voice Trial"
            "Forms_Pro_USL" =  "Dynamics 365 Customer Voice USL"
            "IDENTITY_THREAT_PROTECTION"           = "IDENTITY AND THREAT PROTECTION"
            "INTUNE_A"                           = "Windows Intune Plan A"
            "IT_ACADEMY_AD"                      = "MS IMAGINE ACADEMY"
            "LITEPACK"                           = "Office 365 (Plan P1)"
            "LITEPACK_P2"                        = "Office 365 Small Business Premium"
            "M365_F1"                            = "Microsoft 365 F1"
            "MCOEV"                              = "Microsoft Phone System"
            "MCOIMP"                             = "SKYPE FOR BUSINESS ONLINE (PLAN 1)"
            "MCOLITE"                            = "Lync Online (Plan 1)"
            "MCOMEETACPEA"                       = "Pay Per Minute Audio Conferencing"
            "MCOMEETADD"                         = "Audio Conferencing"
            "MCOMEETADV"                         = "PSTN conferencing"
            "MCOPSTN1"                           = "Domestic Calling Plan (3000 min US / 1200 min EU plans)"
            "MCOPSTN2"                           = "International Calling Plan"
            "MCOPSTN5"                           = "Domestic Calling Plan (120 min calling plan)"
            "MCOPSTN6"                           = "Domestic Calling Plan (240 min calling plan) Note: Limited Availability"
            "MCOPSTNC"                           = "Communications Credits"
            "MCOPSTNPP"                          = "Communications Credits"
            "MCOSTANDARD"                        = "Skype for Business Online Standalone Plan 2"
            "MCOSTANDARD_GOV"                    = "Lync Plan 2G"
            "MCOSTANDARD_MIDMARKET"              = "Lync Online (Plan 1)"
            "MEETING_ROOM" =  "Microsoft Teams Rooms Standard"
            "MFA_PREMIUM"                        = "Azure Multi-Factor Authentication"
            "MIDSIZEPACK"                        = "Office 365 Midsize Business"
            "MS_TEAMS_IW"                        = "Microsoft Teams Trial"
            "O365_BUSINESS"                      = "Office 365 Business"
            "O365_BUSINESS_ESSENTIALS"           = "Office 365 Business Essentials"
            "O365_BUSINESS_PREMIUM"              = "Office 365 Business Premium"
            "OFFICE_PRO_PLUS_SUBSCRIPTION_SMBIZ" = "Office ProPlus"
            "OFFICESUBSCRIPTION"                 = "Office ProPlus"
            "OFFICESUBSCRIPTION_GOV"             = "Office ProPlus"
            "OFFICESUBSCRIPTION_STUDENT"         = "Office ProPlus Student Benefit"
            "PBI_PREMIUM_P1_ADDON" =  "Power BI Premium P1"
            "PLANNERSTANDALONE"                  = "Planner Standalone"
            "POWER_BI_ADDON"                     = "Office 365 Power BI Addon"
            "POWER_BI_INDIVIDUAL_USE"            = "Power BI Individual User"
            "POWER_BI_PRO"                       = "Power BI Pro"
            "POWER_BI_STANDALONE"                = "Power BI Stand Alone"
            "POWER_BI_STANDARD"                  = "Power-BI Standard"
            "POWERAPPS_DEV" =  "Microsoft Power Apps for Developer"
            "POWERAPPS_INDIVIDUAL_USER" = "POWERAPPS AND LOGIC FLOWS"
            "POWERAPPS_PER_APP" =  "PowerApps per app baseline access"
            "POWERAPPS_PER_APP_IW" =  "PowerApps per app baseline access"
            "POWERAPPS_VIRAL"                    = "Microsoft Power Apps & Flow"
            "PROJECT_MADEIRA_PREVIEW_IW_SKU"     = "Dynamics 365 for Financials for IWs"
            "PROJECTCLIENT"                      = "Project Professional"
            "PROJECTESSENTIALS"                  = "Project Lite"
            "PROJECTONLINE_PLAN_1"               = "Project Online"
            "PROJECTONLINE_PLAN_2"               = "Project Online and PRO"
            "PROJECTPREMIUM"                     = "Project Online Premium"
            "PROJECTPROFESSIONAL"                = "Project Professional"
            "PROJECTWORKMANAGEMENT"              = "Office 365 Planner Preview"
            "RIGHTSMANAGEMENT"                   = "Rights Management"
            "RIGHTSMANAGEMENT_ADHOC"             = "Windows Azure Rights Management"
            "RMS_S_ENTERPRISE"                   = "Azure Active Directory Rights Management"
            "RMS_S_ENTERPRISE_GOV"               = "Windows Azure Active Directory Rights Management"
            "RMSBASIC"                           = "RMS BASIC"
            "SHAREPOINTDESKLESS"                 = "SharePoint Online Kiosk"
            "SHAREPOINTDESKLESS_GOV"             = "SharePoint Online Kiosk"
            "SHAREPOINTENTERPRISE"               = "Sharepoint Online (Plan 2)"
            "SHAREPOINTENTERPRISE_GOV"           = "SharePoint Plan 2G"
            "SHAREPOINTENTERPRISE_MIDMARKET"     = "SharePoint Online (Plan 1)"
            "SHAREPOINTLITE"                     = "SharePoint Online (Plan 1)"
            "SHAREPOINTSTANDARD"                 = "Sharepoint Online (Plan 1)"
            "SHAREPOINTSTORAGE"                  = "SharePoint storage"
            "SHAREPOINTWAC"                      = "Office Online"
            "SHAREPOINTWAC_GOV"                  = "Office Online for Government"
            "SMB_APPS" =  "Business Apps (free)"
            "SMB_BUSINESS"                       = "Microsoft 365 Apps For Business"
            "SMB_BUSINESS_ESSENTIALS"            = "Microsoft 365 Business Basic       "
            "SMB_BUSINESS_PREMIUM"               = "Microsoft 365 Business Standard"
            "SPB"                                = "Microsoft 365 Business Premium"
            "SPE_E3"                             = "Microsoft 365 E3"
            "SPE_E3_USGOV_DOD"                   = "Microsoft 365 E3_USGOV_DOD"
            "SPE_E3_USGOV_GCCHIGH"               = "Microsoft 365 E3_USGOV_GCCHIGH"
            "SPE_E5"                             = "Microsoft 365 E5"
            "SPE_F1"                             = "Office 365 F1"
            "SPZA_IW"                            = "App Connect"
            "STANDARD_B_PILOT"                   = "Office 365 (Small Business Preview)"
            "STANDARDPACK"                       = "Enterprise Plan E1"
            "STANDARDPACK_FACULTY"               = "Office 365 (Plan A1) for Faculty"
            "STANDARDPACK_GOV"                   = "Microsoft Office 365 (Plan G1) for Government"
            "STANDARDPACK_STUDENT"               = "Office 365 (Plan A1) for Students"
            "STANDARDWOFFPACK"                   = "Office 365 (Plan E2)"
            "STANDARDWOFFPACK_FACULTY"           = "Office 365 Education E1 for Faculty"
            "STANDARDWOFFPACK_GOV"               = "Microsoft Office 365 (Plan G2) for Government"
            "STANDARDWOFFPACK_IW_FACULTY"        = "Office 365 Education for Faculty"
            "STANDARDWOFFPACK_IW_STUDENT"        = "Office 365 Education for Students"
            "STANDARDWOFFPACK_STUDENT"           = "Microsoft Office 365 (Plan A2) for Students"
            "STANDARDWOFFPACKPACK_FACULTY"       = "Office 365 (Plan A2) for Faculty"
            "STANDARDWOFFPACKPACK_STUDENT"       = "Office 365 (Plan A2) for Students"
            "STREAM"                             = "MICROSOFT STREAM"
            "TEAMS_COMMERCIAL_TRIAL"             = "Teams Commercial Trial"
            "TEAMS_EXPLORATORY"                  = "Teams Exploratory"
            "VIDEO_INTEROP"                      = "Polycom Skype Meeting Video Interop for Skype for Business"
            "VISIOCLIENT"                        = "Visio Pro Online"
            "VISIOONLINE_PLAN1"                  = "Visio Online Plan 1"
            "WACONEDRIVEENTERPRISE"              = "ONEDRIVE FOR BUSINESS (PLAN 2)"
            "WACONEDRIVESTANDARD"                = "ONEDRIVE FOR BUSINESS (PLAN 1)"
            "WIN10_PRO_ENT_SUB"                  = "WINDOWS 10 ENTERPRISE E3"
            "WIN10_VDA_E5"                       = "Windows 10 Enterprise E5"
            "WINDOWS_STORE"                      = "Windows Store for Business"
            "YAMMER_ENTERPRISE"                  = "Yammer for the Starship Enterprise"
            "YAMMER_MIDSIZE"                     = "Yammer"
        } ;



        <# 12:32 PM 3/24/2022 missing entries:
WARNING: 12:31:24:Unable to resolve 'DYN365_CUSTOMER_INSIGHTS_BASE' to this function's static list of name mappings
(function may require an update to accomodate this new(?) license)
WARNING: 12:31:24:Unable to resolve 'POWERAPPS_INDIVIDUAL_USER' to this function's static list of name mappings
(function may require an update to accomodate this new(?) license)
WARNING: 12:31:24:Unable to resolve 'FLOW_PER_USER' to this function's static list of name mappings
(function may require an update to accomodate this new(?) license)
WARNING: 12:31:24:Unable to resolve 'Forms_Pro_USL' to this function's static list of name mappings
(function may require an update to accomodate this new(?) license)
WARNING: 12:31:24:Unable to resolve 'POWERAPPS_PER_APP_IW' to this function's static list of name mappings
(function may require an update to accomodate this new(?) license)
WARNING: 12:31:24:Unable to resolve 'DYN365_CUSTOMER_INSIGHTS_ATTACH' to this function's static list of name mappings
(function may require an update to accomodate this new(?) license)
WARNING: 12:31:24:Unable to resolve 'PBI_PREMIUM_P1_ADDON' to this function's static list of name mappings
(function may require an update to accomodate this new(?) license)
WARNING: 12:31:24:Unable to resolve 'FORMS_PRO' to this function's static list of name mappings
(function may require an update to accomodate this new(?) license)
WARNING: 12:31:24:Unable to resolve 'MEETING_ROOM' to this function's static list of name mappings
(function may require an update to accomodate this new(?) license)
WARNING: 12:31:24:Unable to resolve 'SMB_APPS' to this function's static list of name mappings
(function may require an update to accomodate this new(?) license)
WARNING: 12:31:24:Unable to resolve 'POWERAPPS_PER_APP' to this function's static list of name mappings
(function may require an update to accomodate this new(?) license)
WARNING: 12:31:24:Unable to resolve 'DEFENDER_ENDPOINT_P1' to this function's static list of name mappings
(function may require an update to accomodate this new(?) license)
WARNING: 12:31:24:Unable to resolve 'POWERAPPS_DEV' to this function's static list of name mappings
(function may require an update to accomodate this new(?) license)
#>
    } ; 
    PROCESS {
        $Error.Clear() ;
        $ttl = ($Name|  measure ).count ;  
        $procd = 0 ; 
        foreach ($SkuPartNumber in $Name) {
            $procd ++ ; 
            <#$sBnrS="`n#*------v $(${CmdletName}): PROCESSING ($($procd)/$($ttl)): $($SkuPartNumber) v------" ; 
            $smsg = $sBnrS ; 
            if($silent){} elseif ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            $smsg = "" ; 
            if($silent){} elseif($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
            #>
            if($FullName = $Skus[$SkuPartNumber.toupper()]){
                $smsg = "Resolved '$($Name)' => $($FullName)" ; 
                if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
                $FullName  | write-output ; 
            } else { 
                $smsg = "Unable to resolve '$($Name)' to this function's static list of name mappings (function may require an update to accomodate this new(?) license)" ; 
                #if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } 
                #else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
            } ; 
            <#
            $smsg = $sBnrS.replace('-v','-^').replace('v-','^-')
            if($silent){} elseif ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            #>
        } ; # loop-E
    } 
    END {
    
    } ; 
}
#*------^ END Function get-MGLicenseFullName ^------
