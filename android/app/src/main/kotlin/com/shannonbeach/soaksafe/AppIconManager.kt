package com.shannonbeach.soaksafe

import android.content.ComponentName
import android.content.Context
import android.content.pm.PackageManager
import android.util.Log
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import java.util.concurrent.TimeUnit

/**
 * Switches the launcher icon (activity-alias) based on how long the app has been idle.
 * Happy: < 7 days · Sad: 7–13 days · Storm: 14+ days since last foreground use.
 */
object AppIconManager {
    const val DAYS_SAD = 7
    const val DAYS_STORM = 14

    private const val PREF = "soaksafe_app_icon"
    private const val KEY_LAST_FOREGROUND_MS = "last_foreground_ms"
    private const val WORK_NAME = "soaksafe_app_icon_refresh"
    private const val TAG = "AppIconManager"

    enum class Variant {
        HAPPY,
        SAD,
        STORM,
    }

    fun onAppForeground(context: Context) {
        val app = context.applicationContext
        saveLastForegroundMs(app, System.currentTimeMillis())
        applyVariant(app, Variant.HAPPY)
    }

    fun refreshIconFromIdleTime(context: Context) {
        applyVariant(context.applicationContext, variantForIdleTime(context))
    }

    fun variantForIdleTime(context: Context): Variant {
        val lastMs = getLastForegroundMs(context)
        if (lastMs <= 0L) return Variant.HAPPY
        val idleDays = TimeUnit.MILLISECONDS.toDays(System.currentTimeMillis() - lastMs)
        return when {
            idleDays >= DAYS_STORM -> Variant.STORM
            idleDays >= DAYS_SAD -> Variant.SAD
            else -> Variant.HAPPY
        }
    }

    fun schedulePeriodicRefresh(context: Context) {
        val request = PeriodicWorkRequestBuilder<AppIconUpdateWorker>(1, TimeUnit.DAYS).build()
        WorkManager.getInstance(context).enqueueUniquePeriodicWork(
            WORK_NAME,
            ExistingPeriodicWorkPolicy.KEEP,
            request,
        )
    }

    private fun applyVariant(context: Context, variant: Variant) {
        val pm = context.packageManager
        setAliasEnabled(context, pm, "LauncherHappy", variant == Variant.HAPPY)
        setAliasEnabled(context, pm, "LauncherSad", variant == Variant.SAD)
        setAliasEnabled(context, pm, "LauncherStorm", variant == Variant.STORM)
    }

    private fun setAliasEnabled(
        context: Context,
        pm: PackageManager,
        aliasSimpleName: String,
        enabled: Boolean,
    ) {
        val packageName = context.packageName
        val component = ComponentName(packageName, "$packageName.$aliasSimpleName")
        val state = if (enabled) {
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED
        } else {
            PackageManager.COMPONENT_ENABLED_STATE_DISABLED
        }
        try {
            pm.setComponentEnabledSetting(component, state, PackageManager.DONT_KILL_APP)
        } catch (e: IllegalArgumentException) {
            Log.w(TAG, "Launcher alias unavailable: $aliasSimpleName", e)
        }
    }

    private fun getLastForegroundMs(context: Context): Long =
        context.applicationContext
            .getSharedPreferences(PREF, Context.MODE_PRIVATE)
            .getLong(KEY_LAST_FOREGROUND_MS, 0L)

    private fun saveLastForegroundMs(context: Context, whenMs: Long) {
        context.applicationContext
            .getSharedPreferences(PREF, Context.MODE_PRIVATE)
            .edit()
            .putLong(KEY_LAST_FOREGROUND_MS, whenMs)
            .commit()
    }
}
