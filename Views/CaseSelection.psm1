function Start-CaseSelectionUI {
    param([Mediator]$MediatorObj,
    $CoreCasesObj
    ) 

Add-Type -AssemblyName PresentationFramework
Add-Type -assemblyName PresentationCore
Add-Type -assemblyName WindowsBase
$xamlFile = "$($(get-item $PSCommandPath).Directory.FullName)\XAML\CaseSelection.xaml"

#Create window
$inputXML = Get-Content $xamlFile -Raw

$inputXML = $inputXML -replace 'mc:Ignorable="d"', '' -replace "x:N", 'N' -replace '^<Win.*', '<Window'
[XML]$XAML = $inputXML

$reader = (New-Object System.Xml.XmlNodeReader $xaml)
try {
    $window = [Windows.Markup.XamlReader]::Load( $reader )
} catch {
    Write-Warning $_.Exception
    throw
}


$xaml.SelectNodes("//*[@Name]") | ForEach-Object {
    try {
        Set-Variable -Name "Var_$($_.Name)" -Value $window.FindName($_.Name) -ErrorAction Stop
    } catch {
        throw
    }
}

$Var_CasesDataGrid.ItemsSource = $CoreCasesObj



$NotCloseEvent = $false

$Var_MigrateSelectedBtn.Add_Click( {
    $MediatorObj.IsIndividualMigrationSelected = $true
    $NotCloseEvent = $true
    $window.Close()       
    })

$Var_MigrateAllBtn.Add_Click( {
    $MediatorObj.IsAllMigrationSelected = $true
    $NotCloseEvent = $true
    $window.Close()       
    })

$Var_CloseBtn.Add_Click( {
    $window.Close()       
    })

$window.Add_Closing({
        $HasWindowClosedProperly = [System.Diagnostics.StackTrace]::new().GetFrames().GetMethod().Name -ccontains 'Close'
            if ($HasWindowClosedProperly -eq $false -and $NotCloseEvent -eq $false) {
                $global:WindowClosed = $true
            }
})

$Null = $window.ShowDialog()

}
