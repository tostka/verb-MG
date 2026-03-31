# Resolve-ADUserToMGUserHardmatch.ps1.ps1

#region RESOLVE_ADUSERTOMGUSERHARDMATCH ; #*------v Resolve-ADUserToMGUserHardmatch v------
Function Resolve-ADUserToMGUserHardmatch{
    <#
    .SYNOPSIS
    Resolve-ADUserToMGUserHardmatch - Resolves ADUser to hardmatched MGUser, via conversion of ADUser.ObjectGuid to equivelent MGUser.OnPremisesImmutableId value
    .NOTES
    Version     : 0.0.1
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2026-03-27
    FileName    : Resolve-ADUserToMGUserHardmatch.ps1
    License     : MIT License
    Copyright   : (c) 2026 Todd Kadrie
    Github      : https://github.com/tostka/verb-mg
    Tags        : Powershell,MicrosoftGraph,User,HardMatch,ImmutableID
    AddedCredit : REFERENCE
    AddedWebsite: URL
    AddedTwitter: URL
    REVISIONS
    * 11:54 AM 3/31/2026 init
    .DESCRIPTION
    Resolve-ADUserToMGUserHardmatch - Resolves ADUser to hardmatched MGUser, via conversion of ADUser.ObjectGuid to equivelent MGUser.OnPremisesImmutableId value
    
    Extension of verb-mb\Convert-ADUserObjectGuidToImmutableID that appends trailing get-mguser to the end, and returns the matching mgUser object (rather than the converted immutable string)

    .PARAMETER InputObject
    ADUser object or ADUser.ObjectGuid string to be converte to cloud ImmutableID[-InputObject `$myADUser]
    .INPUTS
    Accepts piped input
    .OUTPUTS
    Microsoft.Graph.PowerShell.Models.MicrosoftGraphUser
    .EXAMPLE
    PS> $adu = get-aduser -id SAMACCOUNTNAME ;
    PS> $adu | Resolve-ADUserToMGUserHardmatch ; 
    Pipeline demo
    .EXAMPLE
    PS> $adu = get-aduser -id SAMACCOUNTNAME ;
    PS> Resolve-ADUserToMGUserHardmatch -inputobject $adu; 
    Commandline demo ADUser input    
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
            'Microsoft.ActiveDirectory.Management.ADUser|System.Collections.Hashtable|System.Management.Automation.PSCustomObject'{
                if($InputObject.objectguid){$InputObject = $InputObject.objectguid }
            }
            'System.Guid'{
                if($InputObject.guid){}
            }
            'System.String'{
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
            #$OpImmutableId| write-output             
            if($mgUser = Get-MgUser -Filter "onPremisesImmutableId eq '$OpImmutableId'"){
                $mgUser  | write-output  ; 
            }else{
                $false | write-output 
            } ; 
        } else { $false | write-output }
    }CATCH {        
        $ErrTrapd=$Error[0] ;
        write-host -foregroundcolor gray "TargetCatch:} CATCH [$($ErrTrapd.Exception.GetType().FullName)] {"  ;
        $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
        write-warning "$($smsg)" ;
    }
} ;
#endregion RESOLVE_ADUSERTOMGUSERHARDMATCH ; #*------^ END Resolve-ADUserToMGUserHardmatch ^------