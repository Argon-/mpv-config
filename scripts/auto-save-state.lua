-- In case "save-position-on-quit" is used (e.g. by config) this script will
-- remove it when only a certain amount of seconds are left to play (threshold).

--if not mp.get_property_bool("options/save-position-on-quit") then
--    return
--end


local opts = require 'mp.options'
local o = {
    thresh_end = 180,
    thresh_start = 60,
}
opts.read_options(o)


-- Return true when multiple files are being played
function check_playlist()
    local pcount, err = mp.get_property_number("playlist-count")
    if not pcount then
        print("error: " .. err)
        pcount = 1
    end

    return pcount > 1
end


-- Return true when the current playback time is not too close to the start or end
function check_time()
    local remaining, err = mp.get_property_number("time-remaining")
    if not remaining then
        print("error: " .. err)
        remaining = -math.huge
    end
    local pos, err = mp.get_property_number("time-pos")
    if not pos then
        print("error: " .. err)
        pos = -math.huge
    end

    return pos > o.thresh_start and remaining > o.thresh_end
end


mp.add_forced_key_binding("q", "quit-watch-later-conditional",
    function()
        mp.set_property_bool("options/save-position-on-quit", check_playlist() or check_time())
        mp.command("quit")
    end)
