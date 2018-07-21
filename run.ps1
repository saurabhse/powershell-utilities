param(
[string]$env,
[string]$reportName
)

Try{
  $myDir = Split-Path -Parent $MyInvocation.MyCommand.Path
  cd $myDir/$reportName
  $imputXml = [xml] (gc $myDir\run_config.xml)
  $dbConfigXml = [xml] (gc $myDir\database_config.xml)
  $paramFileDir = $myDir +"\" +$reportName+"\" +$reportName+"_run.xml"
  $hostName = $dbConfigXml.ConfigInfo.Env | ? {$_.name -eq $env} | Select-Xml hostName
  $user = $dbConfigXml.ConfigInfo.Env | ? {$_.name -eq $env} | Select-Xml user
  $pwd = $dbConfigXml.ConfigInfo.Env | ? {$_.name -eq $env} | Select-Xml pwd
  $serviceName = $dbConfigXml.ConfigInfo.Env | ? {$_.name -eq $env} | Select-Xml serviceName
  $port = $dbConfigXml.ConfigInfo.Env | ? {$_.name -eq $env} | Select-Xml port
  $sid = $dbConfigXml.ConfigInfo.Env | ? {$_.name -eq $env} | Select-Xml sid
  $dbUrl = $hostName.ToString() + " -u " + $user + " -p " +   $pwd + " -n " + $serviceName +" --db-port " + $port + " --db-sid " +   $sid

  $rd = $imputXml.ConfigInfo.Env | ? {$_.name -eq $env} | Select-Xml RootDir
  $inputJrxmlDir = $imputXml.ConfigInfo.Env | ? {$_.name -eq $env} | Select-Xml inputJrxmlDir
  $inputjrxml = $inputJrxmlDir.ToString() +  $reportName+ ".jrxml"
  $outputPdfDir = $imputXml.ConfigInfo.Env | ? {$_.name -eq $env} | Select-Xml outputPdfDir
  $envPath = $imputXml.ConfigInfo.Env | ? {$_.name -eq $env} | Select-Xml envPath

    $envPath +=  $envPath
    $Root = $rd.ToString() + $reportName
    cd $Root
    $RemovePath = $outputPdfDir.ToString()+ $reportName+'\Output\*'
    Try{
        Remove-Item $RemovePath  -recurse -ea Stop
    }catch[System.IO.IOException]{

    }

    copy .\Input\*.jrtx .\Output\
    jasperstarter compile "Input" -o Output
    New-Item .\Output\ReportPDFs -ItemType Directory -Force

    if(Test-Path $paramFileDir){
        $paramFile =  [xml] (gc $paramFileDir)
        $paramList = New-Object System.Collections.ArrayList
        $paramFile.items.item | where { [string]$_.generate -eq "Y"} |
            foreach {
                  $queryparamstr = ''
                  foreach( $param in $_.parameters.parameter | Sort-Object { [int]$_.seqNo}){
                    if($param.type -eq "query"){
                      queryparamstr += $param.name + '='+$param.value+' '
                    }elseif($param.type -eq "*"){
                      queryparamstr += $param.name + '='+$param.value+' '
                      [void]$paramList.Add("."+$param.value)
                    }else{
                        [void]$paramList.Add("."+$param.value)
                    }
                  }

                  $outputValue = $($paramList -join [Environment]::Space)
                  $outputFileName = $paramFile.items.name + $outputValue
                  jasperstarter process $inputjrxml -o "Output\ReportPDFs\$outputFileName" -f pdf -r "Output" -t oracle -H $hostName.ToString() -u $user.ToString() -p $pwd.ToString() -n $serviceName.ToString() --db-port $port.ToString() --db-sid $sid.ToString() -P $queryparamstr.Trim()
            }
    }else{
          jasperstarter process $inputjrxml -o "Output\ReportPDFs" -f pdf -r "Output" -t oracle -H $hostName.ToString() -u $user.ToString() -p $pwd.ToString() -n $serviceName.ToString() --db-port $port.ToString() --db-sid $sid.ToString()
    }

}
Catch [Exception]{
    Write-Host $_.Exception.Message
    exit 777
}
