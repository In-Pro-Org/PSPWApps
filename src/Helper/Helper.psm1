
if (-not (Get-Module -Name 'PwshSpectreConsole' -ListAvailable -ErrorAction SilentlyContinue)) {
    Install-PSResource 'PwshSpectreConsole'
}

if (-not (Get-Module -Name 'PwshSpectreConsole' -ErrorAction SilentlyContinue)) {
    Import-Module 'PwshSpectreConsole'
}

Get-ChildItem -Path $PSScriptRoot -Filter '*.ps1' -Recurse | ForEach-Object { . $_.FullName }

Export-ModuleMember -Function '*'
