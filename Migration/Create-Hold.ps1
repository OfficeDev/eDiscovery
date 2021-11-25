# Importing Scripts
. "$($(get-item $PSCommandPath).Directory.parent.FullName)\Logging\Log.ps1"
. "$($(get-item $PSCommandPath).Directory.parent.FullName)\Main.ps1"

class Hold : CoreHold{
    [array]$ExLocations
    [array]$SPOSites
    [array]$PublicFolder
    Hold($CaseName, $PolicyName, $PolicyDescription, $ExLocations, $SPOSites, $PublicFolder) {
        $this.CoreCaseName = $CaseName
        $this.PolicyName = $PolicyName
        $this.PolicyDescription = $PolicyDescription
        $this.ExLocations = $ExLocations
        $this.SPOSites = $SPOSites
        $this.PublicFolder= $PublicFolder
    }

    [array]ExecuteHoldCommandlets($AdvCaseName) { 
        $HoldRule = Get-CaseHoldRule -Policy "$($this.PolicyName)"
        $this.RuleName = $HoldRule.Name + "Migrated" 
        $this.RuleDescription = $HoldRule.Comment
        $this.Query = $HoldRule.ContentMatchQuery

        #Ex
        $ResultExLocations = @()
        foreach($loc in $this.ExLocations)
        {
            [string] $Eloc = "$loc"
            $ResultExLocations += $Eloc 
        }
        #SPO
        $ResultSPOSites = @()
        foreach($loc in $this.SPOSites)
        {
            [string] $Sloc = "$loc"
            $ResultSPOSites += $Sloc 
        }
        #Public
        $ResultPublicFolder = @()
        foreach($loc in $this.PublicFolder)
        {
            [string] $Ploc = "$loc"
            $ResultPublicFolder += $Ploc 
        }

        #ErrorCountForCustodian
        $cus_Error = 0
        #ErrorCountForNonCustodian
        $nonCus_Error = 0
        #ResultArray
        $ResultArray = @()

        $this.PolicyName += "Migrated"  

        $InfoMessage = "Creating Advance eDiscovery Holds"
        Write-Host "$(Get-Date) $InfoMessage"
        Write-Log -IsInfo -InfoMessage $InfoMessage -LogFile $this.LogFile -ErrorAction:SilentlyContinue
        
            
        try {
            $InfoMessage = "Creating custodian hold rule"
            Write-Host "$(Get-Date) $InfoMessage"
            Write-Log -IsInfo -InfoMessage $InfoMessage -LogFile $this.LogFile -ErrorAction:SilentlyContinue
            foreach($ExLocation in $ResultExLocations)
            {
                $CustodianId=""
                $ErrorPresent =$false
                try
                { 
                    $CustodianId = (New-MgComplianceEdiscoveryCaseCustodian -CaseId "$AdvCaseName" -ApplyHoldToSources:$true -Email $ExLocation -DisplayName "$($this.PolicyName)").Id
                }
                catch
                {
                    $ErrorMessage = $_.ToString()
                    if($ErrorMessage -match "already exists")
                    {
                        
                    }
                    else {
                        $ErrorPresent = $true
                        Write-Host "Error:$(Get-Date) There was an issue in creating Advance eDiscovery custodian hold rule. Please try running the tool again after some time." -ForegroundColor:Red                    
                    }
                    $StackTraceInfo = $_.ScriptStackTrace
                    Write-Log -IsError -ErrorMessage $ErrorMessage -StackTraceInfo $StackTraceInfo -LogFile $this.LogFile -ErrorAction:SilentlyContinue                     
                }
                try
                { 
                    New-MgComplianceEdiscoveryCaseCustodianUserSource -CaseId "$AdvCaseName" -CustodianId $CustodianId -Email $ExLocation                
                }
                catch
                {
                    $ErrorMessage = $_.ToString()
                    if($ErrorMessage -match "already exists")
                    {
                        
                    }
                    else {
                        $ErrorPresent = $true
                        Write-Host "Error:$(Get-Date) There was an issue in creating Advance eDiscovery custodian hold rule. Please try running the tool again after some time." -ForegroundColor:Red                    
                    }
                    $StackTraceInfo = $_.ScriptStackTrace
                    Write-Log -IsError -ErrorMessage $ErrorMessage -StackTraceInfo $StackTraceInfo -LogFile $this.LogFile -ErrorAction:SilentlyContinue                     
                }
                try
                { 
                    Update-MgComplianceEdiscoveryCaseCustodian -CaseId "$AdvCaseName" -CustodianId $CustodianId -ApplyHoldToSources:$true
                }
                catch
                {                    
                    $ErrorMessage = $_.ToString()
                    if($ErrorMessage -match "already exists")
                    {
                        
                    }
                    else {
                        $ErrorPresent = $true
                        Write-Host "Error:$(Get-Date) There was an issue in creating Advance eDiscovery custodian hold rule. Please try running the tool again after some time." -ForegroundColor:Red                    
                    }
                    $StackTraceInfo = $_.ScriptStackTrace
                    Write-Log -IsError -ErrorMessage $ErrorMessage -StackTraceInfo $StackTraceInfo -LogFile $this.LogFile -ErrorAction:SilentlyContinue                     
                }
                if($ErrorPresent -eq $true)
                {
                    $cus_Error = $cus_Error + 1
                }
            }
            $InfoMessage = "Creating non-custodian hold rule"
            Write-Host "$(Get-Date) $InfoMessage"
            Write-Log -IsInfo -InfoMessage $InfoMessage -LogFile $this.LogFile -ErrorAction:SilentlyContinue
            foreach($SPOSite in $ResultSPOSites)
            {
                try
                { 
                    $Body = @{
                        applyHoldToSource = $true
                        dataSource        = @{
                            "@odata.type" = "microsoft.graph.ediscovery.siteSource"
                           site          = @{ webUrl = "$SPOSite" }
                       }
                   }
                  
                  $Uri = "https://graph.microsoft.com/beta/compliance/ediscovery/cases/$AdvCaseName/noncustodialDataSources"
                  Invoke-MgGraphRequest -Uri $Uri -Body $Body -Method POST
                }
                catch
                {
                    $ErrorMessage = $_.ToString()
                    if($ErrorMessage -match "already exists")
                    {
                        
                    }
                    else {
                        $nonCus_Error = $nonCus_Error + 1
                        Write-Host "Error:$(Get-Date) There was an issue in creating Advance eDiscovery non-custodian hold rule. Please try running the tool again after some time." -ForegroundColor:Red
                    }
                    $StackTraceInfo = $_.ScriptStackTrace
                    Write-Log -IsError -ErrorMessage $ErrorMessage -StackTraceInfo $StackTraceInfo -LogFile $this.LogFile -ErrorAction:SilentlyContinue          
                }                
            }
            $errorInfo = ""
            foreach($folder in $ResultPublicFolder)
            {
                $errorInfo = "Public folder location not supported. "
            }
            $queryUpdated = 0
            $policyCreated = 0
            try
            {
                $InfoMessage = "Updating Advance eDiscovery hold rule and adding query to hold rule"
                $CaseHoldPolicyList = $null
                try
                {
                    $CaseHoldPolicyList = Get-CaseHoldPolicy -Case "$AdvCaseName" -DistributionDetail
                }
                catch
                {
                    Write-Host "Error:$(Get-Date) There was an issue in fetching advance eDiscovery hold policy. Please try running the tool again after some time." -ForegroundColor:Red
                    $ErrorMessage = $_.ToString()
                    $StackTraceInfo = $_.ScriptStackTrace
                    Write-Log -IsError -ErrorMessage $ErrorMessage -StackTraceInfo $StackTraceInfo -LogFile $this.LogFile -ErrorAction:SilentlyContinue      
                }
                Write-Host "$(Get-Date) $InfoMessage"
                Write-Log -IsInfo -InfoMessage $InfoMessage -LogFile $this.LogFile -ErrorAction:SilentlyContinue
                if($null -ne $CaseHoldPolicyList)
                {    
                    foreach($policy in $CaseHoldPolicyList)
                    {
                        $policyCreated = $policyCreated + 1            
                    }               
                    foreach($policy in $CaseHoldPolicyList)
                    {
                        try
                        {
                            Set-CaseHoldRule -Identity "$($policy.Name)" -ContentMatchQuery "$($this.Query)" 
                            $queryUpdated = $queryUpdated + 1   
                        }
                        catch
                        {
                        }          
                    } 
                }              
            }
            catch
            {
                Write-Host "Error:$(Get-Date) There was an issue in updating Advance eDiscovery hold rule. Please try running the tool again after some time." -ForegroundColor:Red
                $ErrorMessage = $_.ToString()
                $StackTraceInfo = $_.ScriptStackTrace
                Write-Log -IsError -ErrorMessage $ErrorMessage -StackTraceInfo $StackTraceInfo -LogFile $this.LogFile -ErrorAction:SilentlyContinue      
            } 
            
            if($nonCus_Error -gt 0)
            {
                if($nonCus_Error -eq $ResultSPOSites.Length)
                {$errorInfo = $errorInfo + "No SharePoint site sources migrated. "}
                else
                {$errorInfo = $errorInfo + "$nonCus_Error out of $($ResultSPOSites.Length) SharePoint site sources not migrated. "}
            }
            if($cus_Error -gt 0)
            {
                if($cus_Error -eq $ResultExLocations.Length)
                {$errorInfo = $errorInfo + "No Exchange location migrated. "}
                else
                {$errorInfo = $errorInfo + "$cus_Error out of $($ResultExLocations.Length) Exchange location not migrated. "}
            }

            $queryUpdatedStatus = ""

            if(($queryUpdated -eq $policyCreated) -and ($queryUpdated -ne 0))
            {
                #$queryUpdatedStatus = "All hold policies updated with queries. "
            }
            elseif(($queryUpdated -eq $policyCreated) -and ($queryUpdated -eq 0))
            {
                $queryUpdatedStatus = "No hold policy created. "
            }
            elseif(($queryUpdated -lt $policyCreated) -and ($queryUpdated -ne 0))
            {
                $queryUpdatedStatus = "1 hold policies not updated with queries. "
            }
            elseif(($queryUpdated -lt $policyCreated) -and ($queryUpdated -eq 0))
            {
                $queryUpdatedStatus = "No hold policies updated with queries. "
            }
            
            $Status = ""

            if(($ResultSPOSites.Length -gt 0) -and ($ExLocation.Length -gt 0) )
            {
                if(($policyCreated -eq 2 ) -and ($queryUpdated -eq 2))
                {  
                    if(($nonCus_Error -eq 0) -and ($cus_Error -eq 0))
                    {
                        $Status = "Completely Migrated"
                    }
                    else 
                    {
                        $Status = "Partially Migrated"
                    }
                }
                elseif($policyCreated -gt 0)
                { $Status = "Partially Migrated"}
                elseif($policyCreated -eq 0 )
                { 
                    $Status = "Not Migrated"
                    $errorInfo = $errorInfo + "No hold policy migrated. "
                }
            }
            elseif(($ResultSPOSites.Length -gt 0) -and ($ExLocation.Length -eq 0) )
            {
                if(($policyCreated -eq 1 ) -and ($queryUpdated -eq 1))
                { 
                    if(($nonCus_Error -eq 0) -and ($cus_Error -eq 0))
                    {
                        $Status = "Completely Migrated"
                    }
                    else {
                        $Status = "Partially Migrated"
                    }
                }
                elseif($policyCreated -eq 1 )
                { $Status = "Partially Migrated"}
                elseif($policyCreated -eq 0 )
                { 
                    $Status = "Not Migrated"
                    $errorInfo = $errorInfo +"No hold policy migrated. "
                }
            }
            elseif(($ResultSPOSites.Length -eq 0) -and ($ExLocation.Length -gt 0))
            {
                if(($policyCreated -eq 1 ) -and ($queryUpdated -eq 1))
                { 
                    if(($nonCus_Error -eq 0) -and ($cus_Error -eq 0))
                    {
                        $Status = "Completely Migrated"
                    }
                    else {
                        $Status = "Partially Migrated"
                    }
                }
                elseif($policyCreated -eq 1 )
                { $Status = "Partially Migrated"}
                elseif($policyCreated -eq 0 )
                { 
                    $Status = "Not Migrated"
                    $errorInfo = $errorInfo + "No hold policy migrated. "
                }
            }
            elseif(($ResultSPOSites.Length -eq 0) -and ($ExLocation.Length -eq 0) -and ($policyCreated -eq 0))
            {
                if(($ResultPublicFolder.Length -ne 0) )
                {
                    $Status = "Not Migrated"
                } 
                else
                {
                   $Status = "Not Migrated"
                   $errorInfo = $errorInfo + "No hold policy present. "
                }
            }
            
            $ResultArray += $Status
            $ResultArray += $errorInfo
            $ResultArray += $queryUpdatedStatus
       
            return $ResultArray
        }
        catch {
            Write-Host "Error:$(Get-Date) There was an issue in creating Advance eDiscovery Hold. Please try running the tool again after some time." -ForegroundColor:Red
            $ErrorMessage = $_.ToString()
            $StackTraceInfo = $_.ScriptStackTrace
            Write-Log -IsError -ErrorMessage $ErrorMessage -StackTraceInfo $StackTraceInfo -LogFile $this.LogFile -ErrorAction:SilentlyContinue      
            return $false
        }
    }
}