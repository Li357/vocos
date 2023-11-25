from notes import freqs

# synth sampling rate and output width
FS = 192000
WIDTH = 24

resolution = FS / (2 ** WIDTH)

phases = map(lambda freq: f'{round(freq / resolution):024b}', freqs)
with open('../data/notes.mem', 'w') as f:
  f.write('\n'.join(phases))

# generate pitch bend factors
# pitch bend is 14-bit in MIDI but we'll only take the top 7 bits
# where 64 is no bend, 0 is max lowbend, 127 is max highbend
# and then map them to +-2 semitone range, i.e.
# bend = (x / 64) - 1
# factor = 2^(2 * bend / 12)
# then we'll used fixed-point arithmetic with 2^20 scaling and
# express them as 32-bit numbers
PITCHBEND_WIDTH = 7
PITCHBEND_CENTER = 2 ** (PITCHBEND_WIDTH - 1)
PITCHBEND_BINS = 2 ** PITCHBEND_WIDTH

SHIFT = 20

pitchbend_factors = map(lambda x: f'{round(2 ** ((2 * (x / PITCHBEND_CENTER - 1) / 12) + SHIFT)):032b}', range(PITCHBEND_BINS))
with open('../data/pitchbends.mem', 'w') as f:
  f.write('\n'.join(pitchbend_factors))

# generate mod vibrato phase LUT
# we'll generate varible phase incr values for 0 to 10Hz for mod
# values from 0 to 127
MOD_LFO_MAX = 10
MOD_MAX = 2 ** 7

mod_lfo_phase_max = MOD_LFO_MAX / resolution

mod_phases = map(lambda x: f'{round(mod_lfo_phase_max * x / (MOD_MAX - 1)):024b}', range(MOD_MAX))
with open('../data/modphases.mem', 'w') as f:
  f.write('\n'.join(mod_phases))