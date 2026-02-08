
# ANSI-Farbcodes definieren
$fgColors = @{
    "Black"       = "`e[30m"
    "Red"         = "`e[31m"
    "Green"       = "`e[32m"
    "Yellow"      = "`e[33m"
    "Blue"        = "`e[34m"
    "Magenta"     = "`e[35m"
    "Cyan"        = "`e[36m"
    "White"       = "`e[37m"
    "DarkGray"    = "`e[90m"
    "DarkRed"     = "`e[91m"
    "DarkGreen"   = "`e[92m"
    "DarkYellow"  = "`e[93m"
    "DarkBlue"    = "`e[94m"
    "DarkMagenta" = "`e[95m"
    "DarkCyan"    = "`e[96m"
    "Reset"       = "`e[0m"
}

$bgColors = @{
    "Black"   = "`e[40m"
    "Red"     = "`e[41m"
    "Green"   = "`e[42m"
    "Yellow"  = "`e[43m"
    "Blue"    = "`e[44m"
    "Magenta" = "`e[45m"
    "Cyan"    = "`e[46m"
    "White"   = "`e[47m"
    "Reset"   = "`e[0m"
}

$reset = $fgColors["Reset"]
$output = ""

# Timestamp (Schwarz auf Gelb)
# if ($Log.ContainsKey("timestamp")) {
#     $TimeStamp = $Log.timestamp.ToLongTimeString()
#     $output += "$($fgColors["Black"])$($bgColors[$Configuration.Colors.Timestamp]) $($Timestamp) $reset "
# }

function Write-FormattedLog {
    [CmdletBinding()]
    param(
        [string]$tag,
        [string]$log,
        [switch]$save,
        [Exception] $Exception,
        [System.Management.Automation.ErrorRecord] $ErrorRecord
    )

    if (-not (Get-Module -Name 'PwshSpectreConsole' -ErrorAction SilentlyContinue)) {
        Import-Module 'PwshSpectreConsole'
    }

    #$timestamp = Get-Date -Format 'yyyy.MM.dd HH:mm:ss'
    #$PreTime = "$timestamp "

    $timestamp = Get-Date
    $PreTime = $timestamp.ToLongTimeString()

    $LineColor = 'White'

    switch ($tag) {
        'header' {
            #$icon = '✅'
            $Color = [System.ConsoleColor]::DarkGreen
            Write-PodeHost $log.PadLeft(22) -ForegroundColor $Color
            return
        }
        'routes' {
            $icon = '➡ '
            $Color = [System.ConsoleColor]::Cyan
        }
        'database'	{
            $icon = '💾'
            $Color = [System.ConsoleColor]::DarkMagenta
        }
        'api' {
            $icon = '🔗'
            $Color = [System.ConsoleColor]::DarkCyan
        }
        'htmx' {
            $icon = '🔗'
            $Color = [System.ConsoleColor]::DarkGreen
        }
        'debug' {
            $icon = '🐞'
            $Color = [System.ConsoleColor]::Gray
            $LineColor = [System.ConsoleColor]::DarkGray
            break
        }
        'informational' {
            $icon = 'ℹ️'
            $Color = [System.ConsoleColor]::Blue
        }
        'verbose'	{
            $icon = '🔍'
            $Color = [System.ConsoleColor]::DarkYellow
        }
        'warning'	{
            $icon = '⚠️'
            $Color = [System.ConsoleColor]::Yellow
        }
        'error' {
            $icon = '❌'
            $Color = [System.ConsoleColor]::DarkRed
            $LineColor = [System.ConsoleColor]::Red
        }
        default {
            $icon = '✅'
            $Color = [System.ConsoleColor]::White
            $LineColor = [System.ConsoleColor]::White
        }
    }


    #$prefix = '[{0}] {1} {2} ' -f $timestamp, $tag.PadRight(11), $icon
    $prefix = ' {0} {1} ' -f $tag.PadRight(11), $icon
    $PreLogLength = $PreTime.Length + $prefix.Length

    #Write-SpectreHost -Message $PreTime -NoNewline

    #TODO: MyConsole.ps1 einbinden
    #$Host.UI.WriteLine('Black', 'DarkYellow', $PreTime)

    Write-PodeHost $PreTime -NoNewLine -ForegroundColor DarkYellow
    Write-PodeHost $prefix -NoNewLine -ForegroundColor $Color

    # Write-PodeLog -Name 'pshelpviewer' -InputObject @(
    # 	$timestamp, $prefix, $log
    # )

    if ($Exception) {
        Write-PodeErrorLog -Level $tag -Exception $Exception
    }
    elseif ($ErrorRecord) {
        $ErrorRecord | Write-PodeErrorLog
    }

    $maxLineLength = 120
    try {
        $maxLineLength = [int]($Host.UI.RawUI.WindowSize.Width - $PreLogLength - 1)
    }
    catch {
        $maxLineLength = 120
    }

    if ($maxLineLength -lt 10) {
        $maxLineLength = 120
    }

    $currentPosition = 0

    #TODO: Bessere Lösung für Begrenzung einbauen.
    $CropLogLines = $true
    #$MaxLines = 3

    while ($currentPosition -lt $log.Length) {
        $endPosition = [math]::Min(($log.Length - $currentPosition), $maxLineLength)
        $line = $log.Substring($currentPosition, $endPosition)

        if ($currentPosition -ne 0) {
            if (-not $CropLogLines -or $tag -ne 'debug') {
                Write-PodeHost "$(' ' * $($PreLogLength))$($line)" -ForegroundColor $LineColor
            }
        }
        else {
            Write-PodeHost "$($line)" -ForegroundColor $LineColor
        }

        $currentPosition += $line.Length
    }


    if ($save) {
        $log | Out-File -FilePath "./$($WebEvent.Request.Url.AbsolutePath)/$($WebEvent.Method).json" -Force
    }
}
