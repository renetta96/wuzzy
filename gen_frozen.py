from collections import namedtuple

Key = namedtuple('Key', ['spin', 'x', 'y', 'angle'])

keys = [
	Key(-1, 14.55, -3.4, 0.817475),
	Key(0, 18.45, -3.4, 359.299),
	Key(-1, 15.35, -3.4, 0.503675),
	Key(0, 17.65, -3.4, 359.62),
	Key(-1, 16.1, -3.4, 0.146677),
	Key(0, 16.9, -3.4, 359.977),
	Key(0, 16.9, -3.4, 359.977)
]

stable_idx = 1
new_keys = []
init_key = {'x': -181.531579, 'y':148.684211, 'angle': 319.122298}

for key in keys:
	spin = key.spin
	delta_x = keys[stable_idx].x - key.x
	delta_y = keys[stable_idx].y - key.y

	new_keys.append(Key(spin, init_key['x'] - delta_x, init_key['y'] - delta_y, init_key['angle']))

def print_xml(folder, file, k, scale_x=1, scale_y=1):
	times = [0, 34, 67, 100, 134, 167, 200]
	result = ""

	for idx, key in enumerate(k):
		result += \
		'''<key id="{}" time="{}" spin="{}">
	      <object folder="{}" file="{}" x="{:.6f}" y="{:.6f}" angle="{:.6f}" scale_x="{:.6f}" scale_y="{:.6f}"/>
	    </key>\n'''.format(idx, times[idx], 0, folder, file, key.x, key.y, key.angle, scale_x, scale_y)

	print(result)

print_xml(1, 3, new_keys, 1.654454, 2.25259)
