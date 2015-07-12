import vapoursynth as vs
core = vs.get_core()


threshold  = 12    # (threshold/255)% blocks have to change to consider this a scene change
blocksize  = 16
max_width  = 1920
max_height = 1200
max_fps    = 60


# assume display_fps to be bogus when not in a certain range
target_num = 60 if display_fps < 23.9 or display_fps > 300 else display_fps
while (target_num > max_fps):
    target_num /= 2
target_num = int(target_num * 1e6)
target_den = int(1e6)
source_num = int(container_fps * 1e6)
source_den = int(1e6)

clip = video_in

if not (clip.width > max_width or clip.height > max_height or container_fps > max_fps):
    print('motion-interpolation: {0} -> {1} ({2}) FPS'
          .format(source_num / source_den, target_num / target_den, display_fps))

    clip = core.std.AssumeFPS(clip, fpsnum=source_num, fpsden=source_den)
    sup  = core.mv.Super(clip, pel=2, hpad=blocksize, vpad=blocksize)
    bv   = core.mv.Analyse(sup, blksize=blocksize, isb=True , chroma=True, search=3, searchparam=1)
    fv   = core.mv.Analyse(sup, blksize=blocksize, isb=False, chroma=True, search=3, searchparam=1)
    clip = core.mv.BlockFPS(clip, sup, bv, fv, num=target_num, den=target_den, mode=3, thscd2=threshold)
else:
    print('motion-interpolation: skipping {0}x{1} {2} FPS video'
          .format(clip.width, clip.height, container_fps))


clip.set_output()
