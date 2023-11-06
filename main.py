import time
from manta import Manta
m = Manta('manta.yaml') # create manta python instance using yaml

b = m.voxos.rcv_byte.get()
print(b)
