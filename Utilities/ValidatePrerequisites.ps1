# Importing Scripts
. "$($(get-item $PSCommandPath).Directory.parent.FullName)\Logging\Log.ps1"

function Confirm-Prerequisites {
    <#

        Validates, installs and updates EOM module
        
    #>
    Param
    (
        [String]$LogFile
    )

    Import-Csv "$($(get-item $PSCommandPath).Directory.parent.FullName)\Utilities\Prerequisite.csv" | ForEach-Object {
        
        try {
            $ModuleVersion = (Get-InstalledModule -name $($_.Module) -ErrorAction:SilentlyContinue | Sort-Object Version -Desc)[0].Version
        }
        catch {
            $ModuleVersion = "Error"
            $InfoMessage = "$($_.Module) module is not installed. Installing.."
            Write-Log -IsInfo -InfoMessage $InfoMessage -LogFile $LogFile -ErrorAction:SilentlyContinue
            write-host "$(Get-Date) $InfoMessage"
            Write-Verbose "Installing $($_.Module)"
            Install-Module -Name $($_.Module) -force
        }
        
        
        if ($ModuleVersion -eq "Error") {
            $ModuleVersion = (Get-InstalledModule -name $($_.Module) -ErrorAction:SilentlyContinue | Sort-Object Version -Desc)[0].Version
        }
        
        if ("$ModuleVersion" -lt "$($_.MinVersion)") {
            $InfoMessage = "Your $($_.Module) module is not updated. Updating.."
            Write-Log -IsInfo -InfoMessage $InfoMessage -LogFile $LogFile -ErrorAction:SilentlyContinue
            write-host "$(Get-Date) $InfoMessage"
            Update-Module -Name $($_.Module) -RequiredVersion 2.0.3
        }
    }
    
}