param(
[string]$env,
[string]$reportName
)

$ErrorActionPreference = "stop"
Write-Host "Starting" $env
Try{

	$myDir = Split-Path -Parent $MyInvocation.MyCommand.Path
 	$configxml = [xml] (gc $myDir\combiner_config.xml)
 	$combinerFileDir = $myDir+ "\"+$reportName+ "\"+ $reportName+"_combiner.xml"
 	$combinerxml = [xml] (gc $combinerFileDir)

 	$pdfmergeDir = $configxml.ConfigInfo.Env | ? {$_.name -eq $env} | Select-Xml pdfmergeDir
 	$jreDir = $configxml.ConfigInfo.Env | ? {$_.name -eq $env} | Select-Xml jreDir
 	$ldriveDir = $configxml.ConfigInfo.Env | ? {$_.name -eq $env} | Select-Xml ldriveDir
 	$outputPdfDir = $configxml.ConfigInfo.Env | ? {$_.name -eq $env} | Select-Xml outputPdfDir
 	$inputPdfDir = $configxml.ConfigInfo.Env | ? {$_.name -eq $env} | Select-Xml inputPdfDir
 	$classpath = "$ldriveDir$pdfmergeDir"
 	New-Item $myDir\$reportName\$outputPdfDir -ItemType Directory -Force
 	$destDir = $myDir+ "\"+$reportName+$inputPdfDir
 	$combByName = ""
 	$exclFiles = ""
 	$dow = (Get-Date).DayOfWeek
 	$CurrentDate = Get-Date -Format "MM/dd/yyyy"
 	$FirstDayOfMonth = Get-Date $CurrentDate -Day 1
 	$LastDayOfMonth = Get-Date $FirstDayOfMonth.AddSeconds(-1) -Format "yyyyMMdd"

 	Remove-Item $destDir\* -recusrse
 	$combinerxml.combiner.combinedReport |
 		foreach{
 				$Files = ""
 				$reportPdfname = $_.name
 				$Placement = $_.pageFormat
 				$combinerFileDir = $myDir+"\"+$reportName+$outputPdfDir + "\"+$reportPdfName
 				$combinerFileDir =$combinerFileDir.replace('#{param1}',$LastDayOfMonth)
 				$_.includeReports.report | Sort-Object { [int]$_.seq} | where { [string]$_.include -eq "Y"} |
 					foreach{
 							#use logic to include ignorereport,staticreport
 							$maxAttempts = $_.maxAttempts
 							$waitTime =  $_.$waitTime
 							[int]$okFlag = 0
 							if($maxAttempts -ne $null -and $waitTime -ne $null -and $ignoreReport -ne "Y"){
 								[int] $attemptsRemaining = [convert]::ToInt32($maxAttempts,10)
 								[int] $waitTime = [convert]::ToInt32($waitTime,10)
 								while($attemptsRemaining -ne 0){
 									if(Test-Path $sourceDir){
 										$chkTime = Get-Date
 										$chkTime =  $chkTime.Addminutes(-1)
 										$lastWriteTime = (Get-Item $sourceDir).LastWriteTime
 										while($chkTime -lt $lastWriteTime){
 											Start-Sleep -s 10
 											$lastWriteTime = (Get-Item $sourceDir).LastWriteTime
 											$chkTime = Get-Date
 											$chkTime =  $chkTime.Addminutes(-1)
 										}
 										$okFlag=1;
 										break
 									}else{
 										$attemptsRemaining--;
 										sleep $waitTime
 									}
 								}
 							}
 							#use logic for manadtory report etc

 					}

 					if($combByName -eq "Y"){
 						Get-ChildItem $destDir | where-object { $exclFiles -notconatins $_.name} | sort Name | foreach { $fn=fn+","+$_.name}
 						$Files= $fn.substring(1)
 					}

 					if($Placement -eq "PAGENUM.NONE"){
 						& $jreDir.ToString() -cp $classpath MergePDF $destDir $Files $combinedFileDir > $null
 					}else{
 						& $jreDir.ToString() -cp $classpath MergePDF $destDir $Files $combinedFileDir """$Placement"""> $null
 					}
 		}

 		exit 0
}
Catch [Exception]{
    Write-Host $_.Exception.Message
    exit 777
}
