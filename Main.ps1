# Importing Scripts
. .\Logging\Log.ps1
. .\Telemetry\Telemetry.ps1
. .\Utilities\ValidatePrerequisites.ps1
. .\Reporting\Reporting.ps1

# Global Variables: 
[DateTime] $global:StartTime = $(Get-Date)
# Has Error ocurred
[bool] $global:ErrorOccurred = $false
# Has window closed with title bar
[bool] $global:WindowClosed = $false
# App Name & Directory
[string] $global:AppNameShortHand = "eDiscShift"
[string] $global:AppName = "eDiscoveryShift"
[string] $global:AppDirectory = "Microsoft\$global:AppName"


#UI's
[Array] $global:ViewsUI = @("Welcome.psm1", "CaseSelection.psm1", "ReviewSelection.psm1")


class Mediator {
    [string] $CaseAppendText
    [bool] $IsAllMigrationSelected
    [bool] $IsIndividualMigrationSelected


    Mediator() {
        $this.CaseAppendText = ""
        $this.IsAllMigrationSelected = $false
        $this.IsIndividualMigrationSelected = $false
    }
    
}

class ReportStats {
    [string] $DomainName
    [string] $OrgName
    $SelectedCases
    $MigratedCases
    $FailedCases
    $PartiallyMigratedCases
    [int] $ElapsedSeconds


    ReportStats() {
        $this.DomainName = ""
        $this.OrgName = ""
        $this.SelectedCases = 0
        $this.MigratedCases = 0
        $this.FailedCases = 0
        $this.PartiallyMigratedCases = 0
        $this.ElapsedSeconds = 0
    }
    
}

class CoreCase {
    [string] $CaseName
    [string] $CaseId
    [string] $Description
    [string] $LinkURL
    [string] $LinkText 
    [bool] $IsMigrationEnabled
    [bool] $IsDeletionEnabled
    [string] $LogFile
    [bool]$IsMigrated
    

    #ExecuteCommandlets() {}
}

class CoreHold {
    [string] $CoreCaseName
    [string] $PolicyName 
    [string] $PolicyDescription 
    [string] $RuleName 
    [string] $RuleDescription 
    [string] $Query 
    [string] $LogFile
}

function Get-AppDirectory {
    <#

        Gets or creates the PMT directory in AppData
        
    #>
    If ($IsWindows) {
        $Directory = "$($env:LOCALAPPDATA)\$global:AppDirectory"
    }
    elseif ($IsLinux -or $IsMac) {
        $Directory = "$($env:HOME)/$global:AppName"
    }
    else {
        $Directory = "$($env:LOCALAPPDATA)\$global:AppDirectory"
    }
	
    If (Test-Path $Directory) {
        Return $Directory
    } 
    else {
        mkdir $Directory | out-null
        Return $Directory
    }
}

