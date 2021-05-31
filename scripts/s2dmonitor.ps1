<#
S2D Monitor state
Version 1.0

Description: S2D monitoring script.

Ilia Bakhterev
bakhterets@gmail.com
#>
# Options
[CmdletBinding()]
param (
    [Parameter(Position=0, Mandatory=$True)]
    [ValidateSet('DiscoveryPools','GetPoolInfo','DiscoveryPDisks','GetPDiskInfo','DiscoveryVDisks','GetVDiskInfo','DiscoveryCSVPath','DiscoveryCSVName','GetNodeInfo','DiscoveryRT','GetRTInfo')]
    [string]
    $Action,
    [Parameter(Position=1, Mandatory=$False)]
    [string]
    #[ValidateSet('UniqueID','UniqueDiskID')]
    $UniqueID,
    [Parameter(Position=2, Mandatory=$False)]
    #[ValidateSet('FriendlyName','OperationalStatus','HealthStatus','IsReadOnly','ReadOnlyReason','Size','AllocatedSize','SerialNumber')]
    [string]
    $Parameter
)

function DiscoveryPools {
  $PoolIDs = (Get-StoragePool -IsPrimordial $False).UniqueId.Trim("{}")
  ConvertTo-Json @{"data"=[array]($PoolIDs) | Select-Object @{l="{#UNIQUEID}";e={$_}}}
}

function GetPoolInfo {
  $Pool = (Get-StoragePool -UniqueId "{$UniqueID}")
  if ($Parameter -eq "OperationalStatus") {
    #TypeName: System.String
    $Pool.$Parameter

  } elseif ($Parameter -eq "HealthStatus") {
    #TypeName: System.Int32
    switch ($Pool.$Parameter) {
      Healthy { 0 }
      Warning { 1 }
      Unhealthy { 2 }
      Unknown { 5 }
      Default { 10 }
    }
  
  } elseif ($Parameter -eq "IsReadOnly") {
    #TypeName: System.Boolean
    $Pool.$Parameter
  
  } elseif ($Parameter -eq "ReadOnlyReason") {
    #TypeName: System.String
    $Pool.$Parameter
  
  } else {
    # Size and AllocatedSize has TypeName: System.UInt64
    $Pool.$Parameter
  }
}

function DiscoveryPDisks {
  $PDISKSID = (Get-PhysicalDisk).UniqueId
  ConvertTo-Json @{"data"=[array]($PDISKSID) | Select-Object @{l="{#UNIQUEID}";e={$_}}}
}

function GetPDiskInfo {
  # SerialNumber, MediaType, OperationalStatus, Usage have TypeName: System.String
  # Size have TypeName: System.UInt64
  # HealthStatus have TypeName: System.Int32
  $PDISK = (Get-PhysicalDisk -UniqueId $UniqueID)
  if ($Parameter -eq "HealthStatus") {
    switch ($PDISK.$Parameter) {
      Healthy { 0 }
      Warning { 1 }
      Unhealthy { 2 }
      Unknown { 5 }
      Default { 10 }
    }
  } else {
    $PDISK.$Parameter
  }
}

function DiscoveryVDisks {
  $VDISKID = (Get-VirtualDisk).UniqueId
  ConvertTo-Json @{"data"=[array]($VDISKID) | Select-Object @{l="{#UNIQUEID}";e={$_}}}
}

function GetVDiskInfo {
  # OperationalStatus, Usage have TypeName: System.String
  # Size have TypeName: System.UInt64
  # HealthStatus have TypeName: System.Int32
  $VDISK = (Get-VirtualDisk -UniqueId $UniqueID)
  if ($Parameter -eq "HealthStatus") {
    switch ($VDISK.$Parameter) {
      Healthy { 0 }
      Warning { 1 }
      Unhealthy { 2 }
      Unknown { 5 }
      Default { 10 }
    }
  } else {
    $VDISK.$Parameter
  }
}

function DiscoveryCSVPath {
  $CSVPath = (Get-ClusterSharedVolume).sharedvolumeinfo.friendlyvolumename
  ConvertTo-Json @{"data"=[array]($CSVPath) | Select-Object @{l="{#CSVPATH}";e={$_}}}
}

function DiscoveryCSVName {
  $CSVNAME = (Get-WmiObject win32_PerfFormattedData_CsvFsPerfProvider_ClusterCSVFileSystem).Name
  ConvertTo-Json @{"data"=[array]($CSVNAME) | Select-Object @{l="{#CSVNAME}";e={$_}}}
}

function GetNodeInfo {
  $NODENAME = [System.Net.Dns]::GetHostName()
  if ((Get-ClusterNode -Name $NODENAME).state -eq "Up") { 
    Write-Output "1"
  } else {
    Write-Output "0"
  }
}

function DiscoveryRT {
  $RTNAME = ( Get-ClusterResource | Where-Object {$_.ResourceType -notlike "Virtual Machine*"} )
  ConvertTo-Json @{"data"=[array]($RTNAME) | Select-Object @{l="{#RTNAME}";e={$_}}}
}

function GetRTInfo {
  # State have TypeName: Microsoft.FailoverClusters.PowerShell.ClusterResource
  $RT = Get-ClusterResource -Name $UniqueID
  if ($Parameter -eq "State") {
    switch ($RT.$Parameter) {
      Online { 1 }
      Failed { 0 }
      Default { 2 }
    }
  } else {
    $RT.$Parameter
  }
}

switch ($Action) {
  DiscoveryPools { DiscoveryPools }
  GetPoolInfo { GetPoolInfo }
  DiscoveryPDisks { DiscoveryPDisks }
  GetPDiskInfo { GetPDiskInfo }
  DiscoveryVDisks { DiscoveryVDisks }
  GetVDiskInfo { GetVDiskInfo }
  DiscoveryCSVPath { DiscoveryCSVPath }
  DiscoveryCSVName { DiscoveryCSVName }
  GetNodeInfo { GetNodeInfo }
  DiscoveryRT { DiscoveryRT }
  GetRTInfo { GetRTInfo }
  Default {"!Some Error!"}
}