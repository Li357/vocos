from scipy.io import wavfile
from scipy.fft import fft
import matplotlib.pyplot as plt
import numpy as np

def biquad(b0, b1, b2, a1, a2, pos=False):
  def f(x):
    y = []
    for i in range(len(x)):
      x1 = x[i - 1] if i >= 1 else 0
      x2 = x[i - 2] if i >= 2 else 0
      y1 = y[i - 1] if i >= 1 else 0
      y2 = y[i - 2] if i >= 2 else 0
      v = b0 * x[i] + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
      y.append(v if (pos and v >= 0) or not pos else 0)
    return y
  return f

v_sample_rate, v_data = wavfile.read('voice.wav')
i_sample_rate, i_data = wavfile.read('440.wav')
print(i_sample_rate)

# create filters from filters file
# of 7-octave spaced bandpass filters starting from 50Hz up to 6400Hz
filters = []
with open('bands.txt', 'r') as bank_file:
  params = []
  for i, line in enumerate(bank_file):
    _, _, s_val = line.split(' ')
    params.append(float(s_val))
    if i % 5 == 4:
      filters.append(biquad(*params))
      params = []

# 50 Hz cutoff
envelope = biquad(0.00004244330935142056, 0.00008488661870284112, 0.00004244330935142056, -1.9814857645620922, 0.9816555377994975, pos=True)

i_fs = np.array([f(i_data[:1024]) for f in filters])

out = np.array([])
for i in range(0, len(v_data), 1024):
  chunk = v_data[i:i+1024]
  if len(chunk) < 1024: break
  # amplitudes
  v_fs = np.array([envelope(f(chunk))for f in filters])
  out = np.append(out, np.sum(np.multiply(v_fs, i_fs) / 10000, axis=0))

wavfile.write('out_440.wav', v_sample_rate, out)