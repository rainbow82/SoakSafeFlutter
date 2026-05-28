package com.shannonbeach.soaksafe

import android.content.Context
import androidx.work.Worker
import androidx.work.WorkerParameters

/** Periodically updates the launcher icon when the app has been idle. */
class AppIconUpdateWorker(
    context: Context,
    params: WorkerParameters,
) : Worker(context, params) {
    override fun doWork(): Result {
        AppIconManager.refreshIconFromIdleTime(applicationContext)
        return Result.success()
    }
}
