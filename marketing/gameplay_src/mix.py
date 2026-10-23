import subprocess
SND='/Users/mac/Development/cardgame/assets/sounds/'
EV=[('reveal', 0.75, 0.9), ('put', 1.45, 1), ('shuffle', 2.65, 0.8), ('draw', 2.85, 0.6), ('draw', 3.0, 0.6), ('draw', 3.15, 0.6), ('draw', 3.3, 0.6), ('change_turn', 7.3, 0.6), ('flip', 8.305, 0.75), ('flip', 13.572000000000001, 0.75), ('flip', 16.573, 0.75), ('flip', 19.586999999999996, 0.75), ('flip', 25.587000000000003, 0.75), ('flip', 26.804999999999996, 0.8), ('buy', 27.804999999999996, 1), ('win', 27.904999999999998, 0.7)]
args=['ffmpeg','-v','error','-y','-i','music.wav']; fc=''; mix='[0]'
for i,(f,tm,g) in enumerate(EV,1):
    args+=['-i',SND+f+'.wav']; ms=int(tm*1000)
    fc+=f'[{i}]aformat=channel_layouts=stereo:sample_rates=44100,volume={g},adelay={ms}|{ms}[a{i}];'; mix+=f'[a{i}]'
fc+=f'{mix}amix=inputs={len(EV)+1}:normalize=0,alimiter=limit=0.95,atrim=0:30.50[out]'
subprocess.run(args+['-filter_complex',fc,'-map','[out]','-c:a','pcm_s16le','audio.wav'],check=True); print('ok')
