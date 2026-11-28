# python3 -I match.py <recording.wav> <source.ogg> [...]: is this source in the recording, where and how loud?
import sys, subprocess, numpy as np, soundfile as sf
SR=16000
def load(p):
    raw=subprocess.run(["ffmpeg","-v","error","-i",p,"-f","f32le","-ac","1","-ar",str(SR),"-"],capture_output=True).stdout
    return np.frombuffer(raw,dtype=np.float32).astype(np.float64)
rec=load(sys.argv[1])
for src in sys.argv[2:]:
    s=load(src)
    off=int(float(__import__('os').environ.get('OFF','0'))*SR)
    n=min(len(s)-off, int(float(__import__('os').environ.get('WIN','4'))*SR))
    k=s[off:off+n]-s[off:off+n].mean()
    # normalised cross-correlation by FFT
    L=len(rec)+n
    F=np.fft.rfft(rec,L)*np.conj(np.fft.rfft(k,L))
    cc=np.fft.irfft(F,L)[:len(rec)-n+1]
    c2=np.cumsum(np.concatenate([[0.0],rec*rec])); e=np.sqrt(np.maximum(c2[n:]-c2[:-n],1e-12))[:len(cc)]
    nc=cc/(e*np.sqrt((k*k).sum())+1e-12)
    i=int(np.argmax(nc)); seg=rec[i:i+n]
    gain=(seg*k).sum()/((k*k).sum()+1e-12)
    print("%-34s best match %.2f at %.2f s, playing at %+.1f dB of the file's own level" % (src.split('/')[-1], nc[i], i/SR, 20*np.log10(max(abs(gain),1e-6))))
