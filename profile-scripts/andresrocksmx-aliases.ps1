function gpip() { (Invoke-WebRequest http://ifconfig.me/ip).Content }

$projectsDirectoryPath = "$env:USERPROFILE\projects"
if (Test-Path $projectsDirectoryPath)
{
    New-PSDrive -Name Projects -PSProvider FileSystem -Root $projectsDirectoryPath -Description "Projects directory" | Out-Null
}

function proj { return $projectsDirectoryPath }

function sproj { Set-Location -Path $projectsDirectoryPath }

function oproj { explorer -Path $projectsDirectoryPath }

function lproj { Get-ChildItem -Path $projectsDirectoryPath -Force }

function slproj { 
    sproj
    lproj 
}

function home { 
    return $HOME 
}

function reload-profiles {
    . $PROFILE.CurrentUserAllHosts
    . $PROFILE
}

function Set-AzTheme {
    oh-my-posh init pwsh --config https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/refs/heads/main/themes/cloud-native-azure.omp.json | Invoke-Expression
}

# Find out if the current user identity is elevated (has admin rights)
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal $identity
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Compute file hashes - useful for checking successful downloads 
function md5    { Get-FileHash -Algorithm MD5 $args }
function sha1   { Get-FileHash -Algorithm SHA1 $args }
function sha256 { Get-FileHash -Algorithm SHA256 $args }