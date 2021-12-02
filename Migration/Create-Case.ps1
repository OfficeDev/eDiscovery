# Importing Scripts
. "$($(get-item $PSCommandPath).Directory.parent.FullName)\Logging\Log.ps1"
. "$($(get-item $PSCommandPath).Directory.parent.FullName)\Main.ps1"
#. "$($(get-item $PSCommandPath).Directory.parent.FullName)\Migration\Create-Hold.ps1"

class Case : CoreCase {
    [string] $AdvancedCaseId = "NA"
    [string] $AdvancedLinkURL = "NA"
    [string] $CaseMember = "NA"
    [string] $AdvCaseName = "NA"
    [string] $Comment = ""
    [string] $MigrationStatus = ""
    [bool]$IsAlreadyPresent = $false
    [string]$CaseMemberMigrated = "NA"
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
        $this.AdvCaseName = $this.CaseName + "Migrated" 
        $this.Description += " This was migrated from Core eDiscovery case ID: $($this.CaseId) on date: $(Get-Date -Format 'ddMMyy')." 

        $InfoMessage = "Creating Advance eDiscovery Case"
        Write-Host "$(Get-Date) $InfoMessage"
        Write-Log -IsInfo -InfoMessage $InfoMessage -LogFile $this.LogFile -ErrorAction:SilentlyContinue
            
            
        try {
            $AdvancedCase = New-ComplianceCase -Name "$($this.AdvCaseName)" -CaseType AdvancedEdiscovery -Confirm:$false -Description "$($this.Description)" 
           
            if($AdvancedCase.Identity -ne "" -and $null -ne $AdvancedCase.Identity)
            {
                $this.AdvancedCaseId = $AdvancedCase.Identity
                $this.AdvancedLinkURL = "https://compliance.microsoft.com/advancedediscovery/cases/v2/$($this.AdvancedCaseId)?casename=$($this.AdvCaseName)&casesworkbench=Overview"

                if($null -ne $this.CaseMember )
                {
                    $caseMemberCount =0
                    $successCount =0
                    foreach($member in $this.CaseMember)
                    {
                        $caseMemberCount+=1
                        try
                        {
                            Add-compliancecasemember -Case "$($this.AdvCaseName)" -Member "$($member.Name)"
                            $successCount+=1
                        }
                        catch
                        {
                            #do nothing
                        }
                    }
                    if( $caseMemberCount -eq $successCount)
                    {
                        $this.CaseMemberMigrated = "Success"
                    }
                    elseif(($caseMemberCount -gt $successCount) -and ($successCount -ne 0))
                    {
                        $this.CaseMemberMigrated = "Partial"
                    }
                    else {
                        $this.CaseMemberMigrated = "Failed"
                    }
                }
                $this.IsMigrated= $true
                return $true
            }
            else 
            {
                $AdvancedCaseExisting = Get-ComplianceCase -Identity "$($this.AdvCaseName)" -CaseType AdvancedEdiscovery 
                if($AdvancedCaseExisting.Identity -ne "" -and $null -ne $AdvancedCaseExisting.Identity)
                {
                    $this.AdvancedCaseId = $AdvancedCaseExisting.Identity
                    $this.AdvancedLinkURL = "https://compliance.microsoft.com/advancedediscovery/cases/v2/$($this.AdvancedCaseId)?casename=$($this.AdvCaseName)&casesworkbench=Overview"
                    $this.IsAlreadyPresent = $true
                }
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