# Checkout a remote repository using svn into the supplied local path
Import-Module $env:PicassoTools -DisableNameChecking

function Start-Module($colour) {
    if (!(Test-Software svn.exe 'svn')) {
        Write-Error 'SVN is not installed'
        Install-AdhocSoftware 'svn' 'SVN'
    }

    $url = $colour.remote
    if ([string]::IsNullOrWhiteSpace($url)) {
        throw 'No remote SVN repository passed.'
    }

    $path = $colour.localpath
    if ([string]::IsNullOrWhiteSpace($path)) {
        throw 'No local SVN repository path specified.'
    }

    if (!(Test-Path $path)) {
        New-Item -ItemType Directory -Force -Path $path | Out-Null
    }

    $name = $colour.localname
    if ([string]::IsNullOrWhiteSpace($name)) {
        throw 'No local name supplied for local repository.'
    }

    $revision = $colour.revision
    
    # Delete existing directory
    Push-Location $path
    if ((Test-Path $name)) {
        Backup-Directory $name
    }

    # checkout
    Write-Message "Checking out SVN repository from '$url' to '$path'."
    svn.exe checkout $url $name

    if (!$?) {
        Pop-Location
        throw 'Failed to checkout SVN repository.'
    }

    # reset to revision
    if (![string]::IsNullOrWhiteSpace($revision)) {
        Write-Message "Resetting local repository to revision $revision."
        Push-Location $name
        svn.exe up -r $revision
    
        if (!$?) {
            Pop-Location
            Pop-Location
            throw "Failed to reset repository to revision $revision."
        }
    }

    Pop-Location
    Pop-Location
    Write-Message 'SVN checkout was successful.'
}