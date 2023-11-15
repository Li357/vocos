from manta import Manta
import struct

m = Manta('../manta.yaml')

while True:
  # 24-bit signed interpreted as integer
  out = m.voxos_io.mic_level.get()
  three = struct.pack('<I', out)[:-1]
  print(struct.unpack('<i', three + (b'\0' if three[2] < 128 else b'\xff'))[0])