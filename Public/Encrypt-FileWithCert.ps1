function Encrypt-FileWithCert {
    <#
    .SYNOPSIS
    Encrypts a file using a self-signed certificate and AES encryption, and stores the certificate, encrypted file, and AES key.

    .PARAMETER SecretFilePath
    The path to the file that will be encrypted.

    .PARAMETER CertsDir
    The directory where the certificate and related files will be stored.

    .PARAMETER EncryptedFilePath
    The path where the encrypted file will be saved.

    .PARAMETER EncryptedKeyFilePath
    The path where the encrypted AES key and IV will be saved.

    .EXAMPLE
    $params = @{
        SecretFilePath       = "C:\code\secrets\myDatabase.zip"
        CertsDir             = "C:\temp\certs"
        EncryptedFilePath    = "C:\temp\myDatabase.zip.encrypted"
        EncryptedKeyFilePath = "C:\temp\secret.key.encrypted"
    }
    Encrypt-FileWithCert @params
    Encrypts the file and stores the necessary encryption artifacts.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The path to the file that will be encrypted.")]
        [ValidateNotNullOrEmpty()]
        [string]$SecretFilePath,

        [Parameter(Mandatory = $true, HelpMessage = "The directory where the certificate and related files will be stored.")]
        [ValidateNotNullOrEmpty()]
        [string]$CertsDir,

        [Parameter(Mandatory = $true, HelpMessage = "The path where the encrypted file will be saved.")]
        [ValidateNotNullOrEmpty()]
        [string]$EncryptedFilePath,

        [Parameter(Mandatory = $true, HelpMessage = "The path where the encrypted AES key and IV will be saved.")]
        [ValidateNotNullOrEmpty()]
        [string]$EncryptedKeyFilePath
    )

    Begin {
        Write-EnhancedLog -Message "Starting Encrypt-FileWithCert function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters

        # Step 1: Create necessary directories if not exist
        if (-not (Test-Path -Path $CertsDir)) {
            New-Item -Path $CertsDir -ItemType Directory | Out-Null
            Write-EnhancedLog -Message "Created directory: $CertsDir" -Level "INFO"
        }
    }

    Process {
        try {
            # Step 2: Generate a random password for the certificate
            Add-Type -AssemblyName 'System.Web'
            $certPassword = [System.Web.Security.Membership]::GeneratePassword(128, 2)
            $passwordFilePath = Join-Path $CertsDir "certPassword.txt"
            $certPassword | Out-File -FilePath $passwordFilePath -Encoding UTF8
            Write-EnhancedLog -Message "Generated certificate password saved to: $passwordFilePath" -Level "INFO"

            # Step 3: Create a self-signed certificate and export it
            $cert = New-SelfSignedCertificate -CertStoreLocation "Cert:\CurrentUser\My" -Subject "CN=FileEncryptionCert" -KeyLength 2048 -KeyExportPolicy Exportable -Provider "Microsoft Enhanced RSA and AES Cryptographic Provider"
            $certThumbprint = $cert.Thumbprint
            $certFile = Join-Path $CertsDir "cert.pfx"
            Export-PfxCertificate -Cert "Cert:\CurrentUser\My\$($certThumbprint)" -FilePath $certFile -Password (ConvertTo-SecureString $certPassword -AsPlainText -Force)
            Write-EnhancedLog -Message "Certificate generated and exported to: $certFile" -Level "INFO"

            # Step 4: Encrypt the file with AES
            $aes = [System.Security.Cryptography.AesCryptoServiceProvider]::Create()
            $aes.KeySize = 256
            $aes.GenerateKey()
            $aes.GenerateIV()

            # Read the file content and encrypt with AES
            $plainTextBytes = [System.IO.File]::ReadAllBytes($SecretFilePath)
            $encryptor = $aes.CreateEncryptor($aes.Key, $aes.IV)
            $encryptedBytes = $encryptor.TransformFinalBlock($plainTextBytes, 0, $plainTextBytes.Length)
            [System.IO.File]::WriteAllBytes($EncryptedFilePath, $encryptedBytes)
            Write-EnhancedLog -Message "File encrypted and saved to: $EncryptedFilePath" -Level "INFO"

            # Step 5: Encrypt the AES key with RSA using the certificate
            $rsa = [System.Security.Cryptography.RSACryptoServiceProvider]::new()
            $rsa.ImportParameters($cert.PublicKey.Key.ExportParameters($false))
            $encryptedAESKey = $rsa.Encrypt($aes.Key, $true) # Encrypt the AES key with RSA

            # Save the encrypted AES key and IV to file
            $encryptedAESPackage = $aes.IV + $encryptedAESKey
            [System.IO.File]::WriteAllBytes($EncryptedKeyFilePath, $encryptedAESPackage)
            Write-EnhancedLog -Message "AES key encrypted and saved to: $EncryptedKeyFilePath" -Level "INFO"

            # Step 6: Convert certificate and encrypted AES key to Base64 for further use
            $certBytes = [System.IO.File]::ReadAllBytes($certFile)
            $base64Cert = [Convert]::ToBase64String($certBytes)
            $base64CertFile = Join-Path $CertsDir "cert.pfx.base64"
            [System.IO.File]::WriteAllText($base64CertFile, $base64Cert)
            Write-EnhancedLog -Message "Certificate Base64 encoded and saved to: $base64CertFile" -Level "INFO"

            $keyBytes = [System.IO.File]::ReadAllBytes($EncryptedKeyFilePath)
            $base64Key = [Convert]::ToBase64String($keyBytes)
            $base64KeyFile = Join-Path $CertsDir "secret.key.encrypted.base64"
            [System.IO.File]::WriteAllText($base64KeyFile, $base64Key)
            Write-EnhancedLog -Message "AES key and IV Base64 encoded and saved to: $base64KeyFile" -Level "INFO"

        }
        catch {
            Write-EnhancedLog -Message "Encryption process failed: $($_.Exception.Message)" -Level "ERROR"
            throw "Encryption process failed: $($_.Exception.Message)"
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Encrypt-FileWithCert function" -Level "Notice"
    }
}





# # Define the parameters for the Encrypt-FileWithCert function using splatting
# $params = @{
#     SecretFilePath       = "C:\code\secrets\myDatabase.zip"   # File to be encrypted
#     CertsDir             = "C:\temp\certs"                    # Directory to store certs and related files
#     EncryptedFilePath    = "C:\temp\myDatabase.zip.encrypted" # Output path for encrypted file
#     EncryptedKeyFilePath = "C:\temp\secret.key.encrypted"     # Output path for encrypted AES key and IV
# }

# # Call the function with splatted parameters
# Encrypt-FileWithCert @params
