function Unzip-Directory {
    <#
    .SYNOPSIS
    Extracts the contents of a zip archive to a specified directory.

    .PARAMETER ZipFilePath
    The full path to the zip file that you want to extract.

    .PARAMETER DestinationDirectory
    The directory where the contents of the zip file will be extracted.

    .EXAMPLE
    $params = @{
        ZipFilePath         = "C:\code\secrets\vault.zip"
        DestinationDirectory = "C:\code\secrets\vault"
    }
    Unzip-Directory @params
    Unzips the archive to the specified directory.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The full path to the zip file.")]
        [ValidateNotNullOrEmpty()]
        [string]$ZipFilePath,

        [Parameter(Mandatory = $true, HelpMessage = "The directory where the contents will be extracted.")]
        [ValidateNotNullOrEmpty()]
        [string]$DestinationDirectory
    )

    Begin {
        Write-EnhancedLog -Message "Starting Unzip-Directory function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
            # Check if the zip file exists
            if (-not (Test-Path -Path $ZipFilePath)) {
                Write-EnhancedLog -Message "Zip file does not exist: $ZipFilePath" -Level "ERROR"
                throw "Zip file does not exist: $ZipFilePath"
            }

            # Ensure the destination directory exists
            if (-not (Test-Path -Path $DestinationDirectory)) {
                New-Item -Path $DestinationDirectory -ItemType Directory | Out-Null
                Write-EnhancedLog -Message "Created directory: $DestinationDirectory" -Level "INFO"
            }

            # Extract the zip archive to the destination directory
            [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipFilePath, $DestinationDirectory)
            Write-EnhancedLog -Message "Successfully unzipped the archive to: $DestinationDirectory" -Level "INFO"
        }
        catch {
            Write-EnhancedLog -Message "Error during unzipping: $($_.Exception.Message)" -Level "ERROR"
            throw "Unzipping process failed: $($_.Exception.Message)"
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Unzip-Directory function" -Level "Notice"
    }
}
