# Convert-MGUserOnPremisesImmutableIdToADUserObjectGuid.ps1

#region CONVERT_MGUSERONPREMISESIMMUTABLEIDTOADUSEROBJECTGUID ; #*------v Convert-MGUserOnPremisesImmutableIdToADUserObjectGuid v------
Function Convert-MGUserOnPremisesImmutableIdToADUserObjectGuid{
    <#
    .SYNOPSIS
    Convert-MGUserOnPremisesImmutableIdToADUserObjectGuid - Converts passed MGUser object (or OnPremisesImmutableId string) into equivelent ImmutableID/ADUser.ObjectGuid value
    .NOTES
    Version     : 0.0.1
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2026-03-27
    FileName    : Convert-MGUserOnPremisesImmutableIdToADUserObjectGuid.ps1
    License     : MIT License
    Copyright   : (c) 2026 Todd Kadrie
    Github      : https://github.com/tostka/verb-mg
    Tags        : Powershell,MicrosoftGraph,User,HardMatch,ImmutableID
    AddedCredit : REFERENCE
    AddedWebsite: URL
    AddedTwitter: URL
    REVISIONS
    * 11:51 AM 3/31/2026 revised fail logic - OnpremImuutableID empty/$False/$null (whether cloud-first or not returned on mgu qry, is unqualified; no docs on defaults).
    * 11:51 AM 3/27/2026 init
    .DESCRIPTION
    Convert-MGUserOnPremisesImmutableIdToADUserObjectGuid - Converts passed MGUser object (or OnPremisesImmutableId string) into equivelent ImmutableID/ADUser.ObjectGuid value
    
    .PARAMETER InputObject
    MGUser object or MGUser.OnPremisesImmutableId string to be converted to ADUser ImmutableID/ObjectGuid[-InputObject `$myMGUser]
    .INPUTS
    Accepts piped input
    .OUTPUTS
    System.String
    .EXAMPLE
    PS> $mgu = Get-MgUser -user TARGETUPN -prop onPremisesImmutableId,userprincipalname,id ; 
    PS> $ImmutGuid = $mgu.onPremisesImmutableId | Convert-MGUserOnPremisesImmutableIdToADUserObjectGuid ; 
    PS> $adu = get-aduser -id $ImmutGuid.guid ; 
    Pipeline demo
    .EXAMPLE
    PS> $mgu = Get-MgUser -user TARGETUPN -prop onPremisesImmutableId,userprincipalname,id ; 
    PS> Convert-MGUserOnPremisesImmutableIdToADUserObjectGuid -inputobject $mgu; 
    Commandline demo MGUser input
    .EXAMPLE
    PS> $mgu = Get-MgUser -user TARGETUPN -prop onPremisesImmutableId,userprincipalname,id ; 
    PS> Convert-MGUserOnPremisesImmutableIdToADUserObjectGuid -inputobject $mgu.onPremisesImmutableId ; 
    Commandline demo Guid input
    .EXAMPLE
    PS> $mgu = Get-MgUser -user TARGETUPN -prop onPremisesImmutableId,userprincipalname,id ; 
    PS> Convert-MGUserOnPremisesImmutableIdToADUserObjectGuid -inputobject $mgu.onPremisesImmutableId.tostring() ; 
    Commandline demo string input
    .LINK
    https://github.com/tostka/verb-MG
    #>
    [CmdletBinding()]
    [alias('Convert-MGUserToADUser')]
    PARAM(        
        [Parameter(Mandatory=$True,ValueFromPipeline = $True,HelpMessage="MGUser object or MGUser.OnPremisesImmutableId string to be converte to ADUser ImmutableID/ObjectGuid[-InputObject `$myMGUser]")]
            $InputObject
    ) ;
    TRY{
        switch -regex ($InputObject.gettype().fullname){
            'Microsoft\.Graph\.PowerShell\.Models\.MicrosoftGraphUser|System\.Collections\.Hashtable|System\.Management\.Automation\.PSCustomObject'{
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
            'System\.String'{
                #if($InputObject = [guid]$InputObject){}
            }
            default{
                $smsg = "UNRECOGNIZED -inputobject type:$($InputObject.gettype().fullname)" ; 
                $smsg += "`nPlease specify an ADUser object, or a Guid value" ;
                write-warning $smsg ;
                throw $smsg ; 
            }
        }
        if($InputObject.gettype().fullname -eq 'System.String'){
            if($guid=New-Object -TypeName guid (,[System.Convert]::FromBase64String($InputObject))){
                $guid.guid | write-output                 
            } else { $false | write-output }
        } else { $false | write-output }
    }CATCH {        
        $ErrTrapd=$Error[0] ;
        write-host -foregroundcolor gray "TargetCatch:} CATCH [$($ErrTrapd.Exception.GetType().FullName)] {"  ;
        $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
        write-warning "$($smsg)" ;
    }
} ;
#endregion CONVERT_MGUSERONPREMISESIMMUTABLEIDTOADUSEROBJECTGUID ; #*------^ END Convert-MGUserOnPremisesImmutableIdToADUserObjectGuid ^------