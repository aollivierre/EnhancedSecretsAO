function Install-KeePass {
    <#
    .SYNOPSIS
    Installs KeePass if it is not already installed and validates the installation before and after.

    .PARAMETER KeePassDownloadUrl
    The URL to download the KeePass installer.

    .PARAMETER KeePassInstallPath
    The installation path for KeePass.

    .PARAMETER MaxRetries
    The maximum number of retries for the file download if the first attempt fails.

    .EXAMPLE
    Install-KeePass
    Installs KeePass if it is not already installed.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "The URL to download the KeePass installer.")]
        [ValidateNotNullOrEmpty()]
        [string]$KeePassDownloadUrl = "https://sourceforge.net/projects/keepass/files/KeePass%202.x/2.57/KeePass-2.57-Setup.exe/download",

        [Parameter(Mandatory = $false, HelpMessage = "The installation path for KeePass.")]
        [ValidateNotNullOrEmpty()]
        [string]$KeePassInstallPath = "$env:ProgramFiles\KeePassPasswordSafe2",

        [Parameter(Mandatory = $false, HelpMessage = "Maximum number of retries for the download if it fails.")]
        [ValidateRange(1, 10)]
        [int]$MaxRetries = 3
    )

    Begin {
        Write-EnhancedLog -Message "Starting Install-KeePass function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters

        # Validate if KeePass is already installed
        $validateParams = @{
            SoftwareName  = "KeePass"
            RegistryPath  = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\KeePassPasswordSafe2_is1"
            ExePath       = "$KeePassInstallPath\KeePass.exe"
            MinVersion    = [version]"2.57"
            LatestVersion = [version]"2.57"
        }
    }

    Process {
        try {
            Write-EnhancedLog -Message "Validating KeePass installation before attempting installation..." -Level "INFO"
            $validationResult = Validate-SoftwareInstallation @validateParams

            if ($validationResult.IsInstalled) {
                Write-EnhancedLog -Message "KeePass is already installed and meets the minimum version requirement." -Level "INFO"
                return $true
            }

            # KeePass is not installed, proceed with downloading and installing
            Write-EnhancedLog -Message "KeePass is not installed or does not meet the version requirement. Proceeding with installation." -Level "WARNING"
            Write-Host "Downloading KeePass installer..." -ForegroundColor Cyan
            $installerPath = "$env:TEMP\KeePassSetup.exe"

            # Use the Start-FileDownloadWithRetry function to download the installer
            $downloadParams = @{
                Source      = $KeePassDownloadUrl
                Destination = $installerPath
                MaxRetries  = $MaxRetries
            }
            Start-FileDownloadWithRetry @downloadParams

            Write-Host "Installing KeePass..." -ForegroundColor Cyan
            Start-Process -FilePath $installerPath -ArgumentList "/VERYSILENT", "/NORESTART" -Wait -NoNewWindow -ErrorAction Stop

            # Remove the installer after installation
            Remove-Item -Path $installerPath

            # Validate the installation again after the installation
            Write-EnhancedLog -Message "Validating KeePass installation after installation..." -Level "INFO"
            $postInstallValidation = Validate-SoftwareInstallation @validateParams

            if ($postInstallValidation.IsInstalled) {
                Write-Host "KeePass installed successfully." -ForegroundColor Green
                Write-EnhancedLog -Message "KeePass installed successfully. Version: $($postInstallValidation.InstalledVersion)" -Level "INFO"
            }
            else {
                Write-EnhancedLog -Message "KeePass installation failed or does not meet the version requirement after installation." -Level "ERROR"
                throw "KeePass installation validation failed."
            }
        }
        catch {
            Write-EnhancedLog -Message "Error during KeePass installation: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw
        }
        finally {
            Write-EnhancedLog -Message "Exiting Install-KeePass function" -Level "Notice"
        }
    }

    End {
        # No additional actions in the End block.
    }
}


# Install-KeePass