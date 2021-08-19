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

    [bool]ExecuteHoldCommandlets($AdvCaseName) { 
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

        $this.PolicyName += "Migrated"  

        $InfoMessage = "Creating Advance eDiscovery Holds"
        Write-Host "$(Get-Date) $InfoMessage"
        Write-Log -IsInfo -InfoMessage $InfoMessage -LogFile $this.LogFile -ErrorAction:SilentlyContinue
        
            
        try {
            $AdvancedHold = New-CaseHoldPolicy -Name "$($this.PolicyName)" -Case "$AdvCaseName" -Comment "$($this.PolicyDescription)" -Confirm:$false -Enabled $true -ExchangeLocation $ResultExLocations -PublicFolderLocation $ResultPublicFolder -SharePointLocation $ResultSPOSites
            
            try
            {
                $InfoMessage = "Creating Advance eDiscovery Hold rule"
                Write-Host "$(Get-Date) $InfoMessage"
                Write-Log -IsInfo -InfoMessage $InfoMessage -LogFile $this.LogFile -ErrorAction:SilentlyContinue
         
                $AdvancedRule = New-CaseHoldRule -Name "$($this.RuleName)" -Policy "$($this.PolicyName)" -Comment "$($this.RuleDescription)" -Confirm:$false -ContentMatchQuery "$($this.Query)"
            }
            catch
            {
                Write-Host "Error:$(Get-Date) There was an issue in creating Advance eDiscovery Hold rule. Please try running the tool again after some time." -ForegroundColor:Red
                $ErrorMessage = $_.ToString()
                $StackTraceInfo = $_.ScriptStackTrace
                Write-Log -IsError -ErrorMessage $ErrorMessage -StackTraceInfo $StackTraceInfo -LogFile $this.LogFile -ErrorAction:SilentlyContinue      
                return $false
            }
            return $true
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