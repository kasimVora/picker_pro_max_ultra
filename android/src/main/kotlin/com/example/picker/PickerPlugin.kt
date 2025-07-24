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
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import androidx.exifinterface.media.ExifInterface





class PickerPlugin : FlutterPlugin, MethodCallHandler, ActivityAware,
    PluginRegistry.ActivityResultListener {

    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var pendingResult: Result? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        Log.d("PickerPlugin", "Attached to engine")
        channel = MethodChannel(binding.binaryMessenger, "untitled2")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        Log.d("PickerPlugin", "Detached from engine")
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        Log.d("PickerPlugin", "Attached to activity")
        activity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivity() {
        Log.d("PickerPlugin", "Detached from activity")
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        Log.d("PickerPlugin", "Reattached to activity after config change")
        activity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        Log.d("PickerPlugin", "Detached from activity for config change")
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        Log.d("PickerPlugin", "Method called: ${call.method}")

        when (call.method) {
            "getDoc" -> {
                if (activity == null) {
                    Log.e("PickerPlugin", "No activity attached")
                    result.error("NO_ACTIVITY", "Plugin not attached to an activity", null)
                    return
                }

                val mediaType = call.argument<String>("mediaType") ?: "document"
                val limit = call.argument<Int>("limit") ?: 1
                Log.d("PickerPlugin", "getMedia - mediaType: $mediaType, limit: $limit")

                pendingResult = result

                val intent = Intent(Intent.ACTION_GET_CONTENT)
                intent.putExtra(Intent.EXTRA_ALLOW_MULTIPLE, limit > 1)
                intent.addCategory(Intent.CATEGORY_OPENABLE)

                when (mediaType) {
                    "audio" -> {
                        Log.d("PickerPlugin", "Launching audio picker")
                        intent.type = "audio/*"
                        activity?.startActivityForResult(
                            Intent.createChooser(
                                intent,
                                "Select Audio"
                            ), 1002
                        )
                    }

                    "document" -> {
                        Log.d("PickerPlugin", "Launching document picker")
                        intent.type = "*/*"
                        intent.putExtra(
                            Intent.EXTRA_MIME_TYPES, arrayOf(
                                "application/pdf",
                                "application/msword",
                                "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                                "application/vnd.ms-excel",
                                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                                "text/plain",
                                "application/zip"
                            )
                        )
                        activity?.startActivityForResult(
                            Intent.createChooser(
                                intent,
                                "Select Document"
                            ), 1001
                        )
                    }

                    else -> {
                        Log.e("PickerPlugin", "Invalid media type: $mediaType")
                        result.error(
                            "INVALID_MEDIA_TYPE",
                            "Unsupported media type: $mediaType",
                            null
                        )
                    }
                }
            }

            "compressFile" -> {
                val inputPath = call.argument<String>("inputPath")
                var outputPath = call.argument<String>("outputPath")

                Log.d(
                    "PickerPlugin",
                    "compressFile - inputPath: $inputPath, outputPath: $outputPath"
                )

                if (inputPath == null || outputPath == null) {
                    result.error("INVALID_ARGS", "Missing input or output path", null)
                    return
                }

                val extension = inputPath.substringAfterLast('.').lowercase()
                try {
                    when (extension) {
                        "jpg", "jpeg", "png", "webp" -> {
                            Log.d("PickerPlugin", "Compressing image: $extension")
                            compressImage(inputPath, outputPath)
                        }

                        "temp" -> {
                            Log.d("PickerPlugin", "Compressing image: $extension")

                            outputPath = renameFileExtension(inputPath, "mp4")
                            if (outputPath != null) {
                                compressVideo(outputPath, result)
                            } else {
                                result.error("RENAME_FAILED", "Could not rename file", null)
                            }
                            return
                        }

                        else -> throw Exception("Unsupported file type: $extension")
                    }
                    Log.d("PickerPlugin", "Compression success: $outputPath")
                    result.success(outputPath)
                } catch (e: Exception) {
                    Log.e("PickerPlugin", "Compression failed", e)
                    result.error("COMPRESSION_FAILED", e.localizedMessage, null)
                }
            }

            else -> {
                Log.w("PickerPlugin", "Unknown methodd: ${call.method}")
                result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        Log.d(
            "PickerPlugin",
            "onActivityResult - requestCode: $requestCode, resultCode: $resultCode"
        )
        if ((requestCode == 1001 || requestCode == 1002) && resultCode == Activity.RESULT_OK) {
            val results = mutableListOf<String>()

            if (data?.clipData != null) {
                val count = data.clipData!!.itemCount
                Log.d("PickerPlugin", "Multiple files selected: $count")
                for (i in 0 until count) {
                    val uri = data.clipData!!.getItemAt(i).uri
                    val filePath = copyUriToFile(uri)
                    if (filePath != null) {
                        Log.d("PickerPlugin", "Copied file: $filePath")
                        results.add(filePath)
                    }
                }
            } else if (data?.data != null) {
                val uri = data.data!!
                val filePath = copyUriToFile(uri)
                if (filePath != null) {
                    Log.d("PickerPlugin", "Copied single file: $filePath")
                    results.add(filePath)
                }
            }

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

            Log.d("PickerPlugin", "copyUriToFile success: ${file.absolutePath}")
            file.absolutePath
        } catch (e: Exception) {
            Log.e("PickerPlugin", "Failed to copy file from URI", e)
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
        Log.d("PickerPlugin", "Extracted file name: $name")
        return name
    }

    private fun compressImage(inputPath: String, outputPath: String) {
        Log.d("PickerPlugin", "Starting image compression")
        val exif = ExifInterface(inputPath)
        val orientation = exif.getAttributeInt(
            ExifInterface.TAG_ORIENTATION,
            ExifInterface.ORIENTATION_NORMAL
        )

        val original = BitmapFactory.decodeFile(inputPath)
        val rotated = when (orientation) {
            ExifInterface.ORIENTATION_ROTATE_90 -> rotateBitmap(original, 90f)
            ExifInterface.ORIENTATION_ROTATE_180 -> rotateBitmap(original, 180f)
            ExifInterface.ORIENTATION_ROTATE_270 -> rotateBitmap(original, 270f)
            else -> original
        }

        val resized = Bitmap.createScaledBitmap(
            rotated,
            (rotated.width * 0.5).toInt(),
            (rotated.height * 0.5).toInt(),
            true
        )

        val output = FileOutputStream(File(outputPath))
        resized.compress(Bitmap.CompressFormat.JPEG, 80, output)
        output.flush()
        output.close()
        Log.d("PickerPlugin", "Image compression finished")
    }

    private fun rotateBitmap(source: Bitmap, angle: Float): Bitmap {
        Log.d("PickerPlugin", "Rotating bitmap by $angle degrees")
        val matrix = Matrix()
        matrix.postRotate(angle)
        return Bitmap.createBitmap(source, 0, 0, source.width, source.height, matrix, true)
    }

    private fun renameFileExtension(oldPath: String, newExtension: String): String? {
        return try {
            val oldFile = File(oldPath)
            if (!oldFile.exists()) {
                Log.e("PickerPlugin", "File does not exist: $oldPath")
                return null
            }

            val newPath = oldPath.substringBeforeLast('.') + "." + newExtension
            val newFile = File(newPath)

            if (oldFile.renameTo(newFile)) {
                Log.d("PickerPlugin", "File renamed to: $newPath")
                newPath
            } else {
                Log.e("PickerPlugin", "Failed to rename file")
                null
            }
        } catch (e: Exception) {
            Log.e("PickerPlugin", "Error renaming file", e)
            null
        }
    }



    private fun compressVideo(inputPath: String?, result: MethodChannel.Result) {
        // Check if inputPath is valid
        if (inputPath == null) {
            result.error("INVALID_PATH", "Input path is null", null)
            return
        }

        // Extract the directory from the inputPath and create a new output file name
        val inputFile = File(inputPath)
        val directoryPath = inputFile.parent
        val outputPath = "$directoryPath/compressed_${System.currentTimeMillis()}.mp4"
        result.success(outputPath)
//        val command = "-y -loglevel debug -i $inputPath -c:v mpeg4 $outputPath"

//        FFmpegKit.executeAsync(command) { session: Session ->
//            val returnCode = session.returnCode
//            if (ReturnCode.isSuccess(returnCode)) {
//                val outputFile = File(outputPath)
//                if (outputFile.exists()) {
//                    result.success(outputPath)
//                } else {
//                    result.error("FILE_NOT_CREATED", "Output file was not created.", null)
//                }
//            } else {
//                result.error("COMPRESSION_FAILED", "FFmpeg failed: ${session.failStackTrace}", null)
//            }
//        }
    }


}