function Start-Migration {
    <#

        .SYNOPSIS
            eDiscovery Shift 

        .DESCRIPTION
            eDiscovery Shift

        .PARAMETER TurnOffDataCollection 
            Disables data collection. It can be used by users who wish to turn off data collection by Microsoft. Turning it off 
            will delete the UserConsent file present in the output Report folder and ultimately will not consider acceptance in 
            further running instance of the tool. 
    #>
    Param(
        [CmdletBinding()]
        [Switch]$TurnOffDataCollection
    )

    $OutputDirectoryName = Get-AppDirectory;

    if (($TurnOffDataCollection -eq $true) -and ($(Test-Path -Path "$OutputDirectoryName\UserConsent.txt" -PathType Leaf) -eq $true)) {
        Remove-Item "$OutputDirectoryName\UserConsent.txt"
    }
    $TelemetryEnabled = (Test-Path -Path "$OutputDirectoryName\UserConsent.txt" -PathType Leaf) -and ($(Get-Content "$OutputDirectoryName\UserConsent.txt") -ieq "Yes")
    if ($TelemetryEnabled -eq $false) {
        $cntOfIterations = 1
        Write-Host "Data Collection: The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft's privacy statement. Our privacy statement is located at https://go.microsoft.com/fwlink/?LinkID=824704. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices." -ForegroundColor Yellow
        while ($cntOfIterations -lt 3) {
            Write-Host "Do you accept(Y/N):" -NoNewline -ForegroundColor Yellow
            $telemetryConsent = Read-Host -ErrorAction:SilentlyContinue
            $telemetryConsent = $telemetryConsent.Trim()
            if (($telemetryConsent -ieq "y") -or ($telemetryConsent -ieq "yes")) {
                if (Test-Path -Path "$OutputDirectoryName\UserConsent.txt" -PathType Leaf) {
                    Remove-Item "$OutputDirectoryName\UserConsent.txt"
                }
                New-Item "$OutputDirectoryName\UserConsent.txt" | Out-Null
                Set-Content "$OutputDirectoryName\UserConsent.txt" 'Yes' 
                break
            }
            elseif (($telemetryConsent -ieq "n") -or ($telemetryConsent -ieq "no")) {
                break
            }
            Write-Host "Invalid input! Please try again." -ForegroundColor Red
            $cntOfIterations += 1
        }
        if ($cntOfIterations -eq 3) {
            return
        }
    }

    # Creating the log folder & timestamped log for each running instance
    $LogDirectory = "$OutputDirectoryName\Logs"
    $FileName = "$($global:AppNameShortHand)-$(Get-Date -Format 'yyyyMMddHHmmss').log"
    $LogFile = "$LogDirectory\$FileName"
    
    if ($(Test-Path -Path $LogDirectory) -eq $false) {
        New-Item -Path $LogDirectory -ItemType Directory -ErrorAction:SilentlyContinue | Out-Null
        New-Item -Path $LogFile -ItemType File -ErrorAction:SilentlyContinue | Out-Null
    }
    else {
        New-Item -Path $LogFile -ItemType File -ErrorAction:SilentlyContinue | Out-Null
    }

    # Check if log file exists
    if ($(Test-Path -Path $LogFile) -eq $False) {
        Write-Host "$(Get-Date) Log file cannot be created." -ForegroundColor:Red
    }
    Write-Log -MachineInfo -LogFile $LogFile -ErrorAction:SilentlyContinue

    try {
        Invoke-eDiscoveryShift -LogFile $LogFile -ErrorAction:SilentlyContinue
        $InfoMessage = "Complete! Log file is in $LogFile" 
        Write-Log -IsInfo -InfoMessage $InfoMessage -LogFile $LogFile -ErrorAction:SilentlyContinue
        Write-Host "$(Get-Date) $InfoMessage" -ForegroundColor Yellow
        Write-Log -StopInfo -LogFile $LogFile -ErrorAction:SilentlyContinue
    }
    catch {
        Write-Host "Error:$(Get-Date) There was an issue in running the tool. Please try running the tool again after some time. Log file is in $LogFile." -ForegroundColor:Red
        $ErrorMessage = $_.ToString()
        $StackTraceInfo = $_.ScriptStackTrace
        Write-Log -IsError -ErrorMessage $ErrorMessage -StackTraceInfo $StackTraceInfo -LogFile $LogFile -ErrorAction:SilentlyContinue
            
    }
    try {
        Disconnect-ExchangeOnline -Confirm:$false -ErrorAction:SilentlyContinue
        Disconnect-MgGraph -Confirm:$false -ErrorAction:SilentlyContinue
    }
    catch {
        
    }
}

function Invoke-eDiscoveryShift {
    Param(
        [CmdletBinding()]
        [String]$LogFile
    )
    $InfoMessage = "eDiscovery Shift started"
    Write-Host "$(Get-Date) $InfoMessage"
    Write-Log -IsInfo -InfoMessage $InfoMessage -LogFile $LogFile -ErrorAction:SilentlyContinue

    # Validate prerequisites
    $InfoMessage = "Prerequisites validation initiated"
    Write-Host "$(Get-Date) $InfoMessage"
    Write-Log -IsInfo -InfoMessage $InfoMessage -LogFile $LogFile -ErrorAction:SilentlyContinue
    Confirm-Prerequisites -LogFile $LogFile;
    $InfoMessage = "Prerequisites validation completed"
    Write-Host "$(Get-Date) $InfoMessage"
    Write-Log -IsInfo -InfoMessage $InfoMessage -LogFile $LogFile -ErrorAction:SilentlyContinue

    #Invoke connections
    $InfoMessage = "Establishing Connection"
    Write-Host "$(Get-Date) $InfoMessage"
    Write-Log -IsInfo -InfoMessage $InfoMessage -LogFile $LogFile -ErrorAction:SilentlyContinue
    Invoke-eDiscoveryConnections -LogFile $LogFile
    $InfoMessage = "Connection Established"
    Write-Host "$(Get-Date) $InfoMessage"
    Write-Log -IsInfo -InfoMessage $InfoMessage -LogFile $LogFile -ErrorAction:SilentlyContinue

    #Fetch Cases
    $InfoMessage = "Getting Core Compliance Cases"
    Write-Host "$(Get-Date) $InfoMessage"
    Write-Log -IsInfo -InfoMessage $InfoMessage -LogFile $LogFile -ErrorAction:SilentlyContinue
    $CoreCasesArray = Get-eDiscoveryCoreCases -LogFile $LogFile


    $ReportStatsObj = Create-eDiscoveryCases -CoreCasesArray $CoreCasesArray -LogFile $LogFile  

    #If Telemetry is enabled (For Customers), then collect telemetry
    $OutputDirectoryName = Get-AppDirectory;
    if ((Test-Path -Path "$OutputDirectoryName\UserConsent.txt" -PathType Leaf) -and ($(Get-Content "$OutputDirectoryName\UserConsent.txt") -ieq "Yes")) {
        
        Send-Telemetry -LogFile $LogFile -DataCollectionParameter $ReportStatsObj 
    }
}

