#Tag the image via registry
IF (-Not (Test-path "HKLM:\Software\!gindox")) { New-Item -Path "HKLM:\Software\" -Name "!gindox"; New-Item -Path "HKLM:\Software\!gindox\" -Name "flags" }
New-ItemProperty -Path "HKLM:\Software\!gindox" -Name "Image" -Value "2022core" -PropertyType "String"


#setup domain join via SetupComplete2
IF (!(test-path "C:\Windows\OEM")) { mkdir "C:\Windows\OEM" }
mv "$env:windir\Temp\SetupComplete2.cmd" "C:\Windows\OEM\SetupComplete2.cmd" -Force
mv "$env:windir\Temp\SetupComplete2.ps1" "C:\Windows\OEM\SetupComplete2.ps1" -Force


#INSTALL CHOCOLATEY
$choc = "c:\programdata\chocolatey\choco.exe"
IF (-Not (Test-Path $choc)) {
	Write-Host "install chocolatey" -ForegroundColor Cyan
	Set-ExecutionPolicy Bypass -Scope Process -Force; iwr https://chocolatey.org/install.ps1 -UseBasicParsing | iex
}

