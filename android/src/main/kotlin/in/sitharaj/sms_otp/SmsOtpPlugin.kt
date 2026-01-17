package `in`.sitharaj.sms_otp

import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import com.google.android.gms.auth.api.phone.SmsRetriever
import com.google.android.gms.auth.api.phone.SmsRetrieverClient
import com.google.android.gms.common.api.CommonStatusCodes
import com.google.android.gms.common.api.Status
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.util.regex.Pattern

/**
 * SMS OTP Plugin for Flutter
 * 
 * Provides SMS auto-read functionality using the SMS Retriever API,
 * which doesn't require SMS read permissions.
 */
class SmsOtpPlugin : FlutterPlugin, MethodCallHandler, ActivityAware,
    PluginRegistry.ActivityResultListener, EventChannel.StreamHandler {

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null

    private var context: Context? = null
    private var activity: Activity? = null
    private var smsRetrieverClient: SmsRetrieverClient? = null
    private var smsReceiver: SmsBroadcastReceiver? = null
    
    private var expectedOtpLength: Int = 6
    private var senderFilter: String? = null

    companion object {
        private const val METHOD_CHANNEL = "sms_otp"
        private const val EVENT_CHANNEL = "sms_otp/events"
        private const val SMS_CONSENT_REQUEST = 2
    }

    // ============================================================
    // FlutterPlugin Implementation
    // ============================================================

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        
        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, METHOD_CHANNEL)
        methodChannel.setMethodCallHandler(this)
        
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, EVENT_CHANNEL)
        eventChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        context = null
    }

    // ============================================================
    // MethodCallHandler Implementation
    // ============================================================

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${Build.VERSION.RELEASE}")
            }
            "startListening" -> {
                expectedOtpLength = call.argument<Int>("otpLength") ?: 6
                senderFilter = call.argument<String>("sender")
                startSmsRetriever(result)
            }
            "stopListening" -> {
                stopSmsRetriever()
                result.success(null)
            }
            "getAppSignature" -> {
                val signature = getAppSignature()
                result.success(signature)
            }
            "requestPermissions" -> {
                // SMS Retriever API doesn't need permissions
                result.success("granted")
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    // ============================================================
    // SMS Retriever API
    // ============================================================

    private fun startSmsRetriever(result: Result) {
        val ctx = context ?: run {
            result.error("NO_CONTEXT", "Context not available", null)
            return
        }

        smsRetrieverClient = SmsRetriever.getClient(ctx)
        
        val task = smsRetrieverClient?.startSmsRetriever()
        task?.addOnSuccessListener {
            // SMS Retriever started successfully
            registerSmsReceiver()
            result.success(true)
        }?.addOnFailureListener { e ->
            result.error("SMS_RETRIEVER_ERROR", e.message, null)
        }
    }

    private fun stopSmsRetriever() {
        unregisterSmsReceiver()
    }

    private fun registerSmsReceiver() {
        val ctx = context ?: return
        
        smsReceiver = SmsBroadcastReceiver { message, error ->
            if (error != null) {
                sendEvent(mapOf(
                    "type" to "error",
                    "message" to error,
                    "code" to "SMS_ERROR"
                ))
            } else if (message != null) {
                val otp = extractOtp(message)
                if (otp != null) {
                    sendEvent(mapOf(
                        "type" to "otp_received",
                        "otp" to otp,
                        "message" to message
                    ))
                }
            }
        }

        val intentFilter = IntentFilter(SmsRetriever.SMS_RETRIEVED_ACTION)
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ctx.registerReceiver(smsReceiver, intentFilter, Context.RECEIVER_EXPORTED)
        } else {
            ctx.registerReceiver(smsReceiver, intentFilter)
        }
    }

    private fun unregisterSmsReceiver() {
        try {
            if (smsReceiver != null) {
                context?.unregisterReceiver(smsReceiver)
                smsReceiver = null
            }
        } catch (e: Exception) {
            // Ignore if receiver not registered
        }
    }

    // ============================================================
    // OTP Extraction
    // ============================================================

    private fun extractOtp(message: String): String? {
        // Try various patterns to extract OTP
        val patterns = listOf(
            // Code/OTP followed by digits
            Pattern.compile("(?:code|otp|password|pin|verification)\\s*(?:is|:)?\\s*(\\d{$expectedOtpLength})", Pattern.CASE_INSENSITIVE),
            // Digits followed by "is your"
            Pattern.compile("(\\d{$expectedOtpLength})\\s*(?:is\\s+your|is\\s+the)", Pattern.CASE_INSENSITIVE),
            // General pattern for isolated digits of expected length
            Pattern.compile("\\b(\\d{$expectedOtpLength})\\b")
        )

        for (pattern in patterns) {
            val matcher = pattern.matcher(message)
            if (matcher.find()) {
                return matcher.group(1)
            }
        }

        return null
    }

    // ============================================================
    // App Signature for SMS Retriever
    // ============================================================

    private fun getAppSignature(): String? {
        val ctx = context ?: return null
        return try {
            val helper = AppSignatureHelper(ctx)
            val signatures = helper.getAppSignatures()
            signatures.firstOrNull()
        } catch (e: Exception) {
            null
        }
    }

    // ============================================================
    // EventChannel.StreamHandler Implementation
    // ============================================================

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    private fun sendEvent(data: Map<String, Any?>) {
        activity?.runOnUiThread {
            eventSink?.success(data)
        } ?: run {
            eventSink?.success(data)
        }
    }

    // ============================================================
    // ActivityAware Implementation
    // ============================================================

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivity() {
        unregisterSmsReceiver()
        activity = null
    }

    // ============================================================
    // ActivityResultListener Implementation
    // ============================================================

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == SMS_CONSENT_REQUEST) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                val message = data.getStringExtra(SmsRetriever.EXTRA_SMS_MESSAGE)
                if (message != null) {
                    val otp = extractOtp(message)
                    if (otp != null) {
                        sendEvent(mapOf(
                            "type" to "otp_received",
                            "otp" to otp,
                            "message" to message
                        ))
                    }
                }
            } else {
                sendEvent(mapOf(
                    "type" to "cancelled",
                    "reason" to "User denied SMS consent"
                ))
            }
            return true
        }
        return false
    }
}

/**
 * Broadcast receiver for SMS Retriever API events.
 */
class SmsBroadcastReceiver(
    private val onMessageReceived: (String?, String?) -> Unit
) : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == SmsRetriever.SMS_RETRIEVED_ACTION) {
            val extras = intent.extras
            val status = extras?.get(SmsRetriever.EXTRA_STATUS) as? Status

            when (status?.statusCode) {
                CommonStatusCodes.SUCCESS -> {
                    val message = extras.getString(SmsRetriever.EXTRA_SMS_MESSAGE)
                    onMessageReceived(message, null)
                }
                CommonStatusCodes.TIMEOUT -> {
                    onMessageReceived(null, "SMS retrieval timed out")
                }
                else -> {
                    onMessageReceived(null, "SMS retrieval failed: ${status?.statusCode}")
                }
            }
        }
    }
}
