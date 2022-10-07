<#
.Synopsis
   Check if the process named ProcessName is running and close or continue the process based on the user's input
.DESCRIPTION
   Check if the process named ProcessName is running and close or continue the process based on the user's input
.EXAMPLE
   Close-KRC -ProcessName 'kaseyaremotecontrolhost.exe' -TimeoutMin 30
.NOTES
   Version 0.1
   Author: Proserv Team - VS
#>

param (
    [parameter(Mandatory=$false)]
    [string]$ProcessName ='kaseyaremotecontrolhost',

    [parameter(Mandatory=$false)]
    [int]$TimeoutMin = 30
)

$ProcessName = $ProcessName.Split('.')[0]
$Script:CountDown = $TimeoutMin*60

#region Load Assembly for creating form & button
[void][System.Reflection.Assembly]::LoadWithPartialName( "System.Windows.Forms")
[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.VisualBasic")
#endregion Load Assembly for creating form & button


#region Function Get-TheProcess
Function Get-TheProcess($ProcessName) {
    $(try {Get-Process -Name $ProcessName -ErrorAction Stop} catch {$null})
}
#endregion Function Get-TheProcess

#region Function CleanAndClose
Function CleanAndClose() {
    $Timer.Stop()
    $Form.Close()
    $Form.Dispose()
    $Timer.Dispose()
}
#endregion Function Get-TheProcess

#region Function Tick-Timer
Function Tick-Timer()
{
    --$Script:CountDown
    if ( 0 -gt $Script:CountDown ) {
        CleanAndClose
    } elseif ( $null -eq (Get-TheProcess($ProcessName)) ) {
        $Script:CountDown = -1
        CleanAndClose
        [Microsoft.VisualBasic.Interaction]::MsgBox("The administrator has disconnected from the KaseyaRemoteControl session.", "SystemModal,Information", 'The process $ProcessName closed')
    }
 }
 #endregion Function Tick-Timer


#####Define the form size & placement
$Form = New-Object System.Windows.Forms.Form;
$Form.Text = 'KaseyaRemoteControl is running on your computer. Would you want this to continue?'
$Form.Width = 500;
$Form.Height = 150;
$Form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen;

#############define Close Session button
$buttonCloseSession = New-Object System.Windows.Forms.Button;
$buttonCloseSession.Left = 50;
$buttonCloseSession.Top = 50;
$buttonCloseSession.Width = 120;
$buttonCloseSession.Text = 'Close Session';
$buttonCloseSession.DialogResult = [System.Windows.Forms.DialogResult]::No

#############define OK button
$buttonContinue = New-Object System.Windows.Forms.Button;
$buttonContinue.Left = 300;
$buttonContinue.Top = 50;
$buttonContinue.Width = 100;
$buttonContinue.Text = 'OK';
$buttonContinue.DialogResult = [System.Windows.Forms.DialogResult]::Yes

############# This is when you have to close the form after getting values
$eventHandler = [System.EventHandler] {
    CleanAndClose
}

$Timer = New-Object System.Windows.Forms.Timer
$Timer.Interval = 1000

$Timer.Add_Tick({ Tick-Timer})
$buttonCloseSession.Add_Click($eventHandler)
$buttonContinue.Add_Click($eventHandler)

#############Add controls to all the above objects defined
$Form.Controls.Add($buttonCloseSession)
$Form.Controls.Add($buttonContinue)
$Timer.Start()
$result = $Form.ShowDialog()

switch ( $result ) {
    Yes {
        'User decided to CONTINUE the session' | Write-Output
    }
    No {
        $TheProcess = Get-TheProcess($ProcessName)
        if ($null -ne ($TheProcess) ) {$TheProcess | Stop-Process -Force}
        'User decided to STOP the session' | Write-Output
    }
    Cancel {
        'TIMEOUT' | Write-Output
    }
}