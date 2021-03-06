##########################################################################
# Picassio is a provisioning/deployment script which uses a single linear
# JSON file to determine what commands to execute.
#
# Copyright (c) 2015, Matthew Kelly (Badgerati)
# Company: Cadaeic Studios
# License: MIT (see LICENSE for details)
#
# Example:
#
# {
#    "paint": [
#        {
#            "type": "git",
#            "remote": "https://path//to/some/branch.git"
#            "branch": "master",
#            "path": "C:\\path\\to\\place",
#            "name": "NewBranch"
#        }
#    ]
# }
#########################################################################

# Clones the remote repository into the supplied local path
Import-Module $env:PicassioTools -DisableNameChecking -ErrorAction Stop

function Start-Module($colour, $variables, $credentials)
{
    Test-Module $colour $variables $credentials

    # Check to see if git is installed, if not then install it
    if (!(Test-Software 'git --version' 'git'))
    {
        Write-Warnings 'Git is not installed'
        Install-AdhocSoftware 'git.install' 'Git'
    }

    $remote = (Replace-Variables $colour.remote $variables).Trim()
    $pattern = Get-GitPattern

    if (!($remote -imatch $pattern))
    {
        throw "Remote git repository of '$remote' is not valid."
    }

    $directory = $matches['repo']

    $path = (Replace-Variables $colour.path $variables).Trim()
    if (!(Test-Path $path))
    {
        New-Item -ItemType Directory -Force -Path $path | Out-Null
    }

    $branch = Replace-Variables $colour.branch $variables
    if ([string]::IsNullOrWhiteSpace($branch))
    {
        $branch = 'master'
    }
    else
    {
        $branch = $branch.Trim()
    }

    $commit = Replace-Variables $colour.commit $variables
    if ($commit -ne $null)
    {
        $commit = $commit.Trim()
    }

    $name = Replace-Variables $colour.name $variables
    if ($name -ne $null)
    {
        $name = $name.Trim()
    }

    # delete directory if exists
    Push-Location $path

    try
    {
        if ((Test-Path $directory))
        {
            Backup-Directory $directory
        }
        elseif (![string]::IsNullOrWhiteSpace($name) -and (Test-Path $name))
        {
            Backup-Directory $name
        }

        # clone
        Write-Message "Cloning git repository from '$remote' to '$path'."
        Run-Command 'git.exe' "clone $remote"

        # rename
        if (![string]::IsNullOrWhiteSpace($name))
        {
            Rename-Item $directory $name | Out-Null
            if (!$?)
            {
                throw "Rename of directory from '$directory' to '$name' failed."
            }

            Write-Message "Local directory renamed from '$directory' to '$name'."
            $directory = $name
        }

        # checkout
        Write-Message "Checking out the '$branch' branch."
        Push-Location $directory

        try
        {
            Run-Command 'git.exe' "checkout $branch"

            # reset
            if (![string]::IsNullOrWhiteSpace($commit))
            {
                Write-Message "Resetting local repository to the $commit commit."
                Run-Command 'git.exe' "reset --hard $commit"
            }

            Write-Message 'Git clone was successful.'
        }
        finally
        {
            Pop-Location
        }
    }
    finally
    {
        Pop-Location
    }
}

function Test-Module($colour, $variables, $credentials)
{
    $remote = Replace-Variables $colour.remote $variables
    $pattern = Get-GitPattern

    if ([string]::IsNullOrWhiteSpace($remote) -or $remote.Trim() -inotmatch $pattern)
    {
        throw "Remote git repository of '$remote' is not valid."
    }

    $path = Replace-Variables $colour.path $variables
    if ([string]::IsNullOrWhiteSpace($path))
    {
        throw 'No local git repository path specified.'
    }
}

function Get-GitPattern()
{
    return '(\\|\/)(?<repo>[a-zA-Z]+)\.git'
}
