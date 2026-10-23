import subprocess
SND='/Users/mac/Development/cardgame/assets/sounds/'
EV=[('reveal',1.15,.9),('put',2.3,1),('shuffle',3.65,.8)]+[('draw',3.85+k*.2,.7) for k in range(4)]+\
   [('flip',8.85,.8),('flip',10.3,.6),('flip',11.7,.6),('flip',13.05,.8),('flip',17.25,.8),('change_turn',21.05,.8),('win',21.6,.6),('flip',24.5,.8),('buy',25.5,1),('win',25.6,.7)]
args=['ffmpeg','-v','error','-y','-i','music.wav']; fc=''; mix='[0]'
for i,(f,tm,g) in enumerate(EV,1):
    args+=['-i',SND+f+'.wav']; ms=int(tm*1000)
    fc+=f'[{i}]aformat=channel_layouts=stereo:sample_rates=44100,volume={g},adelay={ms}|{ms}[a{i}];'; mix+=f'[a{i}]'
fc+=f'{mix}amix=inputs={len(EV)+1}:normalize=0,alimiter=limit=0.95,atrim=0:28[out]'
subprocess.run(args+['-filter_complex',fc,'-map','[out]','-c:a','pcm_s16le','audio.wav'],check=True); print('ok')
