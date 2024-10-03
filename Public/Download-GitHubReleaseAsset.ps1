function Download-GitHubReleaseAsset {
    <#
    .SYNOPSIS
    Downloads a release asset from a GitHub repository based on the release tag and asset name.

    .PARAMETER Token
    The personal access token (PAT) for GitHub authentication.

    .PARAMETER RepoOwner
    The owner of the GitHub repository.

    .PARAMETER RepoName
    The name of the GitHub repository.

    .PARAMETER ReleaseTag
    The release tag to identify the specific release.

    .PARAMETER FileName
    The name of the asset file to download.

    .PARAMETER DestinationPath
    The path where the downloaded file will be saved.

    .EXAMPLE
    $params = @{
        Token           = "mypat"
        RepoOwner       = "aollivierre"
        RepoName        = "Vault"
        ReleaseTag      = "0.1"
        FileName        = "ICTC_Project_2_Aug_29_2024.zip.aes.zip"
        DestinationPath = "C:\temp\ICTC_Project_2_Aug_29_2024.zip.aes.zip"
    }
    Download-GitHubReleaseAsset @params
    Downloads the specified asset from the GitHub release.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The personal access token (PAT) for GitHub authentication.")]
        [ValidateNotNullOrEmpty()]
        [string]$Token,

        [Parameter(Mandatory = $true, HelpMessage = "The owner of the GitHub repository.")]
        [ValidateNotNullOrEmpty()]
        [string]$RepoOwner,

        [Parameter(Mandatory = $true, HelpMessage = "The name of the GitHub repository.")]
        [ValidateNotNullOrEmpty()]
        [string]$RepoName,

        [Parameter(Mandatory = $true, HelpMessage = "The release tag to identify the specific release.")]
        [ValidateNotNullOrEmpty()]
        [string]$ReleaseTag,

        [Parameter(Mandatory = $true, HelpMessage = "The name of the asset file to download.")]
        [ValidateNotNullOrEmpty()]
        [string]$FileName,

        [Parameter(Mandatory = $true, HelpMessage = "The path where the downloaded file will be saved.")]
        [ValidateNotNullOrEmpty()]
        [string]$DestinationPath
    )

    Begin {
        Write-EnhancedLog -Message "Starting Download-GitHubReleaseAsset function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters

        # Check if the destination directory exists, create if it doesn't
        $destinationDirectory = Split-Path -Path $DestinationPath -Parent
        if (-not (Test-Path -Path $destinationDirectory)) {
            Write-EnhancedLog -Message "Destination directory does not exist. Creating directory: $destinationDirectory" -Level "INFO"
            New-Item -Path $destinationDirectory -ItemType Directory | Out-Null
        } else {
            Write-EnhancedLog -Message "Destination directory already exists: $destinationDirectory" -Level "INFO"
        }
    }

    Process {
        try {
            # Set headers for GitHub authentication
            $headers = @{
                Authorization = "token $Token"
                Accept        = "application/vnd.github+json"
            }

            # GitHub API URL to get release details
            $releaseUrl = "https://api.github.com/repos/$RepoOwner/$RepoName/releases"

            # Fetch the list of releases
            $releases = Invoke-RestMethod -Uri $releaseUrl -Headers $headers

            # Find the release with the specified tag
            $release = $releases | Where-Object { $_.tag_name -eq $ReleaseTag }

            if ($release) {
                # Find the asset by name
                $asset = $release.assets | Where-Object { $_.name -eq $FileName }

                if ($asset) {
                    $downloadUrl = $asset.url  # Get the asset's download URL
                    Write-EnhancedLog -Message "Asset found, starting download..." -Level "INFO"

                    # Set the download headers
                    $downloadHeaders = @{
                        Authorization = "token $Token"
                        Accept        = "application/octet-stream"
                    }

                    # Download the file
                    Invoke-WebRequest -Uri $downloadUrl -Headers $downloadHeaders -OutFile $DestinationPath
                    Write-EnhancedLog -Message "File downloaded successfully: $FileName to Destination $DestinationPath" -Level "INFO"
                } else {
                    Write-EnhancedLog -Message "Asset $FileName not found in the release." -Level "ERROR"
                    throw "Asset $FileName not found in the release."
                }
            } else {
                Write-EnhancedLog -Message "Release with tag $ReleaseTag not found." -Level "ERROR"
                throw "Release with tag $ReleaseTag not found."
            }
        }
        catch {
            Write-EnhancedLog -Message "Error during GitHub asset download: $($_.Exception.Message)" -Level "ERROR"
            throw "GitHub asset download failed: $($_.Exception.Message)"
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Download-GitHubReleaseAsset function" -Level "Notice"
    }
}
