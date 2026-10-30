package com.mintzer

import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        // Defer alias changes so a notification cold-start finishes first.
        // Sync apply() in onCreate was linked to force-closes on tray tap.
        Handler(Looper.getMainLooper()).post {
            try {
                FestiveLauncher.apply(this)
            } catch (_: Throwable) {
                // Never block open for icon swap.
            }
        }
    }
}
