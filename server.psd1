@{
    Server  = @{
        AutoImport  = @{
            Modules = @{
                Enable     = $true
                ExportOnly = $true
            }
            Snapins = @{
                Enable = $false
            }
            # Functions = @{
            #     Enable = $true
            # }
        }
        FileMonitor = @{
            Enable    = $false
            Include   = @("*.pode", "*.ps1")
            Exclude   = @('podex.ps1', '.Archiv/*', '.history/*', '.vscode/*', '.codex/*', 'node_modules/*')
            ShowFiles = $true
        }
        Request     = @{
            Timeout = 600
        }
    }
    Web     = @{
        ErrorPages = @{
            ShowExceptions = $true
        }
        Static     = @{
            Cache = @{
                Enable = $false
            }
        }
    }
    PodeCfg = @{
        HttpPort       = 8943
        HttpUrl        = 'localhost'
        CertThumbprint = ''
        HttpsEnabled   = $false
    }
    Cache   = @{
        Name               = 'PXFileCache'
        FilePath           = './px-cache.json'
        SQL                = 'PXSQLCache'
        ModulesTTLSeconds  = 30
        CommandsTTLSeconds = 300
        HelpTTLSeconds     = 86400
    }
    Podex   = @{
        Debug        = $true
        DatabaseType = 'SQLite'
        DBFile       = './podex.db'
    }
    Logging = @{
        Path = ".logs"
    }
}