function Invoke-eDiscoveryConnections {
    Param
    (
        [String]$LogFile
    )

    try
    {
        $InfoMessage = "Checking for Exchange Online Management module..."
        Write-Host "$(Get-Date) $InfoMessage"
        Write-Log -IsInfo -InfoMessage $InfoMessage -LogFile $LogFile -ErrorAction:SilentlyContinue
        $ExchangeVersion = (Get-InstalledModule -name "ExchangeOnlineManagement" -ErrorAction:SilentlyContinue | Sort-Object Version -Desc)[0].Version
    }
    catch
    {
        $ExchangeVersion = "Error"
        $InfoMessage = "Exchange Online Management module is not installed. Installing.."
        Write-Host "$(Get-Date) $InfoMessage"
        Write-Log -IsInfo -InfoMessage $InfoMessage -LogFile $LogFile -ErrorAction:SilentlyContinue
        try
        {
            Install-Module -Name "ExchangeOnlineManagement" -force -Scope CurrentUser 
        }
        catch
        {
            $InfoMessage = "Issue faced while installing Exchange Online Management module."
            Write-Log -IsInfo -InfoMessage $InfoMessage -LogFile $LogFile -ErrorAction:SilentlyContinue
        }
    }

    if ($ExchangeVersion -eq "Error") 
    {
        $ExchangeVersion = (Get-InstalledModule -name "ExchangeOnlineManagement" -ErrorAction:SilentlyContinue | Sort-Object Version -Desc)[0].Version
    }
    if ("$ExchangeVersion" -lt "2.0.3") 
    {
        $InfoMessage = "Your Exchange Online Management module is not updated. Updating.."
        Write-Host "$(Get-Date) $InfoMessage"
        Write-Log -IsInfo -InfoMessage $InfoMessage -LogFile $LogFile -ErrorAction:SilentlyContinue
        Install-Module -Name "ExchangeOnlineManagement -Scope CurrentUser -RequiredVersion 2.0.3" 
    }

    try
    {
        $InfoMessage = "Checking for Microsoft Graph (Compliance) module..."
        Write-Host "$(Get-Date) $InfoMessage"
        Write-Log -IsInfo -InfoMessage $InfoMessage -LogFile $LogFile -ErrorAction:SilentlyContinue
        $GraphModule = Get-InstalledModule Microsoft.Graph.Compliance
    }
    catch
    {
        $ExchangeVersion = "Error"
        $InfoMessage = "Microsoft Graph (Compliance) module is not installed. Installing.."
        Write-Host "$(Get-Date) $InfoMessage"
        Write-Log -IsInfo -InfoMessage $InfoMessage -LogFile $LogFile -ErrorAction:SilentlyContinue
        try
        {
            Install-Module -Name "Microsoft.graph.compliance" -force 
        }
        catch
        {
            $InfoMessage = "Issue faced while installing Microsoft Graph (Compliance) module."
            Write-Log -IsInfo -InfoMessage $InfoMessage -LogFile $LogFile -ErrorAction:SilentlyContinue
        }
    }
        

    try {      
        $userName = Read-Host -Prompt 'Input the user name' -ErrorAction:SilentlyContinue
        $InfoMessage = "Connecting to Security & Compliance Center"
        Write-Host "$(Get-Date) $InfoMessage"
        Write-Log -IsInfo -InfoMessage $InfoMessage -LogFile $LogFile -ErrorAction:SilentlyContinue
        Connect-IPPSSession -UserPrincipalName $userName -ErrorAction:SilentlyContinue -WarningAction:SilentlyContinue     
    }
    catch {
        Write-Host "Error:$(Get-Date) There was an issue in connecting to Security & Compliance Center. Please try running the tool again after some time." -ForegroundColor:Red
        $ErrorMessage = $_.ToString()
        $StackTraceInfo = $_.ScriptStackTrace
        Write-Log -IsError -ErrorMessage $ErrorMessage -StackTraceInfo $StackTraceInfo -LogFile $LogFile -ErrorAction:SilentlyContinue  
        throw 'There was an issue in connecting to Security & Compliance Center. Please try running the tool again after some time.'
    }
    try {
        $InfoMessage = "Connecting to Exchange Online"
        Write-Host "$(Get-Date) $InfoMessage"
        Write-Log -IsInfo -InfoMessage $InfoMessage -LogFile $LogFile -ErrorAction:SilentlyContinue
        Connect-ExchangeOnline -Prefix EXOP -UserPrincipalName $userName -ShowBanner:$false -ErrorAction:SilentlyContinue -WarningAction:SilentlyContinue
    }
    catch {
        Write-Host "Error:$(Get-Date) There was an issue in connecting to Exchange Online. Please try running the tool again after some time." -ForegroundColor:Red
        $ErrorMessage = $_.ToString()
        $StackTraceInfo = $_.ScriptStackTrace
        Write-Log -IsError -ErrorMessage $ErrorMessage -StackTraceInfo $StackTraceInfo -LogFile $LogFile -ErrorAction:SilentlyContinue
    }
    try {
        $InfoMessage = "Trying to connect to Microsoft Graph..."
        Write-Host "$(Get-Date) $InfoMessage"
        $GA = Read-Host -Prompt 'Press Y to login using Global Admin credentials(Default is N) ' -ErrorAction:SilentlyContinue
        if($GA -eq 'Y')
        {
            $InfoMessage = "Connecting to Microsoft Graph"
            Write-Host "$(Get-Date) $InfoMessage"
            Write-Log -IsInfo -InfoMessage $InfoMessage -LogFile $LogFile -ErrorAction:SilentlyContinue
            Connect-MgGraph -Scopes "Group.ReadWrite.All,eDiscovery.ReadWrite.All" -ErrorAction:SilentlyContinue -WarningAction:SilentlyContinue
        }
        else {
            $AA = Read-Host -Prompt 'Press Y to login using App credentials(Default is N)  ' -ErrorAction:SilentlyContinue
            if($AA -eq 'Y')
            {
                $clientId = Read-Host -Prompt 'Input the ClientId' -ErrorAction:SilentlyContinue
                $tenantId = Read-Host -Prompt 'Input the TenantId' -ErrorAction:SilentlyContinue
                $certificateThumbprint = Read-Host -Prompt 'Input the Certificate Thumbprint' -ErrorAction:SilentlyContinue
                
                $InfoMessage = "Connecting to Microsoft Graph using app credentials..."
                Write-Host "$(Get-Date) $InfoMessage"
                Connect-MgGraph -ClientID $clientId -TenantId $tenantId -CertificateThumbprint $certificateThumbprint
                
                Start-Sleep -s 15
            }
            else
            {
                Write-Host "Error:$(Get-Date) Please restart the tool and login to MgGraph to use the tool." -ForegroundColor:Red       
            }
        }

       
        Select-MgProfile -Name "beta"
    }
    catch {
        Write-Host "Error:$(Get-Date) There was an issue in connecting to Microsoft Graph. Please try running the tool again after some time." -ForegroundColor:Red
        $ErrorMessage = $_.ToString()
        $StackTraceInfo = $_.ScriptStackTrace
        Write-Log -IsError -ErrorMessage $ErrorMessage -StackTraceInfo $StackTraceInfo -LogFile $LogFile -ErrorAction:SilentlyContinue
    }
}


