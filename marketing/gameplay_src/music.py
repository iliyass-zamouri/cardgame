import numpy as np, wave
import json
TL=json.load(open('clips/timeline.json'))
T_INTRO,T_HERO=2.6,8.0
T_END=T_HERO+TL['hero']-0.3
SR=44100; D=T_END+3.6; N=int(SR*D); t=np.arange(N)/SR
out=np.zeros((N,2))
rng=np.random.default_rng(7)
def add(sig,start,gain=1.0,pan=0.0):
    i=int(start*SR); n=min(len(sig),N-i)
    if n<=0: return
    l=np.cos((pan+1)*np.pi/4); r=np.sin((pan+1)*np.pi/4)
    out[i:i+n,0]+=sig[:n]*gain*l*1.414; out[i:i+n,1]+=sig[:n]*gain*r*1.414
def env(n,a,d):
    x=np.arange(n)/SR; return np.minimum(1,x/max(a,1e-4))*np.exp(-x/d)
def lp(x,a):  # one-pole lowpass
    y=np.empty_like(x); acc=0.0
    for k in range(len(x)): acc+=a*(x[k]-acc); y[k]=acc
    return y
def kick():
    n=int(.45*SR); x=np.arange(n)/SR; f=45+110*np.exp(-x*28)
    return np.sin(2*np.pi*np.cumsum(f)/SR)*np.exp(-x*7)
def boom(L=2.0):
    n=int(L*SR); x=np.arange(n)/SR; f=32+90*np.exp(-x*6)
    return np.sin(2*np.pi*np.cumsum(f)/SR)*np.exp(-x*1.6) + rng.standard_normal(n)*np.exp(-x*9)*.35
def snare():
    n=int(.25*SR); x=np.arange(n)/SR
    nz=rng.standard_normal(n); nz=nz-lp(nz,.15)
    return nz*np.exp(-x*16)*.8+np.sin(2*np.pi*185*x)*np.exp(-x*20)*.4
def hat():
    n=int(.06*SR); nz=rng.standard_normal(n); nz=nz-lp(nz,.6); return nz*np.exp(-np.arange(n)/SR*60)
def note(freq,L,a=.02,d=.5,harm=(1,.5,.25)):
    n=int(L*SR); x=np.arange(n)/SR
    s=sum(h*np.sin(2*np.pi*freq*(k+1)*x) for k,h in enumerate(harm))
    return s*np.minimum(1,x/a)*np.exp(-x/d)
def pad(freqs,L):
    n=int(L*SR); x=np.arange(n)/SR; s=np.zeros(n)
    for f in freqs:
        for det in (-.003,.003): s+=np.sin(2*np.pi*f*(1+det)*x)+.3*np.sin(2*np.pi*2*f*(1+det)*x)
    e=np.minimum(1,x/.4)*np.minimum(1,(L-x)/.4); return s*e/len(freqs)
H=lambda m:440*2**((m-69)/12)
# --- intro: drone + riser
add(pad([H(45),H(52),H(57)],T_INTRO),0,.25)
n=int(.8*SR); x=np.arange(n)/SR
add(lp(rng.standard_normal(n),.05)*(x/.8)**2*3,0,.5)
add(np.sin(2*np.pi*np.cumsum(200+900*(x/.8)**2)/SR)*(x/.8)**2,0,.12)
add(boom(),.8,.9); add(boom(1.2),1.45,.7)
n=int(.5*SR); x=np.arange(n)/SR
add(lp(rng.standard_normal(n),.1)*(x/.5)**2*2,T_INTRO-.5,.6)
add(boom(2.5),T_INTRO,1.0)
# --- groove 3.6..24.6 : Am F C G per bar (2s @120bpm)
chords=[[57,60,64],[53,57,60],[48,52,55],[55,59,62]]
roots=[33,29,36,31]
bar=2.0; t0=T_INTRO
nb=int((T_END-t0)/bar)+1
for b in range(nb):
    s=t0+b*bar; c=b%4
    add(pad([H(m) for m in chords[c]],bar+.3),s,.22)
    for beat in range(4):
        bt=s+beat*.5
        if bt>=T_END-.05: break
        if not (b==0 and beat==0): add(kick(),bt,.85)
        if beat in (1,3) and b>=1: add(snare(),bt,.35)
        add(hat(),bt+.25,.12,.3); 
        if b>=2: add(hat(),bt,.06,-.3)
        # bass 8ths
        for e in (0,.25): add(note(H(roots[c]),.24,.005,.12,(1,.6,.3,.15)),bt+e,.35)
    # arpeggio pluck from bar 2
    if b>=2:
        seq=chords[c]+[chords[c][0]+12]
        for k in range(8):
            add(note(H(seq[k%4]+12),.4,.003,.18,(1,.2)),s+k*.25,.10,(-.5 if k%2 else .5))
# --- end hit
add(boom(3),T_END,1.0)
add(pad([H(45),H(57),H(60),H(64),H(69)],3.4),T_END,.35)
for k,m in enumerate([81,84,88,93]): add(note(H(m),1.2,.002,.5,(1,.1)),T_END+.95+k*.07,.12,(k-1.5)/2)
# fade + normalize
out*=np.minimum(1,(D-t)/.5)[:,None]
out/=np.max(np.abs(out))*1.12
w=wave.open('music.wav','wb'); w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR)
w.writeframes((out*32767).astype(np.int16).tobytes()); w.close(); print('ok')
