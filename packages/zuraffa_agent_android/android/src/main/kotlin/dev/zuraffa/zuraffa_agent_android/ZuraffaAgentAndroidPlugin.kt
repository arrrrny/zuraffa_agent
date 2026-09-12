package dev.zuraffa.zuraffa_agent_android

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.security.KeyStore
import java.util.Base64
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * Android implementation of the dev.zuraffa/agent_platform channel
 * (spec 115): filesDir home + Android Keystore (AES/GCM) secure store.
 *
 * Secrets are encrypted with a Keystore-generated AES key and persisted
 * (IV + ciphertext, Base64) in regular preferences; the key material
 * never leaves the Keystore.
 */
class ZuraffaAgentAndroidPlugin : FlutterPlugin, MethodCallHandler {
    private var channel: MethodChannel? = null
    private var applicationContext: Context? = null

    companion object {
        private const val CHANNEL = "dev.zuraffa/agent_platform"
        private const val KEYSTORE = "AndroidKeyStore"
        private const val MASTER_ALIAS = "zuraffa_agent_master"
        private const val PREFS = "zuraffa_agent_secure"
        private const val GCM_TAG_BITS = 128
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel?.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        applicationContext = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        val context = applicationContext
        if (context == null) {
            result.error("unavailable", "engine not attached", null)
            return
        }
        try {
            when (call.method) {
                "getAgentHome" -> {
                    val home = java.io.File(context.filesDir, "zuraffa_agent")
                    home.mkdirs()
                    result.success(home.absolutePath)
                }
                "secureRead" -> {
                    val key = requiredKey(call)
                    result.success(readSecret(context, key))
                }
                "secureWrite" -> {
                    val key = requiredKey(call)
                    val value = call.argument<String>("value")
                        ?: return result.error("badArgs", "missing value", null)
                    writeSecret(context, key, value)
                    result.success(null)
                }
                "secureDelete" -> {
                    val key = requiredKey(call)
                    deleteSecret(context, key)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("secureStoreFailure", e.message, null)
        }
    }

    private fun requiredKey(call: MethodCall): String {
        val key = call.argument<String>("key")
        require(!key.isNullOrBlank() && !key.contains('\u0000')) { "key must be non-empty" }
        return key
    }

    private fun masterKey(): SecretKey {
        val ks = KeyStore.getInstance(KEYSTORE).apply { load(null) }
        (ks.getKey(MASTER_ALIAS, null) as? SecretKey)?.let { return it }
        val generator = KeyGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_AES, KEYSTORE
        )
        generator.init(
            KeyGenParameterSpec.Builder(
                MASTER_ALIAS,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                .build()
        )
        return generator.generateKey()
    }

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun writeSecret(context: Context, key: String, value: String) {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, masterKey())
        val iv = cipher.iv
        val ciphertext = cipher.doFinal(value.toByteArray(Charsets.UTF_8))
        val packed = Base64.getEncoder().encodeToString(iv) + ":" +
            Base64.getEncoder().encodeToString(ciphertext)
        prefs(context).edit().putString(key, packed).apply()
    }

    private fun readSecret(context: Context, key: String): String? {
        val packed = prefs(context).getString(key, null) ?: return null
        val parts = packed.split(":")
        if (parts.size != 2) return null
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(
            Cipher.DECRYPT_MODE,
            masterKey(),
            GCMParameterSpec(GCM_TAG_BITS, Base64.getDecoder().decode(parts[0]))
        )
        return String(cipher.doFinal(Base64.getDecoder().decode(parts[1])), Charsets.UTF_8)
    }

    private fun deleteSecret(context: Context, key: String) {
        prefs(context).edit().remove(key).apply()
    }
}
