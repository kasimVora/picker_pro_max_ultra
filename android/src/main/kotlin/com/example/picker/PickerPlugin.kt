package com.example.picker

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import android.database.Cursor
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream

class PickerPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.ActivityResultListener {

  private lateinit var channel: MethodChannel
  private var activity: Activity? = null
  private var pendingResult: Result? = null

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(binding.binaryMessenger, "untitled2")
    channel.setMethodCallHandler(this)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    binding.addActivityResultListener(this)
  }

  override fun onDetachedFromActivity() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
    binding.addActivityResultListener(this)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    if (call.method == "getDoc") {
      if (activity == null) {
        result.error("NO_ACTIVITY", "Plugin not attached to an activity", null)
        return
      }

      pendingResult = result

      val intent = Intent(Intent.ACTION_GET_CONTENT)
      intent.type = "*/*"
      intent.putExtra(Intent.EXTRA_MIME_TYPES, arrayOf(
        "application/pdf",
        "application/msword",
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        "application/vnd.ms-excel",
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        "text/plain",
        "application/zip"
      ))
      intent.putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
      intent.addCategory(Intent.CATEGORY_OPENABLE)

      activity?.startActivityForResult(Intent.createChooser(intent, "Select Document"), 1001)
    } else {
      result.notImplemented()
    }
  }

  override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
    if (requestCode == 1001 && resultCode == Activity.RESULT_OK) {
      val results = mutableListOf<String>()

      if (data?.clipData != null) {
        val count = data.clipData!!.itemCount
        for (i in 0 until count) {
          val uri = data.clipData!!.getItemAt(i).uri
          val filePath = copyUriToFile(uri)
          Log.d("PickerPlugin", "Copied file from URI $uri -> $filePath")
          if (filePath != null) {
            results.add(filePath)
          }
        }
      } else if (data?.data != null) {
        val uri = data.data!!
        val filePath = copyUriToFile(uri)
        Log.d("PickerPlugin", "Copied file from URI $uri -> $filePath")
        if (filePath != null) {
          results.add(filePath)
        }
      }

      Log.d("PickerPlugin", "Final file paths list: $results")
      pendingResult?.success(results)
      return true
    }
    return false
  }

  private fun copyUriToFile(uri: Uri): String? {
    return try {
      val inputStream: InputStream? = activity?.contentResolver?.openInputStream(uri)
      val fileName = getFileName(uri)
      val file = File(activity?.cacheDir, fileName)
      val outputStream = FileOutputStream(file)

      inputStream?.copyTo(outputStream)
      inputStream?.close()
      outputStream.close()

      Log.d("PickerPlugin", "File saved to: ${file.absolutePath}")
      file.absolutePath
    } catch (e: Exception) {
      Log.e("PickerPlugin", "Error copying URI to file: ${e.localizedMessage}")
      e.printStackTrace()
      null
    }
  }

  private fun getFileName(uri: Uri): String {
    var name = "file"
    val cursor: Cursor? = activity?.contentResolver?.query(uri, null, null, null, null)
    cursor?.use {
      if (it.moveToFirst()) {
        name = it.getString(it.getColumnIndex(OpenableColumns.DISPLAY_NAME))
      }
    }
    return name
  }
}
