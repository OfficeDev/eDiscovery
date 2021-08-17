# Importing Scripts
. "$($(get-item $PSCommandPath).Directory.parent.FullName)\Logging\Log.ps1"
. "$($(get-item $PSCommandPath).Directory.parent.FullName)\Main.ps1"

class Case : CoreCase {

    [string] $AdvancedCaseId = "NA"
    [string] $AdvancedLinkURL = "NA"
    [string] $CaseMember = "NA"
    Case($CaseName, $CaseId, $Description, $LinkURL) {
        $this.CaseName = $CaseName
        $this.CaseId = $CaseId
        $this.Description = $Description
        $this.LinkURL = $LinkURL
        $this.LinkText = "View Case"
        $this.IsMigrationEnabled = $false
        $this.IsDeletionEnabled = $false
        $this.IsMigrated= $false
    }

    [bool]ExecuteCommandlets() { 
        $this.CaseMember = Get-compliancecasemember -Case "$($this.CaseName)"
        $this.CaseName += "Migrated" 
        $this.Description += " This was migrated from Core eDiscovery case ID: $($this.CaseId) on date: $(Get-Date -Format 'ddMMyy')." 

        $InfoMessage = "Creating Advance eDiscovery Case"
        Write-Host "$(Get-Date) $InfoMessage"
        Write-Log -IsInfo -InfoMessage $InfoMessage -LogFile $this.LogFile -ErrorAction:SilentlyContinue
            
            
        try {
            $AdvancedCase = New-ComplianceCase -Name "$($this.CaseName)" -CaseType AdvancedEdiscovery -Confirm:$false -Description "$($this.Description)" 
            if($AdvancedCase.Identity -ne "" -and $null -ne $AdvancedCase.Identity)
            {
                $this.AdvancedCaseId = $AdvancedCase.Identity
                $this.AdvancedLinkURL = "https://compliance.microsoft.com/advancedediscovery/v2/$($this.AdvancedCaseId)"
                if($null -ne $this.CaseMember )
                {
                    foreach($member in $this.CaseMember)
                    {
                        Add-compliancecasemember -Case "$($this.CaseName)" -Member "$($member.Name)"
                    }
                }
                $this.IsMigrated= $true
                return $true
            }
            else {
                return $false
            } 
           
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