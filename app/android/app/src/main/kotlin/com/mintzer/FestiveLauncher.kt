package com.mintzer

import android.content.ComponentName
import android.content.Context
import android.content.pm.PackageManager

/**
 * Drawer icon aliases. Festive SALE/FEST season ended early (owner 26 Oct 2026)
 * after notification opens force-closed while aliases switched in onCreate.
 * Always keep [DEFAULT] on. Other aliases stay disabled.
 */
object FestiveLauncher {
    private const val DEFAULT = "LauncherDefault"
    private val festive = listOf(
        "LauncherSaleStars",
        "LauncherSaleCrown",
        "LauncherFestStars",
        "LauncherFestCrown",
    )

    fun apply(context: Context) {
        val pm = context.packageManager
        val pkg = context.packageName
        val wanted = DEFAULT
        val all = listOf(DEFAULT) + festive
        val ready = all.all { name ->
            isEnabled(pm, component(pkg, name), name == DEFAULT) == (name == wanted)
        }
        if (ready) return

        val flags = PackageManager.DONT_KILL_APP
        pm.setComponentEnabledSetting(
            component(pkg, wanted),
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
            flags,
        )
        for (name in all) {
            if (name == wanted) continue
            pm.setComponentEnabledSetting(
                component(pkg, name),
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                flags,
            )
        }
    }

    private fun component(pkg: String, name: String) = ComponentName(pkg, "$pkg.$name")

    private fun isEnabled(pm: PackageManager, component: ComponentName, manifestDefault: Boolean): Boolean {
        return when (pm.getComponentEnabledSetting(component)) {
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED -> true
            PackageManager.COMPONENT_ENABLED_STATE_DISABLED -> false
            else -> manifestDefault
        }
    }
}
