local mp = require 'mp'


local auto_change = true
local av_map = {
    ["DELL U2312HM"] = "coreaudio/AppleUSBAudioEngine:FiiO:DigiHug USB Audio:1a160000:3", -- FiiO DAC
    ["SONY TV  *00"] = "coreaudio/AppleGFXHDAEngineOutputDP:0:{D94D-8204-01010101}", -- HDMI
}

function set_audio_device(obs_display)
    if not auto_change then
        return
    end

    local display = obs_display or mp.get_property_native("display-names", "no value")
    if not display or not display[1] then
        print("Invalid display return value: " .. tostring(display))
        return
    end

    local current_adev = mp.get_property("audio-device", "auto")
    local new_adev = av_map[display[1]]
    if new_adev and type(new_adev) == "string" and new_adev ~= current_adev then
        mp.osd_message("Audio device: " .. new_adev)
        mp.set_property("audio-device", new_adev)    
    end
end

mp.add_key_binding("", "set-auto-audio-device", function() set_audio_device(nil) end)
mp.add_key_binding("", "toggle-auto-audio-device", function() auto_change = not auto_change end)

mp.observe_property("display-names", "native", 
    function(name, value)
        set_audio_device(value)
        print(name .. ": " .. tostring(value[1])) 
    end)