import time
from manta import Manta
m = Manta('manta.yaml') # create manta python instance using yaml

a = m.lab8_io_core.misobyte_in.get() # read in the output from our divider
b = m.lab8_io_core.mosibyte_in.get() # read in the output from our divider
time.sleep(0.001)
print(f"{a} and {b}")
