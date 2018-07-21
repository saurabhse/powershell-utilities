param(
[string]$env,
[string]$reportName
)

$ErrorActionPreference = "stop"
Write-Host "Starting" $env
Try{
  $myDir = Split-Path -Parent $MyInvocation.MyCommand.Path
  $configxml = [xml] (gc $myDir\archive_config.xml)
  $archiveXmlFile = $myDir + "\"+ $reportName + "\"+ $reportName + "_archive.xml"
  $archiveXml = [xml] (gc archiveXmlFile)
  $MoveFromPath = $configxml.ConfigInfo.Env | ? {$_.name -eq $env} | Select-Xml MoveFromPath
  $MoveToPath = $configxml.ConfigInfo.Env | ? {$_.name -eq $env} | Select-Xml MoveToPath
  $CurrentDate = (Get-Date).ToString("MMM dd yyyy")
  $archiveXml.archive.reports.report |
    foreach {
          $repType = $_.type
          $move = $MoveFromPath.ToString().replace('#{reportName}',$_.reportName)
          New-Variable -Name "MoveFrom+$repType" -Value ($move + $_.name + $_.extension)
          $moveFrom = Get-Variable -Name "MoveFrom+$repType" -ValueOnly
          New-Variable -Name "MoveTo+$repType" -Value ($MoveToPath.ToString() + $_.name + $_.extension)
          $moveTo = Get-Variable -Name "MoveTo+$repType" -ValueOnly
          New-Variable -Name "NewName+$repType" -Value ($_.name + $CurrentDate+ $_.extension)
          $newName = Get-Variable -Name "NewName+$repType" -ValueOnly
          New-Variable -Name "NewNamePath+$repType" -Value ($MoveToPath.ToString() + $newName )
          $newNamePath = Get-Variable -Name "NewNamePath+$repType"  -ValueOnly
          if(Test-Path $newNamePath){
            Remove-Item $newNamePath
          }
          if(Test-Path $moveFrom){
            Move-Item $moveFrom $moveTo
            Rename-Item $moveTo $newName
          }
    }
    $archiveXml.archive.excludeFolders.foldername |
        foreach {
            $exclFolders += ',' + $_
        }
     $exclFolders  = $exclFolders  -split ","
     Get-ChildItem $myDir | where-object { $exclFolders -notcontains $_.Name -and $_.PSIsContainer} |
        foreach {
            $reportFilePath = $_.FulName.Trim()
            Move-Item $reportFilePath\Output\ReportPDFs\* $myDir\$reportName\Input\ -Force
            Remove-Item $reportFilePath\Input\* -include *.pdf -recurse
        }
    $archiveXml.archive.filesToRemove.name |
      foreach{
            if(Test-Path $_){
              Remove-Item $_
              }
      }
}

Catch [Exception]{
    Write-Host $_.Exception.Message
    exit 777
}
