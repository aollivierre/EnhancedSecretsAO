function Decrypt-FileWithCert {
    <#
    .SYNOPSIS
    Decrypts a file using a certificate and AES encryption by restoring the certificate, decrypting the AES key, and decrypting the original file.

    .PARAMETER CertBase64Path
    The file path to the Base64-encoded certificate.

    .PARAMETER CertPasswordPath
    The file path to the certificate password.

    .PARAMETER KeyBase64Path
    The file path to the Base64-encoded AES key.

    .PARAMETER EncryptedFilePath
    The path to the encrypted file to be decrypted.

    .PARAMETER DecryptedFilePath
    The path where the decrypted file will be saved.

    .PARAMETER CertsDir
    The directory where the certificate files will be stored temporarily.

    .EXAMPLE
    $params = @{
        CertBase64Path    = "C:\temp\certs\cert.pfx.base64"
        CertPasswordPath  = "C:\temp\certpassword.txt"
        KeyBase64Path     = "C:\temp\certs\secret.key.encrypted.base64"
        EncryptedFilePath = "C:\temp\myDatabase.zip.encrypted"
        DecryptedFilePath = "C:\temp\myDatabase.zip"
        CertsDir          = "C:\temp\certs"
    }
    Decrypt-FileWithCert @params
    Decrypts the file using the given certificate and paths.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The file path to the Base64-encoded certificate.")]
        [ValidateNotNullOrEmpty()]
        [string]$CertBase64Path,

        [Parameter(Mandatory = $true, HelpMessage = "The file path to the certificate password.")]
        [ValidateNotNullOrEmpty()]
        [string]$CertPasswordPath,

        [Parameter(Mandatory = $true, HelpMessage = "The file path to the Base64-encoded AES key.")]
        [ValidateNotNullOrEmpty()]
        [string]$KeyBase64Path,

        [Parameter(Mandatory = $true, HelpMessage = "The path to the encrypted file.")]
        [ValidateNotNullOrEmpty()]
        [string]$EncryptedFilePath,

        [Parameter(Mandatory = $true, HelpMessage = "The path where the decrypted file will be saved.")]
        [ValidateNotNullOrEmpty()]
        [string]$DecryptedFilePath,

        [Parameter(Mandatory = $true, HelpMessage = "The directory where the certificate files will be temporarily stored.")]
        [ValidateNotNullOrEmpty()]
        [string]$CertsDir
    )

    Begin {
        Write-EnhancedLog -Message "Starting Decrypt-FileWithCert function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters

        # Step 1: Create necessary directories if not exist
        if (-not (Test-Path -Path $CertsDir)) {
            New-Item -Path $CertsDir -ItemType Directory | Out-Null
            Write-EnhancedLog -Message "Created directory: $CertsDir" -Level "INFO"
        }
    }

    Process {
        try {
            # Step 2: Decode Base64-encoded certificate and save as .pfx
            $base64Cert = Get-Content -Path $CertBase64Path
            $certBytes = [Convert]::FromBase64String($base64Cert)
            $certPath = Join-Path $CertsDir "cert.pfx"
            [System.IO.File]::WriteAllBytes($certPath, $certBytes)
            Write-EnhancedLog -Message "Certificate restored at: $certPath" -Level "INFO"

            # Step 3: Get the certificate password from the file
            $certPassword = Get-Content -Path $CertPasswordPath

            # Step 4: Import the certificate with the private key
            $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
            $cert.Import($certPath, $certPassword, [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::UserKeySet)
            
            if ($cert.HasPrivateKey) {
                Write-EnhancedLog -Message "The certificate's private key is accessible." -Level "INFO"
            } else {
                Write-EnhancedLog -Message "The certificate's private key is not accessible." -Level "ERROR"
                throw "The certificate's private key is not accessible."
            }

            # Step 5: Decode Base64-encoded AES key and IV
            $base64Key = Get-Content -Path $KeyBase64Path
            $keyBytes = [Convert]::FromBase64String($base64Key)
            $aesKeyFilePath = Join-Path $CertsDir "secret.key.encrypted"
            [System.IO.File]::WriteAllBytes($aesKeyFilePath, $keyBytes)
            Write-EnhancedLog -Message "AES key and IV restored at: $aesKeyFilePath" -Level "INFO"

            # Step 6: Read encrypted AES key and IV
            $encryptedAESPackage = [System.IO.File]::ReadAllBytes($aesKeyFilePath)

            # Step 7: Extract IV (first 16 bytes) and encrypted AES key (remaining bytes)
            $iv = $encryptedAESPackage[0..15]
            $encryptedAESKey = $encryptedAESPackage[16..($encryptedAESPackage.Length - 1)]

            # Step 8: Decrypt the AES key using the certificate's private key with RSA-OAEP padding
            $rsaProvider = $cert.PrivateKey -as [System.Security.Cryptography.RSACryptoServiceProvider]
            if (-not $rsaProvider) {
                Write-EnhancedLog -Message "Unable to retrieve RSA private key from certificate." -Level "ERROR"
                throw "Unable to retrieve RSA private key from certificate."
            }

            $aesKey = $rsaProvider.Decrypt($encryptedAESKey, $true)  # Use $true for OAEP padding
            Write-EnhancedLog -Message "AES Key successfully decrypted." -Level "INFO"

            # Step 9: Decrypt the original file using AES
            $encryptedContent = [System.IO.File]::ReadAllBytes($EncryptedFilePath)

            $aes = [System.Security.Cryptography.AesCryptoServiceProvider]::Create()
            $aes.Key = $aesKey
            $aes.IV = $iv
            $decryptor = $aes.CreateDecryptor($aes.Key, $aes.IV)
            $decryptedBytes = $decryptor.TransformFinalBlock($encryptedContent, 0, $encryptedContent.Length)

            # Write the decrypted content to a new file
            [System.IO.File]::WriteAllBytes($DecryptedFilePath, $decryptedBytes)
            Write-EnhancedLog -Message "Decrypted file saved to: $DecryptedFilePath" -Level "INFO"
        }
        catch {
            Write-EnhancedLog -Message "Decryption failed: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw "Decryption process failed: $($_.Exception.Message)"
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Decrypt-FileWithCert function" -Level "Notice"
    }
}



#Example Usage


#    # Define the parameters for the Decrypt-FileWithCert function using splatting
#    $params = @{

#     # Path to the Base64-encoded certificate file.
#     # This file should contain the Base64-encoded contents of the .pfx certificate that you want to use for decryption.
#     CertBase64Path    = "C:\temp\certs\cert.pfx.base64"

#     # Path to the text file that contains the password for the .pfx certificate.
#     # This is the password that will be used to unlock the certificate and access the private key.
#     CertPasswordPath  = "C:\temp\certpassword.txt"

#     # Path to the Base64-encoded AES key file.
#     # This file contains the encrypted AES key that will be used to decrypt the target file.
#     KeyBase64Path     = "C:\temp\certs\secret.key.encrypted.base64"

#     # Path to the file that is encrypted and needs to be decrypted.
#     # This is the target file that was encrypted using the AES key, and it will be decrypted using the AES key and IV.
#     EncryptedFilePath = "C:\temp\myDatabase.zip.encrypted"

#     # Path where the decrypted file will be saved after decryption.
#     # This is the output path where the function will store the decrypted version of the file.
#     DecryptedFilePath = "C:\temp\myDatabase.zip"

#     # Directory where temporary files such as the certificate and the AES key will be stored during the process.
#     # This is a working directory where the function can safely write temporary files during the decryption.
#     CertsDir          = "C:\temp\certs"
# }

# # Call the Decrypt-FileWithCert function and pass the parameters via splatting.
# # This function will use the provided certificate, key, and encrypted file to perform the decryption and save the decrypted file.
# Decrypt-FileWithCert @params