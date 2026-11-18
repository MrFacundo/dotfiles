#!/usr/bin/env python
"""Stand-in for KRunner: owns org.kde.krunner on the session bus and opens walker.

Typing on an empty desktop makes plasmashell call
  /org/kde/krunner org.freedesktop.Application.ActivateAction("Query", [text], ...)
once per keystroke, with the full text typed so far, until the launcher takes focus.
The KRunner shortcut arrives as Activate / CommandLine on the same object.

Walker cannot pre-fill its input. When ydotool is available, the collected text is
pasted into walker (wl-copy + Ctrl+V, independent of the keyboard layout) and the
previous clipboard text is restored.
"""
import shutil
import subprocess
import time

import dbus
import dbus.service
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib

NAME = "org.kde.krunner"
ACTIVATE_DELAY_MS = 60   # Activate may be followed by a Query; let the Query win
INJECT_DELAY_MS = 180    # time for walker (service mode) to map and take focus
REOPEN_GUARD_S = 0.6     # ignore repeated triggers while walker is opening

state = {"pending": None, "last_open": 0.0, "term": "", "inject": None}


def spawn(argv, **kw):
    p = subprocess.Popen(argv, **kw)
    GLib.child_watch_add(GLib.PRIORITY_DEFAULT, p.pid, lambda *_: None)  # reap
    return p


def inject():
    state["inject"] = None
    term = state["term"]
    if not term or not (shutil.which("ydotool") and shutil.which("wl-copy")):
        return False
    old = subprocess.run(["wl-paste", "-n", "-t", "text"], capture_output=True).stdout
    subprocess.run(["wl-copy", "--", term])
    # Ctrl (29) + V (47)
    subprocess.run(["ydotool", "key", "29:1", "47:1", "47:0", "29:0"])

    def restore():
        if old:
            subprocess.run(["wl-copy"], input=old)
        else:
            subprocess.run(["wl-copy", "--clear"])
        return False

    GLib.timeout_add(300, restore)
    return False


def open_walker(term=""):
    if state["pending"]:
        GLib.source_remove(state["pending"])
        state["pending"] = None
    if term:
        state["term"] = term  # Plasma resends the growing text; keep the latest
    if time.monotonic() - state["last_open"] < REOPEN_GUARD_S:
        return False
    state["last_open"] = time.monotonic()
    if not term:
        state["term"] = ""
    spawn(["walker"])
    if term and state["inject"] is None:
        state["inject"] = GLib.timeout_add(INJECT_DELAY_MS, inject)
    return False


def schedule_open():
    if state["pending"] is None:
        state["pending"] = GLib.timeout_add(ACTIVATE_DELAY_MS, open_walker)


class App(dbus.service.Object):
    IFACE = "org.kde.krunner.App"

    @dbus.service.method(IFACE, in_signature="s")
    def query(self, term):
        open_walker(term)

    @dbus.service.method(IFACE, in_signature="ss")
    def querySingleRunner(self, runner, term):
        open_walker(term)

    @dbus.service.method(IFACE)
    def display(self):
        open_walker()

    @dbus.service.method(IFACE)
    def toggleDisplay(self):
        open_walker()

    @dbus.service.method(IFACE)
    def displayWithClipboardContents(self):
        open_walker()

    @dbus.service.method(IFACE, in_signature="s")
    def displaySingleRunner(self, runner):
        open_walker()


class Application(dbus.service.Object):
    """Entry points used by plasmashell (typing) and kglobalaccel (shortcut)."""

    @dbus.service.method("org.freedesktop.Application", in_signature="a{sv}")
    def Activate(self, platform_data):
        schedule_open()

    @dbus.service.method("org.freedesktop.Application", in_signature="sava{sv}")
    def ActivateAction(self, action, params, platform_data):
        if action == "Query" and params:
            open_walker(str(params[0]))
        else:
            schedule_open()

    @dbus.service.method("org.freedesktop.Application", in_signature="asa{sv}")
    def Open(self, uris, platform_data):
        schedule_open()

    @dbus.service.method("org.kde.KDBusService", in_signature="assa{sv}", out_signature="i")
    def CommandLine(self, args, cwd, platform_data):
        schedule_open()
        return 0


DBusGMainLoop(set_as_default=True)
bus = dbus.SessionBus()
name = dbus.service.BusName(NAME, bus, do_not_queue=True)
App(bus, "/App")
Application(bus, "/org/kde/krunner")
GLib.MainLoop().run()
