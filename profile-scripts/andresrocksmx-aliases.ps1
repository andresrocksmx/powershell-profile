function gpip() { (Invoke-WebRequest http://ifconfig.me/ip).Content }

$projectDirectory = "$env:USERPROFILE\projects"
if (Test-Path $projectDirectory )
{
    New-PSDrive -Name Projects -PSProvider FileSystem -Root $projectDirectory  -Description "Projects directory"
}

function proj { return $projectDirectory }

function sproj { Set-Location -Path $projectDirectory }

function oproj { explorer -Path $projectDirectory }

function lproj { Get-ChildItem -Path $projectDirectory -Force }

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

#############

# Find out if the current user identity is elevated (has admin rights)
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal $identity
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# If so and the current host is a command line, then change to red color 
# as warning to user that they are operating in an elevated context
if (($host.Name -match "ConsoleHost") -and ($isAdmin))
{
     $host.UI.RawUI.BackgroundColor = "DarkRed"
     $host.PrivateData.ErrorBackgroundColor = "White"
     $host.PrivateData.ErrorForegroundColor = "DarkRed"
     Clear-Host
}

# Compute file hashes - useful for checking successful downloads 
function md5    { Get-FileHash -Algorithm MD5 $args }
function sha1   { Get-FileHash -Algorithm SHA1 $args }
function sha256 { Get-FileHash -Algorithm SHA256 $args }