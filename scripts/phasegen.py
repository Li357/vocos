from notes import freqs

# synth sampling rate and output width
FS = 192000
WIDTH = 24

resolution = FS / (2 ** WIDTH)

phases = map(lambda freq: f'{round(freq / resolution):024b}', freqs)
with open('../data/notes.mem', 'w') as f:
  f.write('\n'.join(phases))



