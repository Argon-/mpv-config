local mp = require 'mp'


local auto_change = true
local device_description = {}
local av_map = {
    ["default"] = "auto",
}
-- local av_map = {
--     ["DELL U2520D.*"]               = "coreaudio/AppleUSBAudioEngine:FiiO:DigiHug USB Audio:114000:3", -- FiiO USB DAC-E10
--     ["SONY TV  [*]00.*"]            = "coreaudio/4DD90482-0000-0000-011C-0103806C3D78_0C80D000", -- HDMI
--     ["Built[-]in Retina Display.*"] = "coreaudio/BuiltInSpeakerDevice", -- Built-in 2024 MBP
--     ["default"]                     = "auto",
-- }

-- local av_map_patterns = {
--     ["DELL U2520D.*"]               = "coreaudio/AppleUSBAudioEngine[:]FiiO[:]DigiHug USB Audio.*", -- FiiO USB DAC-E10
--     ["SONY TV  [*]00.*"]            = "coreaudio/4DD90482[-]0000[-]0000[-]011C[-]0103806C3D78.*", -- HDMI
--     ["Built[-]in Retina Display.*"] = "coreaudio/BuiltInSpeakerDevice", -- Built-in 2024 MBP
--     ["default"]                     = "auto",
-- }
local av_map_patterns = {
    ["DELL U2520D.*"]               = "FiiO USB DAC[-]E10",
    ["SONY TV  [*]00.*"]            = "SONY TV  [*]00",
    ["Built[-]in Retina Display.*"] = "MacBook Pro Speakers",
    ["default"]                     = "auto",
}


function create_av_map(audio_devices)
    if not audio_devices then
        return
    end

    local new_av_map = {
        ["default"] = "auto",
    }

    --print("Creating new av_map")
    --print("Audio devices: ")
    for _, device in ipairs(audio_devices) do
        --print("   > " .. device.name .. " | " .. device.description)
        for display, audio_patt in pairs(av_map_patterns) do
            --if string.match(device.name, audio_patt) then
            if string.match(device.name, "coreaudio/.*") and string.match(device.description, audio_patt) then
                new_av_map[display] = device.name
                device_description[device.name] = device.description
                --print("      Matched: " .. display .. " -> " .. device.name .. " | " .. device.description)
            end
        end
    end

    print("New av_map:")
    for k, v in pairs(new_av_map) do
        print("   > " .. k .. " -> " .. v)
    end
    av_map = new_av_map
end


function set_audio_device(obs_display)
    if not auto_change then
        return
    end

    local display = obs_display or mp.get_property_native("display-names")
    if display == nil then
        return
    end

    if not display or not display[1] then
        print("Unknown display return value: " .. tostring(display))
        return
    end
    print("Display: " .. display[1])

    -- iterate av_map and search for the first entry that matches display
    local new_adev = nil
    for k, v in pairs(av_map) do
        if string.match(display[1], k) then
            new_adev = v
            break
        end
    end

    if new_adev == nil then
        new_adev = av_map["default"]
        print("No audio match found for display: " .. tostring(display[1]))
    end
    --local new_adev = av_map[display[1]] or av_map["default"]
    local current_adev = mp.get_property("audio-device", av_map["default"])
    if new_adev ~= current_adev then
        mp.osd_message("Audio device: " .. (device_description[new_adev] or new_adev))
        mp.set_property("audio-device", new_adev)
    end
end

mp.observe_property("audio-device-list", "native", function(name, value) create_av_map(value) end)
mp.observe_property("display-names", "native", function(name, value) set_audio_device(value) end)
--mp.add_key_binding("", "set-audio-device", function() set_audio_device(nil) end)
mp.add_key_binding("", "toggle-switching", function()
    if auto_change then
        set_audio_device({"default"})
        mp.osd_message("Audio device: auto (forced)")
        auto_change = false -- set after call to set_audio_device otherwise it won't do anything
    else
        auto_change = true
        set_audio_device(nil)
    end
end)
