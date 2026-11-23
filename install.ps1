# Registers the 30-minute check as a scheduled task for the current user.
$name = 'Shatel Remaining Check'
$action = New-ScheduledTaskAction -Execute 'wscript.exe' -Argument "`"$PSScriptRoot\run.vbs`""
$every30 = New-ScheduledTaskTrigger -Once -At (Get-Date).Date -RepetitionInterval (New-TimeSpan -Minutes 30)
$logon = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME; $logon.Delay = 'PT2M'
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
Register-ScheduledTask -TaskName $name -Action $action -Trigger $every30, $logon -Settings $settings -Force | Out-Null
"Installed '$name'. Remove with: Unregister-ScheduledTask '$name' -Confirm:`$false"
