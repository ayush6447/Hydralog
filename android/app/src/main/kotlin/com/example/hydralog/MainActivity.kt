package com.example.hydralog

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.example.hydralog/usage_stats"

    // Bug fix: known system/launcher packages to always exclude,
    // regardless of whether they have a launch intent.
    // These inflate screen time by 30-90 min compared to Digital Wellbeing.
    private val systemPackageBlacklist = setOf(
        "com.android.systemui",
        "com.android.launcher",
        "com.android.launcher2",
        "com.android.launcher3",
        "com.sec.android.app.launcher",          // Samsung One UI Home
        "com.samsung.android.app.cocktailbarservice",
        "com.samsung.android.app.spage",         // Samsung Free
        "com.samsung.android.app.galaxyfinder",
        "com.samsung.android.bixby.agent",
        "com.samsung.android.bixby.wakeup",
        "com.samsung.android.inputmethod",       // Samsung keyboard
        "com.google.android.inputmethod.latin",  // Gboard
        "com.android.inputmethod.latin",
        "com.swiftkey.swiftkeyapp",
        "com.samsung.android.app.aodservice",    // Always-on display
        "com.samsung.android.lool",              // Device care
        "com.samsung.android.digitalwellbeing",
        "com.google.android.gms",               // Google Play services
        "com.google.android.gsf",
        "android",
        "com.android.phone",
        "com.android.settings",
        packageName,                             // Hydralog itself
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getScreenTimeToday" -> {
                        if (!hasUsageStatsPermission()) {
                            startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                            result.error(
                                "PERMISSION_DENIED",
                                "Usage stats permission not granted",
                                null
                            )
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

        // Today midnight → now
        val calendar = Calendar.getInstance()
        val endTime = calendar.timeInMillis
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)
        val startTime = calendar.timeInMillis

        // Bug fix: use queryAndAggregateUsageStats instead of queryUsageStats.
        // queryUsageStats(INTERVAL_DAILY) can return multiple overlapping entries
        // per package depending on how Samsung partitions intervals, causing
        // double-counting. queryAndAggregateUsageStats returns exactly one
        // merged entry per package — the same source Digital Wellbeing uses.
        val stats = usageManager.queryAndAggregateUsageStats(startTime, endTime)

        var totalMs = 0L
        for ((pkg, usageStats) in stats) {
            val foregroundMs = usageStats.totalTimeInForeground

            // Skip anything under 1 second (transient system callbacks)
            if (foregroundMs < 1000) continue

            // Skip blacklisted system packages
            if (systemPackageBlacklist.contains(pkg)) {
                android.util.Log.d("ScreenTime", "Excluded (blacklist): $pkg")
                continue
            }

            // Skip system apps that have no user-facing launcher icon
            // Bug fix: do NOT use QUERY_ALL_PACKAGES — that triggers Play policy.
            // Instead check ApplicationInfo flags directly.
            try {
                val appInfo = packageManager.getApplicationInfo(pkg, 0)
                val isSystemApp = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
                val isUpdatedSystemApp = (appInfo.flags and ApplicationInfo.FLAG_UPDATED_SYSTEM_APP) != 0
                // Allow updated system apps (e.g. Chrome, YouTube pre-installed but updatable)
                // but exclude pure system apps with no user interaction
                if (isSystemApp && !isUpdatedSystemApp) {
                    android.util.Log.d("ScreenTime", "Excluded (system): $pkg")
                    continue
                }
            } catch (e: Exception) {
                // Package not found — skip it
                continue
            }

            totalMs += foregroundMs
            android.util.Log.d(
                "ScreenTime",
                "Included: $pkg → ${foregroundMs / 1000 / 60}m"
            )
        }

        val totalMinutes = (totalMs / 1000 / 60).toInt()
        android.util.Log.d("ScreenTime", "Total: ${totalMinutes}m")
        return totalMinutes
    }
}
