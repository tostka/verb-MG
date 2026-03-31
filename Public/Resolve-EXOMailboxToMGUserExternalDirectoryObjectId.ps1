# Resolve-EXOMailboxToMGUserExternalDirectoryObjectId.ps1

#region RESOLVE_MGUSERTOADUSERHARDMATCH ; #*------v Resolve-EXOMailboxToMGUserExternalDirectoryObjectId v------
Function Resolve-EXOMailboxToMGUserExternalDirectoryObjectId{
    <#
    .SYNOPSIS
    Resolve-EXOMailboxToMGUserExternalDirectoryObjectId - Resolves and Exchange Online Mailbox object (or it's ExternalDirectoryObjectId guid) to the linked MGUser
    .NOTES
    Version     : 0.0.1
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2026-03-31
    FileName    : Resolve-EXOMailboxToMGUserExternalDirectoryObjectId.ps1
    License     : MIT License
    Copyright   : (c) 2026 Todd Kadrie
    Github      : https://github.com/tostka/verb-mg
    Tags        : Powershell,MicrosoftGraph,User,HardMatch,ImmutableID
    AddedCredit : REFERENCE
    AddedWebsite: URL
    AddedTwitter: URL
    REVISIONS
    * 12:50 PM 3/31/2026init
    .DESCRIPTION
    Resolve-EXOMailboxToMGUserExternalDirectoryObjectId - Resolves and Exchange Online Mailbox object (or it's ExternalDirectoryObjectId guid) to the linked MGUser

    Represents the actual low-level linked objects, rather than those with the same UPN or other descriptor (where Hybrid Conflicts may result in multiple splitbrain mailboxes respectively on ADUser and MGUser).

    .PARAMETER InputObject
    MGUser object or MGUser.OnPremisesImmutableId string to be converted to ADUser ImmutableID/ObjectGuid[-InputObject `$myMGUser]
    .INPUTS
    Accepts piped input
    .OUTPUTS
    Microsoft.ActiveDirectory.Management.ADUser
    .EXAMPLE
    PS> $xoMbx = get-xomailbox TARGETUPN ; 
    PS> $mgu = $XOmBX | Resolve-EXOMailboxToMGUserExternalDirectoryObjectId ;     
    Pipeline demo
    .EXAMPLE
    PS> $mgu = Get-MgUser -user TARGETUPN -prop onPremisesImmutableId,userprincipalname,id ; 
    PS> Resolve-EXOMailboxToMGUserExternalDirectoryObjectId -inputobject $mgu; 
    Commandline demo MGUser input    
    .LINK
    https://github.com/tostka/verb-MG
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'HIGH')]
    [Alias('Resolve-EXOMailboxToMGUser')]
    PARAM(        
        [Parameter(Mandatory=$True,Position=0,ValueFromPipeline = $True,HelpMessage="Exchange Online Mailbox object (or it's ExternalDirectoryObjectId guid string) to be resolved to matching MGUser object[-InputObject `$myExoMailbox]")]
            $InputObject
    ) ;
    TRY{
        switch -regex ($InputObject.gettype().fullname){
            'System\.Management\.Automation\.PSObject|System\.Collections\.Hashtable|System\.Management\.Automation\.PSCustomObject'{                
                if($InputObject.ExternalDirectoryObjectId){
                    $InputObject = $InputObject.ExternalDirectoryObjectId 
                }else{
                    if($InputObject.ExternalDirectoryObjectId -eq $null){
                        $smsg = "Mailbox.ExternalDirectoryObjectId: `$null:"                         
                    }elseif($InputObject.ExternalDirectoryObjectId -eq $false){
                        $smsg = "Mailbox.ExternalDirectoryObjectId:`$false" ; 
                    } ELSE{
                            $smsg += "`nand has a NULL OnPremisesSyncEnabled" ;
                            $smsg = "-> Get-MgUser command DIDN'T SPECIFY REQUIRED -Property ExternalDirectoryObjectId TO RETURN WORKING PROPERTIES FOR THIS CALL!" ;                         
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
            if($Mgu = Get-MgUser -userid $InputObject){
                $Mgu| write-output  ; 
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
#endregion RESOLVE_MGUSERTOADUSERHARDMATCH ; #*------^ END Resolve-EXOMailboxToMGUserExternalDirectoryObjectId ^------