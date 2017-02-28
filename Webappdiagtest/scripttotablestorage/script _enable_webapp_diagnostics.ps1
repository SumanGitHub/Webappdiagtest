Select-AzureRmSubscription -SubscriptionId da90b945-2d6b-4ff4-a0e4-bf541cf8265f


$resourceGroupName = "Webappdiagtestrg"

$tableName = "wadlogtable"

$webappName = "Webappdiagtest"

$webAppLogResource = Get-AzureRmResource -ResourceGroupName $resourceGroupName -ResourceType Microsoft.Web/sites/config -ResourceName $webappName/logs -ApiVersion 2015-08-01

$propertyObject = $webAppLogResource.Properties
       

$tableSasUrl = $propertyObject.applicationLogs.azureTableStorage.sasUrl    
$storageAccountName = Get-AzureRmStorageAccount  -ResourceGroupName  $resourceGroupName
$storageAccountKey = Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storageAccountName.StorageAccountName

$context = New-AzureStorageContext -StorageAccountName $storageAccountName.StorageAccountName -StorageAccountKey $storageAccountKey.Value[0]

$storageTable = Get-AzureStorageTable -Name $tableName -Context $context -ErrorAction SilentlyContinue
if($storageTable -eq $null)
{
$storageTable = New-AzureStorageTable -Name $tableName -Context $context
}
if($tableSasUrl.Length -eq 0)
{
$tableSasUrl = New-AzureStorageTableSASToken -Name $storageTable.Name -Context $context -Permission rau -FullUri -ExpiryTime (Get-Date).AddDays(99999)
}
       
$propertyObject.applicationLogs.azureTableStorage.level = "Information"           
$propertyObject.applicationLogs.azureTableStorage.sasUrl = "$tableSasUrl"
$propertyObject.failedRequestsTracing.enabled = $true
$propertyObject.detailedErrorMessages.enabled = $true
       
Set-AzureRmResource -PropertyObject $propertyObject -ResourceGroupName $resourceGroupName -ResourceType Microsoft.Web/sites/config -ResourceName $webappName/logs -ApiVersion 2015-08-01 -Force
