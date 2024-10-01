function Add-KeePassEntry {
    <#
    .SYNOPSIS
    Adds a new entry to the KeePass database.

    .PARAMETER DatabasePath
    The full path to the KeePass database file.

    .PARAMETER KeyFilePath
    The full path to the key file for the KeePass database.

    .PARAMETER Username
    The username for the entry being added.

    .PARAMETER EntryName
    The name of the entry being added.

    .EXAMPLE
    Add-KeePassEntry -DatabasePath "C:\code\secrets\myDatabase.kdbx" -KeyFilePath "C:\code\secrets\myKeyFile.keyx" -Username "john_doe" -EntryName "example_entry"
    Adds the username "john_doe" to the "example_entry" in the KeePass database.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The full path to the KeePass database file.")]
        [ValidateNotNullOrEmpty()]
        [string]$DatabasePath,

        [Parameter(Mandatory = $true, HelpMessage = "The full path to the key file for the KeePass database.")]
        [ValidateNotNullOrEmpty()]
        [string]$KeyFilePath,

        [Parameter(Mandatory = $true, HelpMessage = "The username for the entry being added.")]
        [ValidateNotNullOrEmpty()]
        [string]$Username,

        [Parameter(Mandatory = $true, HelpMessage = "The name of the entry being added.")]
        [ValidateNotNullOrEmpty()]
        [string]$EntryName
    )

    Begin {
        Write-EnhancedLog -Message "Starting Add-KeePassEntry function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
            # Validate paths
            if (-not (Test-Path -Path $DatabasePath)) {
                Write-EnhancedLog -Message "The database file does not exist: $DatabasePath" -Level "ERROR"
                throw "The database file does not exist: $DatabasePath"
            }

            if (-not (Test-Path -Path $KeyFilePath)) {
                Write-EnhancedLog -Message "The key file does not exist: $KeyFilePath" -Level "ERROR"
                throw "The key file does not exist: $KeyFilePath"
            }

            # Construct command for KeePassXC CLI
            $command = "keepassxc-cli add `"$DatabasePath`" -u `"$Username`" -g `"$EntryName`" --key-file `"$KeyFilePath`" --no-password"

            Write-EnhancedLog -Message "Running command: $command" -Level "INFO"

            # Execute the command
            Invoke-Expression $command

            Write-EnhancedLog -Message "Entry '$EntryName' added successfully to the database." -Level "INFO"
        }
        catch {
            Write-EnhancedLog -Message "Failed to add entry: $($_.Exception.Message)" -Level "ERROR"
            throw "Failed to add entry to the database: $($_.Exception.Message)"
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Add-KeePassEntry function" -Level "Notice"
    }
}


# Add a new entry to the KeePass database
# Define the parameters for adding a new entry
# $entryParams = @{
#     DatabasePath = "C:\code\secrets\myDatabase.kdbx"
#     KeyFilePath  = "C:\code\secrets\myKeyFile.keyx"
#     Username     = "john_doe"
#     EntryName    = "example_entry"
# }

# Add a new entry to the KeePass database
# Add-KeePassEntry @entryParams




