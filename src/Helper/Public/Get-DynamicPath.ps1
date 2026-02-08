
function Get-DynamicPath {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string] $Name,
        [Parameter()]
        [string] $RelativePath,
        [Parameter()]
        [string] $ScriptRoot = (Get-PodeServerPath)
    )

    $DynamicPathItems = @($RelativePath)
    if ($Env:PODE_ENVIRONMENT -and $Name) {
        $DynamicPathItems = , "${Name}.$($Env:PODE_ENVIRONMENT).ps1" + $RelativePath
    }

    $DynamicPath = $DynamicPathItems | ForEach-Object { Join-Path -Path $ScriptRoot -ChildPath $_ } | Where-Object { $_ | Test-Path } | Select-Object -First 1

    if ($DynamicPath) {
        return $DynamicPath
    }
}
