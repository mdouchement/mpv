-- This script displays the state of the palyed media.
-- https://github.com/mdouchement/mpv

-- MIT License

-- Copyright (c) 2020 mdouchement

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

--[[
To configure this script use file show_state.conf in directory script-opts (the "script-opts"
directory must be in the mpv configuration directory, typically ~/.config/mpv/).

Example configuration would be:

key_binding = ";"
duration = 3
style_tags = "{\\fnmonospace}"
scale = 2
font_size = 10
font_color = "e6e6e6"

--]]

local mp = require 'mp'
local options = require 'mp.options'
local assdraw = require 'mp.assdraw'

opts = {
    key_binding = ";",
    duration = 3,         -- in seconds
    style_tags = "",      -- e.g {\\fnmonospace}
    scale = 2,
    font_size = 10,       -- multiplied by scale
    font_color = "e6e6e6" -- ASS hexa color (BGR order <bb><gg><rr>)
}
options.read_options(opts)

function format_duration(duration)
    local h = duration / 3600
    local m = duration % 3600 / 60
    local s = duration % 3600 % 60

    return string.format("%02d:%02d:%02d", h, m, s)
end

function render(msg)
    local ass = assdraw.ass_new()

    ass:an(7)
    ass:append(opts.style_tags)
    ass:append(string.format("{\\fs%d}", opts.font_size * opts.scale))
    ass:append(string.format("{\\1c&H%s}", opts.font_color))
    ass:append(msg)

    local dpi_scale = mp.get_property_native("display-hidpi-scale", 1.0)
    dpi_scale = dpi_scale * opts.scale

    local screenx, screeny, aspect = mp.get_osd_size()
    screenx = screenx / dpi_scale
    screeny = screeny / dpi_scale

    mp.set_osd_ass(screenx, screeny, ass.text)
end

function compute_state()
    local filename = mp.get_property("filename")
    local pcurrent = mp.get_property("playlist-pos-1")
    local pcount = mp.get_property("playlist-count")

    local percent = mp.get_property_number("percent-pos")
    local position = mp.get_property_number("time-pos")
    local remaining = mp.get_property_number("playtime-remaining")
    local total = mp.get_property_number("duration")

    local msg = string.format(
        "%s\\N%s/%s\\N%d%%    %s (%s)    %s",
        filename,
        pcurrent,
        pcount,
        percent,
        format_duration(position),
        format_duration(remaining),
        format_duration(total)
    )
    render(msg)
end

local running = false
function show_state()
    if running then
        return
    end
    running = true

    seconds = 0.0
    timer = mp.add_periodic_timer(0.05, function()
        compute_state()
        seconds = seconds + 0.05
        if seconds >= opts.duration then
            render('')
            timer:kill()
            running = false
        end
    end)
end

mp.add_key_binding(opts.key_binding, "show-state", show_state)