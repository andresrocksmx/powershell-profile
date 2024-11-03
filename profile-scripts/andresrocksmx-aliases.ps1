function gpip() { (Invoke-WebRequest http://ifconfig.me/ip).Content }

function sproj { Set-Location -Path $HOME\projects }

function oproj { explorer -Path $HOME\projects }

function lproj { Get-ChildItem -Path $HOME\projects -Force }

function slproj { 
    sproj
    lproj 
}

function home { 
    return $HOME 
}