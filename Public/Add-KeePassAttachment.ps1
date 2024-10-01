function Add-KeePassAttachment {
    <#
    .SYNOPSIS
    Adds an attachment to a specific entry in a KeePass database.

    .PARAMETER DatabasePath
    The full path to the KeePass database file.

    .PARAMETER EntryName
    The name of the entry to which the attachment will be added.

    .PARAMETER AttachmentName
    The name of the attachment being added.

    .PARAMETER AttachmentPath
    The full path to the attachment file.

    .PARAMETER KeyFilePath
    The full path to the key file for the KeePass database.

    .EXAMPLE
    Add-KeePassAttachment -DatabasePath "C:\code\secrets\myDatabase.kdbx" -EntryName "example_entry" -AttachmentName "certificate" -AttachmentPath "C:\code\secrets\cert.cer" -KeyFilePath "C:\code\secrets\myKeyFile.keyx"
    Adds the certificate as an attachment to the "example_entry" in the KeePass database.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The full path to the KeePass database file.")]
        [ValidateNotNullOrEmpty()]
        [string]$DatabasePath,

        [Parameter(Mandatory = $true, HelpMessage = "The name of the entry to which the attachment will be added.")]
        [ValidateNotNullOrEmpty()]
        [string]$EntryName,

        [Parameter(Mandatory = $true, HelpMessage = "The name of the attachment being added.")]
        [ValidateNotNullOrEmpty()]
        [string]$AttachmentName,

        [Parameter(Mandatory = $true, HelpMessage = "The full path to the attachment file.")]
        [ValidateNotNullOrEmpty()]
        [string]$AttachmentPath,

        [Parameter(Mandatory = $true, HelpMessage = "The full path to the key file for the KeePass database.")]
        [ValidateNotNullOrEmpty()]
        [string]$KeyFilePath
    )

    Begin {
        Write-EnhancedLog -Message "Starting Add-KeePassAttachment function" -Level "Notice"
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

            if (-not (Test-Path -Path $AttachmentPath)) {
                Write-EnhancedLog -Message "The attachment file does not exist: $AttachmentPath" -Level "ERROR"
                throw "The attachment file does not exist: $AttachmentPath"
            }

            # Construct command for KeePassXC CLI
            $command = "keepassxc-cli attachment-import `"$DatabasePath`" `"$EntryName`" `"$AttachmentName`" `"$AttachmentPath`" --key-file `"$KeyFilePath`" --no-password"

            Write-EnhancedLog -Message "Running command: $command" -Level "INFO"

            # Execute the command
            Invoke-Expression $command

            Write-Host "Attachment '$AttachmentName' added successfully to the entry '$EntryName' in the database." -ForegroundColor Green
            Write-EnhancedLog -Message "Attachment '$AttachmentName' added successfully to '$EntryName'." -Level "INFO"
        }
        catch {
            Write-EnhancedLog -Message "Failed to add attachment: $($_.Exception.Message)" -Level "ERROR"
            throw "Failed to add attachment to the entry: $($_.Exception.Message)"
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Add-KeePassAttachment function" -Level "Notice"
    }
}




# $addAttachmentParams = @{
#     DatabasePath    = "C:\code\secrets\myDatabase.kdbx"
#     EntryName       = "example_entry"
#     AttachmentName  = "certificate"
#     AttachmentPath  = "C:\code\secrets\cert.pfx"
#     KeyFilePath     = "C:\code\secrets\myKeyFile.keyx"
# }

# Add-KeePassAttachment @addAttachmentParams