function Write-Log {
    <#

        Writes log
        
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [Switch]$IsError = $false,
        [Parameter(Mandatory = $false)]
        [Switch]$IsWarn = $false,
        [Parameter(Mandatory = $false)]
        [Switch]$IsInfo = $false,
        [Parameter(Mandatory = $false)]
        [Switch]$MachineInfo = $false,
        [Parameter(Mandatory = $false)]
        [Switch]$StopInfo = $false,
        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage,
        [Parameter(Mandatory = $false)]
        [System.Collections.ArrayList]$WarnMessage,
        [Parameter(Mandatory = $false)]
        [string]$InfoMessage,
        [Parameter(Mandatory = $false)]
        [string]$StackTraceInfo,
        [String]$LogFile
    )   

    if ($MachineInfo) {
        $ComputerInfoObj = Get-ComputerInfo 
        $CompName = $ComputerInfoObj.CsName
        $OSName = $ComputerInfoObj.OsName
        $OSVersion = $ComputerInfoObj.OsVersion
        $PowerShellVersion = $PSVersionTable.PSVersion
        try {
            "********************************************************************************************" | Out-File $LogFile -Append -ErrorAction:SilentlyContinue
            "Logging Started" | Out-File $LogFile -Append -ErrorAction:SilentlyContinue
            "Start time: $(Get-Date)" | Out-File $LogFile -Append -ErrorAction:SilentlyContinue
            "Computer Name: $CompName" | Out-File $LogFile -Append -ErrorAction:SilentlyContinue
            "Operating System Name: $OSName" | Out-File $LogFile -Append -ErrorAction:SilentlyContinue
            "Operating System Version: $OSVersion" | Out-File $LogFile -Append -ErrorAction:SilentlyContinue
            "PowerShell Version: $PowerShellVersion" | Out-File $LogFile -Append -ErrorAction:SilentlyContinue
            "********************************************************************************************" | Out-File $LogFile -Append -ErrorAction:SilentlyContinue
         
        }
        catch {
            Write-Host "$(Get-Date) The local machine information cannot be logged." -ForegroundColor:Yellow
        }

    }
    if ($StopInfo) {
        try {
            "********************************************************************************************" | Out-File $LogFile -Append -ErrorAction:SilentlyContinue
            "Logging Ended" | Out-File $LogFile -Append -ErrorAction:SilentlyContinue
            "End time: $(Get-Date)" | Out-File $LogFile -Append -ErrorAction:SilentlyContinue
            "********************************************************************************************" | Out-File $LogFile -Append -ErrorAction:SilentlyContinue
            
            if ($($global:ErrorOccurred) -eq $true) {
                Write-Host "Warning:$(Get-Date) The migration may not be complete due to errors in running the tool. These errors may occur due to multiple reasons. Please refer documentation for more details." -ForegroundColor:Yellow
            }
         
        }
        catch {
            Write-Host "$(Get-Date) The finishing time information cannot be logged." -ForegroundColor:Yellow
        }
    }
    #Error
    if ($IsError) {
        if ($($global:ErrorOccurred) -eq $false) {
            $global:ErrorOccurred = $true
        }
        $Log_content = "$(Get-Date) ERROR: $ErrorMessage"
        try {
            $Log_content | Out-File $LogFile -Append -ErrorAction:SilentlyContinue
            "TRACE: $StackTraceInfo" | Out-File $LogFile -Append -ErrorAction:SilentlyContinue
        }
        catch {
            Write-Host "$(Get-Date) An error event cannot be logged." -ForegroundColor:Yellow  
        }           
    }
    #Warning
    if ($IsWarn) {
        foreach ($Warnmsg in $WarnMessage) {
            $Log_content = "$(Get-Date) WARN: $Warnmsg"
            try {
                $Log_content | Out-File $LogFile -Append -ErrorAction:SilentlyContinue
            }
            catch {
                Write-Host "$(Get-Date) A warning event cannot be logged." -ForegroundColor:Yellow 
            }
        }
    }
    #General
    if ($IsInfo) {
        $Log_content = "$(Get-Date) INFO: $InfoMessage"
        try {
            $Log_content | Out-File $LogFile -Append -ErrorAction:SilentlyContinue
        }
        catch {
            Write-Host "$(Get-Date) A general event cannot be logged." -ForegroundColor:Yellow 
        }
        
    }
}
