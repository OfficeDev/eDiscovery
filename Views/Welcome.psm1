function Start-WelcomeUI {

Add-Type -AssemblyName PresentationFramework
Add-Type -assemblyName PresentationCore
Add-Type -assemblyName WindowsBase
$xamlFile = "$($(get-item $PSCommandPath).Directory.FullName)\XAML\Welcome.xaml"


$fileContent = Get-Content $xamlFile
$fileContent[10] = "<BitmapImage x:Key='MyImageSource1' UriSource='$($(get-item $PSCommandPath).Directory.parent.FullName)\Images\Icon1.png'/>"
$fileContent[11] = "<BitmapImage x:Key='MyImageSource2' UriSource='$($(get-item $PSCommandPath).Directory.parent.FullName)\Images\Icon2.png'/>"
$fileContent[12] = "<BitmapImage x:Key='MyImageSource3' UriSource='$($(get-item $PSCommandPath).Directory.parent.FullName)\Images\Icon3.png'/>"
$fileContent | Set-Content $xamlFile

#Create window
$inputXML = Get-Content $xamlFile -Raw

$inputXML = $inputXML -replace 'mc:Ignorable="d"', '' -replace "x:N", 'N' -replace '^<Win.*', '<Window'
[XML]$XAML = $inputXML

#Read XAML
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
$NotCloseEvent = $false

$Var_WPF_Button.Add_Click( {
    $NotCloseEvent = $true
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