-- autostart
--
-- mako is gone: quickshell owns org.freedesktop.Notifications now (the island
-- shows the banners and keeps the history). swaybg is gone too — the island
-- draws the wallpaper itself so it can crossfade between them.
hl.on("hyprland.start", function()
    -- the pgrep keeps a config reload from spawning a second island; it checks
    -- both process names because `qs` may have been started as `quickshell`
    hl.exec_cmd("pgrep -x qs >/dev/null || pgrep -x quickshell >/dev/null || qs")
end)

hl.on("hyprland.shutdown", function()
    hl.exec_cmd("pkill -x qs || pkill -x quickshell || true")
end)
