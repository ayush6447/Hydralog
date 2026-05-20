package com.example.hydralog

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.example.hydralog/usage_stats"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getScreenTimeToday" -> {
                        if (!hasUsageStatsPermission()) {
                            // Open system settings so user can grant permission
                            startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                            result.error("PERMISSION_DENIED", "Usage stats permission not granted", null)
                        } else {
                            result.success(getScreenTimeMinutesToday())
                        }
                    }
                    "hasUsagePermission" -> {
                        result.success(hasUsageStatsPermission())
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun getScreenTimeMinutesToday(): Int {
        val usageManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager

        val calendar = Calendar.getInstance()
        val endTime = calendar.timeInMillis
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)
        val startTime = calendar.timeInMillis

        val stats = usageManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY, startTime, endTime
        )

        var totalMs = 0L
        for (it in stats) {
            val isUser = isUserApp(this, it.packageName)
            if (it.totalTimeInForeground > 1000 && isUser) {
                totalMs += it.totalTimeInForeground
                android.util.Log.d("HydralogScreenTime", "Included App: ${it.packageName}, Time: ${it.totalTimeInForeground / 1000 / 60}m")
            } else if (it.totalTimeInForeground > 1000) {
                android.util.Log.d("HydralogScreenTime", "Filtered System App: ${it.packageName}, Time: ${it.totalTimeInForeground / 1000 / 60}m")
            }
        }

        android.util.Log.d("HydralogScreenTime", "Total Minutes Calculated: ${totalMs / 1000 / 60}")
        return (totalMs / 1000 / 60).toInt()  // ms → minutes
    }

    private fun isUserApp(context: Context, pkg: String): Boolean {
        if (pkg == context.packageName) return false
        val intent = context.packageManager.getLaunchIntentForPackage(pkg)
        return intent != null
    }
}
