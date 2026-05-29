package com.shannonbeach.soaksafe

import android.app.Application
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.ProcessLifecycleOwner

class SoakSafeApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        ProcessLifecycleOwner.get().lifecycle.addObserver(
            object : DefaultLifecycleObserver {
                private var coldStart = true

                override fun onStart(owner: LifecycleOwner) {
                    val app = this@SoakSafeApplication
                    if (coldStart) {
                        coldStart = false
                        AppIconManager.refreshIconFromIdleTime(app)
                    }
                    AppIconManager.onAppForeground(app)
                }
            },
        )
    }
}
