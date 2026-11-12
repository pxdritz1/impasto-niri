// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   I D L E   S E R V I C E                                                │
// │   idle actions · lock, screen off and suspend timeouts                   │
// │                                                                          │
// │   github.com/pxdritz1/velatura                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Wayland

// Idle lock, screen off and suspend, in place of hypridle.
//
// Quickshell's `IdleMonitor` speaks `ext-idle-notify` directly, so timeouts
// follow the settings live with no daemon to restart. A timeout of zero means
// never. `respectInhibitors` lets video players hold all three off.
Singleton {
    id: root

    // Minutes; `IdleMonitor` takes seconds.
    readonly property int lockAfter: SettingsService.idleLock
    readonly property int screenAfter: SettingsService.idleScreen
    readonly property int suspendAfter: SettingsService.idleSuspend

    readonly property IdleMonitor lockWatch: IdleMonitor {
        enabled: root.lockAfter > 0
        timeout: root.lockAfter * 60
        respectInhibitors: true

        // `lock()` is a no-op when already locked.
        onIsIdleChanged: {
            if (lockWatch.isIdle)
                LockService.lock()
        }
    }

    readonly property IdleMonitor screenWatch: IdleMonitor {
        enabled: root.screenAfter > 0
        timeout: root.screenAfter * 60
        respectInhibitors: true
        onIsIdleChanged: root.screen(!screenWatch.isIdle)
    }

    readonly property IdleMonitor sleepWatch: IdleMonitor {
        enabled: root.suspendAfter > 0
        timeout: root.suspendAfter * 60
        respectInhibitors: true

        // The session action locks and waits for the compositor to confirm
        // before suspending.
        onIsIdleChanged: {
            if (sleepWatch.isIdle)
                SessionService.run("suspend")
        }
    }

    // Niri exposes explicit, idempotent DPMS actions through its IPC.
    function screen(on: bool): void {
        NiriService.runAction([on ? "power-on-monitors" : "power-off-monitors"])
    }
}
