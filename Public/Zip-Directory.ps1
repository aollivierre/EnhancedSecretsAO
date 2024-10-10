# function Zip-Directory {
#     <#
#     .SYNOPSIS
#     Zips the contents of a specified directory into a zip archive.

#     .PARAMETER SourceDirectory
#     The full path to the directory that you want to zip.

#     .PARAMETER ZipFilePath
#     The path where the zip archive will be saved.

#     .EXAMPLE
#     $params = @{
#         SourceDirectory = "C:\code\secrets\vault"
#         ZipFilePath     = "C:\code\secrets\vault.zip"
#     }
#     Zip-Directory @params
#     Zips the contents of the directory into an archive.
#     #>

#     [CmdletBinding()]
#     param (
#         [Parameter(Mandatory = $true, HelpMessage = "The full path to the directory that you want to zip.")]
#         [ValidateNotNullOrEmpty()]
#         [string]$SourceDirectory,

#         [Parameter(Mandatory = $true, HelpMessage = "The path where the zip archive will be saved.")]
#         [ValidateNotNullOrEmpty()]
#         [string]$ZipFilePath
#     )

#     Begin {
#         Write-EnhancedLog -Message "Starting Zip-Directory function" -Level "Notice"
#         Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters

#         # Determine the destination directory and create it if necessary
#         $destinationDir = Split-Path -Path $ZipFilePath -Parent
#         if (-not (Test-Path -Path $destinationDir)) {
#             New-Item -Path $destinationDir -ItemType Directory -Force | Out-Null
#             Write-EnhancedLog -Message "Created destination directory: $destinationDir" -Level "INFO"
#         }
#     }

#     Process {
#         try {
#             # Check if the source directory exists
#             if (-not (Test-Path -Path $SourceDirectory)) {
#                 Write-EnhancedLog -Message "Source directory does not exist: $SourceDirectory" -Level "ERROR"
#                 throw "Source directory does not exist: $SourceDirectory"
#             }

#             # Retry logic to handle file locks or transient issues
#             $maxRetries = 3
#             $retryDelaySeconds = 2
#             $attempt = 0
#             $success = $false

#             while ($attempt -lt $maxRetries -and -not $success) {
#                 try {
#                     # Attempt to compress the directory
#                     Compress-Archive -Path "$SourceDirectory\*" -DestinationPath $ZipFilePath -Force
#                     Write-EnhancedLog -Message "Successfully zipped the directory to: $ZipFilePath" -Level "INFO"
#                     $success = $true
#                 }
#                 catch {
#                     $attempt++
#                     Write-EnhancedLog -Message "Attempt $attempt Error during zipping: $($_.Exception.Message)" -Level "WARNING"
#                     if ($attempt -lt $maxRetries) {
#                         Write-EnhancedLog -Message "Retrying in $retryDelaySeconds seconds..." -Level "INFO"
#                         Start-Sleep -Seconds $retryDelaySeconds
#                     }
#                     else {
#                         Write-EnhancedLog -Message "Max retries reached. Zipping process failed." -Level "ERROR"
#                         throw "Zipping process failed after $maxRetries attempts: $($_.Exception.Message)"
#                     }
#                 }
#             }
#         }
#         catch {
#             # Additional error details for troubleshooting
#             Write-EnhancedLog -Message "Error during zipping: $($_.Exception.Message)" -Level "ERROR"
#             Write-EnhancedLog -Message "StackTrace: $($_.Exception.StackTrace)" -Level "ERROR"
#             Handle-Error -ErrorRecord $_
#             throw "Zipping process failed: $($_.Exception.Message)"
#         }
#     }

#     End {
#         Write-EnhancedLog -Message "Exiting Zip-Directory function" -Level "Notice"
#     }
# }





# Enable long path support if configured
function Enable-LongPathSupport {
    param ([string]$Path)
    if ($Path -notlike "\\?*") {
        return "\\?\$Path"
    }
    return $Path
}

# Log each file path and check if it exceeds the 260-character path length
function Log-And-CheckPaths {
    param ([string]$Directory)
    $exceedsLimit = $false

    Get-ChildItem -Path $Directory -Recurse | ForEach-Object {
        $filePath = $_.FullName
        $fileLength = $filePath.Length

        # Log the file path and its length
        Write-EnhancedLog -Message "File path: $filePath, Length: $fileLength" -Level "INFO"

        # Check if the file path exceeds 260 characters
        if ($fileLength -gt 260) {
            Write-EnhancedLog -Message "File path exceeds 260 characters: $filePath, Length: $fileLength" -Level "WARNING"
            $exceedsLimit = $true
        }
    }

    return $exceedsLimit
}





