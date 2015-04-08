import vapoursynth as vs
core = vs.get_core()

core.std.LoadPlugin("/Users/Julian/.mpv/vs-plugins/fmtconv-r8/src/libfmtconv.dylib")
core.std.LoadPlugin("/Users/Julian/.mpv/vs-plugins/nnedi3/.libs/libnnedi3.dylib")

clip = video_in
clip = core.std.Trim(clip, first=0, length=500000)
clip = core.nnedi3.nnedi3_rpow2(clip, rfactor=2, correct_shift=False)
clip.set_output()
