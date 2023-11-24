from notes import freqs

# synth sampling rate and output width
FS = 192000
WIDTH = 24

resolution = FS / (2 ** WIDTH)

phases = map(lambda freq: f'{round(freq / resolution):024b}', freqs)
with open('../data/notes.mem', 'w') as f:
  f.write('\n'.join(phases))

# also generate pitch bend factors
# pitch bend is 14-bit in MIDI but we'll only take the top 7 bits
# where 64 is no bend, 0 is max lowbend, 127 is max highbend
# and then map them to +-2 semitone range, i.e.
# bend = (x / 64) - 1
# factor = 2^(2 * bend / 12)
# then we'll used fixed-point arithmetic with 2^20 scaling and
# express them as 32-bit numbers
PITCHBEND_WIDTH = 7

pitchbend_factors = map(lambda x: f'{round(2 ** ((2 * (x / 64 - 1) / 12) + 20)):032b}', range(128))
with open('../data/pitchbends.mem', 'w') as f:
  f.write('\n'.join(pitchbend_factors))