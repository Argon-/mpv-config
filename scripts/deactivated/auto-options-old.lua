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
-- To adapt it for personal use one probably has to reimplement a few things.
-- Out of the used functions `determine_level()` is the most important one
-- requiring adjustments since it's pretty OS as well as user specific and
-- serves as an essential component. Other functions provide various, minor
-- supporting functionality, e.g. for use in option-specific sub-decisions.


-- Don't do anything when mpv was called with an explicitly passed --vo option
if mp.get_property_bool("option-info/vo/set-from-commandline") then
    return
end

local opts = require 'mp.options'
local utils = require 'mp.utils'

local o = {
    hq = "desktop",
    mq = "laptop",
    lq = "low-energy",
    highres_desktop_threshold = "1920:1200",
    verbose = false,
    duration = 5,
    duration_err_mult = 2,
}
opts.read_options(o)


-- Specify mpv options for each level

local options = {
    [o.hq] = {
        ["vo"] = "opengl",
        ["scale"]  = "ewa_lanczossharp",
        ["cscale"] = "ewa_lanczossoft",
        ["dscale"] = "mitchell",
        ["tscale"] = "linear",
        ["dither-depth"]        = "auto",
        ["correct-downscaling"] = "yes",
        ["sigmoid-upscaling"]   = "yes",
        ["deband"]              = "yes",
        ["scale-antiring"]  = "0.8",
        ["cscale-antiring"] = "0.9",

        ["hwdec"] = "no",
        ["vd-lavc-threads"] = "16",
    },

    [o.mq] = {
        ["vo"] = "opengl",
        ["scale"]  = "spline36",
        ["cscale"] = "spline36",
        ["dscale"] = "mitchell",
        ["tscale"] = "linear",
        ["dither-depth"]        = "auto",
        ["correct-downscaling"] = "yes",
        ["sigmoid-upscaling"]   = "yes",
        ["deband"]              = "yes",
        ["scale-antiring"]  = "0.8",
        ["cscale-antiring"] = "0.9",

        ["hwdec"] = "no",
    },

    [o.lq] = {
        ["vo"] = "opengl",
        ["scale"]  = "spline36",
        ["dscale"] = "mitchell",
        ["tscale"] = "linear",

        ["hwdec"] = "no",
    },
}


-- Select the options level appropriate for this computer
function determine_level(o, options)
    -- Default level
    local level = o.lq

    -- Overwrite level from command line with --script-opts=ao-level=<level>
    local overwrite = mp.get_opt("ao-level")
    if overwrite then
        if not options[overwrite] then
            print("Forced level does not exist: " .. overwrite)
            return level
        end
        return overwrite
    end

    -- Call an external bash function determining whether this is a desktop or laptop
    local loc = exec({"bash", "-c", 'source "$HOME"/local/shell/location-detection && is-desktop'})
    if loc.error then
        loc.status = 255
    end

    -- Desktop -> hq
    if loc.status == 0 then
        level = o.hq
    -- Laptop  -> mq/lq
    elseif loc.status == 1 then
        level = o.mq
        -- Go down to lq when we are on battery
        bat = exec({"/usr/bin/pmset", "-g", "ac"})
        if bat.stdout == "No adapter attached.\n" then
            level = o.lq
        end
    elseif o.verbose then
        print("unable to determine location, using default level: " .. level)
    end

    return level
end


-- Determine if the currently used resolution is higher than o.highres_threshold
function high_res_desktop(o)
    sp_ret = exec({"/usr/local/bin/resolution", "compare", o.highres_desktop_threshold})
    return not sp_ret.error and sp_ret.status > 2
end


function high_res_video(o)
    print("TODO: high_res_video(o)")
    return false
end


function exec(process)
    p_ret = utils.subprocess({args = process})
    if p_ret.error and p_ret.error == "init" then
        print("ERROR executable not found: " .. process[1])
    end
    return p_ret
end


function set_ASS(b)
    return mp.get_property_osd("osd-ass-cc/" .. (b and "0" or "1"))
end


function red_border(s)
    return set_ASS(true) .. "{\\bord1}{\\3c&H3300FF&}{\\3a&H20&}" .. s .. "{\\r}" .. set_ASS(false)
end


function print_status(name, value, o)
    if not value or not o.level then
        return
    end

    if o.err_occ then
        print("Error setting level: " .. o.level)
        mp.osd_message(red_border("Error setting level: ") .. o.level, o.duration * o.duration_err_mult)
    else
        print("Active level: " .. o.level)
        mp.osd_message(o.level
             .. (high_res_desktop(o) and "\n↳ desktop: high res" or "")
             .. (high_res_video(o) and "\n↳ video: high res" or ""), o.duration)
    end
    mp.unobserve_property(print_status)
end


-- Print status information to VO window and terminal
mp.observe_property("vo-configured", "bool",
                    function (name, value) print_status(name, value, o) end)


-- Determined level and apply the appropriate options
function main()
    o.level = determine_level(o, options)
    o.err_occ = false
    for k, v in pairs(options[o.level]) do
        if type(v) == "function" then
            v = v()
        end
        success, err = mp.set_property(k, v)
        o.err_occ = o.err_occ or not (o.err_occ or success)
        if success and o.verbose then
            print("Set '" .. k .. "' to '" .. v .. "'")
        elseif o.verbose then
            print("Failed to set '" .. k .. "' to '" .. v .. "'")
            print(err)
        end
    end
end

main()