function Invoke-Views {
    Param
    (
        $CoreCasesObj,
        [String]$LogFile
    )

    [Mediator]$MediatorObj = new-object -TypeName Mediator


    Import-Module "$PSScriptRoot\Views\$($global:ViewsUI[0])"
    Start-WelcomeUI 
    if($global:WindowClosed -eq $true)
    {
        throw 
    }

    Import-Module "$PSScriptRoot\Views\$($global:ViewsUI[1])"
    Start-CaseSelectionUI -MediatorObj $MediatorObj -CoreCasesObj $CoreCasesObj
    if($global:WindowClosed -eq $true)
    {
        throw 
    }

    if($($MediatorObj.IsAllMigrationSelected) -eq $true)
    {
        foreach ($CoreCase in $CoreCasesObj) {
            
            $CoreCase.IsMigrationEnabled = $true 
        }
    }

    $FirstReviewedCoreCaseObj = @()
    foreach ($CoreCase in $CoreCasesObj) {
            
        if($CoreCase.IsMigrationEnabled -eq $true)
        {
            $FirstReviewedCoreCaseObj += $CoreCase
        }
    }


    $SecondReviewedCoreCaseObj = @()
    Import-Module "$PSScriptRoot\Views\$($global:ViewsUI[2])"
    Start-ReviewSelectionUI -MediatorObj $MediatorObj -CoreCasesObj $FirstReviewedCoreCaseObj

    if($global:WindowClosed -eq $true)
    {
        throw 
    }

    foreach ($CoreCase in $FirstReviewedCoreCaseObj) {
            
        if($CoreCase.IsDeletionEnabled -eq $false)
        {
            $SecondReviewedCoreCaseObj += $CoreCase
        }
    }

    return $SecondReviewedCoreCaseObj
}

