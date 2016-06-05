-- In case "save-position-on-quit" is used (e.g. by config) this script will
-- remove it when only a certain amount of seconds are left to play (threshold).
--

if not mp.get_property_bool("options/save-position-on-quit") then
    return
end

local opts = require 'mp.options'
local o = {
    thresh_end = 120,
    thresh_start = 240,
    timer_wait = 10,
}
opts.read_options(o)


-- Set thresh_* from command line by using --script-opts=ass-thresh_*=t
t = tonumber(mp.get_opt("ass-thresh_end"))
if t then
    o.thresh_end = t
end
t = tonumber(mp.get_opt("ass-thresh_start"))
if t then
    o.thresh_start = t
end


function check_time()
    remaining, err = mp.get_property_number("time-remaining")
    if not remaining then
        --print("Error: " .. err)
        return
    end
    pos, err = mp.get_property_number("time-pos")
    if not pos then
        --print("Error: " .. err)
        return
    end

    if o.thresh_end > remaining or pos < o.thresh_start then
        mp.set_property_bool("options/save-position-on-quit", false)
    else
        mp.set_property_bool("options/save-position-on-quit", true)
    end
end


-- Check by polling
--timer = mp.add_periodic_timer(o.timer_wait, check_time)
-- Check on every seek
--mp.register_event("seek", check_time)
-- Check on every (un)pause
--mp.observe_property("pause", "bool", check_time)
-- Check on every quit
mp.add_key_binding("q", "quit-check-time", function()
                        check_time()
                        mp.command("quit")
                   end)
