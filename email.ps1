param(
[string]$env,
[string]$reportName
)

$ErrorActionPreference = "stop"
Write-Host "Starting" $env
Try{

	$myDir = Split-Path -Parent $MyInvocation.MyCommand.Path
 	$configxml = [xml] (gc $myDir\email_config.xml)
 	$emailXmlFile = $myDir+ "\"+$reportName+ "\"+ $reportName+"_email.xml"
 	$emailxml = [xml] (gc $emailXmlFile)
 	$SMTPServer = $configxml.ConfigInfo.Env | ? {$_.name -eq $env} | Select-Xml SMTPServer
 	$SMTPPort = $configxml.ConfigInfo.Env | ? {$_.name -eq $env} | Select-Xml SMTPPort
 	$CurrentDate = (Get-Date).ToString("MMMM dd, yyyy")
 	$To = New-Object System.Collections.ArrayList
 	$Attachment = New-Object System.Collections.ArrayList
 	$emailxml.emails.email | ? {$_.env -eq $env} |
 		foreach{
 				$From = $_.from
 				$Subject = $_.subject
 				$Subject = $Subject -replace "#today" , $CurrentDate
 				$Body = $_.body
 				$Body = $Body -replace "#today" , $CurrentDate
 				foreach($toAddr in $_.toAddr.to){
 					[void]$To.Add($toAddr)
 				}
 				foreach($att in $_.attachments.attachment){
 					[void]$Attachment.Add($att)
 				}
 		}

 		send-mailmessage -to $To -from $From -Subject $Subject -Body $Body -Attachments $Attachments -SmtpServer $SMTPServer 
}
Catch [Exception]{
    Write-Host $_.Exception.Message
    exit 777
}
