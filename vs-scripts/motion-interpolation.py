import vapoursynth as vs
core = vs.get_core()


target_num = 60000#int(display_fps * 1e8) # check sanity first
target_den = 1000#int(1e8)
max_width  = 1920
max_height = 1200
blocksize  = 16
threshold  = 12    # (threshold/255)% blocks have to change to consider this a scene change


clip = video_in

if not (clip.width > max_width or clip.height > max_height or container_fps > (target_num / target_den)):
    print('motion-interpolation: {0} -> {1} FPS'.format(container_fps, (target_num / target_den)))
    clip = core.std.AssumeFPS(clip, fpsnum=int(container_fps * 1e8), fpsden=int(1e8))
    sup  = core.mv.Super(clip, pel=2, hpad=blocksize, vpad=blocksize)
    bv   = core.mv.Analyse(sup, blksize=blocksize, isb=True , chroma=True, search=3, searchparam=1)
    fv   = core.mv.Analyse(sup, blksize=blocksize, isb=False, chroma=True, search=3, searchparam=1)
    clip = core.mv.BlockFPS(clip, sup, bv, fv, num=target_num, den=target_den, mode=3, thscd2=threshold)
else:
    print('motion-interpolation: skipping {0}x{1} {2} FPS video'.format(clip.width, clip.height, container_fps))

clip.set_output()
