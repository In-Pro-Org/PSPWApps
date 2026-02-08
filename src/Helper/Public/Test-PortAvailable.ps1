#requires -Modules PSWriteColor

function Test-PortAvailable {
    [CmdletBinding()]
    param (
        [Parameter()]
        [object] $ServerPath
    )

    $cfg = Import-PowerShellDataFile -Path (Join-Path -Path $ServerPath -ChildPath 'server.psd1')
    $httpPort = if ($cfg.PodeCfg -and $cfg.PodeCfg.HttpPort) {
        $cfg.PodeCfg.HttpPort
    }
    else {
        8433
    }

    $PortIsListen = Get-NetTCPConnection -LocalPort $httpPort -State Listen -ErrorAction SilentlyContinue

    if ($PortIsListen) {
        $OwningProc = Get-Process -Id $PortIsListen.OwningProcess
        $Owning = $OwningProc | Select-Object -ExpandProperty ProcessName
        Write-Color -Text "Port $httpPort is already occupied by Process: $Owning" -Color DarkYellow -StartSpaces 2
        if ($Owning -eq 'pwsh') {
            Write-Color -Text "Stopping PowerShell Process..." -Color Cyan -StartSpaces 4 -LinesAfter 1

            try {
                $OwningProc | Stop-Process
            }
            catch {
                Write-PodeLog -ErrObj ($_ | ConvertFrom-ErrorRecord)
                Exit
            }

        }
        else {
            throw "Port is occupied and not from PowerShell! $Owning"
        }
    }
}
