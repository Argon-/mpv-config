-- Set options dynamically.
-- The script aborts without doing anything when you specified a `--vo` option
-- from command line. You can also use `--script-opts=ao-level=<level>`
-- to force a specific level from command line.
--
-- Upon start, `determine_level()` will select a level (o.hq/o.mq/o.lq)
-- whose options will then be applied.
--
-- General mpv options can be defined in the `options` table while VO
-- sub-options are to be defined in `vo_opts`.
--
-- One probably has to reimplement `determine_level()` since it's pretty OS and
-- user specific.


-- Don't do anything when mpv was called with an explicitly passed --vo option
if mp.get_property_bool("option-info/vo/set-from-commandline") then
    return
end

local options = require 'mp.options'
local utils = require 'mp.utils'

local o = {
    hq = "desktop",
    mq = "laptop",
    lq = "laptop (low-power)",
    highres_threshold = "1920:1200",
    verbose = false,
    duration = 5,
    duration_err_mult = 2,
}
options.read_options(o)

-- Tables containing the options to set. Possible levels are considered keys
-- in these tables, values are specified further below.
local vo = {}
local vo_opts = {}
local options = {}


function determine_level(o)
    -- Default level
    local level = o.mq

    -- Overwrite level from command line with --script-opts=ao-level=<level>
    local overwrite = mp.get_opt("ao-level")
    if overwrite then
        if not (vo[overwrite] and vo_opts[overwrite] and options[overwrite]) then
            print("Forced level does not exist: " .. overwrite)
            return level
        end
        return overwrite
    end

    -- Call an external bash function determining if this is a desktop or laptop
    loc = {}
    loc.args = {"bash", "-c", 'source "$HOME"/local/shell/location-detection && is-desktop'}
    loc_ret = utils.subprocess(loc)

    -- Something went wrong
    if loc_ret.error then
        loc_ret.status = 255
    end

    -- Desktop -> hq
    if loc_ret.status == 0 then
        level = o.hq
    -- Laptop  -> mq/lq
    elseif loc_ret.status == 1 then
        level = o.mq
        -- Go down to lq when we are on battery
        bat = {}
        bat.args = {"/usr/bin/pmset", "-g", "ac"}
        bat_ret = utils.subprocess(bat)
        if bat_ret.stdout == "No adapter attached.\n" then
            level = o.lq
        end
    elseif o.verbose then
        print("unable to determine location, using default level: " .. level)
    end

    return level
end


-- Use tables `vo` and `vo_opts` to build a `vo=key1=val1:key2=val2` string
function vo_property_string(level, vo, vo_opts)
    local result = {}
    for k, v in pairs(vo_opts[level]) do
        if type(v) == "function" then
            v = v()
        end
        if v and v ~= "" then
            table.insert(result, k .. "=" ..v)
        else
            table.insert(result, k)
        end
    end
    return vo[level] .. (next(result) == nil and "" or (":" .. table.concat(result, ":")))
end


function is_high_res(o)
    sp = {}
    sp.args = {"/usr/local/bin/resolution", "compare", o.highres_threshold}
    sp_ret = utils.subprocess(sp)
    return not sp_ret.error and sp_ret.status > 2
end


function set_ASS(b)
    return mp.get_property_osd("osd-ass-cc/" .. (b and "0" or "1"))
end


function red_border(s)
    return set_ASS(true) .. "{\\bord1}{\\3c&H3300FF&}{\\3a&H20&}" .. s .. "{\\r}" .. set_ASS(false)
end


-- Define VO for different levels

vo = {
    [o.hq] = "opengl-hq",
    [o.mq] = "opengl-hq",
    [o.lq] = "opengl",
}


-- Define VO sub-options for different levels

vo_opts[o.hq] = {
    ["scale"]  = "ewa_lanczossharp",
    ["cscale"] = "ewa_lanczossoft",
    ["dscale"] = "mitchell",
    ["tscale"] = "oversample",
    ["scale-antiring"]  = "0.8",
    ["cscale-antiring"] = "0.9",

    ["dither-depth"]        = "auto",
    --["icc-profile-auto"]    = "",
    ["target-prim"]         = "bt.709",
    ["scaler-resizes-only"] = "",
    ["sigmoid-upscaling"]   = "",

    --["interpolation"]     = is_high_res(o) and "no" or "yes",
    ["fancy-downscaling"] = "",
    ["source-shader"]     = "~~/shaders/deband.glsl",
    ["icc-cache-dir"]     = "~~/icc-cache",
    ["3dlut-size"]        = "256x256x256",
}

vo_opts[o.mq] = {
    ["scale"]  = "spline36",
    ["cscale"] = "spline36",
    ["dscale"] = "mitchell",
    ["tscale"] = "oversample",
    ["scale-antiring"]  = "0.8",
    ["cscale-antiring"] = "0.9",

    ["dither-depth"]        = "auto",
    --["icc-profile-auto"]    = "",
    ["target-prim"]         = "bt.709",
    ["scaler-resizes-only"] = "",
    ["sigmoid-upscaling"]   = "",

    ["interpolation"]     = is_high_res(o) and "no" or "yes",
    ["fancy-downscaling"] = "",
    ["source-shader"]     = "~~/shaders/deband.glsl",
}

vo_opts[o.lq] = {
    ["scale"]  = "spline36",
    ["dscale"] = "mitchell",
    ["tscale"] = "oversample",

    ["dither-depth"]        = "auto",
    --["icc-profile-auto"]    = "",
    ["target-prim"]         = "bt.709",
    ["scaler-resizes-only"] = "",
    ["sigmoid-upscaling"]   = "",

    --["interpolation"]     = is_high_res(o) and "no" or "yes",
}


-- Define mpv options for different levels.
-- Option names (keys) are given as strings, values as functions without parameters.

options[o.hq] = {
    ["options/vo"] = function () return vo_property_string(o.hq, vo, vo_opts) end,
    ["options/hwdec"] = "no",
    ["options/vd-lavc-threads"] = "16",
}

options[o.mq] = {
    ["options/vo"] = function () return vo_property_string(o.mq, vo, vo_opts) end,
    ["options/hwdec"] = "no",
}

options[o.lq] = {
    ["options/vo"] = function () return vo_property_string(o.lq, vo, vo_opts) end,
    ["options/hwdec"] = "auto",
}


-- Set all defined options for the determined level

local level = determine_level(o)
local err_occ = false
for k, v in pairs(options[level]) do
    if type(v) == "function" then
        v = v()
    end
    success, err = mp.set_property(k, v)
    err_occ = err_occ or not (err_occ or success)
    if success and o.verbose then
        print("Set '" .. k .. "' to '" .. v .. "'")
    elseif o.verbose then
        print("Failed to set '" .. k .. "' to '" .. v .. "'")
        print(err)
    end
end


-- Print status information to VO window and terminal

function print_status(name, value)
    if not value then
        return
    end

    if err_occ then
        print("Error setting level: " .. level)
        mp.osd_message(red_border("Error setting level: ") .. level, o.duration * o.duration_err_mult)
    else
        print("Active level: " .. level)
        mp.osd_message("Level: " .. level, o.duration)
    end
    mp.unobserve_property(print_status)
end

mp.observe_property("vo-configured", "bool", print_status)
