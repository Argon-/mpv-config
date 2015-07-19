import vapoursynth as vs
core = vs.get_core()

clip = video_in
clip = core.vivtc.VDecimate(clip)
clip = core.std.AssumeFPS(clip, fpsnum=24000, fpsden=1001)

clip.set_output()
