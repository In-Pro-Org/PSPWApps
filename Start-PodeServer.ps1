Import-Module Pode.Web -RequiredVersion 0.8.3

# Set ScriptRoot.
$ScriptRoot = if ($PSScriptRoot) {
    $PSScriptRoot
}
elseif ($Host.Name -eq 'Visual Studio Code Host') {
    (Split-Path $psEditor.GetEditorContext().CurrentFile.Path)
}
else {
    './'
}

$env:PODexRoot = $ScriptRoot

$ModulesPath = Join-Path -Path $ScriptRoot -ChildPath 'src'
$Modules = Get-ChildItem -Path $ModulesPath -Filter '*.psm1' -Recurse -File
$Modules | ForEach-Object {
    Import-Module $_.FullName -Force
}

Test-PortAvailable -ServerPath $env:PODexRoot

Start-PodeServer -Threads 2 {

    $Modules | ForEach-Object {
        Export-PodeModule -Name $_.BaseName
    }

    Add-PodeScopedVariable -Name 'Config' -ScriptBlock {
        param($ScriptBlock, $SessionState, $GetPattern, $SetPattern)
        $strScriptBlock = "$($ScriptBlock)"
        $template = "(Get-PodeConfig).'{{name}}'"

        # allows "$port = $config:port" instead of "$port = (Get-PodeConfig).port"
        while ($strScriptBlock -imatch $GetPattern) {
            $getReplace = $template.Replace('{{name}}', $Matches['name'])
            $strScriptBlock = $strScriptBlock.Replace($Matches['full'], "($($getReplace))")
        }

        return [scriptblock]::Create($strScriptBlock)
    }


    #region    get config
    $Config = Get-PodeConfig

    #endregion get config

    #region    setup logging

    # Enable Loggin to Terminal
    #New-PodeLoggingMethod -Path .\logs -Name "PodeWebServer.log" | Enable-PodeErrorLogging
    #New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging

    $LogsPath = Join-Path -Path $ScriptRoot -ChildPath $Config.Logging.Path

    New-PodeLoggingMethod -File -Path $LogsPath -Name 'requests' | Enable-PodeRequestLogging
    New-PodeLoggingMethod -File -Path $LogsPath -Name 'pshelpviewer' -MaxDays 1 -MaxSize 5MB

    if ($Config.Podex.Debug) {
        #New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging -Levels *
        New-PodeLoggingMethod -File -Path $LogsPath -Name 'errors' -MaxDays 1 -MaxSize 5MB | Enable-PodeErrorLogging
    }
    else {
        New-PodeLoggingMethod -File -Path $LogsPath -Name 'errors' -MaxDays 1 -MaxSize 5MB | Enable-PodeErrorLogging
    }
    #endregion setup logging

    # Use default system Theme
    Use-PodeWebTemplates -Title "Tinu's PodeWebApp" -Theme Auto

    # Add Navbar
    $Properties = @{
        Name = 'Pode.Web on GitHub'
        Url  = 'https://github.com/Badgerati/Pode.Web'
        Icon = 'help-circle'
    }

    $navgithub = New-PodeWebNavLink @Properties -NewTab
    Set-PodeWebNavDefault -Items $navgithub

    # Running on Windows
    if (($PSVersionTable.PSVersion.Major -lt 6) -or ($IsWindows)) {
        Write-Host "Running on Windows $($PSScriptRoot)"

        # Add dynamic pages
        foreach ($item in (Get-ChildItem (Join-Path $PSScriptRoot -ChildPath 'pages'))) {
            . "$($item.FullName)"
        }

        # Add Listener to Tcp Port 8080 on localhost
        # $EPProperties = @{
        #     #Address  = 'PodeWebApp'
        #     Address  = '0.0.0.0'
        #     Port     = 8943
        #     Protocol = 'http'
        # }

        $httpsEnabled = $Config.PodeCfg.HttpsEnabled ?? $false

        $EPProperties = @{
            Address  = $Config.PodeCfg.HttpUrl ?? '127.0.0.1'
            Port     = $Config.PodeCfg.HttpPort ?? 8433
            Protocol = if ($httpsEnabled) { 'https' } else { 'http' }
        }

        Add-PodeEndpoint @EPProperties #-SelfSigned

        if ($Config.Podex.Debug) {
            $Routes = Get-PodeRoute | Sort-Object -Unique -Property Path, Method

            $Routes | ForEach-Object {
                Write-FormattedLog -tag 'routes' -log "$($_.Method.PadRight(8).ToUpper()) -> $($_.Path.PadRight(40))"
            }
        }

        # Start Browser
        #$Path = "microsoft-edge:$($EPProperties.Protocol)://$($EPProperties.Address):$($EPProperties.Port)/"
        $Path = "$($EPProperties.Protocol)://$($EPProperties.Address):$($EPProperties.Port)/"

        #Start-Process $Path -WindowStyle maximized

    }
    elseif ($IsMacOS) {
        Write-Host "Running on Mac $($PSScriptRoot)"
        # Add dynamic pages
        foreach ($item in (Get-ChildItem (Join-Path $PSScriptRoot -ChildPath 'pages') -Exclude 'win_*')) {
            . "$($item.FullName)"
        }
        # Add Listener to Tcp Port 8080 on localhost
        $EPProperties = @{
            Address  = 'localhost'
            Port     = 8080
            Protocol = 'http'
        }
        Add-PodeEndpoint @EPProperties
        # Start Browser
        $Path = "$($EPProperties.Protocol)://$($EPProperties.Address):$($EPProperties.Port)/"
        Start-Process $Path

    }
    elseif ($IsLinux) {
        Write-Host "Running on Linux $($PSScriptRoot)"
        # Add dynamic pages
        foreach ($item in (Get-ChildItem (Join-Path $PSScriptRoot -ChildPath 'pages') -Exclude 'win_*')) {
            . "$($item.FullName)"
        }
        # Add Listener to Tcp Port 8080 on localhost
        $EPProperties = @{
            Address  = 'localhost'
            Port     = 8080
            Protocol = 'http'
        }
        Add-PodeEndpoint @EPProperties
        # Start Browser
        $Path = "$($EPProperties.Protocol)://$($EPProperties.Address):$($EPProperties.Port)/"
        Start-Process $Path

    }

}
