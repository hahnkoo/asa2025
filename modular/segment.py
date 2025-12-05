"""A Python script for unsupervised phonetic segmentation based on spectro-temporal representation

This script is a Python implementation of the segmentation algorithm for my Praat script of the same name. The rationale for providing the script in Python is two-fold: speed and extensibility. The segmentation algorithm runs much faster with this script than the Praat script. The script allows one to use various libraries in Python to build a speech processing pipeline including phonetic segmentation.

Main differences between this script and the Praat script are input and output. As for input, the Praat script (a) extracts spectro-temporal features from audio recordings on the fly using built-in Praat functionalities or (b) loads features extracted elsewhere and saved in text files. This script only does (b). That said, you can use load_features.praat if you wish to extract the same spectro-temporal features from Praat. As for output, the Praat script saves the segmentation output in a Praat TextGrid file. This script (a) by default, saves phonetic boundary timestamps in a text file or (b) optionally, saves the segmentation output in a Praat TextGrid file.

Another difference is lack of silence filtering. The Praat script allows users to apply the silence detection command in Praat to revise boundaries post-hoc. This script does not. That said, you can use silence_filter.praat if you wish to apply the silence filter to the TextGrid files from this script. Just make sure to provide the corresponding sound files with the same names: e.g. TEST_DR1_FAKS0_SA1.WAV for TEST_DR1_FAKS0_SA1.TextGrid.

Last updated: 12/4/2025
"""

__author__ = 'Hahn Koo (hahn.koo@sjsu.edu)'


import argparse, glob, sys
import numpy as np


def load_features(fn, separator, header, transpose):
	x = []
	with open(fn) as f:
		if header: h = f.readline()
		for line in f:
			x.append(np.array(line.strip().split(separator), dtype=float))
	out = np.array(x)
	if transpose: out = out.T
	return out

def load_offsets_or_durations(fn):
	x = {}
	with open(fn) as f:
		header = f.readline()
		for line in f:
			fname, val = line.strip().split(',')
			x[fname] = float(val)
	return x

def delta(x, window_size):
	"""Delta:

	delta_i[t] = sum_{k=1}^n k * (x_i[t+k] - x_i[t-k]) / sum_{k=1}^n 2*k^2
	"""
	delta = np.zeros_like(x)
	n = x.shape[1]
	x = np.pad(x, ((0, 0), (window_size, window_size)), mode='edge')
	norm = 0
	for k in range(1, window_size+1):
		delta += k * (x[:, window_size+k:window_size+k+n] - x[:, window_size-k:window_size-k+n])
		norm += 2 * k**2
	return delta / norm

def spectral_transition_measure(x, window_size):
	"""Spectral transition measure:

	d[t] = sum_{i=1}^D delta_i[t]**2 / D
	"""
	return (delta(x, window_size)**2).sum(axis=0) / x.shape[0]

def average_sides(x, window_size):
	n = x.shape[1]
	left = np.zeros_like(x)
	right = np.zeros_like(x)
	x = np.pad(x, ((0, 0), (window_size, window_size)), mode='edge')
	for k in range(window_size): left += x[:, k:k+n]
	left /= window_size
	for k in range(1, window_size+1): right += x[:, window_size+k:window_size+k+n]
	right /= window_size
	return left, right

def cosine_distance(x, window_size):
	"""Cosine distance:

	d[t] = 1 - cossim(avg(x[t-window_size:t]), avg(x[t+1:t+1+window_size]))
	"""
	n = x.shape[1]
	left, right = average_sides(x, window_size)
	dp = (left * right).sum(axis=0)
	left_norm = np.linalg.norm(left, axis=0)
	right_norm = np.linalg.norm(right, axis=0)
	cossim = dp / (left_norm * right_norm)
	return 1 - cossim

def log(x, eps=1e-10):
	mn = np.min(x)
	return np.log10(x - mn + eps)

def normalize(x, eps=1e-10):
	mx = np.max(x) + eps
	mn = np.min(x)
	return (x - mn) / (mx - mn)

