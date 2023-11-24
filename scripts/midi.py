import mido
import serial
import serial.tools.list_ports as port_list

midi_ports = mido.get_output_names()
for idx, port in enumerate(midi_ports):
    print(f'{idx}: {port}')
idx = int(input('Choose a MIDI device to read from: '))
midi = mido.open_input(midi_ports[idx])

ser_ports = list(port_list.comports())
for idx, port in enumerate(ser_ports):
    print(f'{idx}: {port} {port.vid} {port.pid}')

idx = int(input('Choose a serial port to send to: '))
ser = serial.Serial(ser_ports[idx].device, baudrate=3_000_000)

try:
  while True:
    evt = midi.receive()
    ser.write(evt.bin())
    print(f'{evt.bin().hex(sep=" ")}\t{evt}')
except KeyboardInterrupt:
    ser.close()
    midi.close()
    print('Goodbye!')
