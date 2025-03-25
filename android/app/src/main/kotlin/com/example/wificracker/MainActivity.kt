package com.example.wificracker

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.os.Build
import android.app.ActivityManager
import android.content.Context

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.wificracker/foreground_service"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startService" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        val serviceIntent = Intent(this, ForegroundService::class.java)
                        startForegroundService(serviceIntent)
                        result.success(null)
                    } else {
                        result.error("UNAVAILABLE", "Foreground service not available", null)
                    }
                }
                "stopService" -> {
                    val serviceIntent = Intent(this, ForegroundService::class.java)
                    stopService(serviceIntent)
                    result.success(null)
                }
                "isServiceRunning" -> {
                    result.success(isServiceRunning(ForegroundService::class.java))
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    private fun isServiceRunning(serviceClass: Class<*>): Boolean {
        val manager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        for (service in manager.getRunningServices(Integer.MAX_VALUE)) {
            if (serviceClass.name == service.service.className) {
                return true
            }
        }
        return false
    }
} 