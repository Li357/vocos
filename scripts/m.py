from manta import Manta
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation

m = Manta('../manta.yaml')

# fig, ax = plt.subplots(figsize=(6, 3))
# buf = [0] * 100
# fil = [0] * 100
 
# x = range(100)
# ln, ln2 = plt.plot(x, buf[:100], '-', x, fil[:100], 'g-')

# def update(frame):
#     out = m.voxos_io.mic_level.get()
#     print(temp1)
#     buf.append(out)
#     fil.append(temp1)
#     ln.set_data(x, buf[-100:])
#     ln2.set_data(x, fil[-100:])
#     ax.autoscale()
#     ax.set_ylim(min(buf[-100:]), max(buf[-100:]))
#     return ln,
 
# animation = FuncAnimation(fig, update, interval=50)
# plt.show()

while True:
  temp1 = m.voxos_io.temp1.get()
  print(f'{temp1}')