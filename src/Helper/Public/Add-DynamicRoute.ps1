using namespace System.Collections
using namespace System.Collections.Concurrent
using namespace System.Collections.Generic

enum RouteResponseType {
    Json
    View
    Html
    Text
    File
    Redirect
    Xml
    Yaml
    Markdown
    Csv
}

class RouteData {
    [string] $PageName
    [string] $Title
    [List[object]] $Components = [List[object]]::new()
    [hashtable] $Meta = @{}

    RouteData() {
        #$this.Components = [List[object]]::new()
        #$this.Meta = @{}
    }

    RouteData([string] $PageName, [string] $Title) {
        $this.PageName = $PageName
        $this.Title = $Title
    }

    RouteData([string] $PageName, [string] $Title, [object] $Components) {
        $this.PageName = $PageName
        $this.Title = $Title
        $Components | ForEach-Object {
            $this.Components.Add($_)
        }
    }

    [void] AddComponent([object] $Component) {
        if ($null -eq $Component) {
            return
        }

        $this.Components.Add($Component)
    }

    [hashtable] ToHashtable() {
        return @{
            PageName   = $this.PageName
            Title      = $this.Title
            Components = @($this.Components)
            Meta       = $this.Meta
        }
    }
}

class RouteResponse {
    [RouteResponseType] $Type
    [string] $Path
    [RouteData] $Data
    [object] $Value
    [int] $StatusCode = 200
    [int] $Depth = 5
    [string] $ContentType
    [switch] $MarkdownAsHtml

    RouteResponse() {
    }

    static [RouteResponse] Json([object] $Value, [int] $StatusCode, [int] $Depth) {
        $Instance = [RouteResponse]::new()
        $Instance.Type = [RouteResponseType]::Json
        $Instance.Value = $Value
        $Instance.StatusCode = $StatusCode
        $Instance.Depth = $Depth
        return $Instance
    }

    static [RouteResponse] View([string] $Path, [RouteData] $Data) {
        return [RouteResponse]::View($Path, $Data, 200)
    }

    static [RouteResponse] View([string] $Path, [RouteData] $Data, [int] $StatusCode) {
        $Instance = [RouteResponse]::new()
        $Instance.Type = [RouteResponseType]::View
        $Instance.Path = $Path
        $Instance.Data = $Data
        $Instance.StatusCode = $StatusCode

        return $Instance
    }

    static [RouteResponse] Redirect([string] $UrlOrPath) {
        $Instance = [RouteResponse]::new()
        $Instance.Type = [RouteResponseType]::Redirect
        $Instance.Path = $UrlOrPath
        $Instance.StatusCode = 302
        return $Instance
    }

    [void] Write() {
        switch ($this.Type) {
            'View' {
                $ViewData = @{}
                if ($null -ne $this.Data) {
                    $ViewData = $this.Data.ToHashtable()
                }

                # Pode: Write-PodeViewResponse -Path <String> -Data <Hashtable> -StatusCode <Int32>
                Write-PodeViewResponse -Path $this.Path -Data $ViewData -StatusCode $this.StatusCode
                break
            }

            'Json' {
                if (-not [string]::IsNullOrWhiteSpace($this.Path)) {
                    Write-PodeJsonResponse -Path $this.Path -StatusCode $this.StatusCode
                }
                else {
                    Write-PodeJsonResponse -Value $this.Value -StatusCode $this.StatusCode -Depth $this.Depth
                }
                break
            }

            'Html' {
                if (-not [string]::IsNullOrWhiteSpace($this.Path)) {
                    Write-PodeHtmlResponse -Path $this.Path -StatusCode $this.StatusCode
                }
                else {
                    Write-PodeHtmlResponse -Value $this.Value -StatusCode $this.StatusCode
                }
                break
            }

            'Text' {
                if ([string]::IsNullOrWhiteSpace($this.ContentType)) {
                    Write-PodeTextResponse -Value $this.Value -StatusCode $this.StatusCode
                }
                else {
                    Write-PodeTextResponse -Value $this.Value -StatusCode $this.StatusCode -ContentType $this.ContentType
                }
                break
            }

            'File' {
                if ([string]::IsNullOrWhiteSpace($this.ContentType)) {
                    Write-PodeFileResponse -Path $this.Path -StatusCode $this.StatusCode
                }
                else {
                    Write-PodeFileResponse -Path $this.Path -StatusCode $this.StatusCode -ContentType $this.ContentType
                }
                break
            }

            'Redirect' {
                Move-PodeResponseUrl -Url $this.Path
                break
            }

            'Xml' {
                if (-not [string]::IsNullOrWhiteSpace($this.Path)) {
                    Write-PodeXmlResponse -Path $this.Path -StatusCode $this.StatusCode
                }
                else {
                    Write-PodeXmlResponse -Value $this.Value -Depth $this.Depth -StatusCode $this.StatusCode
                }
                break
            }

            'Yaml' {
                if (-not [string]::IsNullOrWhiteSpace($this.Path)) {
                    Write-PodeYamlResponse -Path $this.Path -StatusCode $this.StatusCode
                }
                else {
                    Write-PodeYamlResponse -Value $this.Value -Depth $this.Depth -StatusCode $this.StatusCode
                }
                break
            }

            'Markdown' {
                if (-not [string]::IsNullOrWhiteSpace($this.Path)) {
                    Write-PodeMarkdownResponse -Path $this.Path -StatusCode $this.StatusCode -AsHtml:$this.MarkdownAsHtml
                }
                else {
                    Write-PodeMarkdownResponse -Value $this.Value -StatusCode $this.StatusCode -AsHtml:$this.MarkdownAsHtml
                }
                break
            }

            'Csv' {
                if (-not [string]::IsNullOrWhiteSpace($this.Path)) {
                    Write-PodeCsvResponse -Path $this.Path -StatusCode $this.StatusCode
                }
                else {
                    Write-PodeCsvResponse -Value $this.Value -StatusCode $this.StatusCode
                }
                break
            }

            default {
                throw "Unsupported RouteResponseType: $($this.Type)"
            }
        }
    }
}

