$PendingReboot = $false
Add-Type -AssemblyName System.Windows.Forms

function Check-Updates {
    # Counts Updates (includes 3rd party things like hp drives etc)
    Write-Host "Checking for updates..."
    $UpdateSession = New-Object -ComObject Microsoft.Update.Session
    $UpdateSearcher = $UpdateSession.CreateupdateSearcher()
    $Updates = @($UpdateSearcher.Search("IsHidden=0 and IsInstalled=0").Updates)
    $global:count_updates_pending = $Updates | Measure-Object | Select-Object -ExpandProperty Count
}

Check-Updates

if ($count_updates_pending -gt 0) {
  Write-Host "$count_updates_pending"
  $PendingReboot = $true
}

function Start-Timer {
    #Get monitor resolution of primary monitor
    $monitordetails = [System.Windows.Forms.SystemInformation]::PrimaryMonitorSize
    $monitorheight = $monitordetails.Height
    $monitorwidth = $monitordetails.Width
    $Counter_Form = New-Object System.Windows.Forms.Form
    $Counter_Form.Text = "Reboot in:" # The top text of the timer
    $Counter_Form.Height = $monitorheight * .10
    $Counter_Form.Width = $monitorwidth * .08
    $Counter_Form.WindowState = "Normal" # Makes the timer neither minimized nor maximized
    $Counter_Form.Top = $monitorheight *.05
    $Counter_Form.Left = $monitorwidth *.85
    $Counter_Form.StartPosition = "manual"     # This ensures we can control where on the screen the form appears
    $Counter_Label = New-Object System.Windows.Forms.Label
    $Counter_Label.AutoSize = $true
    $Counter_Form.TopMost = $true # Always keeps the timer on top
    $Counter_Form.ShowInTaskbar = $false
    $Counter_Form.MinimizeBox = $false
    $Counter_Form.MaximizeBox = $false
    $Counter_Form.ControlBox = $false
    $Counter_Form.SizeGripStyle = "Hide"
    $Counter_Label.ForeColor = "Green"
    $normalfont = New-Object System.Drawing.Font("Times New Roman",14)
    $Counter_Label.Font = $normalfont
    $Counter_Label.Left = 10
    $Counter_Label.Top = 10
    $Counter_Form.Controls.Add($Counter_Label)
    $s = 14399 # The amount of seconds the timer has
    while ($s -ge 0) {
        $string_s = $s.toString() # Converts the $s int to a string
        $ts =  [timespan]::fromseconds($string_s) # Timespan object requires a string parameter, hence the previous conversion
        if ($s -le 540) { # Once the timer is less than 10 minutes, change the color to red
            $Counter_Label.ForeColor = "Red"
        }
        $delay = $ts.ToString("hh\:mm") # Converts the previous timespan object to "hh\:mm" format
        $Counter_Form.Show()
        $Counter_Label.Text = "$($delay)"
        start-sleep 60 # Updates the timer every 60 seconds and subtracts 60 from $s
        $s -= 60
    }
    $Counter_Form.Close()
    Restart-Computer # Once timer hits 0, reset the computer
}

if ($PendingReboot -eq $true) {
    $wshell = New-Object -ComObject Wscript.Shell 
    #create a popup notification with a yes/no option that goes away after 1800 seconds if no input is detected. <4> adds yes/no buttons, <64> adds info icon, <4096> keeps window prioritized
    $Output = $wshell.Popup("You have a pending reboot to apply updates. Would you like to reboot now? If not, you can defer for 4 hours.",1800,"Notice From Pixel Machinery - Reboot Required",4+64 + 4096)
    #if the user presses "yes" to reboot, restart the computer. Else, kick off rest of script
    if ($Output -eq 6) {
        Write-Host "Yes returned"
        Restart-Computer
    } elseif ($Output -eq 7) {
        Write-Host "No returned"
        Start-Timer
    } elseif ($Output -eq -1) {
        Write-Host "No response given"
        Start-Timer
    }
} else {
  Write-Host "No pending reboot at this time"
}