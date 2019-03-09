-- Save watch-later conditionally.
-- a) Always for playlists (so mpv remembers the position within this playlist)
-- b) Never for files shorter than `min_length` seconds
-- c) When the current playback position is > `thresh_start` and < `thresh_end`


local opts = require 'mp.options'
local o = {
    min_length = 600,
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
-- Always return false for short files, no matter the playback time
function check_time()
    local duration = mp.get_property_number("duration", 9999)
    if duration < o.min_length then
        return false
    end

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


mp.add_key_binding("q", "quit-watch-later-conditional",
    function()
        mp.set_property_bool("options/save-position-on-quit", check_playlist() or check_time())
        mp.command("quit")
    end)
