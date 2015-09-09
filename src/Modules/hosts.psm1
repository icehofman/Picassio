# Updates the hosts file
Import-Module $env:PICASSO_TOOLS -DisableNameChecking

function Colour-UpdateHosts($colour) {
    $hostFile = "$env:windir\System32\drivers\etc\hosts"
    if (!(Test-Path $hostFile)) {
        throw "Hosts file does not exist at: '$hostFile'."
    }

    $ensure = $colour.ensure
    if ([String]::IsNullOrWhiteSpace($ensure)) {
        throw 'No ensure parameter supplied for hosts update.'
    }

    # check we have a valid ensure property
    $ensure = $ensure.ToLower()
    if ($ensure -ne 'added' -and $ensure -ne 'removed') {
        throw "Invalid ensure parameter supplied for hosts: '$ensure'."
    }

    # check IP
    $ip = $colour.ip
    if ([String]::IsNullOrWhiteSpace($ip)) {
        $ip = [String]::Empty
    }

    # check hostname
    $hostname = $colour.hostname
    if ([String]::IsNullOrWhiteSpace($hostname)) {
        $hostname = [String]::Empty
    }

    if ($ensure -eq 'added' -and ([String]::IsNullOrWhiteSpace($ip) -or [String]::IsNullOrWhiteSpace($hostname))) {
        throw 'No IP or Hostname has been supplied for adding a host entry.'
    }
    elseif ($ensure -eq 'removed' -and [String]::IsNullOrWhiteSpace($ip) -and [String]::IsNullOrWhiteSpace($hostname)) {
        throw 'No IP and Hostname have been supplied for removing a host entry.'
    }

    Write-Message "Ensuring $ip/$hostname are $ensure."

    switch ($ensure) {
        'added'
            {
                ("$ip`t`t$hostname") | Out-File -FilePath $hostFile -Encoding ASCII -Append
            }

        'removed'
            {
                $regex = ".*?$ip.*?$hostname.*?"
                $lines = Get-Content $hostFile
                $lines | Where-Object { $_ -notmatch $regex } | Out-File -FilePath $hostFile -Encoding ASCII
            }
    }

    if (!$?) {
        throw "Failed to $ensure $ip/$hostname to the hosts file."
    }

    Write-Message "$ip/$hostname has been $ensure successfully."
}