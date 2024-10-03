function Export-KeePassAttachment {
    <#
    .SYNOPSIS
    Exports an attachment from an entry in a KeePass database.

    .PARAMETER DatabasePath
    The full path to the KeePass database file.

    .PARAMETER EntryName
    The name of the entry containing the attachment.

    .PARAMETER AttachmentName
    The name of the attachment to be exported.

    .PARAMETER ExportPath
    The path where the attachment will be exported.

    .PARAMETER KeyFilePath
    The full path to the key file for the KeePass database.

    .EXAMPLE
    Export-KeePassAttachment -DatabasePath "C:\code\secrets\myDatabase.kdbx" -EntryName "example_entry" -AttachmentName "certificate" -ExportPath "C:\code\secrets\cert-fromdb.crt" -KeyFilePath "C:\code\secrets\myKeyFile.keyx"
    Exports the "certificate" attachment from the "example_entry" to the specified export path.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The full path to the KeePass database file.")]
        [ValidateNotNullOrEmpty()]
        [string]$DatabasePath,

        [Parameter(Mandatory = $true, HelpMessage = "The name of the entry containing the attachment.")]
        [ValidateNotNullOrEmpty()]
        [string]$EntryName,

        [Parameter(Mandatory = $true, HelpMessage = "The name of the attachment to be exported.")]
        [ValidateNotNullOrEmpty()]
        [string]$AttachmentName,

        [Parameter(Mandatory = $true, HelpMessage = "The path where the attachment will be exported.")]
        [ValidateNotNullOrEmpty()]
        [string]$ExportPath,

        [Parameter(Mandatory = $true, HelpMessage = "The full path to the key file for the KeePass database.")]
        [ValidateNotNullOrEmpty()]
        [string]$KeyFilePath
    )

    Begin {
        Write-EnhancedLog -Message "Starting Export-KeePassAttachment function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters


        Write-EnhancedLog -Message "Ensuring that KeePass is installed" -Level "Notice"
        Install-KeePass

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

            # # Full path to the KeePass CLI executable
            # $keepassCliPath = "C:\Program Files\KeePassXC\keepassxc-cli.exe"

            # # Build the command with the full path
            # $command = "`"$keepassCliPath`" attachment-export `"$DatabasePath`" `"$EntryName`" `"$AttachmentName`" `"$ExportPath`" --key-file `"$KeyFilePath`" --no-password"


            # List of common paths where KeePassXC CLI might be installed
            $commonPaths = @(
                "C:\Program Files\KeePassXC\keepassxc-cli.exe",
                "C:\Program Files (x86)\KeePassXC\keepassxc-cli.exe"
            )

            # Find the KeePass CLI path
            $keepassCliPath = $commonPaths | Where-Object { Test-Path $_ }

            if (-not $keepassCliPath) {
                throw "KeePassXC CLI not found in common paths."
            }

            # Build the command with the dynamically located KeePassXC CLI path
            # $command = "`"$keepassCliPath`" attachment-export `"$DatabasePath`" `"$EntryName`" `"$AttachmentName`" `"$ExportPath`" --key-file `"$KeyFilePath`" --no-password"


            # Write-EnhancedLog -Message "Running command: $command" -Level "INFO"


         

            # Execute the command
            # Invoke-Expression $command




            # Build the arguments list for the KeePassXC CLI command
            # We're using Start-Process instead of Invoke-Expression, so we create a clean argument array
            $arguments = @(
                "attachment-export"               # Command to export an attachment from the KeePass database
                "`"$DatabasePath`""               # Path to the KeePass database file, wrapped in escaped quotes to handle spaces
                "`"$EntryName`""                  # Entry name within the KeePass database, escaped in quotes
                "`"$AttachmentName`""             # Name of the attachment to export from the specified entry
                "`"$ExportPath`""                 # Path where the exported attachment will be saved, escaped in quotes to handle spaces
                "--key-file"                      # Option to specify the key file for database access
                "`"$KeyFilePath`""                # Path to the key file used to unlock the KeePass database, escaped in quotes
                "--no-password"                   # Instruct the CLI to skip prompting for a password since only a key file is used
            )


            # Log the command (for debugging purposes)
            Write-EnhancedLog -Message "Running command: $keepassCliPath $($arguments -join ' ')" -Level "INFO"


            # Wait-Debugger

            # Use Start-Process to execute the command
            $process = Start-Process -FilePath $keepassCliPath -ArgumentList $arguments -Wait -NoNewWindow -PassThru

            # Check the exit code
            if ($process.ExitCode -ne 0) {
                throw "KeePassXC CLI failed with exit code $($process.ExitCode)"
            }



            # Check if the file was actually exported
            if (Test-Path -Path $ExportPath) {
                Write-EnhancedLog -Message "Attachment '$AttachmentName' exported successfully to '$ExportPath'." -Level "INFO"
            }
            else {
                Write-EnhancedLog -Message "Attachment export failed: '$ExportPath' does not exist." -Level "ERROR"
                throw "Attachment export failed: '$AttachmentName' not found at '$ExportPath'."
            }



            # Write-EnhancedLog -Message "Attachment '$AttachmentName' exported successfully to '$ExportPath'." -Level "INFO"
        }
        catch {
            Write-EnhancedLog -Message "Failed to export attachment: $($_.Exception.Message)" -Level "ERROR"
            throw "Failed to export attachment from the entry: $($_.Exception.Message)"
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Export-KeePassAttachment function" -Level "Notice"
    }
}

# $exportAttachmentParams = @{
#     DatabasePath    = "C:\code\secrets\myDatabase.kdbx"
#     EntryName       = "example_entry"
#     AttachmentName  = "certificate"
#     ExportPath      = "C:\code\secrets\cert-fromdb.pfx"
#     KeyFilePath     = "C:\code\secrets\myKeyFile.keyx"
# }

# Export-KeePassAttachment @exportAttachmentParams