class Route {
    [string] $Name
    [string] $Path
    [string[]] $Method
    [scriptblock] $ScriptBlock
    [RouteResponse] $Response

    [string] $ContentType
    [string] $EndpointName
    [string] $Authentication
    [scriptblock[]] $Middleware
    [hashtable] $ArgumentList

    Route() {
        $this.Method = @('Get')
        $this.Middleware = @()
        $this.ArgumentList = @{}
    }

    Route([string] $Path, [string[]] $Method, [scriptblock] $ScriptBlock) {
        $this.Path = $Path
        $this.Method = $Method
        $this.ScriptBlock = $ScriptBlock
    }

    [void] Normalize() {
        if ([string]::IsNullOrWhiteSpace($this.Path)) {
            throw 'Route.Path must not be empty.'
        }

        if (-not $this.Path.StartsWith('/')) {
            $this.Path = "/$($this.Path)"
        }

        if ($null -eq $this.Method -or $this.Method.Count -eq 0) {
            throw 'Route.Method must contain at least one HTTP method.'
        }

        $NormalizedMethods = foreach ($CurrentMethod in $this.Method) {
            if ([string]::IsNullOrWhiteSpace($CurrentMethod)) {
                continue
            }

            $CleanMethod = $CurrentMethod.Trim()
            if ($CleanMethod.Length -eq 1) {
                $CleanMethod.ToUpperInvariant()
            }
            else {
                ($CleanMethod.Substring(0, 1).ToUpperInvariant() + $CleanMethod.Substring(1).ToLowerInvariant())
            }
        }

        $this.Method = @($NormalizedMethods | Sort-Object -Unique)
    }

    [string] GetKey() {
        $this.Normalize()

        if (-not [string]::IsNullOrWhiteSpace($this.Name)) {
            return $this.Name
        }

        $MethodKey = ($this.Method -join ',')
        return "$MethodKey::$($this.Path)"
    }

    [scriptblock] BuildPodeScriptBlock() {
        $RouteInstance = $this

        return {
            param($WebEvent)

            $Result = $null

            if ($null -ne $using:RouteInstance.ScriptBlock) {
                $Result = & $using:RouteInstance.ScriptBlock $WebEvent
            }
            elseif ($null -ne $using:RouteInstance.Response) {
                $Result = $using:RouteInstance.Response
            }
            else {
                throw "Route '$($RouteInstance.GetKey())' has neither ScriptBlock nor Response."
            }

            if ($Result -is [RouteResponse]) {
                $Result.Write()
                return
            }

            # Default: JSON
            ([RouteResponse]::Json($Result)).Write()
        }
    }

