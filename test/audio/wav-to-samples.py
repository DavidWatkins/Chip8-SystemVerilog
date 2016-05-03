import wave, struct, sys


def open_wav(wave_file):
	return wave.open(wave_file, 'r')

def read_samples(wave_file, nb_frames):
    frame_data = wave_file.readframes(nb_frames)
    if frame_data:
        sample_width = wave_file.getsampwidth()
        nb_samples = len(frame_data) // sample_width
        format = {1:"%db", 2:"<%dh", 4:"<%dl"}[sample_width] % nb_samples
        return struct.unpack(format, frame_data)
    else:
        return ()

def samples_to_hex(sample_list):
	if sample_list:
		return [hex(sample & (2**16-1)) for sample in sample_list]
	else:
		return []

def write_wave(sample_list, output_file):
	with open(output_file, 'w') as outfile:
		for s in sample_list:
			outfile.write(s + '\n')


if __name__ == "__main__":
	if (len(sys.argv) != 3):
		print("Usage: python wav-to-samples.py <wav file> <output file> \n")
		exit(1)
	wave = open_wav(sys.argv[1])
	n = wave.getnframes()
	samples = read_samples(wave, n)
	hex_samples = samples_to_hex(samples)
	write_wave(hex_samples, sys.argv[2])
	wave.close()
	print("Samples successfully exported to " + sys.argv[2] + '\n')
	exit(0)

