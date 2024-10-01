function New-KeePassDatabase {
    <#
    .SYNOPSIS
    Creates a new KeePass database with a specified path and key file.

    .PARAMETER DatabasePath
    The full path to the KeePass database file.

    .PARAMETER KeyFilePath
    The full path to the key file for the KeePass database.

    .EXAMPLE
    New-KeePassDatabase -DatabasePath "C:\code\secrets\myDatabase.kdbx" -KeyFilePath "C:\code\secrets\myKeyFile.keyx"
    Creates a new KeePass database at the specified path with the given key file.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The full path to the KeePass database file.")]
        [ValidateNotNullOrEmpty()]
        [string]$DatabasePath = "C:\code\secrets\myDatabase.kdbx",

        [Parameter(Mandatory = $true, HelpMessage = "The full path to the key file for the KeePass database.")]
        [ValidateNotNullOrEmpty()]
        [string]$KeyFilePath = "C:\code\secrets\myKeyFile.keyx"
    )

    Begin {
        Write-EnhancedLog -Message "Starting New-KeePassDatabase function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters

        # Extract directories from paths
        $databaseDirectory = Split-Path -Path $DatabasePath
        $keyFileDirectory = Split-Path -Path $KeyFilePath

        # Check if the directory exists, and create it if it doesn't
        if (-not (Test-Path -Path $databaseDirectory)) {
            Write-Host "Directory does not exist. Creating directory: $databaseDirectory" -Level "Warning"
            New-Item -Path $databaseDirectory -ItemType Directory | Out-Null
        }
        else {
            Write-EnhancedLog -Message "Directory already exists: $databaseDirectory" -Level "Notice"
        }

    }

    Process {
        # Check if the directory for the database exists
        if (-not (Test-Path -Path $databaseDirectory)) {
            Write-EnhancedLog -Message "The directory for the database path does not exist: $databaseDirectory" -Level "ERROR"
            throw "The directory for the database path does not exist."
        }

        # Check if the directory for the key file exists
        if (-not (Test-Path -Path $keyFileDirectory)) {
            Write-EnhancedLog -Message "The directory for the key file path does not exist: $keyFileDirectory" -Level "ERROR"
            throw "The directory for the key file path does not exist."
        }

        # Command to create KeePass database with the specified key file
        $command = "keepassxc-cli db-create `"$DatabasePath`" --set-key-file `"$KeyFilePath`""

        try {
            Invoke-Expression $command
            Write-EnhancedLog -Message "Database '$DatabasePath' created successfully with key file '$KeyFilePath'." -Level "INFO"
        }
        catch {
            Write-EnhancedLog -Message "Failed to create the KeePass database: $($_.Exception.Message)" -Level "ERROR"
            throw "Failed to create the database. $($_.Exception.Message)"
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting New-KeePassDatabase function" -Level "Notice"
    }
}

# # Define the path to the database and key file
# $databaseParams = @{
#     DatabasePath = "C:\code\secrets\myDatabase.kdbx"
#     KeyFilePath  = "C:\code\secrets\myKeyFile.keyx"
# }

# # Now you can safely create the database
# New-KeePassDatabase @databaseParams

# Wait-Debugger