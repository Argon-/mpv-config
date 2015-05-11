import vapoursynth as vs
core = vs.get_core()

clip = video_in
clip = core.std.Trim(clip, first=0, length=500000)
clip = core.f3kdb.Deband(clip, grainy=16, grainc=16, output_depth=16, dynamic_grain=True)
#clip = core.resize.Bicubic(clip, format=vs.YUV420P8)
clip.set_output()
