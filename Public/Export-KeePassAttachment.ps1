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
            $command = "keepassxc-cli attachment-export `"$DatabasePath`" `"$EntryName`" `"$AttachmentName`" `"$ExportPath`" --key-file `"$KeyFilePath`" --no-password"

            Write-EnhancedLog -Message "Running command: $command" -Level "INFO"

            # Execute the command
            Invoke-Expression $command

            Write-EnhancedLog -Message "Attachment '$AttachmentName' exported successfully to '$ExportPath'." -Level "INFO"
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