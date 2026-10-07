-- autostart
--
-- mako is gone: quickshell owns org.freedesktop.Notifications now (the island
-- shows the banners and keeps the history). swaybg is gone too — the island
-- draws the wallpaper itself so it can crossfade between them.
hl.on("hyprland.start", function()
    -- the pgrep keeps a config reload from spawning a second island
    hl.exec_cmd("pgrep -x qs >/dev/null || qs")
    -- kitty daemon: next Super+Enter opens in ~70ms instead of ~480ms
    hl.exec_cmd("pgrep -f 'kitty --single-instance --instance-group=hmain' >/dev/null || kitty --single-instance --instance-group=hmain --start-as=hidden")
end)

hl.on("hyprland.shutdown", function()
    hl.exec_cmd("pkill -x quickshell || true")
end)
