param (
    # Cleans the current cuild directory
    [Parameter(Mandatory=$false)]
    [Switch]$confirm,

    # location where template will be build
    [Parameter(Mandatory=$true)]
    [ValidateSet("northeurope", "southeastasia")]
    $location,

    # 
    [Parameter(Mandatory=$true)]
    [ValidateSet("2022-datacenter-core-smalldisk","2022-datacenter-smalldisk")]
    $sku
)

<#
$location = "North Europe"
Get-AzVMImagePublisher -Location $location | Select PublisherName | Where-Object { $_.PublisherName -like '*Windows*' }
$publisher = "MicrosoftWindowsServer"
Get-AzVMImageOffer -Location $location -PublisherName $publisher | Select Offer
$offer  = "WindowsServer"
Get-AzVMImageSku -Location $location -PublisherName $publisher -Offer $offer | Select Skus
#>

if ($confirm.IsPresent) {
    Remove-Item -Force -Recurse ".\build"  -ErrorAction SilentlyContinue
}


if (Test-Path ".\build" -PathType Container) {
    if ((Read-Host "build directory present, confirm it will be cleared: (Y) ").ToLower() -eq 'y') {
        Remove-Item -Path ".\build" -Force -Recurse -ErrorAction SilentlyContinue
    } else {
        Write-Warning "Build directory still preset, please re-run."
        exit
    }
}



New-Item ".\build" -ItemType Directory
Copy-Item -Recurse -Path ".\windows\*" -Destination ".\build\."



$azsid = Get-AzKeyVaultSecret -VaultName 'corpgindoxvault' -Name 'corp-gindox-packer-subscription-id' -AsPlainText
$aztid = Get-AzKeyVaultSecret -VaultName 'corpgindoxvault' -Name 'corp-gindox-packer-tenant-id' -AsPlainText
$azcid = Get-AzKeyVaultSecret -VaultName 'corpgindoxvault' -Name 'corp-gindox-packer-client-id' -AsPlainText
$azpwd = Get-AzKeyVaultSecret -VaultName 'corpgindoxvault' -Name 'corp-gindox-packer-client-secret' -AsPlainText

$addomain = Get-AzKeyVaultSecret -VaultName 'corpgindoxvault' -Name 'corp-gindox-packer-addomain' -AsPlainText
$addomainou = Get-AzKeyVaultSecret -VaultName 'corpgindoxvault' -Name 'corp-gindox-packer-addomain-ou' -AsPlainText
$addomainuser = Get-AzKeyVaultSecret -VaultName 'corpgindoxvault' -Name 'corp-gindox-packer-addomain-user' -AsPlainText
$addomainpass = Get-AzKeyVaultSecret -VaultName 'corpgindoxvault' -Name 'corp-gindox-packer-addomain-pass' -AsPlainText

$packerresourcegroup = Get-AzKeyVaultSecret -VaultName 'corpgindoxvault' -Name 'corp-gindox-packer-resourcegroup' -AsPlainText


$env:PACKER_LOG = "1"
$env:PACKER_LOG_PATH = $PSScriptRoot + "\packer-build-windows.log.txt"
$env:PACKER_CACHE_DIR = $env:TEMP


switch ($sku) {
    "2022-datacenter-core-smalldisk" { $img = "corpgindox_tmpl2022core" }
    "2022-datacenter-smalldisk" { $img = "corpgindox_tmpl2022" }
}

$setupCompleteFile = $PSScriptRoot + ".\build\uploadscripts\SetupComplete2.ps1"

(Get-Content -Path $setupCompleteFile) | ForEach-Object {
	$_ 	-replace '#corp-gindox-packer-addomain-ou#', $addomainou `
		-replace '#corp-gindox-packer-addomain-user#', $addomainuser `
		-replace '#corp-gindox-packer-addomain-pass#', $addomainpass `
		-replace '#corp-gindox-packer-addomain#', $addomain 
} | Set-Content $setupCompleteFile

Set-Location ".\build\"

packer build `
	   -force `
	   -var "subscription_id=$azsid" `
	   -var "tenant_id=$aztid" `
	   -var "client_id=$azcid" `
	   -var "client_secret=$azpwd" `
	   -var "image_sku=$sku" `
	   -var "vm_size=Standard_B2s" `
	   -var "winrm_username=packer" `
	   -var "resource_group=$packerresourcegroup" `
	   -var "azure_location=$location" `
	   -var "managed_image_name=$img" `
	   -var "managed_image_storage_account_type=Standard_LRS" `
	   -only=azure-build "windows.json"

Set-Location $PSScriptRoot
