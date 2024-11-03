#opt-out of telemetry before doing anything, only if PowerShell is run as admin
if ([bool]([System.Security.Principal.WindowsIdentity]::GetCurrent()).IsSystem) {
    [System.Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', 'true', [System.EnvironmentVariableTarget]::Machine)
}

# Example to switch profile to your own GitHub account when forked.
#[System.Environment]::SetEnvironmentVariable('POWERSHELL_PROFILE_GITHUB_ACCOUNT', 'ChrisTitusTech', [System.EnvironmentVariableTarget]::User)
$githubAccount = $env:POWERSHELL_PROFILE_GITHUB_ACCOUNT
if ([string]::IsNullOrEmpty($githubAccount)) {
    $githubAccount = "andresrocksmx"
    Write-Host "Using user profile from GitHub account $githubAccount (Default)." -ForegroundColor Yellow
    Write-Host "To load from different GitHub account, set this in environment variable 'POWERSHELL_PROFILE_GITHUB_ACCOUNT'"
    Write-Host "Example => [System.Environment]::SetEnvironmentVariable('POWERSHELL_PROFILE_GITHUB_ACCOUNT', 'andresrocksmx', [System.EnvironmentVariableTarget]::User)"
}
else {
    Write-Host "Using user profile from GitHub account $githubAccount." -ForegroundColor Yellow
}

# Example to suspend updates while you work in
#[System.Environment]::SetEnvironmentVariable('POWERSHELL_PROFILE_SUSPEND_UPDATES', 'true', [System.EnvironmentVariableTarget]::User)
$pwshProfileSuspendUpdates = $env:POWERSHELL_PROFILE_SUSPEND_UPDATES

# Initial GitHub.com connectivity check with 1 second timeout
$canConnectToGitHub = Test-Connection github.com -Count 1 -Quiet -TimeoutSeconds 1

# Detect Version of PowerShell & Create Profile directories if they do not exist.
$profilePath = ""
if ($PSVersionTable.PSEdition -eq "Core") {
    $profilePath = "$env:userprofile\Documents\Powershell"
}
elseif ($PSVersionTable.PSEdition -eq "Desktop") {
    $profilePath = "$env:userprofile\Documents\WindowsPowerShell"
}

if (!(Test-Path -Path $profilePath)) {
    New-Item -Path $profilePath -ItemType Directory
}

function Update-ProfileScripts {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        $ProfileScriptName
    )

    if (-not $global:canConnectToGitHub) {
        Write-Host "Skipping profile update check due to GitHub.com not responding within 1 second." -ForegroundColor Yellow
        return
    }

    try {
        $ProfileScriptName = $ProfileScriptName -replace '\\', '/' # URL path friendly (forward slashes)
        $fileDirectoryPath = Split-Path $ProfileScriptName
        $destinationFilePath = "$profilePath\$ProfileScriptName" -replace '/', '\' # Windows file path friendly (backward slashes)
        $tempFileDirectoryPath = "$env:temp\$fileDirectoryPath" -replace '/', '\' # Windows file path friendly (backward slashes)
        $tempFilePath = "$env:temp\$ProfileScriptName" -replace '/', '\' # Windows file path friendly (backward slashes)

        New-Item -Path $tempFileDirectoryPath -ItemType Directory -Force | Out-Null

        if (!(Test-Path -Path $destinationFilePath -PathType Leaf)) {
            New-Item -Path $destinationFilePath -ItemType File -Force | Out-Null
        }

        $url = "https://raw.githubusercontent.com/$githubAccount/powershell-profile/main/$ProfileScriptName"
        $oldhash = Get-FileHash $destinationFilePath
        Invoke-RestMethod $url -OutFile $tempFilePath
        $newhash = Get-FileHash $tempFilePath
        if ($newhash.Hash -ne $oldhash.Hash) {
            Copy-Item -Path $tempFilePath -Destination $destinationFilePath -Force
            Write-Host "New version of script '$ProfileScriptName' has been downloaded and saved @ [$destinationFilePath]." -ForegroundColor Magenta
        }
    }
    catch {
        Write-Error "Unable to check for user profile updates"
    }
    finally {
        Remove-Item $tempFilePath -ErrorAction SilentlyContinue
    }
}

$profileConfiguration = @{
    Profile = "andresrocksmx_profile.ps1"
    Scripts = @(
        "profile-scripts/kubernetes-aliases.ps1"
        "profile-scripts/az-cli-autocompleter.ps1"
        "profile-scripts/andresrocksmx-aliases.ps1"
    )
}

if ($pwshProfileSuspendUpdates -ne 'true' -and $pwshProfileSuspendUpdates -ne '1') {

    $profileConfiguration.Scripts | ForEach-Object { Update-ProfileScripts -ProfileScriptName $_ }
    Update-ProfileScripts -ProfileScriptName $profileConfiguration.Profile
}
else {
    Write-Warning 'Automatic PowerShell Profile updates suspended ($env:POWERSHELL_PROFILE_SUSPEND_UPDATES). Use command Resume-Updates to active them.'
}

function Import-ToUserProfile {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        $FileName
    )

    $userProfile = "$profilePath\Profile.ps1" # $PROFILE.CurrentUserAllHosts
    if (!(Test-Path -Path $userProfile -PathType Leaf)) {
        New-Item -Path $userProfile -ItemType File -Force | Out-Null
        Write-Host "User profile @ [$userProfile] has been created." -ForegroundColor Yellow
    }

    $userProfileContent = Get-Content -Path $userProfile -Raw
    $userProfileScriptCommand = '. $PSScriptRoot\{0}' -f $FileName
    $userProfileScriptCommandRegex = [regex]::Escape($userProfileScriptCommand)
    $matchUserProfileScript = $userProfileContent -match $userProfileScriptCommandRegex

    if (!$matchUserProfileScript) {
        $userProfileContent += "`n$userProfileScriptCommand"
        $userProfileContent | Out-File $userProfile
        $(Get-Content -Path $userProfile -Raw).Trim("`r", "`n") | Out-File $userProfile

        Write-Host "User profile @ [$userProfile] has been updated and is now loading script '$FileName'. Please restart your shell to reflect changes" -ForegroundColor Magenta
    }
}

Import-ToUserProfile -FileName $profileConfiguration.Profile
$profileConfiguration.Scripts | ForEach-Object { . "$PSScriptRoot\$_" }