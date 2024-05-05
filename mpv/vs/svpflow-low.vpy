##超低配svpflow补帧
import vapoursynth as vs
from vapoursynth import core
clip=video_in
fps = container_fps if container_fps > 0.1 else 23.976
##自适应分辨率，请自己将显示器分辨率设置好
screen_width = 2560  # 设置显示器的宽度
screen_height = 1600  # 设置显示器的高度
screen_ratio = screen_width/screen_height  # 显示器分辨率的宽高比
clip_ratio = clip.width/clip.height  # 输入分辨率的宽高比
rewidth = clip.width	#缩放后的宽度
reheight = clip.height	#缩放后的高度
##计算输出分辨率
if clip_ratio > screen_ratio:
    rewidth = screen_width
    reheight = int(screen_width/clip_ratio)
else:
    rewidth = int(screen_height*clip_ratio)
    reheight = screen_height
clip = clip.resize.Point(format=vs.YUV420P8, dither_type="random", width=rewidth, height=reheight)
##自适应倍帧###########################
##当abs为fasle时，目标帧数=num/den*源帧率（倍帧），能兼容帧数有变化的视频（虽然这种视频很少）
##当abs为true时，目标帧率=num/den（固定帧数），顺滑度可能不如倍帧？（瞎猜的，没有理论也没有实践）
##源帧率超过第一个IF后面数字的的帧率就会禁用补帧，这个数字可以自己改，有高刷屏并且配置还行的话可以改到70以上
if container_fps > 77 :
	raise Warning("源帧率超过限制的范围，已临时禁用该脚本。")
elif container_fps > 27 :
	smoothfps_params = "{rate:{num:2,den:1,abs:false},algo:13,gpuid:0,scene:{},mask:{area:75,cover:75}}"
elif container_fps > 17 :
	smoothfps_params = "{rate:{num:5,den:2,abs:false},algo:13,gpuid:0,scene:{},mask:{area:75,cover:75}}"
else :
	smoothfps_params = "{rate:{num:4,den:1,abs:false},algo:13,gpuid:0,scene:{},mask:{area:75,cover:75}}"
super_params="{pel:1,scale:{up:0,down:0},gpu:1,full:false,rc:true}"
analyse_params="{gpu:1,block:{overlap:0},main:{search:{coarse:{distance:-8},type:2}}}"
##↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑##
##↑gpu:1开启显卡加速(注意有两处gpu:0需要修改)，如果补帧失效请改回0                                                  ↑##
##↑gpuid决定用哪张显卡加速，仅在gpu:1时起作用，默认值0，双卡笔记本建议改成21，可用数值0/11/12/21##
############################################################################################
super=core.svp1.Super(clip,super_params)
vectors=core.svp1.Analyse(super["clip"],super["data"],clip,analyse_params)
smooth=core.svp2.SmoothFps(clip,super["clip"],super["data"],vectors["clip"],vectors["data"],smoothfps_params,src=clip,fps=fps)
smooth.set_output()
