function Upload-GitHubReleaseAsset {
    <#
    .SYNOPSIS
    Uploads an asset to a GitHub release using the GitHub CLI.

    .PARAMETER repoOwner
    The owner of the GitHub repository.

    .PARAMETER repoName
    The name of the GitHub repository.

    .PARAMETER releaseTag
    The tag of the release where the asset will be uploaded.

    .PARAMETER filePath
    The path of the file to be uploaded as an asset.

    .EXAMPLE
    $params = @{
        repoOwner  = "aollivierre"
        repoName   = "Vault"
        releaseTag = "0.1"
        filePath   = "C:\temp2\vault.GH.Asset.zip"
    }
    Upload-GitHubReleaseAsset @params
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The owner of the GitHub repository.")]
        [ValidateNotNullOrEmpty()]
        [string]$repoOwner,

        [Parameter(Mandatory = $true, HelpMessage = "The name of the GitHub repository.")]
        [ValidateNotNullOrEmpty()]
        [string]$repoName,

        [Parameter(Mandatory = $true, HelpMessage = "The tag of the release where the asset will be uploaded.")]
        [ValidateNotNullOrEmpty()]
        [string]$releaseTag,

        [Parameter(Mandatory = $true, HelpMessage = "The path of the file to be uploaded as an asset.")]
        [ValidateNotNullOrEmpty()]
        [string]$filePath
    )

    Begin {
        Write-EnhancedLog -Message "Starting GitHub Asset Upload Script" -Level "NOTICE"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters


        
        # Define the URL for the GitHub CLI releases page
        $githubCLIReleasesUrl = "https://api.github.com/repos/cli/cli/releases/latest"

        # Define the local path to save the installer
        $installerPath = "$env:TEMP\gh_cli_installer.msi"

        # Example invocation to install GitHub CLI:
        Install-GitHubCLI -releasesUrl $githubCLIReleasesUrl -installerPath $installerPath

    }

    Process {
        try {
            # Check if the file exists
            Write-EnhancedLog -Message "Checking if file exists: $filePath" -Level "INFO"
            if (-not (Test-Path -Path $filePath)) {
                Write-EnhancedLog -Message "File does not exist: $filePath" -Level "ERROR"
                throw "File does not exist: $filePath"
            }
            Write-EnhancedLog -Message "File exists: $filePath" -Level "INFO"

            # Upload the file using GitHub CLI
            Write-EnhancedLog -Message "Uploading asset $filePath to release $releaseTag..." -Level "INFO"
            $command = "gh release upload $releaseTag $filePath --repo $repoOwner/$repoName"
            Invoke-Expression $command

            Write-EnhancedLog -Message "File uploaded successfully: $filePath" -Level "INFO"
        }
        catch {
            Handle-Error -Message "Error during upload: $($_.Exception.Message)" -ErrorRecord $_
            throw
        }
    }

    End {
        Write-EnhancedLog -Message "Script finished." -Level "NOTICE"
    }
}