function Get-eDiscoveryCoreCasesHolds {
    Param
    (
        $CaseName,
        [String]$LogFile
    )
    $CoreCaseHoldsArray = @()

    try {
       
        #Fetch Holds
        $InfoMessage = "Getting Core Compliance Case Holds"
        Write-Host "$(Get-Date) $InfoMessage"
        Write-Log -IsInfo -InfoMessage $InfoMessage -LogFile $LogFile -ErrorAction:SilentlyContinue
        $CoreCaseHoldsArray = Get-CaseHoldPolicy -case "$CaseName" -DistributionDetail
        
    }
    catch {
        Write-Host "Error:$(Get-Date) There was an issue in fetching Core Compliance Case Holds. Please try running the tool again after some time." -ForegroundColor:Red
        $ErrorMessage = $_.ToString()
        $StackTraceInfo = $_.ScriptStackTrace
        Write-Log -IsError -ErrorMessage $ErrorMessage -StackTraceInfo $StackTraceInfo -LogFile $LogFile -ErrorAction:SilentlyContinue
    }
    return $CoreCaseHoldsArray
}

function Get-eDiscoveryCoreCases {
    Param
    (
        [String]$LogFile
    )

    $CoreCasesArray = @()

    try {
        $CoreCasesArray = Get-ComplianceCase -ErrorAction:SilentlyContinue | Where-Object {$_.CaseType -eq "eDiscovery"}
    }
    catch {
        Write-Host "Error:$(Get-Date) There was an issue in fetching Core Compliance Cases. Please try running the tool again after some time." -ForegroundColor:Red
        $ErrorMessage = $_.ToString()
        $StackTraceInfo = $_.ScriptStackTrace
        Write-Log -IsError -ErrorMessage $ErrorMessage -StackTraceInfo $StackTraceInfo -LogFile $LogFile -ErrorAction:SilentlyContinue
    }
    return $CoreCasesArray
}

