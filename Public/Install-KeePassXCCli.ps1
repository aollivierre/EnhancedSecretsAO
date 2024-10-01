function Install-KeePassXCCli {
    <#
    .SYNOPSIS
    Installs KeePassXC CLI based on the operating system and validates the installation before and after.

    .PARAMETER OS
    The operating system where KeePassXC CLI will be installed. Valid values are 'Windows' or 'Linux'.

    .PARAMETER MaxRetries
    The maximum number of retries for the file download if the first attempt fails.

    .EXAMPLE
    Install-KeePassXCCli -OS 'Windows'
    Installs KeePassXC CLI on a Windows system.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The operating system where KeePassXC CLI will be installed.")]
        [ValidateSet('Windows', 'Linux')]
        [string]$OS,

        [Parameter(Mandatory = $false, HelpMessage = "Maximum number of retries for the download if it fails.")]
        [ValidateRange(1, 10)]
        [int]$MaxRetries = 3
    )

    Begin {
        Write-EnhancedLog -Message "Starting Install-KeePassXCCli function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters

        # Validate parameters for the software based on OS
        if ($OS -eq 'Windows') {
            $validateParams = @{
                SoftwareName  = "KeePassXC CLI"
                RegistryPath  = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\KeePassXC_is1"
                ExePath       = "$env:ProgramFiles\KeePassXC\KeePassXC.exe"
                MinVersion    = [version]"2.7.9"
                LatestVersion = [version]"2.7.9"
            }
        } elseif ($OS -eq 'Linux') {
            $validateParams = @{
                SoftwareName  = "KeePassXC CLI"
                ExePath       = "/usr/local/bin/keepassxc-cli"
                MinVersion    = [version]"2.7.9"
                LatestVersion = [version]"2.7.9"
            }
        }
    }

    Process {
        try {
            Write-EnhancedLog -Message "Validating KeePassXC CLI installation before attempting installation..." -Level "INFO"
            $validationResult = Validate-SoftwareInstallation @validateParams

            if ($validationResult.IsInstalled) {
                Write-EnhancedLog -Message "KeePassXC CLI is already installed and meets the minimum version requirement." -Level "INFO"
                return $true
            }

            # KeePassXC CLI is not installed, proceed with downloading and installing
            Write-EnhancedLog -Message "KeePassXC CLI is not installed or does not meet the version requirement. Proceeding with installation." -Level "WARNING"

            if ($OS -eq 'Windows') {
                Write-Host "Downloading KeePassXC CLI installer for Windows..." -ForegroundColor Cyan
                $installerUrl = "https://github.com/keepassxreboot/keepassxc/releases/download/2.7.9/KeePassXC-2.7.9-Win64.msi"
                $installerPath = "$env:TEMP\KeePassXC.msi"

                # Use the Start-FileDownloadWithRetry function to download the installer
                $downloadParams = @{
                    Source      = $installerUrl
                    Destination = $installerPath
                    MaxRetries  = $MaxRetries
                }
                Start-FileDownloadWithRetry @downloadParams

                # Install KeePassXC CLI using msiexec
                Write-Host "Installing KeePassXC CLI..." -ForegroundColor Cyan
                Start-Process msiexec.exe -ArgumentList "/i $installerPath /quiet /norestart" -Wait -NoNewWindow -ErrorAction Stop

                # Remove the installer after installation
                Remove-Item -Path $installerPath

            } elseif ($OS -eq 'Linux') {
                Write-Host "Downloading KeePassXC CLI for Linux..." -ForegroundColor Cyan
                $appImageUrl = "https://github.com/keepassxreboot/keepassxc/releases/download/2.7.9/KeePassXC-2.7.9-x86_64.AppImage"
                $appImagePath = "/usr/local/bin/keepassxc-cli"

                # Use the Start-FileDownloadWithRetry function to download the AppImage
                $downloadParams = @{
                    Source      = $appImageUrl
                    Destination = $appImagePath
                    MaxRetries  = $MaxRetries
                }
                Start-FileDownloadWithRetry @downloadParams

                # Make the AppImage executable
                Write-Host "Setting permissions for KeePassXC CLI AppImage..." -ForegroundColor Cyan
                sudo chmod +x $appImagePath
            }

            # Validate the installation again after the installation
            Write-EnhancedLog -Message "Validating KeePassXC CLI installation after installation..." -Level "INFO"
            $postInstallValidation = Validate-SoftwareInstallation @validateParams

            if ($postInstallValidation.IsInstalled) {
                Write-Host "KeePassXC CLI installed successfully." -ForegroundColor Green
                Write-EnhancedLog -Message "KeePassXC CLI installed successfully. Version: $($postInstallValidation.InstalledVersion)" -Level "INFO"
            } else {
                Write-EnhancedLog -Message "KeePassXC CLI installation failed or does not meet the version requirement after installation." -Level "ERROR"
                throw "KeePassXC CLI installation validation failed."
            }
        }
        catch {
            Write-EnhancedLog -Message "Error during KeePassXC CLI installation: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw
        }
        finally {
            Write-EnhancedLog -Message "Exiting Install-KeePassXCCli function" -Level "Notice"
        }
    }

    End {
        # No additional actions in the End block.
    }
}








# if ($PSVersionTable.PSVersion.Major -ge 6) {
#     # PowerShell 7+ (cross-platform)
#     if ($IsWindows) {
#         $OS = 'Windows'
#     } elseif ($IsLinux) {
#         $OS = 'Linux'
#     } else {
#         throw "Unsupported operating system."
#     }
# } else {
#     # PowerShell 5 (Windows-only)
#     $OS = 'Windows'
# }

# Write-Host "Operating system detected: $OS"



# # Install KeePassXC CLI if it's not already installed
# if (-not (Get-Command keepassxc-cli -ErrorAction SilentlyContinue)) {
#     Install-KeePassXCCli -OS $OS
# }
