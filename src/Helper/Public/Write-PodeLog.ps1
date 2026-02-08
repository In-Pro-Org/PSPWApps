#requires -Modules PSWriteColor

function Write-PodeLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        $ErrObj
    )

    $Script = $ErrObj.Script.Split($ScriptRoot)[-1]
    $Message = "[$Script][$($ErrObj.Line)] $($ErrObj.Exception)"

    if (Get-Command -Name Write-FormattedLog -ErrorAction SilentlyContinue) {
        Write-FormattedLog -tag 'error' -log $Message -ErrorRecord $Err
    }
    else {
        Write-Color -Text '[Error]' -Color DarkRed -Encoding utf8 -NoNewLine
        Write-Color -Text $Message -Color DarkRed -Encoding utf8 -StartSpaces 2
    }

}