function Create-eDiscoveryCases {
    Param
    (
        $CoreCasesArray,
        [String]$LogFile
    )

    $CoreCasesObj = @()

    # Load individual check definitions
    $CaseFiles = Get-ChildItem "$PSScriptRoot\Migration"
    
    $IsCoreCasesPresent = $false
    
    ForEach ($CaseFile in $CaseFiles) {

        if ($CaseFile.BaseName -match '^Create-(.*)$') {
            if ($matches[1] -eq "Case") { 
                Write-Verbose "Importing $($matches[1])" 
                . $CaseFile.FullName | Out-Null

                foreach ($case in $CoreCasesArray) {
                    $CoreCase = New-Object -TypeName $matches[1]($case.Name, $case.Identity, $case.Description, "https://compliance.microsoft.com/classicediscovery/v1/$($case.Identity)")
                    $CoreCase.LogFile = $LogFile
                    $CoreCasesObj += $CoreCase
                    $IsCoreCasesPresent = $true
                }
            }
        }
    }

    if($IsCoreCasesPresent -eq $false)
    {
        Absent-CaseStats -LogFile $LogFile
        return
    }

    [array]$UpdatedCoreCaseObj = Invoke-Views -CoreCasesObj $CoreCasesObj -LogFile $LogFile 

    #Migration with stats computation
    if($($UpdatedCoreCaseObj.Count) -eq 0)
    {
        Absent-CaseStats -LogFile $LogFile
        return
    }

    $SelectedCases = 0
    $MigratedCases = 0
    $FailedCases = 0
    $PartialMigratedHolds = 0
    $CompletelyMigratedHolds = 0
    $NotMigratedHolds = 0

    $MigratedCoreCases = @()
    $InfoMessage = "Case Migration Started"
    Write-Log -IsInfo -InfoMessage $InfoMessage -LogFile $LogFile -ErrorAction:SilentlyContinue
    foreach ($CoreCase in $UpdatedCoreCaseObj) 
    {
        $countOfHold = 0
        if($($CoreCase.IsDeletionEnabled) -eq $false)
        {
            $SelectedCases += 1
            [bool] $IsMigrated = $CoreCase.ExecuteCommandlets();
            if($IsMigrated -eq $true)
            {
                $MigratedCases += 1
                $MigratedCoreCases += $CoreCase

                $Holds = Get-eDiscoveryCoreCasesHolds -CaseName $CoreCase.CaseName -LogFile $CoreCase.LogFile
                foreach($hold in $Holds)
                {
                    $countOfHold += 1
                }

                $AdvCaseId = $CoreCase.AdvancedCaseId

                $NewHoldObj = @()
                $IsHoldPresent = $false
        
                $CaseFiles = Get-ChildItem "$PSScriptRoot\Migration"
                ForEach ($CaseFile in $CaseFiles) 
                {
                    if ($CaseFile.BaseName -match '^Create-(.*)$') 
                    {
                        if ($matches[1] -eq "Hold") 
                        { 
                            Write-Verbose "Importing $($matches[1])" 
                            . $CaseFile.FullName | Out-Null
    
                            foreach ($HoldData in $Holds) 
                            {
                                $NewHold = New-Object -TypeName $matches[1]($CoreCase.CaseName,$HoldData.Name,$HoldData.Comment,[array]$HoldData.ExchangeLocation.Name,[array]$HoldData.SharePointLocation.Name,[array]$HoldData.PublicFolderLocation)
                                $NewHold.LogFile = $CoreCase.LogFile
                                $NewHoldObj += $NewHold
                                $IsHoldPresent = $true
                            }
                        }
                    }
                }

                if(($IsHoldPresent -eq $true) -and ($countOfHold -eq 1))
                {
                    $HasHoldMigrationFailed = $false
                    foreach($HoldInfo in $NewHoldObj)
                    {
                        $results = $HoldInfo.ExecuteHoldCommandlets($AdvCaseId)
                
                        foreach($result in $results)
                        {
                            if($result -eq "Completely Migrated")
                            {
                                if(($CoreCase.CaseMemberMigrated -eq "Failed" ) -or ($CoreCase.CaseMemberMigrated -eq "Partial"))
                                {
                                    $PartialMigratedHolds += 1
                                    $CoreCase.MigrationStatus = "Partial"  
                                    $CoreCase.Comment = $CoreCase.Comment + "Some case member not migrated. "
                                }
                                elseif(($CoreCase.CaseMemberMigrated -eq "Success" ) -or ($CoreCase.CaseMemberMigrated -eq "NA"))
                                {
                                    if($results[1] -match "Public folder location not supported.")
                                        { 
                                            $PartialMigratedHolds += 1
                                            $CoreCase.MigrationStatus = "Partial"  
                                        }
                                       else 
                                       {
                                            $CompletelyMigratedHolds += 1
                                            $CoreCase.MigrationStatus = "Complete" 
                                       }
                                }
                            }
                            elseif($result -eq "Not Migrated")
                            {
                               # if(($results[1] -match "No hold policy present.") -or (($results[1] -match "Public folder location not supported.") -and (-not ($results[1] -match "No hold policy migrated."))))
                                if(($results[1] -match "No hold policy present.") -or ($results[1] -match "Public folder location not supported."))                         
                                {
                                    if( ($results[1] -match "No hold policy migrated."))
                                    {
                                        $NotMigratedHolds += 1
                                        $CoreCase.MigrationStatus = "Skipped"
                                        try 
                                        {
                                            Remove-ComplianceCase -Identity "$($CoreCase.AdvCaseName)" -Confirm:$false                               
                                            $CoreCase.Comment = $CoreCase.Comment + "Advance eDiscovery case removed as no hold policy migrated. " 
                                            $CoreCase.AdvancedCaseId = "NA"
                                            $CoreCase.AdvancedLinkURL = "NA"     
                                            Set-ComplianceCase -Identity $($CoreCase.CaseName) -Description $($CoreCase.CoreDescription)                                                                  
                                        }
                                        catch {
                            
                                        }
                                    }
                                    else
                                    {
                                    if($CoreCase.CaseMemberMigrated -eq "Failed")
                                    {
                                        $CoreCase.Comment = $CoreCase.Comment + "No case member migrated. " 
                                        $NotMigratedHolds += 1
                                        $CoreCase.MigrationStatus = "Skipped" 
                                        try 
                                        {
                                            Remove-ComplianceCase -Identity "$($CoreCase.AdvCaseName)" -Confirm:$false                                           
                                            $CoreCase.Comment = $CoreCase.Comment + "Advance eDiscovery case removed as no hold policy or case member formed. " 
                                            $CoreCase.AdvancedCaseId = "NA"
                                            $CoreCase.AdvancedLinkURL = "NA" 
                                            Set-ComplianceCase -Identity $($CoreCase.CaseName) -Description $($CoreCase.CoreDescription)                                                                      
                                        }
                                        catch {
                            
                                        }                                        
                                    }
                                    elseif($CoreCase.CaseMemberMigrated -eq "Success") {
                                        if($results[1] -match "Public folder location not supported.")
                                        { 
                                            $PartialMigratedHolds += 1
                                            $CoreCase.MigrationStatus = "Partial"  
                                        }
                                       else 
                                       {
                                            $CompletelyMigratedHolds += 1
                                            $CoreCase.MigrationStatus = "Complete" 
                                       }
                                    }
                                    elseif($CoreCase.CaseMemberMigrated -eq "Partial") {
                                        $PartialMigratedHolds += 1
                                        $CoreCase.MigrationStatus = "Partial"  
                                        $CoreCase.Comment = $CoreCase.Comment + "Some case member not migrated. " 
                                    }else {
                                        $CoreCase.Comment = $CoreCase.Comment + "No case member present. " 
                                        $NotMigratedHolds += 1
                                        $CoreCase.MigrationStatus = "Skipped"
                                        try 
                                        {
                                            Remove-ComplianceCase -Identity "$($CoreCase.AdvCaseName)" -Confirm:$false
                                            $CoreCase.Comment = $CoreCase.Comment + "Advance eDiscovery case removed as no hold policy or case member present. " 
                                            $CoreCase.AdvancedCaseId = "NA"
                                            $CoreCase.AdvancedLinkURL = "NA"  
                                            Set-ComplianceCase -Identity $($CoreCase.CaseName) -Description $($CoreCase.CoreDescription)                                                                                                             
                                        }
                                        catch {
                            
                                        }
                                    }
                                }

                                                                      
                                }
                                else {
                                    $NotMigratedHolds += 1
                                    $CoreCase.MigrationStatus = "Skipped" 
                                    $HasHoldMigrationFailed = $true
                                    try 
                                    {
                                        Remove-ComplianceCase -Identity "$($CoreCase.AdvCaseName)" -Confirm:$false                 
                                        $CoreCase.Comment = $CoreCase.Comment + "Advance eDiscovery case removed as no hold policy formed. " 
                                        $CoreCase.AdvancedCaseId = "NA"
                                        $CoreCase.AdvancedLinkURL = "NA"  
                                        Set-ComplianceCase -Identity $($CoreCase.CaseName) -Description $($CoreCase.CoreDescription)                                                                    
                                    }
                                    catch {
                            
                                    }
                                }                                
                            }
                            elseif($result -eq "Partially Migrated")
                            {
                                $PartialMigratedHolds += 1
                                $CoreCase.MigrationStatus = "Partial" 
                            }
                            else
                            { $CoreCase.Comment = $CoreCase.Comment + $result  }               
                        }
                    }
                }
                elseif ($countOfHold -gt 1)
                {
                    try 
                    {
                        $NotMigratedHolds += 1
                        $CoreCase.MigrationStatus = "Skipped"
                        $CoreCase.Comment = "Not supported. More than one hold policy present. "
                        Remove-ComplianceCase -Identity "$($CoreCase.AdvCaseName)" -Confirm:$false                      
                        $CoreCase.AdvancedCaseId = "NA"
                        $CoreCase.AdvancedLinkURL = "NA" 
                        Set-ComplianceCase -Identity $($CoreCase.CaseName) -Description $($CoreCase.CoreDescription)                                       
                    }
                    catch {
               
                    }        
                }
                elseif ($countOfHold -eq 0) 
                {
                    try 
                    {
                        if(($CoreCase.CaseMemberMigrated -eq "Success" ) )
                        {
                            $CompletelyMigratedHolds += 1
                            $CoreCase.MigrationStatus = "Complete"                           
                        }
                        elseif(($CoreCase.CaseMemberMigrated -eq "Failed" ) )                               
                        {
                            try 
                            {
                                $NotMigratedHolds += 1
                                $CoreCase.MigrationStatus = "Skipped"
                                Remove-ComplianceCase -Identity "$($CoreCase.AdvCaseName)" -Confirm:$false
                                $CoreCase.Comment = $CoreCase.Comment + "Advance eDiscovery case removed as no parameter is migrated. " 
                                $CoreCase.AdvancedCaseId = "NA"
                                $CoreCase.AdvancedLinkURL = "NA"
                                Set-ComplianceCase -Identity $($CoreCase.CaseName) -Description $($CoreCase.CoreDescription)                                        
                            }
                            catch {
               
                            }  
                        }
                        elseif(($CoreCase.CaseMemberMigrated -eq "Partial"))                               
                        {
                            $PartialMigratedHolds += 1
                            $CoreCase.MigrationStatus = "Partial"
                            $CoreCase.Comment = $CoreCase.Comment + "Some case member not migrated. " 
                        }
                        elseif( $CoreCase.CaseMemberMigrated -eq "NA")                               
                        {
                            try 
                            {
                                $NotMigratedHolds += 1
                                $CoreCase.MigrationStatus ="Skipped"
                                Remove-ComplianceCase -Identity "$($CoreCase.AdvCaseName)" -Confirm:$false
                                $CoreCase.Comment = $CoreCase.Comment + "Advance eDiscovery case removed as no parameter is present. " 
                                $CoreCase.AdvancedCaseId = "NA"
                                $CoreCase.AdvancedLinkURL = "NA" 
                                Set-ComplianceCase -Identity $($CoreCase.CaseName) -Description $($CoreCase.CoreDescription)                                       
                            }
                            catch {
               
                            }        
                            
                        }
                        #Remove-ComplianceCase -Identity "$($CoreCase.AdvCaseName)" -Confirm:$false
                    }
                    catch 
                    {
               
                    }
                }
            }
            else
            {
                $NotMigratedHolds += 1
                $CoreCase.MigrationStatus = "Skipped"
                if($CoreCase.IsAlreadyPresent -eq $true)
                {
                    $CoreCase.MigrationStatus = "Skipped"
                    $CoreCase.Comment = $CoreCase.Comment + "The advance eDiscovey case is already present. "
                }
            }
        }
    }

    $InfoMessage = "Migration Completed"
    Write-Log -IsInfo -InfoMessage $InfoMessage -LogFile $LogFile -ErrorAction:SilentlyContinue

    [ReportStats]$ReportStatsObj = new-object -TypeName ReportStats

    $ReportStatsObj.DomainName = (Get-AcceptedDomains -LogFile $LogFile)
    $ReportStatsObj.OrgName = (Get-OrganisationName -LogFile $LogFile)
    $ReportStatsObj.SelectedCases = $SelectedCases
    $ReportStatsObj.MigratedCases = $CompletelyMigratedHolds
    $ReportStatsObj.FailedCases = $NotMigratedHolds
    $ReportStatsObj.PartiallyMigratedCases= $PartialMigratedHolds
    $ReportStatsObj.ElapsedSeconds =  ($(Get-Date)- $global:StartTime).TotalSeconds

    try
    { 
        Create-Report -CasesArray $UpdatedCoreCaseObj -ReportObj $ReportStatsObj -LogFile $LogFile
    }
    catch
    {
        $ErrorMessage = $_.ToString()
        Write-host $ErrorMessage
    }
    return $ReportStatsObj
}

