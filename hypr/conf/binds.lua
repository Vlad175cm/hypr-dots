local S = "SUPER"
local SA = "SUPER + ALT"
local SS = "SUPER + SHIFT"

hl.bind(S .. " + Return", hl.dsp.exec_cmd("kitty --single-instance --instance-group=hmain"))
hl.bind(S .. " + B", hl.dsp.exec_cmd("zen-browser"))
-- the island: the main panel (what hovering the island opens), then the rest
hl.bind(S .. " + A", hl.dsp.exec_cmd("qs ipc call island dashboard"))
hl.bind(S .. " + D", hl.dsp.exec_cmd("qs ipc call island open launcher"))
hl.bind(S .. " + W", hl.dsp.exec_cmd("qs ipc call island open wallpapers"))
hl.bind(S .. " + N", hl.dsp.exec_cmd("qs ipc call island open notifications"))
hl.bind(S .. " + K", hl.dsp.exec_cmd("qs ipc call island open keys"))
hl.bind(S .. " + C", hl.dsp.exec_cmd("qs ipc call island open info"))
hl.bind(SS .. " + B", hl.dsp.exec_cmd("qs ipc call island open battery"))
hl.bind(S .. " + E", hl.dsp.exec_cmd("nautilus --new-window"))
hl.bind(S .. " + T", hl.dsp.exec_cmd("Telegram"))

hl.bind(S .. " + Q", hl.dsp.window.close())
hl.bind(S .. " + F", hl.dsp.window.fullscreen({ action = "toggle" }))
hl.bind(SA .. " + F", hl.dsp.window.float({ action = "toggle" }))
hl.bind(S .. " + V", hl.dsp.layout("togglesplit"))

hl.bind(S .. " + LEFT", hl.dsp.focus({ direction = "left" }))
hl.bind(S .. " + RIGHT", hl.dsp.focus({ direction = "right" }))
hl.bind(S .. " + UP", hl.dsp.focus({ direction = "up" }))
hl.bind(S .. " + DOWN", hl.dsp.focus({ direction = "down" }))

hl.bind(SA .. " + LEFT", hl.dsp.window.move({ direction = "left" }))
hl.bind(SA .. " + RIGHT", hl.dsp.window.move({ direction = "right" }))
hl.bind(SA .. " + UP", hl.dsp.window.move({ direction = "up" }))
hl.bind(SA .. " + DOWN", hl.dsp.window.move({ direction = "down" }))

for i = 1, 10 do
    local n = i % 10
    hl.bind(S .. " + " .. n, hl.dsp.focus({ workspace = tostring(i) }))
    hl.bind(S .. " + SHIFT + " .. n, hl.dsp.window.move({ workspace = tostring(i) }))
end

hl.bind(SS .. " + A", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/screenshot.sh area"))
hl.bind(SS .. " + W", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/screenshot.sh window"))
hl.bind(SS .. " + F", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/screenshot.sh full"))

hl.bind(S .. " + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(S .. " + S", hl.dsp.exit())
hl.bind(SS .. " + R", hl.dsp.exec_cmd("hyprctl reload"))

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"), { repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 5%+"), { repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { repeating = true })

local kbd_dev = nil
local pfd = io.popen("ls /sys/class/leds/ 2>/dev/null")
if pfd then
    for label in pfd:lines() do
        if label:match("::kbd_backlight$") then
            kbd_dev = label
            break
        end
    end
    pfd:close()
end

if kbd_dev then
    hl.bind("XF86KbdBrightnessUp", hl.dsp.exec_cmd("brightnessctl --device='" .. kbd_dev .. "' set +10%"), { repeating = true })
    hl.bind("XF86KbdBrightnessDown", hl.dsp.exec_cmd("brightnessctl --device='" .. kbd_dev .. "' set 10%-"), { repeating = true })
end
