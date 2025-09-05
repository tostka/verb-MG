# get-MGCodeCmdletPermissionsTDO.ps1

#region get_MGCodeCmdletPermissionsTDO ; #*------v get-MGCodeCmdletPermissionsTDO v------
#if(-not (get-childitem function:get-MGCodeCmdletPermissionsTDO -ea 0)){
    function get-MGCodeCmdletPermissionsTDO {
        <#
        .SYNOPSIS
        get-MGCodeCmdletPermissionsTDO - wrapper for verb-dev\get-codeprofileAST() that parses [verb]-MG[noun] cmdlets from a specified -file or -scriptblock, and reseolves the necessary connect-mgGraph -scope permissions, using the Find-MgGraphCommand  command.
        .NOTES
        Version     : 0.0.
        Author      : Todd Kadrie
        Website     : http://www.toddomation.com
        Twitter     : @tostka / http://twitter.com/tostka
        CreatedDate : 2024-06-07
        FileName    : get-MGCodeCmdletPermissionsTDO
        License     : MIT License
        Copyright   : (c) 2024 Todd Kadrie
        Github      : https://github.com/tostka/verb-AAD
        Tags        : Powershell,AzureAD,Authentication,Test
        AddedCredit : 
        AddedWebsite: 
        AddedTwitter: 
        REVISIONS
        * 3:49 PM 9/5/2025 FUNDEMENTAL FLAW: find-mgGraphCommand DOES NOT HAVE ALL MGGRAPH CMDLET PERMS! And it doesn't throw errors on empty perms, it just returns NOTHING
            So I coded in some low-brow post empty-perm sanity checks: If the cmd has -confim/-force/-whatif, it's likely potentially destructive. 
            If it has parameters on psScriptAnalyzer's change trigger verbv list: New, Set, Remove, Start, Stop, Restart, Reset, and Update - likewise
            Outputs a warning to manually lookup the M$ Dox Permissions table for each cmdlet.
        * 1:49 PM 5/14/2025 add: -cmdlets, bypasses AST parsing cuts right to find-mgGraphCommand expansion; additional verbose status echos (as it's returning very limited set of perms)
        * 4:37 PM 5/12/2025 retweaked expansion; found that the cmdlet name filtering wasn't working as a raw [regex], had to .tostring() the regex to get it to return more than a single item
        * 12:23 PM 5/6/2025 wrapper for verb-dev\get-codeprofileAST() that parses [verb]-MG[noun] cmdlets from a specified -file or -scriptblock, and reseolves the necessary connect-mgGraph delegated access -scope permissions, using the Find-MgGraphCommand command.
        .DESCRIPTION
        wrapper for verb-dev\get-codeprofileAST() that parses [verb]-MG[noun] cmdlets from a specified -file or -scriptblock, and reseolves the necessary connect-mgGraph -scope permissions, using the Find-MgGraphCommand command.
        .PARAMETER  File
        Path to script/module file to be parsed for matching cmdlets[-Path path-to\script.ps1]
        .PARAMETER scriptblock
        Scriptblock of code to be parsed for matching cmdlets[-scriptblock `$sbcode]
        .PARAMETER CommandFilterRegex
        Regular expression filter to match commands within GenericCommand lines parsed from subject code (defaults \w+-mg\w+)[-CommandFilterRegex '\w+-mgDomain\w+']
        .PARAMETER ModuleFilterRegex 
        Regular expression filter to match commands solely in matching Module (defaults 'Microsoft\.Graph')[-CommandFilterRegex 'Microsoft\.Graph\.Identity\.DirectoryManagement\s\s\s']
        .PARAMETER Cmdlets
        MGGraph cmdlet names to be Find-MgGraphCommand'd into delegated access -scope permissions (bypasses ASTParser discovery)
        .INPUTS
        Does not accept piped input
        .OUTPUTS
        None (records transcript file)
        .EXAMPLE
        PS> $PermsRqd = get-MGCodeCmdletPermissionsTDO -path D:\scripts\new-MGDomainRegTDO.ps1 ; 
        Typical pass script pass, using the -path param
        .EXAMPLE
        PS> $PermsRqd = get-MGCodeCmdletPermissionsTDO -scriptblock (gcm -name get-MGCodeCmdletPermissionsTDO).definition ; 
        Typical function pass, using get-command to return the definition/scriptblock for the subject function.
        .EXAMPLE
        PS> write-verbose "Typically from the BEGIN{} block of an Advanced Function, or immediately after PARAM() block" ; 
        PS> $Verbose = [boolean]($VerbosePreference -eq 'Continue') ;
        PS> $rPSCmdlet = $PSCmdlet ;
        PS> $rPSScriptRoot = $PSScriptRoot ;
        PS> $rPSCommandPath = $PSCommandPath ;
        PS> $rMyInvocation = $MyInvocation ;
        PS> $rPSBoundParameters = $PSBoundParameters ;
        PS> $pltRvEnv=[ordered]@{
        PS>     PSCmdletproxy = $rPSCmdlet ;
        PS>     PSScriptRootproxy = $rPSScriptRoot ;
        PS>     PSCommandPathproxy = $rPSCommandPath ;
        PS>     MyInvocationproxy = $rMyInvocation ;
        PS>     PSBoundParametersproxy = $rPSBoundParameters
        PS>     verbose = [boolean]($PSBoundParameters['Verbose'] -eq $true) ;
        PS> } ;
        PS> $rvEnv = resolve-EnvironmentTDO @pltRVEnv ;  
        PS> if($rvEnv.isScript){
        PS>     if($rvEnv.PSCommandPathproxy){ $prxPath = $rvEnv.PSCommandPathproxy }
        PS>     elseif($script:PSCommandPath){$prxPath = $script:PSCommandPath}
        PS>     elseif($rPSCommandPath){$prxPath = $rPSCommandPath} ; 
        PS>     $PermsRqd = get-MGCodeCmdletPermissionsTDO -Path $prxPath  ; 
        PS> } ; 
        PS> if($rvEnv.isFunc){
        PS>     $PermsRqd = get-MGCodeCmdletPermissionsTDO -Path (gcm -name $rvEnv.FuncName).definition ; 
        PS> } ; 
        Demo leveraging resolve-environmentTDO outputs
        .LINK
        https://bitbucket.org/tostka/verb-dev/
        #>  
        [CmdletBinding()]
        ## PSV3+ whatif support:[CmdletBinding(SupportsShouldProcess)]
        ###[Alias('Alias','Alias2')]
        PARAM(
            [Parameter(Position = 0,ValueFromPipeline = $true, HelpMessage = "Path to script/module file to be parsed for matching cmdlets[-Path path-to\script.ps1]")]
                [ValidateScript( {Test-Path $_})][ValidatePattern( "\.(ps1|psm1|txt)$")]
                [Alias('PSPath','File')]
                [system.io.fileinfo]$Path,
            [Parameter(Position = 1,HelpMessage = "Scriptblock of code to be parsed for matching cmdlets[-scriptblock `$sbcode]")]
                [Alias('code')]
                $scriptblock,
            [Parameter(HelpMessage = "Regular expression filter to match commands within GenericCommand lines parsed from subject code (defaults \w+-mg\w+)[-CommandFilterRegex '\w+-mgDomain\w+']")]
                [regex]$CommandFilterRegex = '\w+\-mg\w+',
            [Parameter(HelpMessage = "Regular expression filter to match commands solely in matching Module (defaults 'Microsoft\.Graph')[-CommandFilterRegex 'Microsoft\.Graph\.Identity\.DirectoryManagement\s\s\s']")]
                [regex]$ModuleFilterRegex = '^Microsoft\.Graph',
            [Parameter(HelpMessage = "MGGraph cmdlet names to be Find-MgGraphCommand'd into delegated access -scope permissions (bypasses ASTParser discovery)[-Cmdlets @('get-MgDomain','get-MGContext')]")]
                [string[]]$Cmdlets
        );  
        BEGIN {
            $Verbose = ($VerbosePreference -eq "Continue") ;
            if($Cmdlets){
                $smsg = "-Cmdlets (skipping -path/-scriptblock AST parsing)" ; 
                if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
            }else{
                TRY{
                    if(-NOT ($path -OR $scriptblock)){
                        throw "neither -Path or -Scriptblock specified: Please specify one or the other when running" ; 
                        break ; 
                    } elseif($path -AND $scriptblock){
                        throw "BOTH -Path AND -Scriptblock specified: Please specify EITHER one or the other when running" ; 
                        break ; 
                    } ;  
                    if ($Path -AND $Path.GetType().FullName -ne 'System.IO.FileInfo'){
                        $smsg = "(convert path to gci)" ; 
                        if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
                        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
                        $Path = get-childitem -path $Path ; 
                    } ;
                    if ($scriptblock -AND $scriptblock.GetType().FullName -ne 'System.Management.Automation.ScriptBlock'){
                        $smsg = "(recast -scriptblock to [scriptblock])" ; 
                        if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
                        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
                        $scriptblock= [scriptblock]::Create($scriptblock) ; 
                    } ;
                } CATCH {
                    $ErrTrapd=$Error[0] ;
                    $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                } ; 
            } ; 
        } ;
        PROCESS {
            $sw = [Diagnostics.Stopwatch]::StartNew();
            if($Cmdlets){
                $smsg = "-cmdlets specified:`n$(($Cmdlets|out-string).trim())" ;                     
            }else{
                $pltgCPA=[ordered]@{
                    erroraction = 'STOP' ;  
                    GenericCommands = $true ;               
                } ;
                if($Path){ $pltgCPA.add('Path',$Path.fullname)}
                if($ScriptBlock){ $pltgCPA.add('ScriptBlock',$ScriptBlock)}
                $smsg = "get-CodeProfileAST  w`n$(($pltgCPA|out-string).trim())" ; 
                if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
                $GCmds = (get-CodeProfileAST @pltgCPA).GenericCommands ; 
                # shouldn't need .tostring() on a regex type, but w returns full list, wo returns just 1 item.
                $GCmds.extent.text | ?{$_ -match $CommandFilterRegex.tostring()} | foreach-object {$cmdlets += $matches[0]} ; 
                $smsg = "Normalize & unique names"; 
                if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
                if($ModuleFilterRegex){
                    $cmdlets = $cmdlets | select -unique | foreach-object { 
                        get-command -name $_| ?{$_.source -match $ModuleFilterRegex} 
                    } | select -expand name | select -unique ;         
                }else {
                    $cmdlets = $cmdlets | foreach-object { 
                        get-command -name $_| select -expand name 
                    } | select -unique ;
                }
                $smsg = "Parsed following matching cmdlets:`n$(($cmdlets|out-string).trim())" ;   
            } ;               
            if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
            write-host -foregroundcolor yellow "Resolving $($cmdlets.count) cmdlets against Find-MgGraphCommand..." ; 
            $PermsRqd = @() ;         
            write-host -foregroundcolor yellow "[" -nonewline ; 
            $cmdlets |foreach-object{
                $thisCmdlet = $_ ; 
                $smsg = "$($thisCmdlet)" ; 
                if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
                write-host -NoNewline '.' ; 
                $thisCommand = get-command -Name $thisCmdlet -EA STOP
                #$PermsRqd += Find-MgGraphCommand -command $thisCmdlet -ea 0| Select -First 1 -ExpandProperty Permissions | Select -Unique name ; 
                $thisPerm = $null ; 
                $thisPerm = Find-MgGraphCommand -command $thisCmdlet -ea 0| Select -First 1 -ExpandProperty Permissions | Select -Unique name ; 
                if($thisPerm){
                    $PermsRqd += $thisPerm ; 
                    $smsg = "(Find-MgGraphCommand -command $($thisCmdlet) returned Permissions:`n$(($thisPerm -join ','|out-string).trim()))" ; 
                }else {
                    $smsg = "($($Cmdlet):no Permissions returned (by Microsoft.Graph.Authentication\Find-MgGraphCommand())" ; 
                    <# 11:27 AM 9/5/2025 issues: Find-MgGraphCommand IS MISSING A TON OF CMDLET PERMS!
                    remove-mgdomain is clearly destructive, but returns no permissions in the cmd:

                    [How to get all Graph API permissions required to run selected code using PowerShell](https://doitpshway.com/how-to-get-all-graph-api-permissions-required-to-run-selected-code-using-powershell)
                    Drawbacks ( to relying on Find-MgGraphCommand):
                    * Official command Find-MgGraphCommand is used to translate command/URI calls to required permissions, 
                            doesn't contain permissions for all commands/URIs (but this will be hopefully solved in the future)
                    * Returns all permissions that can be used, not just the least one (but I am trying to solve this on my own)
                    * URIs passed via parameter splatting or through variables aren't detected right now
                    * but you will be notified about such issue, so you can solve this manually       
                    
                    built deps etc for: Get-CodeGraphPermissionRequirement
                    and ran it: much more code, same garbage output:
                    #-=-=-=-=-=-=-=-=
                    VERBOSE: 'remove-mgdomain' doesn't need any permissions?!                        

                    simple test on noperms:
                    - does it have -confirm|-force|-whatif support? => implies it's potentially destructive, and shouuld require *some* kind of perms, throw an error back
                    #>
                    $riskParams = @() ; 
                    $rgxShouldProcParams = 'confirm|force|whatif'
                    if($hasShouldProcParams = $thisCommand.parameters.keys -match $rgxShouldProcParams){
                        $riskParams = @($hasShouldProcParams)
                        $smsg += "`nBUT!:$($thisCmdlet) has following risk-reflecting parameters:$($hasShouldProcParams -join ',') " ; ; 
                    } ; 
                    $verbsPSUseShouldProcessForStateChangingFunctions = @('New','Set','Remove','Start','Stop','Restart','Reset','and Update') ; 
                    $rgxverbsPSUseShouldProcessForStateChangingFunctions = [regex]$rgx = ('(' + (($verbsPSUseShouldProcessForStateChangingFunctions |%{[regex]::escape($_)}) -join '|') + ')') ;
                    if($StateChgParams = $thisCommand.parameters.keys -match $rgxverbsPSUseShouldProcessForStateChangingFunctions){
                        $riskParams = $(@($riskParams);@($StateChgParams)) ; 
                        $smsg += "`nBUT!:$($thisCmdlet) has following ShouldProcessForStateChanging parameters:$($riskparams -join ',') " ; ; 
                    } ; 
                    if($riskParams){
                        $smsg += "`nFind-MgGraphCommand null Permissions return is likely *WRONG*: you should search for the doc page for:$($thisCmdlet), and manually assemble the connect-mgGraph -scope array from those specifications." ;
                        $smsg += "`n(Find the Description: Permissions table, for the *accurate* perms for the cmdlet)" ;
                    } ; 
                } ; 
                if($riskParams){
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN -Indent} 
                    else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                }else{
                    if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
                } ; 
            } ; 
            write-host -foregroundcolor yellow "]" ; 
            $PermsRqd = $PermsRqd.name | select -unique ;
        } ; # PROC-E  
        END {
            $sw.Stop() ;
            $smsg = ("Elapsed Time: {0:dd}d {0:hh}h {0:mm}m {0:ss}s {0:fff}ms" -f $sw.Elapsed) ; 
            if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
            if($PermsRqd){
                $PermsRqd | write-output ; 
                $smsg = "(Resolved Perm Names:" ; 
                #$smsg += "`n$((|out-string).trim())" ; 
                $smsg += "`n'$(($PermsRqd) -join "','")'" ; 
                $smsg += "`nCan be cached into a `$MGPermissionsScope etc, to skip this lengthy -scope discovery process)" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
            } else { 
                $false | write-output 
            } ; 
        } ; # END-E
    } ; 
#} ; 
#endregion get_MGCodeCmdletPermissionsTDO ; #*------^ END get-MGCodeCmdletPermissionsTDO ^------