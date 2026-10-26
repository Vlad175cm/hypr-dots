local S = "SUPER"
local SA = "SUPER + ALT"
local SS = "SUPER + SHIFT"

hl.bind(S .. " + Return", hl.dsp.exec_cmd("kitty"))
hl.bind(S .. " + B", hl.dsp.exec_cmd("zen-browser"))
-- the island: the main panel (what hovering the island opens), then the rest
hl.bind(S .. " + A", hl.dsp.exec_cmd("qs ipc call island dashboard"))
hl.bind(S .. " + D", hl.dsp.exec_cmd("qs ipc call island open launcher"))
hl.bind(S .. " + W", hl.dsp.exec_cmd("qs ipc call island open wallpapers"))
hl.bind(S .. " + N", hl.dsp.exec_cmd("qs ipc call island open notifications"))
hl.bind(S .. " + K", hl.dsp.exec_cmd("qs ipc call island open keys"))
hl.bind(S .. " + C", hl.dsp.exec_cmd("qs ipc call island open info"))
hl.bind(SS .. " + B", hl.dsp.exec_cmd("qs ipc call island open battery"))
hl.bind(SS .. " + V", hl.dsp.exec_cmd("qs ipc call island open clipboard"))
hl.bind(S .. " + E", hl.dsp.exec_cmd("kitty -e yazi"))
hl.bind(S .. " + T", hl.dsp.exec_cmd("Telegram"))

hl.bind(S .. " + Q", hl.dsp.window.close())
hl.bind(S .. " + F", hl.dsp.window.fullscreen({ action = "toggle" }))
hl.bind(SA .. " + F", hl.dsp.window.float({ action = "toggle" }))
hl.bind(S .. " + V", hl.dsp.layout("togglesplit"))

hl.bind(S .. " + LEFT", hl.dsp.focus({ direction = "left" }))
hl.bind(S .. " + RIGHT", hl.dsp.focus({ direction = "right" }))
hl.bind(S .. " + UP", hl.dsp.focus({ direction = "up" }))
hl.bind(S .. " + DOWN", hl.dsp.focus({ direction = "down" }))

local function is_float()
    local w = hl.get_active_window()
    return w ~= nil and w.floating
end

local function move_active(dir, dx, dy)
    return function()
        if is_float() then
            hl.dispatch(hl.dsp.window.move({ x = dx, y = dy, relative = true }))
        else
            hl.dispatch(hl.dsp.window.move({ direction = dir }))
        end
    end
end

local function resize_active(dx, dy)
    return function()
        if is_float() then
            hl.dispatch(hl.dsp.window.resize({ x = dx, y = dy, relative = true }))
        end
    end
end

hl.bind(SA .. " + LEFT", move_active("left", -20, 0))
hl.bind(SA .. " + RIGHT", move_active("right", 20, 0))
hl.bind(SA .. " + UP", move_active("up", 0, -20))
hl.bind(SA .. " + DOWN", move_active("down", 0, 20))

hl.bind(SA .. " + CTRL + LEFT", resize_active(-20, 0), { repeating = true })
hl.bind(SA .. " + CTRL + RIGHT", resize_active(20, 0), { repeating = true })
hl.bind(SA .. " + CTRL + UP", resize_active(0, -20), { repeating = true })
hl.bind(SA .. " + CTRL + DOWN", resize_active(0, 20), { repeating = true })

local function drag_float()
    if is_float() then
        hl.dispatch(hl.dsp.window.drag())
    end
end

local function resize_drag_float()
    if is_float() then
        hl.dispatch(hl.dsp.window.resize())
    end
end

hl.bind(S .. " + mouse:272", drag_float, { mouse = true })
hl.bind(S .. " + mouse:273", resize_drag_float, { mouse = true })

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
