#!/usr/bin/env bash

qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
    function get_value(valueName) {
        d = desktops()[0];
        d.currentConfigGroup = Array("Wallpaper", "org.kde.slideshow", "General");
        return d.readConfig(valueName);
    }
    function set_value(valueName, value) {
        d = desktops()[0];
        d.currentConfigGroup = Array("Wallpaper", "org.kde.slideshow", "General");
        d.writeConfig(valueName, value);
    }
    orig_paths = get_value("SlidePaths");
    fake_paths = Array("/"+ Math.floor(Math.random() * (Math.pow(10, 16) + 1)));
    set_value("SlidePaths", fake_paths);
    set_value("SlidePaths", orig_paths.split(","));'
