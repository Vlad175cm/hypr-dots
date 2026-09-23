hl.curve("smooth", { type = "bezier", points = { { 0.16, 1.0 }, { 0.30, 1.0 } } })
hl.curve("glide", { type = "bezier", points = { { 0.25, 1.0 }, { 0.40, 1.0 } } })

hl.config({
    animations = {
        enabled = true,
        workspace_wraparound = false,
    },
    misc = {
        animate_manual_resizes = true,
        animate_mouse_windowdragging = true,
    },
})

hl.animation({ leaf = "windows", enabled = true, speed = 7.0, bezier = "glide", style = "popin 94%" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 6.5, bezier = "glide", style = "popin 94%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 5.0, bezier = "smooth", style = "popin 86%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 5.0, bezier = "smooth" })

hl.animation({ leaf = "workspaces", enabled = true, speed = 8.0, bezier = "glide", style = "slidefade 12%" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 7.5, bezier = "glide", style = "slidefade 12%" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 7.5, bezier = "glide", style = "slidefade 12%" })

hl.animation({ leaf = "fade", enabled = true, speed = 4.5, bezier = "glide" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 4.0, bezier = "glide" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 3.5, bezier = "smooth" })
hl.animation({ leaf = "fadeSwitch", enabled = true, speed = 4.0, bezier = "glide" })
hl.animation({ leaf = "fadePopups", enabled = true, speed = 3.5, bezier = "glide" })
hl.animation({ leaf = "fadePopupsIn", enabled = true, speed = 3.0, bezier = "glide" })
hl.animation({ leaf = "fadePopupsOut", enabled = true, speed = 3.0, bezier = "smooth" })

hl.animation({ leaf = "layers", enabled = true, speed = 4.0, bezier = "glide", style = "fade" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 3.5, bezier = "glide", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 3.0, bezier = "smooth", style = "fade" })

hl.animation({ leaf = "border", enabled = false })
hl.animation({ leaf = "borderangle", enabled = false })
hl.animation({ leaf = "shadowangle", enabled = false })
hl.animation({ leaf = "glowangle", enabled = false })
hl.animation({ leaf = "monitorAdded", enabled = true, speed = 4.0, bezier = "glide" })
