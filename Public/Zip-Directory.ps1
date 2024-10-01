function Zip-Directory {
    <#
    .SYNOPSIS
    Zips the contents of a specified directory into a zip archive.

    .PARAMETER SourceDirectory
    The full path to the directory that you want to zip.

    .PARAMETER ZipFilePath
    The path where the zip archive will be saved.

    .EXAMPLE
    $params = @{
        SourceDirectory = "C:\code\secrets\vault"
        ZipFilePath     = "C:\code\secrets\vault.zip"
    }
    Zip-Directory @params
    Zips the contents of the directory into an archive.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The full path to the directory that you want to zip.")]
        [ValidateNotNullOrEmpty()]
        [string]$SourceDirectory,

        [Parameter(Mandatory = $true, HelpMessage = "The path where the zip archive will be saved.")]
        [ValidateNotNullOrEmpty()]
        [string]$ZipFilePath
    )

    Begin {
        Write-EnhancedLog -Message "Starting Zip-Directory function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters

        # Determine the destination directory and create it if necessary
        $destinationDir = Split-Path -Path $ZipFilePath -Parent
        if (-not (Test-Path -Path $destinationDir)) {
            New-Item -Path $destinationDir -ItemType Directory | Out-Null
            Write-EnhancedLog -Message "Created destination directory: $destinationDir" -Level "INFO"
        }
    }

    Process {
        try {
            # Check if the source directory exists
            if (-not (Test-Path -Path $SourceDirectory)) {
                Write-EnhancedLog -Message "Source directory does not exist: $SourceDirectory" -Level "ERROR"
                throw "Source directory does not exist: $SourceDirectory"
            }

            # Create the zip archive from the directory
            [System.IO.Compression.ZipFile]::CreateFromDirectory($SourceDirectory, $ZipFilePath, [System.IO.Compression.CompressionLevel]::Optimal, $false)
            Write-EnhancedLog -Message "Successfully zipped the directory to: $ZipFilePath" -Level "INFO"
        }
        catch {
            Write-EnhancedLog -Message "Error during zipping: $($_.Exception.Message)" -Level "ERROR"
            throw "Zipping process failed: $($_.Exception.Message)"
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Zip-Directory function" -Level "Notice"
    }
}
