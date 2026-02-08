
function Register-ApiFileRoutes {
    [CmdletBinding()]
    param (

    )

    $ScriptRoot = Get-PodeServerPath
    $RoutesConfig = ($Config:Global).Routes.FileApiRoutes
    $ApiRoutesPath = Join-Path -Path $ScriptRoot -ChildPath 'api'

    $ApiRouteGroups = Get-ChildItem -Path $ApiRoutesPath -Directory
    $ApiRouteFiles = Get-ChildItem -Path $ApiRoutesPath -Filter *.ps1 -Recurse -File

    $ApiRoutes = [ordered]@{}
    $ApiRouteGroups | ForEach-Object {
        $ApiGroupName = $_.Name
        $ApiGroupPath = $_.FullName
        $ApiGroupRoutes = [System.Collections.ArrayList]::new()

        if ($RoutesConfig.$ApiGroupName.OpenApiFile) {
            $SchemeFile = Get-DynamicPath -RelativePath $RoutesConfig.$ApiGroupName.OpenApiFile
            $GroupScheme = Get-Content -Path $SchemeFile | ConvertFrom-Yaml -Ordered
        }

        $ApiGroupRouteFiles = $ApiRouteFiles | Where-Object { $_.FullName -imatch "^$ApiGroupPath" }

        foreach ($File in $ApiGroupRouteFiles) {
            $Method = (Get-Culture).TextInfo.ToTitleCase($File.BaseName)
            $RelativePath = $File.FullName -replace [regex]::Escape($ScriptRoot + '\'), '' -replace '\\', '/'
            $ApiPath = '/' + ($RelativePath -replace '\.ps1$', '')

            if ($Method -in @('Get', 'Post', 'Put', 'Delete')) {
                $ApiPath = $ApiPath -replace '/(get|post|put|delete)$', ''


            }
            elseif ($Config.Podex.Debug -and $RelativePath -match '/debug/') {
                $ApiPath = $ApiPath -replace '/debug', ''
                $Method = 'Get'
            }
            else {
                $Method = 'Get'
            }

            #TODO: ApiPath durch :name, :command, :version entsprechend ersetzen

            $OATags = @($ApiGroupName)
            $OARouteInfo = @{
                Tags = $OATags
            }

            if ($GroupScheme) {
                foreach ($Path in $GroupScheme.paths.Keys) {
                    if ($ApiPath -eq (($Path -replace '({|})', '') + '/')) {
                        if ($GroupScheme.paths.$Path.Keys -icontains $Method) {
                            $ApiScheme = $GroupScheme.paths.$Path.$Method

                            $OARouteInfo['Summary'] = $ApiScheme.summary ?? ''
                            $OARouteInfo['Description'] = $ApiScheme.description ?? ''
                        }

                        $ApiPathNew = $Path.Replace('{', ':').Replace('}', '')
                    }
                }

            }

            $ApiDefinition = @{
                RouteArgs   = @{
                    Path     = $ApiPathNew ?? $ApiPath
                    Method   = $Method
                    FilePath = $File.FullName
                    Group    = $ApiGroupName
                }
                OARouteInfo = $OARouteInfo
            }
            $ApiGroupRoutes.Add($ApiDefinition)
        }

        $ApiRoutes[$ApiGroupName] = $ApiGroupRoutes
    }

    #TODO: Api Registrierung und OA Info´s setzen.

<#
    foreach ($file in (Get-ChildItem -Path (Join-Path -Path $ScriptRoot -ChildPath 'api') -Filter *.ps1 -Recurse -File)) {
        $method = (Get-Culture).TextInfo.ToTitleCase($file.BaseName)
        $relativePath = $file.FullName -replace [regex]::Escape($ScriptRoot + '\'), '' -replace '\\', '/'
        $apiPath = '/' + ($relativePath -replace '\.ps1$', '')

        if (-not $Config.Podex.Debug -and $relativePath -match '/debug/') {
            continue
        }

        if ($method -in @('Get', 'Post', 'Put', 'Delete')) {
            $apiPath = $apiPath -replace '/(get|post|put|delete)$', ''

            if ($relativePath -match '/(modules|helpindex|px|v1)/') {
                $Regex = '(^|/)(name|command|version)(?=/|$)'
                $apiPath = $apiPath -replace $Regex, '$1:$2'
            }

        }
        elseif ($Config.Podex.Debug -and $relativePath -match '/debug/') {
            $apiPath = $apiPath -replace '/debug', ''
            $method = 'Get'
        }
        else {
            $method = 'Get'
        }

        switch ($relativePath) {
            { $_ -imatch '(^|/)\s*api/cache(/|$)' } {
                $Group = 'cache'
            }
            { $_ -imatch '(^|/)\s*api/v1(/|$)' } {
                $Group = 'v1'
            }
            { $_ -imatch '(^|/)\s*api/px(/|$)' } {
                $Group = 'PX'
            }
            { $_ -imatch '(^|/)\s*api/helpindex(/|$)' } {
                $Group = 'helpindex'
            }
            { $_ -imatch '(^|/)\s*api/modules(/|$)' } {
                $Group = 'modulexplorer'
            }
            default {
                $Group = 'default'
            }
        }

        Add-PodeRoute -Path $apiPath -Method $method -FilePath $file.FullName -Group $Group -PassThru | Set-PodeOARouteInfo -Tags $Group
    }
#>

}
