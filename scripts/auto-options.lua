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

local f = require 'auto-options-functions'
local opts = require 'mp.options'

local o = {
    hq = "desktop",
    mq = "laptop",
    lq = "laptop (low-power)",
    highres_threshold = "1920:1200",
    force_low_res = false,
    verbose = false,
    duration = 5,
    duration_err_mult = 2,
}
opts.read_options(o)


-- Specify a VO for each level

vo = {
    [o.hq] = "opengl-hq",
    [o.mq] = "opengl-hq",
    [o.lq] = "opengl",
}


-- Specify VO sub-options for different levels

vo_opts = {
    [o.hq] = {
        ["scale"]  = "ewa_lanczossharp",
        ["cscale"] = "ewa_lanczossoft",
        ["dscale"] = "mitchell",
        ["tscale"] = "triangle",
        ["scale-antiring"]  = "0.8",
        ["cscale-antiring"] = "0.9",

        ["dither-depth"]        = "auto",
        ["target-prim"]         = "bt.709",
        ["correct-downscaling"] = "yes",
    },

    [o.mq] = {
        ["scale"]  = "spline36",
        ["cscale"] = "spline36",
        ["dscale"] = "mitchell",
        ["tscale"] = "triangle",
        ["scale-antiring"]  = "0.8",
        ["cscale-antiring"] = "0.9",

        ["dither-depth"]        = "auto",
        ["target-prim"]         = "bt.709",
        ["correct-downscaling"] = "yes",
    },

    [o.lq] = {
        ["scale"]  = "spline36",
        ["dscale"] = "mitchell",
        ["tscale"] = "triangle",

        ["dither-depth"]        = "auto",
        ["target-prim"]         = "bt.709",
        ["correct-downscaling"] = "yes",
    },
}


-- Specify general mpv options for different levels

options = {
    [o.hq] = {
        ["options/vo"] = function () return vo_property_string(o.hq, vo, vo_opts) end,
        ["options/hwdec"] = "no",
        ["options/vd-lavc-threads"] = "16",
    },

    [o.mq] = {
        ["options/vo"] = function () return vo_property_string(o.mq, vo, vo_opts) end,
        ["options/hwdec"] = "no",
    },

    [o.lq] = {
        ["options/vo"] = function () return vo_property_string(o.lq, vo, vo_opts) end,
        ["options/hwdec"] = "auto",
    },
}


-- Print status information to VO window and terminal

mp.observe_property("vo-configured", "bool",
                    function (name, value) print_status(name, value, o) end)


-- Determined level and set the appropriate options

function main()
    o.force_low_res = mp.get_opt("ao-flr")
    o.level = determine_level(o, vo, vo_opts, options)
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
