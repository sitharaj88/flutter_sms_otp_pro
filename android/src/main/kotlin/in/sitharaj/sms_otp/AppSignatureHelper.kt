package `in`.sitharaj.sms_otp

import android.content.Context
import android.content.ContextWrapper
import android.content.pm.PackageManager
import android.util.Base64
import java.nio.charset.StandardCharsets
import java.security.MessageDigest
import java.security.NoSuchAlgorithmException
import java.util.Arrays

/**
 * Helper class to generate the app signature hash for SMS Retriever API.
 * 
 * The hash is an 11-character string that uniquely identifies your app.
 * This hash must be included at the end of your OTP SMS message for the
 * SMS Retriever API to automatically receive the message.
 * 
 * Example SMS format:
 * ```
 * <#> Your verification code is 123456
 * AbCdEfGhIjK
 * ```
 */
class AppSignatureHelper(context: Context) : ContextWrapper(context) {

    companion object {
        private const val HASH_TYPE = "SHA-256"
        private const val NUM_HASHED_BYTES = 9
        private const val NUM_BASE64_CHAR = 11
    }

    /**
     * Get all the app signatures for the current package.
     * 
     * @return List of app signature hashes
     */
    fun getAppSignatures(): List<String> {
        val appSignatures = mutableListOf<String>()

        try {
            val packageName = packageName
            val packageManager = packageManager
            val signatures = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
                val packageInfo = packageManager.getPackageInfo(
                    packageName,
                    PackageManager.GET_SIGNING_CERTIFICATES
                )
                val signingInfo = packageInfo.signingInfo
                
                if (signingInfo == null) {
                    return emptyList()
                }

                if (signingInfo.hasMultipleSigners()) {
                    signingInfo.apkContentsSigners
                } else {
                    signingInfo.signingCertificateHistory
                }
            } else {
                @Suppress("DEPRECATION")
                val packageInfo = packageManager.getPackageInfo(
                    packageName,
                    PackageManager.GET_SIGNATURES
                )
                packageInfo.signatures
            }

            for (signature in signatures ?: emptyArray()) {
                val hash = hash(packageName, signature.toCharsString())
                if (hash != null) {
                    appSignatures.add(hash)
                }
            }
        } catch (e: PackageManager.NameNotFoundException) {
            // Package not found - shouldn't happen for current app
        }

        return appSignatures
    }

    /**
     * Generate the 11-character hash from package name and signature.
     */
    private fun hash(packageName: String, signature: String): String? {
        val appInfo = "$packageName $signature"
        try {
            val messageDigest = MessageDigest.getInstance(HASH_TYPE)
            messageDigest.update(appInfo.toByteArray(StandardCharsets.UTF_8))
            
            var hashSignature = messageDigest.digest()
            
            // Truncate to first 9 bytes
            hashSignature = Arrays.copyOfRange(hashSignature, 0, NUM_HASHED_BYTES)
            
            // Base64 encode and take first 11 characters
            var base64Hash = Base64.encodeToString(hashSignature, Base64.NO_PADDING or Base64.NO_WRAP)
            base64Hash = base64Hash.substring(0, NUM_BASE64_CHAR)
            
            return base64Hash
        } catch (e: NoSuchAlgorithmException) {
            // SHA-256 should always be available
        }
        return null
    }
}
