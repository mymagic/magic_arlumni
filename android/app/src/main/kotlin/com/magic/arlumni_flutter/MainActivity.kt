package com.magic.arlumni_flutter

import android.content.Context
import android.graphics.Bitmap
import android.net.Uri
import android.net.Uri.fromFile
import android.os.Bundle
import android.os.StrictMode
import android.view.View
import androidx.core.net.toUri
import com.google.firebase.ml.common.modeldownload.FirebaseLocalModel
import com.google.firebase.ml.common.modeldownload.FirebaseModelManager
import com.google.firebase.ml.vision.FirebaseVision
import com.google.firebase.ml.vision.common.FirebaseVisionImage
import com.google.firebase.ml.vision.label.FirebaseVisionImageLabel
import com.google.firebase.ml.vision.label.FirebaseVisionImageLabeler
import com.google.firebase.ml.vision.label.FirebaseVisionOnDeviceAutoMLImageLabelerOptions
import io.flutter.app.FlutterActivity
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugins.GeneratedPluginRegistrant
import java.io.File
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.util.Log

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.mymagic.arlumni/helper"
    private var startupName = ""
    private var confidence = ""
    private lateinit var detector: FirebaseVisionImageLabeler
    private var fvresult: List<FirebaseVisionImageLabel> = emptyList()
    private lateinit var currentBitmap: Bitmap
    private var filePath: String = ""
    private lateinit var tmp_result: Result


    override fun onCreate(savedInstanceState: Bundle?) {
        turnOnStrictMode()
        super.onCreate(savedInstanceState)
        GeneratedPluginRegistrant.registerWith(this)

        val fireBaseLocalModelSource = FirebaseLocalModel.Builder("alumni")
                .setAssetFilePath("model/manifest.json")
                .build()

        //Registering the model loaded above with the ModelManager Singleton
        FirebaseModelManager.getInstance().registerLocalModel(fireBaseLocalModelSource)
        val optionsBuilder = FirebaseVisionOnDeviceAutoMLImageLabelerOptions.Builder().setConfidenceThreshold(0.4F)
        optionsBuilder.setLocalModelName("alumni")
        detector = FirebaseVision.getInstance().getOnDeviceAutoMLImageLabeler(optionsBuilder.build())

        MethodChannel(flutterView, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method.equals("classifyImage")) {
                tmp_result = result
                filePath = call.argument("path")!!
                currentBitmap = convertPathToBitmap(filePath)
                if (currentBitmap != null) {
                    getStartupFromBitmap(currentBitmap)
                } else {
                    result.error("UNAVAILABLE", "Startup Name not found.", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun turnOnStrictMode() {
        StrictMode.setThreadPolicy(
                StrictMode.ThreadPolicy.Builder().permitNetwork().build())
    }

    fun convertPathToBitmap(filePath: String): Bitmap {
        val image = File(filePath)
        val bmOptions = BitmapFactory.Options()
        var bitmap = BitmapFactory.decodeFile(image.getAbsolutePath(), bmOptions)
        val m = Matrix()
        m.postRotate(360F)

        val cropX = (bitmap.width * 0.2).toInt()
        val cropY = (bitmap.height * 0.25).toInt()

        var curBitmap = Bitmap.createBitmap(bitmap, cropX, cropY, bitmap.width - 2 * cropX, bitmap.height - 2 * cropY, m, true)
        bitmap.recycle()

        return curBitmap
    }

    private fun getStartupFromBitmap(bitmap: Bitmap) {
        val image = FirebaseVisionImage.fromBitmap(bitmap)
        val resultArray: ArrayList<String> = ArrayList()
        Log.e("TAG", "inside getStartupFromtBitmap")
        if (image != null) {
            Log.e("TAG", "inside image not null")
            detector.processImage(image)
                    .addOnSuccessListener { labels ->
                        //  Initialize variables with default values
//                    var text = "No startup detected"
//                    var confidence = 0f
                        if (labels.size != 0) {
                            Log.e("TAG", "inside labels not null")
//                  Get startup label and confidence level rom TFLite Model
                            startupName = labels[0].text
                            confidence = labels[0].confidence.toString()
                            resultArray.add(startupName)
                            resultArray.add(confidence)
                        }
                        tmp_result.success(resultArray)
                    }
                    .addOnFailureListener { e ->
                        // Task failed with an exception
                        print("Unknown error occured")
                    }
        }
    }
}


