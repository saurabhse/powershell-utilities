param(
[parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][ValidateSet("Prod","UAT","Local")][string]$env,
[parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][ValidateSet("")][string]$quantname
)
[System.Reflection.Assembly]::LoadWithPartialName("System.Data.OracleClient")

function ConnectOracle([string] $connectionString = $(throw "connectionString is required"))
{
	$conn = New-Object System.Data.OracleClient.OracleConnection($connectionString)
}

function getProperty(
[string] $filename = $(throw "filename is required"),
[string] $name = $(throw "name is required"),
[string] $propname = $(throw "propname is required")
){
	
	$config = [xml](gc $myDir\$filename)
	$item = $config.configuration.connectionStrings.add | where { $_.name -eq $name}
	if(!$item){
			throw "failed"
	}
	return $item.$propname
	
}

function getProperty1(
[string] $filename = $(throw "filename is required"),
[string] $name = $(throw "name is required"),
[string] $propname = $(throw "propname is required")
){
	
	$config = [xml](gc $myDir\$filename)
	$item = $config.configuration.connectionStrings.DateCheck | where { $_.name -eq $name}
	if(!$item){
			throw "failed"
	}
	return $item.$propname
	
}


$myDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$connectionString = getProperty ./insert_config.xml $env connectionString
$maxattempts = getProperty ./insert_config.xml $env maxattempts
$waitTimeStr = getProperty ./insert_config.xml $env waitTimeStr
$queryString = getProperty ./insert_config.xml $quantname queryString
$queryString1 = getProperty ./insert_config.xml $quantname queryString1
$queryString2 = getProperty ./insert_config.xml $quantname queryString2
$queryString3 = getProperty ./insert_config.xml $quantname queryString3
$tableName = getProperty ./insert_config.xml $quantname tableName


$conn = ConnectOracle($connectionString)

$command = New-Object System.Data.OracleClient.OracleCommand($queryString,$conn)
$command1 = New-Object System.Data.OracleClient.OracleCommand($queryString1,$conn)
$command2 = New-Object System.Data.OracleClient.OracleCommand($queryString2,$conn)
$command3 = New-Object System.Data.OracleClient.OracleCommand($queryString3,$conn)

$command.ExecuteScalar()
$commitFlag = $command2.ExecuteScalar()
$command1.ExecuteScalar()
$command2.ExecuteScalar() # commit
$okFlag = $command3.ExecuteScalar()

$conn.Close()

if($okFlag -gt "1"){
	exit 0
}

if($okFlag -eq "0"){
	exit 1
}

$Error[0] | f1 -Force
