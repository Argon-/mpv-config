
local utils = require 'mp.utils'
local msg = require 'mp.msg'

-- quality levels
local HIGH = "High Quality"
local MID  = "Mid Quality"
local LOW  = "Low Quality"
-- location (desktop/laptop)
local loc = 255
-- platform
local is_linux, is_osx, is_windows = false, false, false


local function exec(process)
    p_ret = utils.subprocess({args = process})
    if p_ret.error and p_ret.error == "init" then
        msg.error("executable not found: " .. process[1])
    end
    return p_ret
end


local function get_platform()
    local is_linux = false
    local is_osx = false
    local is_windows = type(package) == 'table' and type(package.config) == 'string' and package.config:sub(1, 1) == '\\'
    if not is_windows then
        uname = exec({"uname"})
        is_linux = uname.stdout == "Linux\n"
        is_osx = uname.stdout == "Darwin\n"
        if is_linux == is_osx then
            msg.error("platform detection ambiguous")
        end
    end
    return is_linux, is_osx, is_windows
end


function is_desktop()
    --local loc = exec({"bash", "-c", 'source "$HOME"/local/shell/location-detection && is-desktop'})
    if loc.error then
        msg.error("location detection failed")
        loc.status = 255
    end
    return loc.status == 0
end

function is_laptop()
    --local loc = exec({"bash", "-c", 'source "$HOME"/local/shell/location-detection && is-desktop'})
    if loc.error then
        msg.error("location detection failed")
        loc.status = 255
    end
    return loc.status == 1
end


function on_battery()
    if is_osx then
        local bat = exec({"/usr/bin/pmset", "-g", "batt"})
        return not bat.stdout:match("Now drawing from 'AC Power'")
    elseif is_linux then
        local res = exec({"/bin/cat", "/sys/class/power_supply/AC/online"})
        return res.stdout == "0\n"
    elseif is_windows then
        msg.error("on_battery() not implemented for windows")
    end
    return false
end


local function determine_level(width, height, fps)
    if on_battery() then
        return LOW
    end

    if is_laptop() then
        if width > 1919 then
            return LOW
        end
        if fps > 58 then
            return LOW
        end
        return MID
    elseif is_desktop() then
        if width > 4096 then
            return MID
        end
        return HIGH
    end
    msg.error("could not determine profile")
    return HIGH
end


local function is_level(level)
    return function(width, height, fps)
        local l = determine_level(width, height, fps)
        --mp.osd_message(l)
        return l == level
    end
end


is_high = is_level(HIGH)
is_mid = is_level(MID)
is_low = is_level(LOW)


loc = exec({"bash", "-c", 'source "$HOME"/local/shell/location-detection && is-desktop'})
is_linux, is_osx, is_windows = get_platform()
