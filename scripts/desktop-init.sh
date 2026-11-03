#!/bin/bash

# Moves all windows of a given resourceClass to a monitor.
# target: "builtin" (the laptop panel, connector name starting with eDP)
#         or "primary" (the other connected monitor).
# Retries for a few seconds in the background since apps can take a while
# to create their window after being launched.
move_window_to() {
    local resourceClass="$1" target="$2"
    (
        for i in $(seq 1 15); do
            local js plugin
            js=$(mktemp /tmp/kwin-move-XXXXXX.js)
            cat > "$js" <<EOF
(function() {
    var screens = workspace.screens;
    if (screens.length < 2) return;
    var builtin = null, other = null;
    for (var i = 0; i < screens.length; i++) {
        if (screens[i].name.indexOf("eDP") === 0) builtin = screens[i];
        else other = screens[i];
    }
    var dest = ("$target" === "builtin") ? builtin : other;
    if (!dest) return;
    var wins = workspace.windowList();
    for (var i = 0; i < wins.length; i++) {
        if (wins[i].resourceClass === "$resourceClass") {
            workspace.sendClientToScreen(wins[i], dest);
        }
    }
})();
EOF
            plugin="move-$$-$i-$RANDOM"
            local id
            id=$(qdbus org.kde.KWin /Scripting loadScript "$js" "$plugin" 2>/dev/null)
            qdbus org.kde.KWin /Scripting/Script$id run >/dev/null 2>&1
            qdbus org.kde.KWin /Scripting unloadScript "$plugin" >/dev/null 2>&1
            rm -f "$js"
            sleep 1
        done
    ) &
}

qdbus org.kde.KWin /KWin org.kde.KWin.setCurrentDesktop 3
sleep 1
#microsoft-edge '--app=https://app.element.io/#/room/!VOeLKKXGJhjiRQTOJd:matrix.org' --class=WebApp-Element4888 &
element-desktop &
move_window_to "element-desktop" "builtin"
sleep 1
teams-for-linux &
move_window_to "teams-for-linux" "builtin"

sleep 2
qdbus org.kde.KWin /KWin org.kde.KWin.setCurrentDesktop 2
sleep 1
code &
move_window_to "com.microsoft.VSCode" "primary"

sleep 2
qdbus org.kde.KWin /KWin org.kde.KWin.setCurrentDesktop 1
sleep 1
firefox --new-window 'https://jira.iter.org/secure/RapidBoard.jspa?rapidView=20958' --new-tab 'https://git.iter.org/projects/COA/repos/psps-webapp/pull-requests' &
move_window_to "firefox" "primary"
#zen --new-window &

#sleep 2
#qdbus org.kde.KWin /KWin org.kde.KWin.setCurrentDesktop 4
#sleep 1
#thunderbird &

sleep 2
qdbus org.kde.KWin /KWin org.kde.KWin.setCurrentDesktop 5
sleep 1
#/var/lib/flatpak/exports/bin/org.chromium.Chromium --app=https://web.whatsapp.com/ --class=WebApp-WhatsApp3987 --name=WebApp-WhatsApp3987 &
#ghostty -e "nchat" &
#sleep 1
ghostty -e "cliamp" &
move_window_to "com.mitchellh.ghostty" "primary"

disown -a
exit 0
