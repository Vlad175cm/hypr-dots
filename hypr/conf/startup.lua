hl.on("hyprland.start", function()
    hl.exec_cmd("mako")
    hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/start-wallpaper.sh")
end)

hl.on("hyprland.shutdown", function()
    hl.exec_cmd("pkill swaybg || true")
end)
