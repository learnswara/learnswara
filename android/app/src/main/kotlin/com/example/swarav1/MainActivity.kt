package com.example.swarav1

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.soundtouch/native"
    private var methodChannel: MethodChannel? = null

    init {
        System.loadLibrary("soundtouch_wrapper")  // Load the wrapper library
    }

    // Declare all native methods
    external fun createSoundTouch(): Long
    external fun processSample(handle: Long, samples: FloatArray, numSamples: Int)
    external fun setPitchSemiTones(handle: Long, pitch: Double)
    external fun setTempoChange(handle: Long, tempo: Double)
    external fun setRateChange(handle: Long, rate: Double)
    external fun receiveSamples(handle: Long, output: FloatArray, maxSamples: Int): Int
    external fun disposeSoundTouch(handle: Long)
    external fun processSound(inputFilePath: String, outputFilePath: String): String

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            if (call.method == "processSound") {
                val inputPath = call.argument<String>("inputPath")
                val outputPath = call.argument<String>("outputPath")

                if (inputPath != null && outputPath != null) {
                    try {
                        // Call the native method to process sound
                        val response = processSound(inputPath, outputPath)
                        result.success(response)
                    } catch (e: Exception) {
                        result.error("PROCESSING_ERROR", e.message, null)
                    }
                } else {
                    result.error("INVALID_ARGUMENTS", "Input or Output path is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        methodChannel?.setMethodCallHandler(null)
        super.onDestroy()
    }
}
