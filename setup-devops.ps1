# Ensure the script can run with elevated privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Please run this script as an Administrator!"
    break
}

# Example to switch profile to your own GitHub account when forked.
#[System.Environment]::SetEnvironmentVariable('POWERSHELL_PROFILE_GITHUB_ACCOUNT', 'ChrisTitusTech', [System.EnvironmentVariableTarget]::User)
$githubAccount = $env:POWERSHELL_PROFILE_GITHUB_ACCOUNT
if([string]::IsNullOrEmpty($githubAccount)) {
    $githubAccount = "andresrocksmx"
    Write-Host "Using profile from GitHub account $githubAccount (Default)." -ForegroundColor Yellow
    Write-Host "To load from different GitHub account, set this in environment variable 'POWERSHELL_PROFILE_GITHUB_ACCOUNT'"
    Write-Host "Example => [System.Environment]::SetEnvironmentVariable('POWERSHELL_PROFILE_GITHUB_ACCOUNT', 'ChrisTitusTech', [System.EnvironmentVariableTarget]::User)"
}
else {
    Write-Host "Using profile from GitHub account $githubAccount." -ForegroundColor Yellow
}

# Function to test internet connectivity
function Test-InternetConnection {
    try {
        Test-Connection -ComputerName www.google.com -Count 1 -ErrorAction Stop
        return $true
    }
    catch {
        Write-Warning "Internet connection is required but not available. Please check your connection."
        return $false
    }
}

# Check for internet connectivity before proceeding
if (-not (Test-InternetConnection)) {
    break
}

# Profile creation or update
# Detect Version of PowerShell & Create Profile directories if they do not exist.
$profilePath = ""
if ($PSVersionTable.PSEdition -eq "Core") {
    $profilePath = "$env:userprofile\Documents\Powershell"
}
elseif ($PSVersionTable.PSEdition -eq "Desktop") {
    $profilePath = "$env:userprofile\Documents\WindowsPowerShell"
}

if (!(Test-Path -Path $profilePath)) {
    New-Item -Path $profilePath -ItemType Directory | Out-Null
}

$backupUserProfile = $true
$userProfile = "$profilePath\Profile.ps1"
if (!(Test-Path -Path $userProfile -PathType Leaf)) {
    New-Item -Path $userProfile -ItemType File -Force | Out-Null
    Write-Host "User profile @ [$userProfile] has been created." -ForegroundColor Yellow
    $backupUserProfile = $false
}

if($backupUserProfile) {
    Get-Item -Path $userProfile | Copy-Item -Destination "$userProfile.bak" -Force
    Write-Host "Original user profile @ [$userProfile] has been backed up."
}

function Import-ToUserProfile {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        $FileName
    )

    $userProfileDownloadPath = "$profilePath\$FileName"
    Invoke-RestMethod https://github.com/$githubAccount/powershell-profile/raw/main/$FileName -OutFile $userProfileDownloadPath
    Write-Host "The user profile @ [$userProfileDownloadPath] has been created."

    $userProfileContent = Get-Content -Path $userProfile -Raw
    $userProfileScriptCommand = '. $PSScriptRoot\{0}' -f $FileName
    $userProfileScriptCommandRegex = [regex]::Escape($userProfileScriptCommand)
    $matchUserProfileScript = $userProfileContent -match $userProfileScriptCommandRegex

    if (!$matchUserProfileScript) {
        $userProfileContent += "`n$userProfileScriptCommand"
        $userProfileContent | Out-File $userProfile
        $(Get-Content -Path $userProfile -Raw).Trim("`r", "`n") | Out-File $userProfile

        Write-Host "User profile @ [$userProfile] has been updated and is now loading script '$FileName'. Please restart your shell to reflect changes" -ForegroundColor Magenta
        & $userProfile
    }
}

Import-ToUserProfile -FileName 'andresrocksmx_profile.ps1'