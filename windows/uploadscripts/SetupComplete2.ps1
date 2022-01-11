$adou = "#corp-gindox-packer-addomain-ou#"

$un = "#corp-gindox-packer-addomain-user#"
$pw = "#corp-gindox-packer-addomain-pass#"
$pass = ConvertTo-SecureString -String $pw -AsPlainText -Force
$cred = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $un, $pass

$principal = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$Action = New-ScheduledTaskAction -Execute 'PowerShell' -Argument "-command &{rm -Force C:\Windows\OEM\SetupComplete2.cmd;rm -Force C:\Windows\OEM\SetupComplete2.ps1;Get-ScheduledTask -TaskName setup-cleanup | Unregister-ScheduledTask -Confirm:`$false}"
$Trigger = New-ScheduledTaskTrigger -Once -At (get-date).AddHours(-1) -RepetitionInterval (New-TimeSpan -Minutes 3); $Trigger.EndBoundary = (get-date).AddHours(1).ToString('s')
$Task = New-ScheduledTask -Principal $principal -Action $Action -Trigger $Trigger -Settings (New-ScheduledTaskSettingsSet -Compatibility Win8 -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Hours 2) -DeleteExpiredTaskAfter (New-TimeSpan -Minutes 3))
$Task | Register-ScheduledTask -TaskName "setup-cleanup"


Add-Computer -DomainName "#corp-gindox-packer-addomain#" -OUPath $adou -Credential $cred -Restart -Force