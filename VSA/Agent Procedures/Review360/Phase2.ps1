Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Windows.Forms.DataVisualization
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.DirectoryServices.AccountManagement
# .Net methods for hiding/showing the console in the background
Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();

[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'
#region Functions
function Hide-Console {
    $consolePtr = [Console.Window]::GetConsoleWindow()
    #0 hide
    [Console.Window]::ShowWindow($consolePtr, 0)
}

function Set-ButtonState {
    if ( ($null -ne $listView.SelectedItems[0]) -and ( -not [string]::IsNullOrEmpty($txtBoxCompany.Text)) -and (-not [string]::IsNullOrEmpty($txtBoxScore.Text)) ) {
        $btnGenerateReport.Enabled = $true
    } else {
        $btnGenerateReport.Enabled = $false
    }
}

function New-Container () {
param (
    [parameter(Mandatory =$true, 
        ValueFromPipeline=$true)]
    [ValidateScript({
        if( -Not ( "$ScriptPath\Assets\$_" | Test-Path -PathType leaf ) ){
            throw "`nTemplate file [$_] not found"
        }
        return $true
    })]
    [string] $Template,

    [parameter(Mandatory =$true, 
        ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $OutputFile
    )

    $TemplatePath = Join-Path -Path "$ScriptPath\Assets" -ChildPath $Template
    Copy-Item -Path $TemplatePath -Destination $OutputFile -Force -Confirm:$false
}

function Get-EntryString {
[OutputType([String])]
param (
    [System.IO.Compression.ZipArchive] $Container,
    [parameter(Mandatory =$true, 
        ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $EntryName
    )
    $EntryObject = $Container.GetEntry( $EntryName )
    Write-Debug "Get Entry [$EntryName] in archive [$Container]"
    if ( $null -ne $EntryObject ) {
        $Entry = $EntryObject.Open()
        $buffer = [System.Array]::CreateInstance([byte], $Entry.Length)
        $null = $Entry.Read($buffer, 0, $Entry.Length)
        $EntryAsString = [System.Text.Encoding]::UTF8.GetString($buffer)
        $Entry.Close()
    } else {
        Write-Debug "No Entry [$EntryName] in archive [$Container]!"
    }
    return $EntryAsString
}
    
function Set-EntryString {
param (
    [System.IO.Compression.ZipArchive] $Container,

    [parameter(Mandatory =$true, 
        ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $EntryName,

    [ValidateNotNullOrEmpty()]
    [string] $EntryString
    )
    $EntryObject = $Container.GetEntry( $EntryName )
    Write-Debug "Get Entry [$EntryName] in archive [$Container]"
    if ( $null -ne $EntryObject ) {
        $Entry = $EntryObject.Open()

        $buffer = [System.Text.Encoding]::UTF8.GetBytes($EntryString)
        $null = $Entry.Seek(0, [System.IO.SeekOrigin]::Begin)
        $Entry.SetLength($buffer.Length)
        $Entry.Write($buffer, 0, $buffer.Length)
        $Entry.Close()
    } else {
        Write-Debug "No Entry [$EntryName] in archive [$Container]!"
    }
}

#endregion Functions
$PrincipalContext = New-Object System.DirectoryServices.AccountManagement.PrincipalContext('Domain') -ErrorAction SilentlyContinue

$ScriptPath = Split-Path $script:MyInvocation.MyCommand.Path
$Script:TheProduct = [string]::Empty
[array]$FormControls = @()

# The form window
[int] $imageSize = 48
[string] $iconBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAAAXNSR0IArs4c6QAABEBJREFUeF7tW3lMFFcc/oZdjkUQoYfFaDAiKjZAjTF4JN66aCiBBCWaVVutDUnTUOsRE62aeEbjGRKjiKYpmmi0ghwSLyAmpVASitBaYoy2VQ
ItxuiuF+zOMzPLrIu7q3Ptmri/+Wtn5vfe+77v/d7ve5PZ4SAclvMLAZwWfwfPkYeSnDNckJKXpjlPEIAFz6R7MiUBKANoCVANoCJILhDECpANkg2SDZINkg0GsQmAXIBcgFyAXIBcgFzAzwpUr5sMc8rH4iic5TzAcbAWZWJn+S3s
qGgHHEy89i4Ov9rg2KHR+GPnLBeveXvqUX2jC2AMrCTHg+9fHVasPtWGquZOICQwgvhFAAG6rfhzRIYZXCQZA0KWlornWxckY2PW6LdO+MWWLmQf+BU9dv+VKd0FWD49AcUrxnmQ+zC/Eg+e9IrX2U/ZXsn3OnhkH2xEVVMHYAjxiO
EEFYX2Oi4X/QRgDM9OZCEi9NWsSwwcPINxWZl4WrgsFd/MHuEi12vnkfZDDW7+awWkrOcZEuOjsDU3GRkpgxE7INRDjNqb3Zix/brm2qGLAKkJMWjZNsNnSnOWUic5t7V/tqkDC/Y3ONc6A9ISBqJizSQMjTW9dWm4B9ie2xG9skJR
G/dgzQLss6RglTnRJ4DHz3oR83WleL9l+0zUtnej4McWceYMHNC6axaSh0SrJuBeW9R0okmAb82JOGRJeeO4phXleN7jEGdfsrpPYiNwZ+8cr8tFKYmQJaVCAqk+1AvAAFbivZh5W/vStZ+/S0fO+HjVgPulb9+eQktnfhVgzNoraO
+0ITYqFAPCjbjX/dSVBaZwA+4dMCMuKkwVfmlDpaqxWyP1AgDYvehTrJ2f5Lv4LXH6vrvtCUVryKpLsNp6nO0Yw15LKr7P8F1H3AfgeQZDn6NoJS+01ySA0EH95qmYODLOA8vcPb/g8o3/sHjKMJzMH+8Va25hI841dPQJAWRNiEdZ
QbpPXre7bBi55ooevF19aBZA6Kn4q3FYPi2hHzDOy+z7Qp664Rpa/3nsuj0xKQ71m6b2Cz9W9zdWHmvWlbwuGSAhSh42EH/umCmeSmAjI4x4UpQpC/QLO4+IL8r6bWzMnw1G9epJGLX+Km7dt8rqR2mQLhngPqiw3qUCdWffXAz/KF
IRpiM1d5F//HdFbbQE6y6AC4yPJz65YMO/vIAeOy83XHWc3wQIMxnx4qi89H8dfW7hbzjXcF81KSUN/SaACIIxPCzKxCCT58OMN5B2Bw9h5nktWzsl7PWwQTnjxUSFortwHoxeHnGl9ulb6tB4+6Gc7nSN8W8GvAZVeCD8//B8fNC3
++MZQ9qmWrTdfaQrKSWdBVQAJcACFUsC0KsxejVGr8YC6LqBKm3yx6EiSEWQiiAVQSqC8mvm+xdJLkAuQC5ALkAu8P7VdvmMyAXIBYLzy3FpjeQ5/5YUnCKIn8+/BEt0mmpycuo8AAAAAElFTkSuQmCC'

$iconBytes = [Convert]::FromBase64String($iconBase64)
$stream    = [System.IO.MemoryStream]::new($iconBytes, 0, $iconBytes.Length)

$form      = New-Object System.Windows.Forms.Form
$form.Text = "Kaseya 360 review"
$form.Size = New-Object System.Drawing.Size( $($imageSize * 20), $($imageSize * 10) )
$form.Icon = [System.Drawing.Icon]::FromHandle(([System.Drawing.Bitmap]::new($stream).GetHIcon()))

$handler_FormLoad = {
    Hide-Console
}
$form.add_Load($handler_FormLoad)

#region analysis DataGridView
[int] $ListWidth      = $imageSize * 6
[int] $ListHeight     = $imageSize * 5
[int] $ListX          = $imageSize * 8
[int] $ListY          = $imageSize * 3

$dataGridView = New-Object System.Windows.Forms.DataGridView
$dataGridView.Location = New-Object System.Drawing.Point($ListX, $ListY)
$dataGridView.Size = New-Object System.Drawing.Size($ListWidth, $ListHeight)
$dataGridView.Visible = $false
$FormControls += $dataGridView

$dataTable = New-Object System.Data.DataTable
$dataTable.Columns.Add("Category")
$dataTable.Columns.Add("Value")

#endregion analysis DataGridView

#region choose product
#[int] $ListWidth      = $imageSize * 6
[int] $ListHeight     = $imageSize * 8
[int] $ListX          = $imageSize / 4
[int] $ListY          = $imageSize / 2


$listView             = New-Object System.Windows.Forms.ListView
$listView.Location    = New-Object System.Drawing.Point($ListX, $ListY)
$listView.Size        = New-Object System.Drawing.Size( $ListWidth, $ListHeight)
$listView.View        = 'Details'
$listView.MultiSelect = $false

$imageList            = New-Object System.Windows.Forms.ImageList
$imageList.ImageSize  = New-Object System.Drawing.Size($imageSize, $imageSize)  # Set the desired image size

$listView.Columns.Add('Chose a product to review', $ListWidth) | Out-Null

$ListViewItems = @(
    @{Text = "AutoTask"; Image = "$ScriptPath\Assets\autotask.png"},
    @{Text = "BCDR"; Image = "$ScriptPath\Assets\bcdr.png"},
    @{Text = "BMS"; Image = "$ScriptPath\Assets\bms.png"},
    @{Text = "DRMM"; Image = "$ScriptPath\Assets\drmm.png"},
    @{Text = "ITG"; Image = "$ScriptPath\Assets\itg.png"},
    @{Text = "Traverse"; Image = "$ScriptPath\Assets\traverse.png"},
    @{Text = "Unitrends"; Image = "$ScriptPath\Assets\unitrends.png"},
    @{Text = "Vorex"; Image = "$ScriptPath\Assets\vorex.png"},
    @{Text = "VSA"; Image = "$ScriptPath\Assets\vsa.png"}
)

# Add items to the list view
foreach ($item in $ListViewItems) {
    $listViewItem = New-Object System.Windows.Forms.ListViewItem
    $listViewItem.Text = $item.Text

    if (Test-Path $item.Image) {
        $image = [System.Drawing.Image]::FromFile($item.Image)
        $imageList.Images.Add($image)
        $listViewItem.ImageIndex = $imageList.Images.Count - 1
    }

    $listView.Items.Add($listViewItem) | Out-Null
}
# Set the image list for the list view
$listView.SmallImageList = $imageList

$FormControls += $listView

# Event handler for the SelectedIndexChanged event
$handler_SelectedIndexChanged = {
    $selectedItem = $listView.SelectedItems[0]
    if ($selectedItem) {
        $Script:TheProduct = $selectedItem.Text
        $imageIndex = $selectedItem.ImageIndex
        Write-Debug "Selected Item: $Script:TheProduct (Image Index: $imageIndex)"

        [array] $AnalysisValues = @()
        switch ($Script:TheProduct) { #the small logo
            'autotask'  { $AnalysisValues += @('')}            
            'bcdr'      { $AnalysisValues += @('')}
            'bms'       { $AnalysisValues += @('')}
            'drmm'      { $AnalysisValues += @('')}
            'itg'       { $AnalysisValues += @('')}
            'traverse'  { $AnalysisValues += @('')}
            'unitrends' { $AnalysisValues += @('')}
            'vorex'     { $AnalysisValues += @('')}
            'vsa'       { $AnalysisValues += @(
                            @('Automation', 25),
                            @('Policies', 25),
                            @('Patching', 25),
                            @('Monitoring', 25)
                            )
                        }
        }

        $dataTable.Clear()
        $AnalysisValues | ForEach-Object {
            $row = $dataTable.NewRow()
            $row[0] = $_[0]
            $row[1] = $_[1]
            $dataTable.Rows.Add($row)
            $dataGridView.DataSource = $dataTable
        }

    }
    $labelGeneral.Visible = $true
    $dataGridView.Visible = $true
    $labelGeneral.Text = "Review for the product: $Script:TheProduct"
    Set-ButtonState
}

# Add the event handler to the SelectedIndexChanged event
$listView.add_SelectedIndexChanged($handler_SelectedIndexChanged)
#endregion choose product

#label
$labelGeneral           = New-Object System.Windows.Forms.Label
$labelGeneral.Location  = New-Object System.Drawing.Point($($imageSize * 7), $($imageSize /2 ))
$labelGeneral.Size      = New-Object System.Drawing.Size($($imageSize * 10), $($imageSize /2 ))
$labelGeneral.TextAlign = [System.Drawing.ContentAlignment]::TopCenter
$labelGeneral.Visible   = $false
$labelGeneral.Text      = 'Review for the product:'
$FormControls += $labelGeneral

#Enter Company text box
$txtBoxCompany          = New-Object System.Windows.Forms.TextBox
$txtBoxCompany.Location = New-Object System.Drawing.Point( $($imageSize * 10), $imageSize)
$txtBoxCompany.Size     = New-Object System.Drawing.Size($($imageSize * 2), $($imageSize /2 ))
$FormControls += $txtBoxCompany

$labelCompany           = New-Object System.Windows.Forms.Label
$labelCompany.Location  = New-Object System.Drawing.Point($($imageSize * 7), $imageSize)
$labelCompany.Size      = New-Object System.Drawing.Size($($imageSize * 3), $($imageSize /2 ))
$labelCompany.Text      = 'Company name'
$labelCompany.TextAlign = [System.Drawing.ContentAlignment]::TopCenter

$FormControls += $labelCompany
# Event handler for the KeyPress event of the Company text
$handler_CompanyTextBoxKeyPress = {
    Set-ButtonState
}
# Event handler for the Leave event of the Company textbox
$handler_CompanyTextBoxLeave = {
    Set-ButtonState
}

# Add the event handlers to the textbox
$txtBoxCompany.add_KeyPress($handler_CompanyTextBoxKeyPress)
$txtBoxCompany.add_Leave($handler_CompanyTextBoxLeave)

#Health Score textbox for numeric input
$txtBoxScore          = New-Object System.Windows.Forms.TextBox
$txtBoxScore.Location = New-Object System.Drawing.Point($($imageSize * 10), $($imageSize*1.5 ))
$txtBoxScore.Size     = New-Object System.Drawing.Size( $imageSize, $($imageSize /2 ))
$FormControls += $txtBoxScore


$labelScore           = New-Object System.Windows.Forms.Label
$labelScore.Location  = New-Object System.Drawing.Point($($imageSize * 7), $($imageSize*1.5 ))
$labelScore.Size      = New-Object System.Drawing.Size($($imageSize * 3), $($imageSize /2 ))
$labelScore.Text      = 'Health Score'
$labelScore.TextAlign = [System.Drawing.ContentAlignment]::TopCenter
$FormControls += $labelScore


# Event handler for the KeyPress event of the Score text
$handler_ScoreTextBoxKeyPress = {
    param ($sender, $e)

    # Check if the pressed key is a valid digit
    if (-not [char]::IsDigit($e.KeyChar)) {
        # Handle non-digit characters
        $e.Handled = $true
    }
    Set-ButtonState
}

# Event handler for the Leave event of the Score textbox
$handler_ScoreTextBoxLeave = {
    param ($sender, $e)
    $text = $sender.Text
    $number = [int]$text

    # Check if the number is within the valid range
    if ($number -lt 1 -or $number -gt 100) {
        $sender.Text = ''
        $sender.Focus()
    }
    Set-ButtonState
}

# Add the event handlers to the txtBoxScore input field
$txtBoxScore.add_KeyPress($handler_ScoreTextBoxKeyPress)
$txtBoxScore.add_Leave($handler_ScoreTextBoxLeave)

# Create the Generate Report button
$btnGenerateReport          = New-Object System.Windows.Forms.Button
$btnGenerateReport.Text     = "Generate review"
$btnGenerateReport.Location = New-Object System.Drawing.Point($($imageSize * 16), $($imageSize * 6))
$btnGenerateReport.Size     = New-Object System.Drawing.Size($($imageSize * 3), $($imageSize / 2))
$btnGenerateReport.Enabled  = $false

$FormControls += $btnGenerateReport

# Event handler for the Generate Report click event
$handler_ButtonClick = {
    #
    $saveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
    $saveFileDialog.Filter = "Word Document (*.docx)|*.docx"
    $saveFileDialog.DefaultExt = "docx"
    $saveFileDialog.Title = "Save File"
    $saveFileDialog.FileName = "$Script:TheProduct"
    $saveFileDialog.InitialDirectory = "$ScriptPath"
    #region Generate the report
    if ($saveFileDialog.ShowDialog() -eq 'OK') {
        $ReviewDoc = $saveFileDialog.FileName

        New-Container -Template 'txtTemplate.360' -OutputFile $ReviewDoc

        [string] $xlFileName = 'Microsoft_Excel_Worksheet.xlsx'
        $xlEmbedded = Join-Path -Path "$ScriptPath\Assets" -ChildPath $xlFileName
        New-Container -Template 'xlTemplate.360' -OutputFile $xlEmbedded

        Write-Debug "Report File saved as: [$ReviewDoc]"

        $btnGenerateReport.Enabled = $false
        
        $labelGeneral.Text = "One moment, please"
        $btnGenerateReport.Text = "File is being saved"
        
        #release graphical resources occupied by the $listView
        $listView.Dispose()

        #Get New Logo File
        $Script:TheProduct = $Script:TheProduct.ToLower()
        Write-Debug "TheProduct: $Script:TheProduct"
    
        Write-Debug "NewLogo: $NewLogo"
        #Open the word document
    
        $DocFile = [System.IO.Compression.ZipFile]::Open($ReviewDoc, 'Update')    
        #region process the word document's graphics
    
        #Get New Logo File
        $Script:TheProduct = $Script:TheProduct.ToLower()
        $NewLogo = Join-Path -Path "$ScriptPath\Assets" -ChildPath "$Script:TheProduct.png"

        Write-Debug "TheProduct: $Script:TheProduct"
        Write-Debug "NewLogo: $NewLogo"
    
        [string[]]$LogoPath = @('word/media/image1.png') #the big logo

        switch ($Script:TheProduct) { #the small logo
            'autotask'  { $LogoPath += 'word/media/image13.png'}
            'bcdr'      { $LogoPath += 'word/media/image17.png'}
            'bms'       { $LogoPath += 'word/media/image11.png'}
            'drmm'      { $LogoPath += 'word/media/image10.png'}
            'itg'       { $LogoPath += 'word/media/image14.png'}
            'traverse'  { $LogoPath += 'word/media/image15.png'}
            'unitrends' { $LogoPath += 'word/media/image16.png'}
            'vorex'     { $LogoPath += 'word/media/image12.png'}
            'vsa'       { $LogoPath += 'word/media/image9.png' }
        }
        $LogoPath | Out-String | Write-Debug
    
        foreach ($Logo in $LogoPath) {
            $LogoInTheDoc = $DocFile.GetEntry( $Logo )
            if ( $null -ne $LogoInTheDoc ) {
                $LogoInTheDoc.Delete()
                Write-Debug "Deleted in DOCX: $Logo"
            }
            Write-Debug "Add to $DocFile : [$NewLogo] as [$Logo]"
            Try {
                [IO.Compression.ZipFileExtensions]::CreateEntryFromFile( $DocFile, $NewLogo, $Logo )
            }
            Catch {"Error creating entry";$Error[0];break}
        }
        #endregion process the word document's graphics

        #region process the word document's text
        #Get Current user's display name
        if ( $null -ne $PrincipalContext) {
        $DisplayName = [System.DirectoryServices.AccountManagement.UserPrincipal]::FindByIdentity($PrincipalContext, [System.DirectoryServices.AccountManagement.IdentityType]::SamAccountName, $env:USERNAME) `
                                    | Select-Object -ExpandProperty DisplayName
        } else {  $DisplayName = $env:USERNAME }
        $Date        = [datetime]::Now.ToString('MM\/dd\/yyyy')
        $CompanyName = [System.Security.SecurityElement]::Escape($txtBoxCompany.Text)
        $Product     = ($Script:TheProduct).ToUpper()
        $ScoreText   = [string]::Empty
        $ScoreColor  = [string]::Empty

        switch ( $([int]$txtBoxScore.Text) )
        {
            ({$PSItem -le 49}) {
                $ScoreText =  'A score ranging from 1% to 49% reflects a below-average level of configuration and optimization of #Product#. Such a score indicates that your instance of #Product# is not effectively utilizing its capabilities, resulting in suboptimal performance and efficiency. The configuration settings may be misaligned, causing bottlenecks or compatibility issues. Optimization techniques, such as optimization or fine-tuning, have not been adequately implemented. To improve #Product# utilization, it would be necessary to review and adjust the configuration settings and implement optimization strategies to enhance its overall functionality.'
                $ScoreColor = 'FF0000'
            }
            ({ $PSItem -ge 50 -and $PSItem -lt 80}) {
                $ScoreText =  'A score ranging from 50% to 79% suggests that #Product# is generally configured and optimized at an average level. While it may possess some functional and operational effectiveness, there is room for improvement in terms of maximizing its performance and efficiency. Your instance of #Product# likely meets basic requirements and performs adequately but may fall short of delivering exceptional results or optimal user experiences. Enhancements and fine-tuning could be implemented to achieve higher levels of productivity, stability, and user satisfaction.'
                $ScoreColor = 'FFC000'
            }
            ({ $PSItem -ge 80 }) {
                $ScoreText =  'A score ranging from 80%-100% signifies an above-average level of configuration and optimization of #Product#. It indicates that #Product# has been meticulously fine-tuned to deliver exceptional performance and efficiency. With such a score, your instance of #Product# exhibits optimized resource utilization, streamlined workflows, and minimal bottlenecks. It showcases the implementation of best practices, ensuring smooth operation and reliability. Such high scores indicate a thorough understanding of #Product# infrastructure and a commitment to refining it for optimal functionality and user experience.'
                $ScoreColor = '00B050'
            }
        
        }
    
        $body = Get-EntryString -Container $DocFile -EntryName 'word/document.xml'
        $body = $body.Replace('#Color#', $ScoreColor)
        $body = $body.Replace('#Date#', $Date)
        $body = $body.Replace('#Author#', $DisplayName)
        $body = $body.Replace('#ScoreText#', $ScoreText)
        $body = $body.Replace('#Company#', $CompanyName)
        $body = $body.Replace('#Product#', $Product)
        $body = $body.Replace('#ScoreValue#', $txtBoxScore.Text)
        Set-EntryString -Container $DocFile -EntryName 'word/document.xml' -EntryString $body
        #endregion process the word document's text

        #region process Analysis diagram
        $editedData = @()

        foreach ($row in $dataGridView.Rows) {
            if ($row.Cells['Category'].Value -ne $null -and $row.Cells['Value'].Value -ne $null) {
                $editedData += @{
                    'Category' = $row.Cells['Category'].Value
                    'Value'  = $row.Cells['Value'].Value
                }
            }
        }

        if ($editedData.Count -gt 0) {
        
            [string]$Chart = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<c:chartSpace xmlns:c="http://schemas.openxmlformats.org/drawingml/2006/chart" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:c16r2="http://schemas.microsoft.com/office/drawing/2015/06/chart"><c:date1904 val="0"/><c:lang val="en-US"/><c:roundedCorners val="0"/><mc:AlternateContent xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"><mc:Choice Requires="c14" xmlns:c14="http://schemas.microsoft.com/office/drawing/2007/8/2/chart"><c14:style val="103"/></mc:Choice><mc:Fallback><c:style val="3"/></mc:Fallback></mc:AlternateContent><c:chart><c:autoTitleDeleted val="1"/><c:plotArea><c:layout/><c:pieChart><c:varyColors val="1"/><c:ser><c:idx val="0"/><c:order val="0"/><c:tx><c:strRef><c:f>Sheet1!$B$1</c:f><c:strCache><c:ptCount val="1"/><c:pt idx="0"><c:v>Problem Areas</c:v></c:pt></c:strCache></c:strRef></c:tx>#dPt#<c:dLbls>#Labels#<c:spPr><a:solidFill><a:sysClr val="window" lastClr="FFFFFF"/></a:solidFill><a:ln><a:solidFill><a:srgbClr val="4472C4"><a:tint val="58000"/></a:srgbClr></a:solidFill></a:ln><a:effectLst/></c:spPr><c:dLblPos val="outEnd"/><c:showLegendKey val="0"/><c:showVal val="0"/><c:showCatName val="1"/><c:showSerName val="0"/><c:showPercent val="1"/><c:showBubbleSize val="0"/><c:showLeaderLines val="0"/><c:extLst><c:ext uri="{CE6537A1-D6FC-4f65-9D91-7224C49458BB}" xmlns:c15="http://schemas.microsoft.com/office/drawing/2012/chart"><c15:spPr xmlns:c15="http://schemas.microsoft.com/office/drawing/2012/chart"><a:prstGeom prst="wedgeRectCallout"><a:avLst/></a:prstGeom><a:noFill/><a:ln><a:noFill/></a:ln></c15:spPr></c:ext></c:extLst></c:dLbls>#Category##Value#<c:extLst><c:ext uri="{C3380CC4-5D6E-409C-BE32-E72D297353CC}" xmlns:c16="http://schemas.microsoft.com/office/drawing/2014/chart"><c16:uniqueId val="{00000000-F7BA-4441-909C-807B5BA9C3BF}"/></c:ext></c:extLst></c:ser><c:dLbls><c:dLblPos val="outEnd"/><c:showLegendKey val="0"/><c:showVal val="0"/><c:showCatName val="1"/><c:showSerName val="0"/><c:showPercent val="1"/><c:showBubbleSize val="0"/><c:showLeaderLines val="0"/></c:dLbls><c:firstSliceAng val="0"/></c:pieChart><c:spPr><a:noFill/><a:ln><a:noFill/></a:ln><a:effectLst/></c:spPr></c:plotArea><c:plotVisOnly val="1"/><c:dispBlanksAs val="gap"/><c:extLst><c:ext uri="{56B9EC1D-385E-4148-901F-78D8002777C0}" xmlns:c16r3="http://schemas.microsoft.com/office/drawing/2017/03/chart"><c16r3:dataDisplayOptions16><c16r3:dispNaAsBlank val="1"/></c16r3:dataDisplayOptions16></c:ext></c:extLst><c:showDLblsOverMax val="0"/></c:chart><c:spPr><a:solidFill><a:schemeClr val="bg1"/></a:solidFill><a:ln w="9525" cap="flat" cmpd="sng" algn="ctr"><a:noFill/><a:round/></a:ln><a:effectLst/></c:spPr><c:txPr><a:bodyPr/><a:lstStyle/><a:p><a:pPr><a:defRPr/></a:pPr><a:endParaRPr lang="en-US"/></a:p></c:txPr><c:externalData r:id="rId3"><c:autoUpdate val="0"/></c:externalData></c:chartSpace>
'@
            $dPt      = [string]::Empty
            $Labels   = [string]::Empty
            [string]$Category = '<c:cat><c:strRef><c:f>Sheet1!$A$2:$A${0}</c:f><c:strCache><c:ptCount val="{1}"/>' -f $($editedData.Count + 1), $editedData.Count
            [string]$Value    = '<c:val><c:numRef><c:f>Sheet1!$B$2:$B${0}</c:f><c:numCache><c:formatCode>General</c:formatCode><c:ptCount val="{1}"/>'  -f $($editedData.Count + 1), $editedData.Count
            
            #build new nodes by hand and force it to be an XML object
            [int] $HSLStart = 50000
            [int] $HSLStep  = 5000
            for ($i = 0 ; $i -lt $editedData.Count ; $i++) {
                $dPt += '<c:dPt><c:idx val="{0}"/><c:bubble3D val="0"/><c:spPr><a:solidFill><a:schemeClr val="accent1"><a:tint val="{3}"/></a:schemeClr></a:solidFill><a:ln><a:noFill/></a:ln><a:effectLst><a:outerShdw blurRad="63500" sx="102000" sy="102000" algn="ctr" rotWithShape="0"><a:prstClr val="black"><a:alpha val="20000"/></a:prstClr></a:outerShdw></a:effectLst></c:spPr><c:extLst><c:ext uri="{1}" xmlns:c16="http://schemas.microsoft.com/office/drawing/2014/chart"><c16:uniqueId val="{2}"/></c:ext></c:extLst></c:dPt>' -f $i, '{C3380CC4-5D6E-409C-BE32-E72D297353CC}', "{$((New-Guid | Select-Object -ExpandProperty Guid).ToUpper())}", $($HSLStart +$i*$HSLStep)
                $Labels += '<c:dLbl><c:idx val="{0}"/><c:spPr><a:solidFill><a:sysClr val="window" lastClr="FFFFFF"/></a:solidFill><a:ln><a:solidFill><a:srgbClr val="4472C4"><a:tint val="{5}"/></a:srgbClr></a:solidFill></a:ln><a:effectLst/></c:spPr><c:txPr><a:bodyPr rot="0" spcFirstLastPara="1" vertOverflow="clip" horzOverflow="clip" vert="horz" wrap="square" lIns="38100" tIns="19050" rIns="38100" bIns="19050" anchor="ctr" anchorCtr="1"><a:spAutoFit/></a:bodyPr><a:lstStyle/><a:p><a:pPr><a:defRPr sz="1000" b="1" i="0" u="none" strike="noStrike" kern="1200" baseline="0"><a:solidFill><a:schemeClr val="accent1"><a:tint val="{4}"/></a:schemeClr></a:solidFill><a:latin typeface="+mn-lt"/><a:ea typeface="+mn-ea"/><a:cs typeface="+mn-cs"/></a:defRPr></a:pPr><a:endParaRPr lang="en-US"/></a:p></c:txPr><c:dLblPos val="outEnd"/><c:showLegendKey val="0"/><c:showVal val="0"/><c:showCatName val="1"/><c:showSerName val="0"/><c:showPercent val="1"/><c:showBubbleSize val="0"/><c:extLst><c:ext uri="{1}" xmlns:c15="http://schemas.microsoft.com/office/drawing/2012/chart"><c15:spPr xmlns:c15="http://schemas.microsoft.com/office/drawing/2012/chart"><a:prstGeom prst="wedgeRectCallout"><a:avLst/></a:prstGeom><a:noFill/><a:ln><a:noFill/></a:ln></c15:spPr></c:ext><c:ext uri="{2}" xmlns:c16="http://schemas.microsoft.com/office/drawing/2014/chart"><c16:uniqueId val="{3}"/></c:ext></c:extLst></c:dLbl>' -f $i, '{CE6537A1-D6FC-4f65-9D91-7224C49458BB}', '{C3380CC4-5D6E-409C-BE32-E72D297353CC}', "{$((New-Guid | Select-Object -ExpandProperty Guid).ToUpper())}", $($HSLStart +$i*$HSLStep), $($HSLStart +$i*$HSLStep)
                $Category += '<c:pt idx="{0}"><c:v>{1}</c:v></c:pt>' -f $i, $editedData[$i].Category
                $Value += '<c:pt idx="{0}"><c:v>{1}</c:v></c:pt>' -f $i, $editedData[$i].Value
            }
            $Category += '</c:strCache></c:strRef></c:cat>'
            $Value    += '</c:numCache></c:numRef></c:val>'
            $Chart = $Chart -replace '#dPt#', $dPt -replace '#Labels#', $Labels -replace '#Category#', $Category -replace '#Value#', $Value

            Set-EntryString -Container $DocFile -EntryName 'word/charts/chart1.xml' -EntryString $Chart 
        }
        #endregion process Analysis diagram

        #region process embedded Excel
        $XLFile = [System.IO.Compression.ZipFile]::Open($xlEmbedded, 'Update')
        [string]$Sheet = @"
<?xml version=`"1.0`" encoding=`"UTF-8`" standalone=`"yes`"?>
<worksheet xmlns=`"http://schemas.openxmlformats.org/spreadsheetml/2006/main`" xmlns:r=`"http://schemas.openxmlformats.org/officeDocument/2006/relationships`" xmlns:mc=`"http://schemas.openxmlformats.org/markup-compatibility/2006`" mc:Ignorable=`"x14ac xr xr2 xr3`" xmlns:x14ac=`"http://schemas.microsoft.com/office/spreadsheetml/2009/9/ac`" xmlns:xr=`"http://schemas.microsoft.com/office/spreadsheetml/2014/revision`" xmlns:xr2=`"http://schemas.microsoft.com/office/spreadsheetml/2015/revision2`" xmlns:xr3=`"http://schemas.microsoft.com/office/spreadsheetml/2016/revision3`" xr:uid=`"{2D4EB63A-BE9E-431F-B9A8-8BC561016770}`"><dimension ref=`"A1:B$($editedData.Count + 1)`"/><sheetViews><sheetView tabSelected=`"1`" workbookViewId=`"0`"><selection activeCell=`"B2`" sqref=`"B2`"/></sheetView></sheetViews><sheetFormatPr defaultRowHeight=`"14.4`" x14ac:dyDescent=`"0.3`"/><cols><col min=`"1`" max=`"1`" width=`"11`" customWidth=`"1`"/><col min=`"2`" max=`"2`" width=`"13.6640625`" customWidth=`"1`"/></cols><sheetData><row r=`"1`" spans=`"1:2`" x14ac:dyDescent=`"0.3`"><c r=`"A1`" t=`"s`"><v>0</v></c><c r=`"B1`" t=`"s`"><v>1</v></c></row>
"@

             
            #build new nodes by hand and force it to be an XML object
        for ([int] $i = 0 ; $i -lt $editedData.Count ; $i++) {
            $Sheet += '<row r="{0}" spans="1:2" x14ac:dyDescent="0.3"><c r="A{1}" t="s"><v>{2}</v></c><c r="B{3}"><v>{4}</v></c></row>' -f $($i + 2), $($i + 2), $($i + 2), $($i + 2), $editedData[$i].Value
        }
        $Sheet += '</sheetData><pageMargins left="0.7" right="0.7" top="0.75" bottom="0.75" header="0.3" footer="0.3"/><tableParts count="1"><tablePart r:id="rId1"/></tableParts></worksheet>'
        
        Set-EntryString -Container $XLFile -EntryName 'xl/worksheets/sheet1.xml' -EntryString $Sheet
############

       [string]$sharedStrings = @"
<?xml version=`"1.0`" encoding=`"UTF-8`" standalone=`"yes`"?>
<sst xmlns=`"http://schemas.openxmlformats.org/spreadsheetml/2006/main`" count=`"$($editedData.Count + 2)`" uniqueCount=`"$($editedData.Count + 2)`"><si><t xml:space=`"preserve`"> </t></si><si><t>Problem Areas</t></si>
"@
        #build new nodes by hand and force it to be an XML object
        for ([int] $i = 0 ; $i -lt $editedData.Count ; $i++) {
            $sharedStrings += '<si><t>{0}</t></si>' -f $editedData[$i].Category
        }

        $sharedStrings += '</sst>'

        Set-EntryString -Container $XLFile -EntryName 'xl/sharedStrings.xml' -EntryString $sharedStrings

        $XLFile.Dispose()
        #endregion process embedded Excel

        #region update Embedded Excel

        $EntryName = "word/embeddings/$xlFileName"
        $ExcelInTheDoc = $DocFile.GetEntry( $EntryName )
        if ( $null -ne $ExcelInTheDoc ) {
            $ExcelInTheDoc.Delete()
            Write-Debug "Deleted in DOCX: $ExcelInTheDoc"
        }
        Write-Debug "Add to $DocFile : [$ExcelInTheDoc]"
        Try {
            [IO.Compression.ZipFileExtensions]::CreateEntryFromFile( $DocFile, $xlEmbedded, $EntryName )
        }
        Catch {"Error creating entry";$Error[0];break}
        #endregion update Embedded Excel

        #Cleanup
        Remove-Item $xlEmbedded -Force -Confirm:$false
        
        $DocFile.Dispose()
        $form.Close()
    }
    
    #endregion Generate the report
}

# Add the event handler to the button click event
$btnGenerateReport.add_Click($handler_ButtonClick)

# Add the controls to the form
$FormControls | ForEach-Object {$form.Controls.Add($_)}

[void]$form.ShowDialog()