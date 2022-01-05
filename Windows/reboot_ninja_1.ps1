#----------------------------------------------------
#GUI that prompts the user to reboot their computer.
#
#Created by William Huntley on 14 February 2020.
#----------------------------------------------------

Function Create-GetSchedTime {
Param(
$SchedTime
)
$script:StartTime = (Get-Date).AddSeconds($TotalTime)
$RestartDate = ((get-date).AddSeconds($TotalTime)).AddMinutes(-1)
$RDate = (Get-Date $RestartDate -f 'dd.MM.yyyy') -replace "\.","/"
$RTime = Get-Date $RestartDate -f 'HH:mm'
&schtasks /delete /tn "Post Maintenance Restart" /f
&schtasks /create /sc once /tn "Post Maintenance Restart" /tr "'C:\Windows\system32\cmd.exe' /c shutdown /r /t 400" /SD $RDate /ST $RTime /f
}
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName( "Microsoft.VisualBasic") | Out-Null
$Title = "DHTS Reboot Notification"
$Message = "In order to apply urgent security patches and updates to your computer, your machine must be restarted.
If you do not wish to restart your computer at this time please click on the cancel button below."
$Button1Text = "Restart now"
$Button2Text = "Postpone for 1 hour"
$Button3Text = "Postpone for 4 hours"
$Form = $null
$Button1 = $null
$Button2 = $null
$Label = $null
$TextBox = $null
$Result = $null
$timerUpdate = New-Object 'System.Windows.Forms.Timer'
$TotalTime = 300 #in seconds
Create-GetSchedTime -SchedTime $TotalTime
$timerUpdate_Tick={
# Define countdown timer
[TimeSpan]$span = $script:StartTime - (Get-Date)
# Update the display
$hours = "{0:00}" -f $span.Hours
$mins = "{0:00}" -f $span.Minutes
$secs = "{0:00}" -f $span.Seconds
$labelTime.Text = "{0}:{1}:{2}" -f $hours, $mins, $secs
$timerUpdate.Start()
if ($span.TotalSeconds -le 0)
{
$timerUpdate.Stop()
&schtasks /delete /tn "Post Maintenance Restart" /f
shutdown /r /t 0
}
}
$Form_StoreValues_Closing=
{
#Store the control values
}

$Form_Cleanup_FormClosed=
{
#Remove all event handlers from the controls
try
{
$Form.remove_Load($Form_Load)
$timerUpdate.remove_Tick($timerUpdate_Tick)
#$Form.remove_Load($Form_StateCorrection_Load)
$Form.remove_Closing($Form_StoreValues_Closing)
$Form.remove_FormClosed($Form_Cleanup_FormClosed)
}
catch [Exception]
{ }
}

# Form
$Form = New-Object -TypeName System.Windows.Forms.Form
$Form.Text = $Title
$Form.Size = New-Object -TypeName System.Drawing.Size(407,205)
$Form.StartPosition = "CenterScreen"
$Form.ControlBox = $False
$Form.Topmost = $true
$Form.KeyPreview = $true
$Form.ShowInTaskbar = $Formalse
$Form.FormBorderStyle = "FixedDialog"
$Form.MaximizeBox = $Formalse
$Form.MinimizeBox = $Formalse
$Icon = [system.drawing.icon]::ExtractAssociatedIcon("c:\Windows\System32\UserAccountControlSettings.exe")
$Form.Icon = $Icon

# Button One (Reboot/Shutdown Now)
$Button1 = New-Object -TypeName System.Windows.Forms.Button
$Button1.Size = New-Object -TypeName System.Drawing.Size(90,25)
$Button1.Location = New-Object -TypeName System.Drawing.Size(10,135)
$Button1.Text = $Button1Text
$Button1.Font = 'Tahoma, 10pt'
$Button1.Add_Click({
&schtasks /delete /tn "Post Maintenance Restart" /f
shutdown /r /t 0
$Form.Close()
})
$Form.Controls.Add($Button1)
# Button Two (Postpone for 1 Hour)
$Button2 = New-Object -TypeName System.Windows.Forms.Button
$Button2.Size = New-Object -TypeName System.Drawing.Size(133,25)
$Button2.Location = New-Object -TypeName System.Drawing.Size(105,135)
$Button2.Text = $Button2Text
$Button2.Font = 'Tahoma, 10pt'
$Button2.Add_Click({
$Button2.Enabled = $False
$timerUpdate.Stop()
$TotalTime = 3600
Create-GetSchedTime -SchedTime $TotalTime
$timerUpdate.add_Tick($timerUpdate_Tick)
$timerUpdate.Start()
})
$Form.Controls.Add($Button2)
# Button Three (Postpone for 4 Hours)
$Button3 = New-Object -TypeName System.Windows.Forms.Button
$Button3.Size = New-Object -TypeName System.Drawing.Size(140,25)
$Button3.Location = New-Object -TypeName System.Drawing.Size(243,135)
$Button3.Text = $Button3Text
$Button3.Font = 'Tahoma, 10pt'
$Button3.Add_Click({
$Button3.Enabled = $False
$timerUpdate.Stop()
$TotalTime = 14400
Create-GetSchedTime -SchedTime $TotalTime
$timerUpdate.add_Tick($timerUpdate_Tick)
$timerUpdate.Start()
})
$Form.Controls.Add($Button3)

# Label
$Label = New-Object -TypeName System.Windows.Forms.Label
$Label.Size = New-Object -TypeName System.Drawing.Size(445,35)
$Label.Location = New-Object -TypeName System.Drawing.Size(10,15)
$Label.Text = $Message
$label.Font = 'Tahoma, 10pt'
$Form.Controls.Add($Label)

# Label2
$Label2 = New-Object -TypeName System.Windows.Forms.Label
$Label2.Size = New-Object -TypeName System.Drawing.Size(355,30)
$Label2.Location = New-Object -TypeName System.Drawing.Size(10,100)
$Label2.Text = $Message2
$label2.Font = 'Tahoma, 10pt'
$Form.Controls.Add($Label2)

# labelTime
$labelTime = New-Object 'System.Windows.Forms.Label'
$labelTime.AutoSize = $True
$labelTime.Font = 'Arial, 26pt, style=Bold'
$labelTime.Location = '120, 60'
$labelTime.Name = 'labelTime'
$labelTime.Size = '43, 15'
$labelTime.TextAlign = 'MiddleCenter'
$labelTime.ForeColor = '242, 103, 34'
$Form.Controls.Add($labelTime)

#Start the timer
$timerUpdate.add_Tick($timerUpdate_Tick)
$timerUpdate.Start()
# Show
$Form.Add_Shown({$Form.Activate()})
#Clean up the control events
$Form.add_FormClosed($Form_Cleanup_FormClosed)
#Store the control values when form is closing
$Form.add_Closing($Form_StoreValues_Closing)
#Show the Form
$Form.ShowDialog() | Out-Null