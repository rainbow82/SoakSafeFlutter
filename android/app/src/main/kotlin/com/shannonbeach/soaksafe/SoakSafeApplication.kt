package com.shannonbeach.soaksafe

import android.app.Application
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.ProcessLifecycleOwner

class SoakSafeApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        AppIconManager.schedulePeriodicRefresh(this)
        AppIconManager.refreshIconFromIdleTime(this)
        ProcessLifecycleOwner.get().lifecycle.addObserver(
            object : DefaultLifecycleObserver {
                override fun onStart(owner: LifecycleOwner) {
                    AppIconManager.onAppForeground(this@SoakSafeApplication)
                }
            },
        )
    }
}
