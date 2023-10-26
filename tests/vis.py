from scipy.io import wavfile
import matplotlib.pyplot as plt

_, voice = wavfile.read('voice.wav')
_, out = wavfile.read('out.wav')

plt.plot(voice / max(voice))
plt.plot(out / max(out))
plt.show()