function Zip-Directory {
    <#
    .SYNOPSIS
    Zips the contents of a specified directory into a zip archive.

    .PARAMETER SourceDirectory
    The full path to the directory that you want to zip.

    .PARAMETER ZipFilePath
    The path where the zip archive will be saved.

    .PARAMETER EnableLongPathSupport
    If set to $true, enables support for file paths longer than 260 characters.

    .EXAMPLE
    $params = @{
        SourceDirectory        = "C:\code\secrets\vault"
        ZipFilePath            = "C:\code\secrets\vault.zip"
        EnableLongPathSupport  = $true
    }
    Zip-Directory @params
    Zips the contents of the directory into an archive, with support for long paths.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The full path to the directory that you want to zip.")]
        [ValidateNotNullOrEmpty()]
        [string]$SourceDirectory,

        [Parameter(Mandatory = $true, HelpMessage = "The path where the zip archive will be saved.")]
        [ValidateNotNullOrEmpty()]
        [string]$ZipFilePath,

        [Parameter(Mandatory = $false, HelpMessage = "Enables support for file paths longer than 260 characters.")]
        [bool]$EnableLongPathSupport = $false
    )

    Begin {
        Write-EnhancedLog -Message "Starting Zip-Directory function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters



        # Adjust paths if long path support is enabled
        if ($EnableLongPathSupport) {
            $SourceDirectory = Enable-LongPathSupport -Path $SourceDirectory
            $ZipFilePath = Enable-LongPathSupport -Path $ZipFilePath
        }

        # Check for long paths if long path support is not enabled
        if (-not $EnableLongPathSupport -and (Log-And-CheckPaths -Directory $SourceDirectory)) {
            Write-EnhancedLog -Message "Long paths detected but long path support is not enabled." -Level "ERROR"
            throw "Long paths detected. Enable long path support to proceed."
        }

        # Determine the destination directory and create it if necessary
        $destinationDir = Split-Path -Path $ZipFilePath -Parent
        if (-not (Test-Path -Path $destinationDir)) {
            New-Item -Path $destinationDir -ItemType Directory -Force | Out-Null
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

            # Retry logic to handle file locks or transient issues
            $maxRetries = 3
            $retryDelaySeconds = 2
            $attempt = 0
            $success = $false

            while ($attempt -lt $maxRetries -and -not $success) {
                try {
                    # Attempt to compress the directory
                    Compress-Archive -Path "$SourceDirectory\*" -DestinationPath $ZipFilePath -Force
                    Write-EnhancedLog -Message "Attempt $($attempt + 1): Successfully zipped the directory." -Level "INFO"
                    $success = $true
                }
                catch {
                    $attempt++
                    Write-EnhancedLog -Message "Attempt $attempt Error during zipping: $($_.Exception.Message)" -Level "WARNING"
                    if ($attempt -lt $maxRetries) {
                        Write-EnhancedLog -Message "Retrying in $retryDelaySeconds seconds..." -Level "INFO"
                        Start-Sleep -Seconds $retryDelaySeconds
                    }
                    else {
                        Write-EnhancedLog -Message "Max retries reached. Zipping process failed." -Level "ERROR"
                        throw "Zipping process failed after $maxRetries attempts: $($_.Exception.Message)"
                    }
                }
            }

            # Verify that the ZIP file was actually created
            if (Test-Path -Path $ZipFilePath) {
                Write-EnhancedLog -Message "ZIP file successfully created at: $ZipFilePath" -Level "INFO"
            }
            else {
                Write-EnhancedLog -Message "ZIP file was not found at the expected location: $ZipFilePath" -Level "ERROR"
                throw "ZIP file was not created successfully."
            }
        }
        catch {
            # Additional error details for troubleshooting
            Write-EnhancedLog -Message "Error during zipping: $($_.Exception.Message)" -Level "ERROR"
            Write-EnhancedLog -Message "StackTrace: $($_.Exception.StackTrace)" -Level "ERROR"
            throw "Zipping process failed: $($_.Exception.Message)"
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Zip-Directory function" -Level "Notice"
    }
}
