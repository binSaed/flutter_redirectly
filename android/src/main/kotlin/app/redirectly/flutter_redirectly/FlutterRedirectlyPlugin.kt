package app.redirectly.flutter_redirectly

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.EventChannel.StreamHandler
import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.util.Log
import kotlinx.coroutines.*
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

/** FlutterRedirectlyPlugin */
class FlutterRedirectlyPlugin: FlutterPlugin, MethodCallHandler, StreamHandler, ActivityAware {
  private lateinit var channel: MethodChannel
  private lateinit var eventChannel: EventChannel
  private var eventSink: EventSink? = null
  private var activity: Activity? = null
  
  private var apiKey: String? = null
  private var baseUrl: String? = null
  private var enableDebugLogging: Boolean = false
  
  companion object {
    private const val TAG = "FlutterRedirectly"
  }

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_redirectly")
    channel.setMethodCallHandler(this)
    
    eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "flutter_redirectly/link_clicks")
    eventChannel.setStreamHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "initialize" -> initialize(call, result)
      "createLink" -> createLink(call, result)
      "createTempLink" -> createTempLink(call, result)
      "getLinks" -> getLinks(result)
      "updateLink" -> updateLink(call, result)
      "deleteLink" -> deleteLink(call, result)
      "getInitialLink" -> getInitialLink(result)
      else -> result.notImplemented()
    }
  }

  private fun initialize(call: MethodCall, result: Result) {
    apiKey = call.argument<String>("apiKey")
    baseUrl = call.argument<String>("baseUrl")
    enableDebugLogging = call.argument<Boolean>("enableDebugLogging") ?: false
    
    if (apiKey == null || baseUrl == null) {
      result.error("INVALID_CONFIG", "API key and base URL are required", null)
      return
    }
    
    if (enableDebugLogging) {
      Log.d(TAG, "FlutterRedirectly initialized with baseUrl: $baseUrl")
    }
    
    result.success(null)
  }

  private fun createLink(call: MethodCall, result: Result) {
    val slug = call.argument<String>("slug")
    val target = call.argument<String>("target")
    val metadata = call.argument<Map<String, Any>>("metadata")
    
    if (slug == null || target == null) {
      result.error("INVALID_PARAMS", "Slug and target are required", null)
      return
    }
    
    CoroutineScope(Dispatchers.IO).launch {
      try {
        val response = makeApiRequest("POST", "/api/v1/links", mapOf(
          "slug" to slug,
          "target" to target,
          "metadata" to metadata
        ).filterValues { it != null })
        
        withContext(Dispatchers.Main) {
          result.success(response)
        }
      } catch (e: Exception) {
        withContext(Dispatchers.Main) {
          result.error("API_ERROR", "Failed to create link: ${e.message}", null)
        }
      }
    }
  }

  private fun createTempLink(call: MethodCall, result: Result) {
    val target = call.argument<String>("target")
    val slug = call.argument<String>("slug")
    val ttlSeconds = call.argument<Int>("ttlSeconds") ?: 900
    
    if (target == null) {
      result.error("INVALID_PARAMS", "Target is required", null)
      return
    }
    
    CoroutineScope(Dispatchers.IO).launch {
      try {
        val response = makeApiRequest("POST", "/api/v1/temp-links", mapOf(
          "target" to target,
          "slug" to slug,
          "ttlSeconds" to ttlSeconds
        ).filterValues { it != null })
        
        withContext(Dispatchers.Main) {
          result.success(response)
        }
      } catch (e: Exception) {
        withContext(Dispatchers.Main) {
          result.error("API_ERROR", "Failed to create temp link: ${e.message}", null)
        }
      }
    }
  }

  private fun getLinks(result: Result) {
    CoroutineScope(Dispatchers.IO).launch {
      try {
        val response = makeApiRequest("GET", "/api/v1/links", null)
        
        withContext(Dispatchers.Main) {
          result.success(response)
        }
      } catch (e: Exception) {
        withContext(Dispatchers.Main) {
          result.error("API_ERROR", "Failed to get links: ${e.message}", null)
        }
      }
    }
  }

  private fun updateLink(call: MethodCall, result: Result) {
    val slug = call.argument<String>("slug")
    val target = call.argument<String>("target")
    
    if (slug == null || target == null) {
      result.error("INVALID_PARAMS", "Slug and target are required", null)
      return
    }
    
    CoroutineScope(Dispatchers.IO).launch {
      try {
        val response = makeApiRequest("PUT", "/api/links/$slug", mapOf(
          "target" to target
        ))
        
        withContext(Dispatchers.Main) {
          result.success(response)
        }
      } catch (e: Exception) {
        withContext(Dispatchers.Main) {
          result.error("API_ERROR", "Failed to update link: ${e.message}", null)
        }
      }
    }
  }

  private fun deleteLink(call: MethodCall, result: Result) {
    val slug = call.argument<String>("slug")
    
    if (slug == null) {
      result.error("INVALID_PARAMS", "Slug is required", null)
      return
    }
    
    CoroutineScope(Dispatchers.IO).launch {
      try {
        makeApiRequest("DELETE", "/api/links/$slug", null)
        
        withContext(Dispatchers.Main) {
          result.success(null)
        }
      } catch (e: Exception) {
        withContext(Dispatchers.Main) {
          result.error("API_ERROR", "Failed to delete link: ${e.message}", null)
        }
      }
    }
  }

  private fun getInitialLink(result: Result) {
    val intent = activity?.intent
    val uri = intent?.data
    
    if (uri != null && isRedirectlyLink(uri)) {
      val linkData = processRedirectlyUri(uri)
      result.success(linkData)
    } else {
      result.success(null)
    }
  }

  private fun makeApiRequest(method: String, endpoint: String, body: Map<String, Any>?): Any? {
    val url = URL("$baseUrl$endpoint")
    val connection = url.openConnection() as HttpURLConnection
    
    try {
      connection.requestMethod = method
      connection.setRequestProperty("Authorization", "Bearer $apiKey")
      connection.setRequestProperty("Content-Type", "application/json")
      connection.connectTimeout = 10000
      connection.readTimeout = 10000
      
      if (body != null && (method == "POST" || method == "PUT")) {
        connection.doOutput = true
        val jsonBody = JSONObject(body).toString()
        connection.outputStream.use { it.write(jsonBody.toByteArray()) }
      }
      
      val responseCode = connection.responseCode
      val inputStream = if (responseCode in 200..299) {
        connection.inputStream
      } else {
        connection.errorStream
      }
      
      val response = inputStream?.bufferedReader()?.use { it.readText() } ?: ""
      
      if (responseCode !in 200..299) {
        throw Exception("HTTP $responseCode: $response")
      }
      
      return if (response.isNotEmpty()) {
        if (response.startsWith("[")) {
          // Parse as JSON array
          org.json.JSONArray(response).let { jsonArray ->
            (0 until jsonArray.length()).map { i ->
              jsonObjectToMap(jsonArray.getJSONObject(i))
            }
          }
        } else {
          // Parse as JSON object
          jsonObjectToMap(JSONObject(response))
        }
      } else {
        null
      }
    } finally {
      connection.disconnect()
    }
  }

  private fun jsonObjectToMap(jsonObject: JSONObject): Map<String, Any?> {
    val map = mutableMapOf<String, Any?>()
    val keys = jsonObject.keys()
    while (keys.hasNext()) {
      val key = keys.next()
      val value = jsonObject.get(key)
      map[key] = when (value) {
        is JSONObject -> jsonObjectToMap(value)
        is org.json.JSONArray -> {
          (0 until value.length()).map { i ->
            val item = value.get(i)
            if (item is JSONObject) jsonObjectToMap(item) else item
          }
        }
        JSONObject.NULL -> null
        else -> value
      }
    }
    return map
  }

  private fun isRedirectlyLink(uri: Uri): Boolean {
    val host = uri.host ?: return false
    return host.contains("redirectly.app") || 
           (host.contains("localhost") && uri.getQueryParameter("user") != null)
  }

  private fun processRedirectlyUri(uri: Uri): Map<String, Any?> {
    val originalUrl = uri.toString()
    val host = uri.host ?: ""
    val pathSegments = uri.pathSegments
    
    val (username, slug) = if (host.contains("redirectly.app")) {
      // Production URL: username.redirectly.app/slug
      val hostParts = host.split(".")
      if (hostParts.size < 3 || pathSegments.isEmpty()) {
        return mapOf(
          "originalUrl" to originalUrl,
          "slug" to "unknown",
          "username" to "unknown",
          "error" to mapOf(
            "message" to "Invalid URL format",
            "type" to 3, // linkResolution
            "statusCode" to null
          ),
          "receivedAt" to System.currentTimeMillis()
        )
      }
      Pair(hostParts[0], pathSegments[0])
    } else if (host.contains("localhost")) {
      // Development URL: localhost:3000?user=username/slug
      val userParam = uri.getQueryParameter("user")
      if (userParam == null) {
        return mapOf(
          "originalUrl" to originalUrl,
          "slug" to "unknown", 
          "username" to "unknown",
          "error" to mapOf(
            "message" to "No user parameter in localhost URL",
            "type" to 3, // linkResolution
            "statusCode" to null
          ),
          "receivedAt" to System.currentTimeMillis()
        )
      }
      val parts = userParam.split("/")
      if (parts.size != 2) {
        return mapOf(
          "originalUrl" to originalUrl,
          "slug" to "unknown",
          "username" to "unknown", 
          "error" to mapOf(
            "message" to "Invalid development URL format",
            "type" to 3, // linkResolution
            "statusCode" to null
          ),
          "receivedAt" to System.currentTimeMillis()
        )
      }
      Pair(parts[0], parts[1])
    } else {
      return mapOf(
        "originalUrl" to originalUrl,
        "slug" to "unknown",
        "username" to "unknown",
        "error" to mapOf(
          "message" to "Unrecognized URL format",
          "type" to 3, // linkResolution
          "statusCode" to null
        ),
        "receivedAt" to System.currentTimeMillis()
      )
    }
    
    if (enableDebugLogging) {
      Log.d(TAG, "Processing Redirectly link: username=$username, slug=$slug")
    }
    
    return mapOf(
      "originalUrl" to originalUrl,
      "slug" to slug,
      "username" to username,
      "linkDetails" to null, // Would need backend endpoint to fetch details
      "error" to null,
      "receivedAt" to System.currentTimeMillis()
    )
  }

  // EventChannel StreamHandler methods
  override fun onListen(arguments: Any?, events: EventSink?) {
    eventSink = events
  }

  override fun onCancel(arguments: Any?) {
    eventSink = null
  }

  // ActivityAware methods
  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivity() {
    activity = null
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    eventChannel.setStreamHandler(null)
  }
} 