Function Absent-CaseStats {
    Param(
        $LogFile
    )

    $InfoMessage = "No cases to migrate"
    Write-Host "$(Get-Date) $InfoMessage" -ForegroundColor:Yellow
    Write-Log -IsInfo -InfoMessage $InfoMessage -LogFile $LogFile -ErrorAction:SilentlyContinue
            
    [ReportStats]$ReportStatsObj = new-object -TypeName ReportStats

    $ReportStatsObj.DomainName = (Get-AcceptedDomains -LogFile $LogFile)
    $ReportStatsObj.OrgName = (Get-OrganisationName -LogFile $LogFile)
    $ReportStatsObj.SelectedCases = 0
    $ReportStatsObj.MigratedCases = 0
    $ReportStatsObj.FailedCases = 0
    $ReportStatsObj.ElapsedSeconds = ($(Get-Date)- $global:StartTime).TotalSeconds
    return
}

Function Get-AcceptedDomains {
    Param(
        [string]$LogFile
    )
    $DomainName = ""
    try {
        [System.Collections.ArrayList]$WarnMessage = @()
        $DomainName = (Get-EXOPAcceptedDomain -ErrorAction:SilentlyContinue -WarningVariable +WarnMessage | Where-Object { $_.InitialDomain -eq $True }).DomainName
        Write-Log -IsWarn -WarnMessage $WarnMessage -LogFile $LogFile -ErrorAction:SilentlyContinue
    }
    catch {
        $DomainName = "Error"
        Write-Host "Error:$(Get-Date) There was an issue in fetching tenant name information. Please try running the tool again after some time." -ForegroundColor:Red
        $ErrorMessage = $_.ToString()
        $StackTraceInfo = $_.ScriptStackTrace
        Write-Log -IsError -ErrorMessage $ErrorMessage -StackTraceInfo $StackTraceInfo -LogFile $LogFile -ErrorAction:SilentlyContinue      
    }
    Return $DomainName
}

Function Get-OrganisationName {
    Param(
        [string]$LogFile
    )
    
    $OrgName = ""
    try {
        [System.Collections.ArrayList]$WarnMessage = @()
        $OrgName = (Get-EXOPOrganizationConfig -ErrorAction:SilentlyContinue).DisplayName
        Write-Log -IsWarn -WarnMessage $WarnMessage -LogFile $LogFile -ErrorAction:SilentlyContinue
    }
    catch {
        $OrgName = "Error"
        Write-Host "Error:$(Get-Date) There was an issue in fetching organization name information. Please try running the tool again after some time." -ForegroundColor:Red
        $ErrorMessage = $_.ToString()
        $StackTraceInfo = $_.ScriptStackTrace
        Write-Log -IsError -ErrorMessage $ErrorMessage -StackTraceInfo $StackTraceInfo -LogFile $LogFile -ErrorAction:SilentlyContinue      
    }   
    Return $OrgName
}