    [void] Register() {
        $this.Normalize()

        $Parameters = @{
            Method      = $this.Method
            Path        = $this.Path
            ScriptBlock = $this.BuildPodeScriptBlock()
        }

        if (-not [string]::IsNullOrWhiteSpace($this.ContentType)) {
            $Parameters.ContentType = $this.ContentType
        }

        if (-not [string]::IsNullOrWhiteSpace($this.EndpointName)) {
            $Parameters.EndpointName = $this.EndpointName
        }

        if (-not [string]::IsNullOrWhiteSpace($this.Authentication)) {
            $Parameters.Authentication = $this.Authentication
        }

        if ($null -ne $this.Middleware -and $this.Middleware.Count -gt 0) {
            $Parameters.Middleware = $this.Middleware
        }

        if ($null -ne $this.ArgumentList -and $this.ArgumentList.Count -gt 0) {
            $Parameters.ArgumentList = $this.ArgumentList
        }

        Add-PodeRoute @Parameters
    }
}

class RouteFactory {
    [ConcurrentDictionary[string, Route]] $Routes

    RouteFactory() {
        $this.Routes = [ConcurrentDictionary[string, Route]]::new()
    }

    [Route] Add([Route] $Route) {
        if ($null -eq $Route) {
            throw 'Route must not be null.'
        }

        $RouteKey = $Route.GetKey()
        $Added = $this.Routes.TryAdd($RouteKey, $Route)

        if (-not $Added) {
            throw "A route with key '$RouteKey' already exists."
        }

        return $Route
    }

    [Route] Get([string] $Key) {
        if ([string]::IsNullOrWhiteSpace($Key)) {
            return $null
        }

        $Found = $null
        if ($this.Routes.TryGetValue($Key, [ref] $Found)) {
            return $Found
        }

        return $null
    }

    [Route[]] List() {
        return @($this.Routes.Values)
    }

    [void] RegisterAll() {
        foreach ($Route in $this.Routes.Values) {
            $Route.Register()
        }
    }
}

function Add-DynamicRoute {
    [CmdletBinding()]
    param (
        [Parameter()]
        [object] $RouteObject
    )

    $Data = @{
        PageName   = 'Home'
        Title      = 'Podex - PowerShell/Pode + htmx Framework for Building Web Applications'
        Components = @('about')
    }

    $Response = @{
        Path = 'layouts/main'
        Data = $Data
    }

    $Route = @{
        Path = '/'
        Method = 'Get', 'Post'
        ScriptBlock = {
            Write-PodeViewResponse @Response
        }
    }

    Add-PodeRoute @Route

    #TODO: Verifizieren und testen der Klassen und einbinden dynamischer Routen.

    # Add-PodeRoute -Path '/' -Method Get, Post -ScriptBlock { Write-PodeViewResponse -Path 'layouts/main' -Data @{ PageName = 'Home'; Title = 'Podex - PowerShell/Pode + htmx Framework for Building Web Applications'; Components = @('about'); } }
    # Add-PodeRoute -Path '/crudmgr'	-Method Get, Post -ScriptBlock { Write-PodeViewResponse -Path 'layouts/main' -Data @{ PageName = 'CRUDMgr'; Title = 'Podex - CRUD Management Demo'; Components = @('crudmgr'); } }

    ##########################################################

    $Factory = [RouteFactory]::new()

    $RouteData = [RouteData]::new(
        'Home',
        'Podex - PowerShell/Pode + htmx Framework for Building Web Applications',
        @('about')
    )
    $RouteResponse = [RouteResponse]::View(
        'layouts/main',
        $RouteData
    )
    $Route = [Route]::new(
        '/',
        @('Get', 'Post'),
        { $RouteResponse.Write() }
    )

    $null = $Factory.Add($Route)

    ############################################################

    $HomeRoute = [Route]::new(
        '/',
        @('Get', 'Post'),
        [RouteResponse]::View(
            'layouts/main',
            [RouteData]::new(
                'Home',
                'Podex - PowerShell/Pode + htmx Framework for Building Web Applications',
                @('about')
            )
        )
    )

}

function Test-RouteClass {
    [CmdletBinding()]
    param (

    )

    $Factory = [RouteFactory]::new()

    # 1) JSON Route (dynamisch per ScriptBlock)
    $Factory.Add([Route]::new(
        '/api/ping',
        @('Get'),
        {
            param($WebEvent)
            return @{
                Value     = 'pong'
                Path      = $WebEvent.Path
                Timestamp = (Get-Date)
            }
        }
    )) | Out-Null

    # 2) View Route (statische RouteResponse -> generischer Handler schreibt Response)
    $HomeData = [RouteData]::new('Home', 'Startseite')
    $HomeData.AddComponent(@{ Type = 'Hero'; Text = 'Willkommen' })

    $HomeRoute = [Route]::new()
    $HomeRoute.Path = '/'
    $HomeRoute.Method = @('Get')
    $HomeRoute.Response = [RouteResponse]::View('index', $HomeData, 200)

    $Factory.Add($HomeRoute) | Out-Null

    $Factory.RegisterAll()
}