def find_peaks(d, threshold):
	bigger_than_left = d[1:-1] > d[:-2]
	bigger_than_right = d[1:-1] > d[2:]
	bigger_than_threshold = d[1:-1] > threshold
	peaks = bigger_than_left * bigger_than_right * bigger_than_threshold
	return np.where(peaks == 1)[0] + 1

def peaks(d, peak_height, offset, frame_shift):
	p = find_peaks(d, peak_height)
	return p * frame_shift + offset

def save_as_textgrid(ofn, boundaries, duration):
	bs = [round(b, 6) for b in boundaries]
	bs = [0.0] + bs + [duration]
	stamps = [(bs[i], bs[i+1]) for i in range(len(bs)-1)]
	interval_name = 'phones'
	header = 'File type = "ooTextFile"\nObject class = "TextGrid"'
	header += '\n\nxmin = 0\nxmax = ' + str(duration)
	header += '\ntiers? <exists>\nsize = 1'
	subheader = '\nitem []:\n\titem[1]:'
	subheader += '\n\t\tclass = "IntervalTier"\n\t\tname = "' + interval_name + '"'
	subheader += '\n\t\txmin = 0\n\t\txmax = ' + str(duration)
	subheader += '\n\t\tintervals: size = ' + str(len(stamps)) 
	out = header + subheader
	for i, (st, et) in enumerate(stamps):
		if i == len(stamps)-1: et = min(et, duration)
		entry = '\n\t\t\tintervals [' + str(i+1) + ']'
		entry += '\n\t\t\txmin = ' + str(st)
		entry += '\n\t\t\txmax = ' + str(et)
		entry += '\n\t\t\ttext = ""'
		out += entry
	with open(ofn, 'w') as f: f.write(out)


if __name__ == '__main__':
	parser = argparse.ArgumentParser()
	parser.add_argument('--features', type=str)
	parser.add_argument('--separator', type=str, default='\t')
	parser.add_argument('--header', action='store_true')
	parser.add_argument('--transpose', action='store_true')
	parser.add_argument('--log_feature', action='store_true')
	parser.add_argument('--normalize_feature', action='store_true')
	parser.add_argument('--distance', type=str)
	parser.add_argument('--normalize_distance', action='store_true')
	parser.add_argument('--window_size', type=int, default=2)
	parser.add_argument('--offset', type=float, default=0.0)
	parser.add_argument('--offset_file', type=str)
	parser.add_argument('--duration_file', type=str)
	parser.add_argument('--peak_height', type=float, default=0.05)
	parser.add_argument('--frame_shift', type=float, default=0.01)
	parser.add_argument('--outdir', type=str)
	parser.add_argument('--textgrid', action='store_true')
	args = parser.parse_args()
	offsets = {}
	if args.offset_file: offsets = load_offsets_or_durations(args.offset_file)
	durations = {}
	if args.duration_file: durations = load_offsets_or_durations(args.duration_file)
	for fn in glob.glob(args.features):
		handle = fn.split('/')[-1]
		sys.stderr.write('# Segmenting ' + handle + '...\r')
		x = load_features(fn, args.separator, args.header, args.transpose)
		if args.normalize_feature: x = normalize(x)
		if args.log_feature: x = log(x)
		if args.distance == 'cosine': d = cosine_distance(x, args.window_size)
		else: d = spectral_transition_measure(x, args.window_size)
		if args.normalize_distance: d = normalize(d)
		p = peaks(d, args.peak_height, offsets.get(handle, args.offset), args.frame_shift)
		ofn = args.outdir + '/' + '.'.join(handle.split('.')[:-1])
		duration = durations.get(handle, args.frame_shift * len(d) + offsets.get(handle, args.offset))
		if args.textgrid:
			ofn = ofn + '.TextGrid'
			save_as_textgrid(ofn, p, duration)
		else:
			with open(ofn, 'w') as of:
				for b in p: of.write(str(b) + '\n')
	sys.stderr.write('\n# Segmentation complete. Outputs saved in ' + args.outdir + '.\n')
