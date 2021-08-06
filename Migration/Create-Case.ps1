# Importing Scripts
. "$($(get-item $PSCommandPath).Directory.parent.FullName)\Logging\Log.ps1"
. "$($(get-item $PSCommandPath).Directory.parent.FullName)\Main.ps1"

class Case : CoreCase {

    Case($CaseName, $CaseId, $Description, $LinkURL) {
        $this.CaseName = $CaseName
        $this.CaseId = $CaseId
        $this.Description = $Description
        $this.LinkURL = $LinkURL
        $this.IsMigrationEnabled = $false
        $this.IsDeletionEnabled = $false
    }


    [bool]ExecuteCommandlets() { 
        $this.CaseName += "Migrated" 
        $this.Description += " This was migrated from Core eDiscovery case ID: $($this.CaseId) on date: $(Get-Date -Format 'ddMMyy')." 

        $InfoMessage = "Creating Advance eDiscovery Case"
        Write-Host "$(Get-Date) $InfoMessage"
        Write-Log -IsInfo -InfoMessage $InfoMessage -LogFile $this.LogFile -ErrorAction:SilentlyContinue
            
            
        try {
            $AdvancedCase = New-ComplianceCase -Name "$($this.CaseName)" -CaseType AdvancedEdiscovery -Confirm:$false -Description "$($this.Description)" -ErrorAction:SilentlyContinue
            return $true
        }
        catch {
            Write-Host "Error:$(Get-Date) There was an issue in creating Advance eDiscovery Case. Please try running the tool again after some time." -ForegroundColor:Red
            $ErrorMessage = $_.ToString()
            $StackTraceInfo = $_.ScriptStackTrace
            Write-Log -IsError -ErrorMessage $ErrorMessage -StackTraceInfo $StackTraceInfo -LogFile $this.LogFile -ErrorAction:SilentlyContinue      
            return $false
        }
    }
}