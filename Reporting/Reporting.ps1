# Importing Scripts
. "$($(get-item $PSCommandPath).Directory.parent.FullName)\Logging\Log.ps1"
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

function Create-Report {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [array]$CasesArray, 
        $ReportObj,
        [String]$LogFile
    )

    
    $InfoMessage = "Creating Report"
    Write-Log -IsInfo -InfoMessage $InfoMessage -LogFile $LogFile -ErrorAction:SilentlyContinue

    $DataCollectionParameter = $DataCollectionParameter | ConvertTo-Json

    try {
        try {
            $OutputDirectoryName = Get-AppDirectory
            $ReportDirectory = "$OutputDirectoryName\Reports"
            $FileName = "$($global:AppNameShortHand)-$(Get-Date -Format 'yyyyMMddHHmmss').xlsx"
            $ReportFile = "$ReportDirectory\$FileName"


        $FileName = "$($global:AppNameShortHand)-$(Get-Date -Format 'yyyyMMddHHmmss').csv"          
            $temporaryCsvFile = "$ReportDirectory\$FileName"

               if  ( !( Test-Path -Path $ReportDirectory -PathType "Container" ) ) {
            New-Item -Path $ReportDirectory -ItemType "Container" -ErrorAction Stop
        }

#Delimiter ";" helps that result is parsed correctly. Comma delimiter parses incorrectly.
$objects = @()
$objects | Export-Csv -ErrorAction Stop -path $temporaryCsvFile -noTypeInformation -Delimiter ";" 

            $excel = New-Object -ComObject Excel.Application
            $excel.Visible = $true
            [System.Threading.Thread]::CurrentThread.CurrentCulture = 'en-US'
            
            $workbook = $excel.Workbooks.Open($temporaryCsvFile)
            $ReportSheet = $workbook.Worksheets.Item(1)
            $ReportSheet.Name = 'eDiscovey Report'
            
            $row=1;
            $column=1
            
            $ReportSheet.Cells.Item($row,$column)= "Customer Details"
            $ReportSheet.Cells.Item($row,$column).Font.Bold=$True
            $row++
            $column++
            
            $ReportSheet.Cells.Item($row,$column) = "Domain Name"
            $column++
            
            $ReportSheet.Cells.Item($row,$column) = $ReportObj.DomainName
            $row++
            $column=2
            
            $ReportSheet.Cells.Item($row,$column) = "Organisation Name"
            $column++
            
            $ReportSheet.Cells.Item($row,$column) = $ReportObj.OrgName
            $row++
            $column=1
            $row++
            
            $ReportSheet.Cells.Item($row,$column)= "Migration Summary"
            $ReportSheet.Cells.Item($row,$column).Font.Bold=$True
            $row++
            $column++
            
            $ReportSheet.Cells.Item($row,$column) = "Selected Cases"
            $column++
            
            $ReportSheet.Cells.Item($row,$column) = $ReportObj.SelectedCases
            $row++
            $column=2
            
            $ReportSheet.Cells.Item($row,$column) = "Migrated Cases"
            $column++
            
            $ReportSheet.Cells.Item($row,$column) =($ReportObj.MigratedCases/100)*$ReportObj.SelectedCases
            $row++
            $column=2
            
            $ReportSheet.Cells.Item($row,$column) = "Failed Cases"
            $column++
            
            $ReportSheet.Cells.Item($row,$column) = ($ReportObj.FailedCases/100)*$ReportObj.SelectedCases
            $row++
            $column=2
            
            $ReportSheet.Cells.Item($row,$column) = "Session Duration(in ms)"
            $column++
            
            $ReportSheet.Cells.Item($row,$column) = $ReportObj.ElapsedMilliseconds
            $row++
            $column=2
            
            $row++
            $column=1
            
            $ReportSheet.Cells.Item($row,$column)= "Detailed Report"
            $ReportSheet.Cells.Item($row,$column).Font.Bold=$True
            $row++
            $row++
            
            $ReportSheet.Cells.Item($row,$column) = "S.No."
            $ReportSheet.Cells.Item($row,$column).Font.Bold=$True
            $column++
            
            $ReportSheet.Cells.Item($row,$column) = "Case name"
            $ReportSheet.Cells.Item($row,$column).Font.Bold=$True
            $column++
            
            $ReportSheet.Cells.Item($row,$column) = "Case Id"
            $ReportSheet.Cells.Item($row,$column).Font.Bold=$True
            $column++
            
            $ReportSheet.Cells.Item($row,$column) = "Migration Status"
            $ReportSheet.Cells.Item($row,$column).Font.Bold=$True
            $column++
            
            $ReportSheet.Cells.Item($row,$column) = "Core eDiscovery link"
            $ReportSheet.Cells.Item($row,$column).Font.Bold=$True
            $column++
            
            $ReportSheet.Cells.Item($row,$column) = "Advanced eDiscovery link"
            $ReportSheet.Cells.Item($row,$column).Font.Bold=$True
            $column++
            
            $row++
            $column=1
            
            $count=1
            
            foreach ($CoreCase in $CasesArray) {
                        $ReportSheet.Cells.Item($row,$column) = $count
                        $column++
            
                        $ReportSheet.Cells.Item($row,$column) = $CoreCase.CaseName
                        $column++
            
                        $ReportSheet.Cells.Item($row,$column) = "Core Case Id:" + $CoreCase.CaseId + ", Advanced Case Id:" + $CoreCase.AdvancedCaseId
                        $column++
            
                        $ReportSheet.Cells.Item($row,$column) = $CoreCase.IsMigrated
                        $column++
            
                        $ReportSheet.Cells.Item($row,$column) = "View Case"
                        $ReportSheet.Hyperlinks.Add(
                            $ReportSheet.Cells.Item($row,$column),
                            "",
                            $CoreCase.LinkURL,
                            "View Core eDiscovery Case at M365 Compliance Center",
                            $ReportSheet.Cells.Item($row,$column).Text
                            ) | Out-Null
                        $column++
                        if( $CoreCase.AdvancedLinkURL -eq "NA")
                        {$ReportSheet.Cells.Item($row,$column) = $CoreCase.AdvancedLinkURL}
                        else
                        {
                            $ReportSheet.Cells.Item($row,$column) ="View Case"
                         $ReportSheet.Hyperlinks.Add(
                            $ReportSheet.Cells.Item($row,$column),
                            "",
                            $CoreCase.AdvancedLinkURL,
                            "View Advanced eDiscovery Case at M365 Compliance Center",
                            $ReportSheet.Cells.Item($row,$column).Text
                            ) | Out-Null
                        }
                        $row++
                        $column=1
                        $count++
                    }
            
            $ReportSheet.columns.item(1).columnWidth = 20
            $ReportSheet.columns.item(2).columnWidth = 50
            $ReportSheet.columns.item(3).columnWidth = 50
            $ReportSheet.columns.item(4).columnWidth = 25
            $ReportSheet.columns.item(5).columnWidth = 25
            $ReportSheet.columns.item(6).columnWidth = 25
            $ReportSheet.columns.item(6).Style.WrapText = $true
        

            $workbook.SaveAs($ReportFile,51)
            $excel.Quit()

            [System.Runtime.InteropServices.Marshal]::ReleaseComObject([System.__ComObject]$excel) | Out-Null
            if(Test-Path -path $temporaryCsvFile) { 
                Remove-Item -path $temporaryCsvFile -ErrorAction Stop
                Write-Verbose "Temporary csv file deleted: $temporaryCsvFile" 
        }
            explorer.exe "/Select,$ReportFile"

            Write-Host "$(Get-Date) Report has been updated succesfully" -ForegroundColor:Green
            $InfoMessage = "$(Get-Date) INFO: Report has been updated succesfully"
            Write-Log -IsInfo -InfoMessage $InfoMessage -LogFile $LogFile -ErrorAction:SilentlyContinue

            Write-Host "$(Get-Date) Complete report is in $ReportFile" -ForegroundColor:Yellow
            $InfoMessage = "$(Get-Date) INFO: Complete report is in $ReportFile"
            Write-Log -IsInfo -InfoMessage $InfoMessage -LogFile $LogFile -ErrorAction:SilentlyContinue

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