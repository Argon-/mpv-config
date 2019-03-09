do_stuff = false

mp.register_idle(function()
    if not do_stuff then print("poll") end
    os.execute("sleep " .. tonumber(1))
    print("idle")
    do_stuff=false
end)

mp.add_forced_key_binding("j", "test", function()
    print("binding")
    do_stuff=true
end, {repeatable=true})
