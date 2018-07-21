param(
[string]$env,
[string]$relVrsn
)

$ErrorActionPreference = "stop"
Write-Host "Starting" $env
Try{
  $ws_net = New-Object -COM WScript.Network
   $myDir = Split-Path -Parent $MyInvocation.MyCommand.Path
   $printFileDir = $myDir + "\"+ $reportName + "\"+ $reportName + "_print.xml"
   $printxml = [xml] (gc $printFileDir)
   $dow = (Get-Date).DayOfWeek
   $printxml.print.printReports | where { [string]$_.envi -eq $env} |
      foreach{
            foreach($rep in $_.report){
              if($rep.dayToPrint -eq $dow -or ($rep.dayToPrint.Contains($dow)) -or ($rep.dayToPrint -eq "*")){
                Start-Process -FilePath $rep.file -verb Print -PassThru | %{sleep 120;$_} | kill
              }
            }
      }
exit 0
}
Catch [Exception]{
    Write-Host $_.Exception.Message
    exit 777
}
