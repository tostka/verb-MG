# Resolve-MGUserToADUserHardmatch.ps1

#region RESOLVE_MGUSERTOADUSERHARDMATCH ; #*------v Resolve-MGUserToADUserHardmatch v------
Function Resolve-MGUserToADUserHardmatch{
    <#
    .SYNOPSIS
    Resolve-MGUserToADUserHardmatch - ResolvesMGUser to hardmatched ADUser, via conversion of MGUser.OnPremisesImmutableId to equivelent ADUser.ObjectGuid value
    .NOTES
    Version     : 0.0.1
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2026-03-31
    FileName    : Resolve-MGUserToADUserHardmatch.ps1
    License     : MIT License
    Copyright   : (c) 2026 Todd Kadrie
    Github      : https://github.com/tostka/verb-mg
    Tags        : Powershell,MicrosoftGraph,User,HardMatch,ImmutableID
    AddedCredit : REFERENCE
    AddedWebsite: URL
    AddedTwitter: URL
    REVISIONS
    9:15 AM 3/31/2026 init
    .DESCRIPTION
    Resolve-MGUserToADUserHardmatch - ResolvesMGUser to hardmatched ADUser, via conversion of MGUser.OnPremisesImmutableId to equivelent ADUser.ObjectGuid value
    
    Extension of verb-mb\Convert-MGUserOnPremisesImmutableIdToADUserObjectGuid that appends trailing get-aduser to the end, and returns the matching ADUser object (rather than the converted immutable string)
    
    .PARAMETER InputObject
    MGUser object or MGUser.OnPremisesImmutableId string to be converted to ADUser ImmutableID/ObjectGuid[-InputObject `$myMGUser]
    .INPUTS
    Accepts piped input
    .OUTPUTS
    Microsoft.ActiveDirectory.Management.ADUser
    .EXAMPLE
    PS> $mgu = Get-MgUser -user TARGETUPN -prop onPremisesImmutableId,userprincipalname,id ; 
    PS> $mgu | Resolve-MGUserToADUserHardmatch ;     
    Pipeline demo
    .EXAMPLE
    PS> $mgu = Get-MgUser -user TARGETUPN -prop onPremisesImmutableId,userprincipalname,id ; 
    PS> Resolve-MGUserToADUserHardmatch -inputobject $mgu; 
    Commandline demo MGUser input    
    .LINK
    https://github.com/tostka/verb-MG
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'HIGH')]
    PARAM(        
        [Parameter(Mandatory=$True,Position=0,ValueFromPipeline = $True,HelpMessage="MGUser object or MGUser.OnPremisesImmutableId string to be converte to ADUser ImmutableID/ObjectGuid[-InputObject `$myMGUser]")]
            $InputObject
    ) ;
    TRY{
        switch -regex ($InputObject.gettype().fullname){
            'Microsoft.Graph.PowerShell.Models.MicrosoftGraphUser|System.Collections.Hashtable|System.Management.Automation.PSCustomObject'{
                <#
                switch ($InputObject.OnPremisesSyncEnabled) {
                    $true  { "Directory-synced user" }
                    $false { "Cloud-only user" }
                    $null  { "Property not returned (query incomplete)" } # not accurate in our Tenant: bulk of cloud-firsts have $null, not $false
                }
                #>
                if($InputObject.onPremisesImmutableId){
                    $InputObject = $InputObject.onPremisesImmutableId 
                }else{
                    if($InputObject.onPremisesImmutableId -eq $null){
                        $smsg = "MGUser object -eq `$null:" 
                        $smsg += "`n EITHER: *lacks* populated onPremisesImmutableId!`n(Get-MgUser command DIDN'T SPECIFY REQUIRED -Property 'onPremisesImmutableId' to return working properties for this call)" ;
                        $smsg += "`n OR: UNSET CLOUD-FIRST OBJECT (8408 cloud-1st mgus 03-2026 had `$null, only 5 had `$false)" ;
                    }elseif($InputObject.onPremisesImmutableId -eq $false){
                        $smsg = "MGUser object onPremisesImmutableId:`$false! EXPLICIT CLOUD-FIRST OBJECT!" ; 
                    } ELSE{
                            $smsg += "`nand has a NULL OnPremisesSyncEnabled" ;
                            $smsg = "-> Get-MgUser command DIDN'T SPECIFY REQUIRED -Property onPremisesImmutableId TO RETURN WORKING PROPERTIES FOR THIS CALL!" ;                         
                    }; 
                    WRITE-WARNING  $SMSG
                }
            }
            'System.String'{
                #if($InputObject = [guid]$InputObject){}
            }
            default{
                $smsg = "UNRECOGNIZED -inputobject type:$($InputObject.gettype().fullname)" ; 
                $smsg += "`nPlease specify an ADUser object, or a Guid value" ;
                write-warning $smsg ;
                #throw $smsg ; 
            }
        }
        if($InputObject.gettype().fullname -eq 'System.String'){
            if($guid=New-Object -TypeName guid (,[System.Convert]::FromBase64String($InputObject))){
                #$guid.guid | write-output 
                $ImmutGuid = $guid
                if($ADUser = get-aduser -id $ImmutGuid.guid ){
                    $ADUser | write-output  ; 
                }else{
                    $false | write-output 
                } ; 
            } else { $false | write-output }
        } else { $false | write-output }
    }CATCH {        
        $ErrTrapd=$Error[0] ;
        write-host -foregroundcolor gray "TargetCatch:} CATCH [$($ErrTrapd.Exception.GetType().FullName)] {"  ;
        $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
        write-warning "$($smsg)" ;
    }
} ;
#endregion RESOLVE_MGUSERTOADUSERHARDMATCH ; #*------^ END Resolve-MGUserToADUserHardmatch ^------