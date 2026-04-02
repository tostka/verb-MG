# Convert-ADUserObjectGuidToImmutableID.ps1

#region CONVERT_ADUSEROBJECTGUIDTOIMMUTABLEID ; #*------v Convert-ADUserObjectGuidToImmutableID v------
Function Convert-ADUserObjectGuidToImmutableID{
    <#
    .SYNOPSIS
    Convert-ADUserObjectGuidToImmutableID - Converts passed ADUser object (or ObjectGuid string) into equivelent ImmutableID/MGUser.OnPremisesImmutableId value
    .NOTES
    Version     : 0.0.1
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2026-03-27
    FileName    : Convert-ADUserObjectGuidToImmutableID.ps1
    License     : MIT License
    Copyright   : (c) 2026 Todd Kadrie
    Github      : https://github.com/tostka/verb-mg
    Tags        : Powershell,MicrosoftGraph,User,HardMatch,ImmutableID
    AddedCredit : REFERENCE
    AddedWebsite: URL
    AddedTwitter: URL
    REVISIONS
    * 11:13 AM 3/27/2026 init
    .DESCRIPTION
    Convert-ADUserObjectGuidToImmutableID - Converts passed ADUser object (or ObjectGuid string) into equivelent ImmutableID/MGUser.OnPremisesImmutableId value
    
    .PARAMETER InputObject
    ADUser object or ADUser.ObjectGuid string to be converte to cloud ImmutableID[-InputObject `$myADUser]
    .INPUTS
    Accepts piped input
    .OUTPUTS
    System.String
    .EXAMPLE
    PS> $adu = get-aduser -id SAMACCOUNTNAME ;
    PS> $MguOPImmut = $adu.objectguid | Convert-ADUserObjectGuidToImmutableID ; 
    PS> $mgUser = Get-MgUser -Filter "onPremisesImmutableId eq '$MguOPImmut'"
    Pipeline demo
    .EXAMPLE
    PS> $adu = get-aduser -id SAMACCOUNTNAME ;
    PS> Convert-ADUserObjectGuidToImmutableID -inputobject $adu; 
    Commandline demo ADUser input
    .EXAMPLE
    PS> $adu = get-aduser -id SAMACCOUNTNAME ;
    PS> Convert-ADUserObjectGuidToImmutableID -inputobject $adu.objectguid ; 
    Commandline demo Guid input
    .EXAMPLE
    PS> $adu = get-aduser -id SAMACCOUNTNAME ;
    PS> Convert-ADUserObjectGuidToImmutableID -inputobject $adu.objectguid.tostring() ; 
    Commandline demo string input
    .LINK
    https://github.com/tostka/verb-MG
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'HIGH')]
    PARAM(        
        [Parameter(Mandatory=$True,ValueFromPipeline = $True,HelpMessage="ADUser object or ADUser.ObjectGuid string to be converte to cloud ImmutableID[-InputObject `$myADUser]")]
            $InputObject
    ) ;
    TRY{
        switch -regex ($InputObject.gettype().fullname){
            'Microsoft\.ActiveDirectory\.Management\.ADUser|System\.Collections\.Hashtable|System\.Management\.Automation\.PSCustomObject'{
                if($InputObject.objectguid){$InputObject = $InputObject.objectguid }
            }
            'System\.Guid'{
                if($InputObject.guid){}
            }
            'System\.String'{
                if($InputObject = [guid]$InputObject){}
            }
            default{
                $smsg = "UNRECOGNIZED -inputobject type:$($InputObject.gettype().fullname)" ; 
                $smsg += "`nPlease specify an ADUser object, or a Guid value" ;
                write-warning $smsg ;
                throw $smsg ; 
            }
        }
        if($OpImmutableId = [System.Convert]::ToBase64String($InputObject.ToByteArray())){
            $OpImmutableId| write-output 
        } else { $false | write-output }
    }CATCH {        
        $ErrTrapd=$Error[0] ;
        write-host -foregroundcolor gray "TargetCatch:} CATCH [$($ErrTrapd.Exception.GetType().FullName)] {"  ;
        $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
        write-warning "$($smsg)" ;
    }
} ;
#endregion CONVERT_ADUSEROBJECTGUIDTOIMMUTABLEID ; #*------^ END Convert-ADUserObjectGuidToImmutableID ^------