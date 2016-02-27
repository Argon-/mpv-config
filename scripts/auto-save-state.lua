-- In case "save-position-on-quit" is used (e.g. by config) this script will
-- remove it when only a certain amount of seconds are left to play (threshold).
--

if not mp.get_property_bool("options/save-position-on-quit") then
    return
end

local opts = require 'mp.options'
local o = {
    threshold = 120,
    timer_wait = 10,
}
opts.read_options(o)

-- Set threshold from command line by using --script-opts=ass-threshold=t
t = tonumber(mp.get_opt("ass-threshold"))
if t then
    o.threshold = t
end


function check_time()
    remaining, err = mp.get_property_number("time-remaining")
    if not remaining then
        --print("Error: " .. err)
        return
    end

    if (o.threshold > remaining) then
        mp.set_property_bool("options/save-position-on-quit", false)
    else
        mp.set_property_bool("options/save-position-on-quit", true)
    end
end


-- Check by polling
--timer = mp.add_periodic_timer(o.timer_wait, check_time)
-- Check on every seek
mp.register_event("seek", check_time)
-- Check on every (un)pause
mp.observe_property("pause", "bool", check_time)
-- Check on every quit
mp.add_key_binding("q", "quit-check-time", function()
                        check_time()
                        mp.command("quit")
                   end)
