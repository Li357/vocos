from math import pi, sin
import numpy as np

def gen_sine(samples, width):
  amp = 2 ** (width - 1)
  # generate just a quarter of a period and exploit symmetries
  return [round(amp * sin(x * 2 * pi / samples)) for x in range(samples // 4)]

def write_to_mem(samples, width, file):
  with open(file, 'w') as f:
    for sample in samples:
      f.write(f'{np.binary_repr(sample, width=width)}\n')

SAMPLES = 2 ** 16
WIDTH = 24
sine = gen_sine(SAMPLES, WIDTH)
write_to_mem(sine, WIDTH, 'sine.mem')