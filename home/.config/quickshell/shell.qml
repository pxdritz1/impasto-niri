// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   S H E L L                                                              │
// │   quickshell entry point · windows and top-level wiring                  │
// │                                                                          │
// │   github.com/pxdritz1/velatura                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

// Greyscale text: subpixel edges assume an opaque ground and fringe on a
// transparent surface.
//@ pragma Env QSG_DISTANCEFIELD_ANTIALIASING=gray

// Application icons: one set, the same shape for every app.
//@ pragma IconTheme WhiteSur-dark

import QtQuick
import Quickshell
import Quickshell.Io

import "./bar"
import "./capture"
import "./desktop"
import "./dock"
import "./lock"
import "./services"
import "./settings"
import "./theme"

// Entry point: the windows, the services that must start at boot, and the
// wiring between services that may not reference each other.
ShellRoot {
    id: root

    // Singletons are built on first use. Each of these has to be running from
    // boot, not from the moment a panel first reads it.
    Component.onCompleted: {
        // Restores the saved palette.
        void ThemeService.activeId
        // Builds the launcher index ahead of the first open.
        void LauncherService.applications
        // Keeps history, so the graph has data before the panel opens.
        void StatsService.ready
        // Starts Niri output discovery and the read-only shortcut catalogue.
        void MonitorService.monitors
        void ShortcutService.catalogue
        // Reads the user's name and face ahead of the first lock.
        void AccountService.user
        // Counts the time in each application from the start of the session.
        void ScreenTimeService.away
        // Registers the polkit agent, so a request is answered from the start.
        void PolkitService.asking
        // Initializes the Niri colour picker before the first request.
        void PickerService.available
        // Starts the clipboard watcher.
        void ClipboardService.count
        // Reads the virtual machines, one of which may be running from before.
        void VmService.loaded
        // Probes the monitor source, so the first take is not silent, and
        // picks up a take left running by a previous shell.
        void RecorderService.available
        // Restores the night light.
        void SunsetService.available
        // Arms the idle monitors.
        void IdleService.lockAfter
        // Holds every sleep until the lock is up.
        void SessionService.sleepPending
        // Seeds the example profiles on a first install.
        void ProfileService.arrived
        // Lists the virtual camera, so a call can pick it.
        void CameraService.ready
    }

    // ── SCREENS ─────────────────────────────────────────────────────────────
    //
    // Every surface is a Variants over the screens. A PanelWindow whose
    // ShellScreen is destroyed (output unplugged) does not recover when handed
    // a new one; Variants destroys and rebuilds the window with the list,
    // which does.

    // The island is the same bar on every screen, and one of them is LIVE: the
    // screen being worked on. It changes hands the moment the focus does —
    // nothing is created and nothing is destroyed, so the crossing costs no
    // frame and what is under the pointer is always what answers it. It waits
    // only while a panel is open, since moving then is a panel closing itself.
    // The primary is the fallback.
    property string islandName: MonitorService.effectivePrimaryName

    readonly property string wantedIslandName: {
        const focused = NiriService.focusedOutput
        for (const screen of Quickshell.screens)
            if (screen.name === focused)
                return focused
        return MonitorService.effectivePrimaryName
    }

    onWantedIslandNameChanged: root.settleIsland()

    function settleIsland(): void {
        root.claimIsland(root.wantedIslandName)
    }

    // A bar saying the pointer is on it (`Bar.claimed`), which is the same
    // answer the compositor's focus gives a moment earlier — except when the
    // pointer was warped there rather than walked.
    function claimIsland(name: string): void {
        if (name === "" || root.islandName === name || (root.island?.expanded ?? false))
            return
        root.islandName = name
    }

    readonly property Connections islandRests: Connections {
        target: root.island

        function onExpandedChanged(): void {
            root.settleIsland()
        }
    }

    // `islandName` with a screen that is not plugged in resolved away, so an
    // output leaving never leaves every bar inert.
    readonly property string liveScreenName: {
        for (const screen of Quickshell.screens)
            if (screen.name === root.islandName)
                return root.islandName
        return MonitorService.effectivePrimaryName
    }

    // The live bar's island. Notifiable through `instances` and through each
    // bar's own `live`, so it follows the flag rather than a window.
    readonly property var island: {
        for (const bar of bars.instances)
            if (bar.live)
                return bar.island
        return null
    }

    // ── BARS ────────────────────────────────────────────────────────────────
    //
    // One bar per screen, exactly one of them live. A layer surface cannot
    // change output, so an island that moved would be a bar built from
    // nothing on the far screen, its clock and workspaces animating in over
    // the same drawing. Every screen carrying the whole bar, with one flag
    // deciding which is live, costs one transparent surface per screen and no
    // frames at all.

    // The space the bars keep, held per screen and never rebuilt, so swapping
    // one kind of bar for another moves no windows.
    Variants {
        model: Quickshell.screens

        BarReserve {
            required property var modelData

            screen: modelData
        }
    }

    Variants {
        id: bars

        model: Quickshell.screens

        Bar {
            required property var modelData

            screen: modelData
            live: modelData.name === root.liveScreenName

            onClaimed: root.claimIsland(modelData.name)
        }
    }

    // Widgets under the windows, on every screen: a row carries the screen it
    // is on, and every board has a grid of its own.
    Variants {
        model: Quickshell.screens

        Desktop {
            required property var modelData

            screen: modelData
        }
    }

    // A dock on every screen, each drawn or not by `dockEverywhere` and
    // which screen is live.
    Variants {
        model: Quickshell.screens

        Dock {
            required property var modelData

            screen: modelData
            live: modelData.name === root.liveScreenName

            // The dock cannot see the island, so it asks.
            onLauncherRequested: root.island?.toggle("launcher")
        }
    }

    // The screens' corners, rounded off only while the setting is on.
    Variants {
        model: SettingsService.screenCorners ? Quickshell.screens : []

        ScreenCorners {
            required property var modelData

            screen: modelData
            live: modelData.name === root.liveScreenName
        }
    }

    // Notes docked on the screen edges, on every screen, for the desktop's
    // reason. A deck is a row like a widget and carries its screen too.
    Variants {
        model: Quickshell.screens

        Deck {
            required property var modelData

            screen: modelData
        }
    }

    // A normal window rather than an island panel, so the island stays
    // visible while its settings change.
    SettingsWindow {
        id: settingsWindow

        // The palette and wallpaper pickers live on the island.
        onPanelRequested: panel => root.island?.open(panel)
    }

    // The control centre's gear. The island has already closed itself.
    Connections {
        target: root.island

        function onSettingsRequested(): void {
            settingsWindow.open()
        }
    }

    Connections {
        target: DesktopService

        function onSettingsRequested(): void {
            root.island?.close()
            settingsWindow.open()
        }
    }

    // The bar's settings button, which closes the window it opened.
    Connections {
        target: ModuleService

        function onSettingsRequested(): void {
            root.toggleSettings()
        }
    }

    // A program asking for root opens the island on its request, and the
    // island closes once it is answered.
    Connections {
        target: PolkitService

        function onRequested(): void {
            root.island?.open("auth")
        }

        function onSettled(): void {
            if (root.island?.state.openPanel === "auth")
                root.island?.close()
        }
    }

    // Optional clipboard wipe on lock. Joined here so neither service depends
    // on the other. Password-manager copies are never stored in the first
    // place; this covers everything else.
    Connections {
        target: LockService

        function onLockedChanged(): void {
            if (LockService.locked && SettingsService.clipboardWipeOnLock)
                ClipboardService.wipe()
        }
    }

    // ext-session-lock. The bar is not on screen while it is up.
    LockScreen {}

    // The lock screenshots the desktop before covering it, so it waits until
    // the island is collapsed and settled.
    Binding {
        target: LockService
        property: "shellQuiet"
        value: !root.island || (!root.island.expanded && root.island.settled)
    }



    // An open panel holds the keyboard exclusively, which beats a normal
    // window, so the island closes first or the window cannot be typed in.
    function toggleSettings(): void {
        if (!settingsWindow.shown)
            root.island?.close()
        settingsWindow.toggle()
    }



    // The clipboard and the emoji are launcher modes: pressed again on that
    // mode it closes, pressed on another mode it switches. The query is set
    // before opening because with `launcherFits` the panel's height depends on
    // it, and the island is sized before the panel exists.
    function openLauncherOn(mode: string): void {
        const sigil = SettingsService.launcherPrefix(mode)
        const showing = root.island?.state.openPanel === "launcher"
        if (showing && LauncherService.query.startsWith(sigil)) {
            root.island?.close()
            return
        }
        LauncherService.query = sigil
        root.island?.open("launcher")
    }



    // The colour picker captures the screen, so let the island settle first.
    function pickColor(): void {
        const wasOpen = root.island?.expanded ?? false
        root.island?.close()
        PickerService.pick(wasOpen ? PickerService.settle : 0)
    }

    // Always built rather than behind a Loader: creating a layer surface at
    // capture time flashes a black frame over the screen being captured.
    CaptureOverlay {}

    // Region recording, joined here to keep the two services acyclic.
    Connections {
        target: CaptureService

        function onRecordRequested(shape: string, geometry: string): void {
            RecorderService.startAt(shape, geometry)
        }
    }

    // A new wallpaper re-derives the adaptive palette. Wired here so the
    // dependency runs one way: the theme knows about wallpapers, not the
    // reverse.
    Connections {
        target: WallpaperService

        function onApplied(path: string): void {
            ThemeService.reloadAdaptiveColors()
        }
    }

    // ── IPC ─────────────────────────────────────────────────────────────────
    //
    // Everything the velatura command and `qs ipc call` can reach. Every
    // palette push hangs off WallpaperService.applied, which only fires
    // inside this process, so the file manager's "Set as Wallpaper" comes in
    // here too:
    //   qs ipc call wallpaper set <path>
    Commands {
        island: root.island
        settingsToggle: root.toggleSettings
        launcherMode: root.openLauncherOn
        pickColor: root.pickColor
    }

}
