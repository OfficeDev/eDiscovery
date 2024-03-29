# Importing Scripts
. "$($(get-item $PSCommandPath).Directory.parent.FullName)\Logging\Log.ps1"
function Send-Telemetry {
    <#

        Send telemetry
        
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        $DataCollectionParameter,
        [String]$LogFile
    )

    
    $InfoMessage = "Collecting Telemetry"
    Write-Log -IsInfo -InfoMessage $InfoMessage -LogFile $LogFile -ErrorAction:SilentlyContinue

    $DataCollectionParameter = $DataCollectionParameter | ConvertTo-Json

    try {
            
        # URI and Function Key to trigger the Azure Function 
        $URI = "https://ediscshifttelemetryapp.azurewebsites.net/api/eDiscShiftTelemetryFunction"

        try {
            # Call the URI
            $ResponseMessage = Invoke-WebRequest -Uri $URI -ContentType "application/json" -Method POST -Body $DataCollectionParameter -ErrorAction:SilentlyContinue                   
            Write-Log -IsInfo -InfoMessage $ResponseMessage -LogFile $LogFile -ErrorAction:SilentlyContinue
            Write-Host "$(Get-Date) $ResponseMessage" -ForegroundColor Yellow                
        }
        catch {
            $ErrorMessage = $_.ToString()
            $StackTraceInfo = $_.ScriptStackTrace
            Write-Log -IsError -ErrorMessage $ErrorMessage -StackTraceInfo $StackTraceInfo -LogFile $LogFile -ErrorAction:SilentlyContinue                                 
        }                      
    }
    catch {
        $ErrorMessage = $_.ToString()
        $StackTraceInfo = $_.ScriptStackTrace
        Write-Log -IsError -ErrorMessage $ErrorMessage -StackTraceInfo $StackTraceInfo -LogFile $LogFile -ErrorAction:SilentlyContinue                 
    }
}