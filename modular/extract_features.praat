# Title: A Praat script for extracting spectro-temporal features
# Author: Hahn Koo (hahn.koo@sjsu.edu)
# Last updated: 12/2/2025

clearinfo

## Procedures

procedure spec: sound_in, window_length_in, max_freq_in, time_step_in, freq_step_in, window_shape_in$
 select sound_in
 s = To Spectrogram: window_length_in, max_freq_in, time_step_in, freq_step_in, window_shape_in$
 s_matrix = To Matrix
 removeObject: s
 select s_matrix
endproc

procedure melspec: sound_in, window_length_in, time_step_in, first_filter_in, filter_distance_in, max_freq_in
 select sound_in
 s = To MelSpectrogram: window_length_in, time_step_in, first_filter_in, filter_distance_in, max_freq_in
 s_matrix = To Matrix: "no"
 removeObject: s
 select s_matrix
endproc

procedure mfcc: sound_in, n_coef_in, window_length_in, time_step_in, first_filter_in, filter_distance_in, max_freq_in, use_c0_in
 select sound_in
 s = To MFCC: n_coef_in, window_length_in, time_step_in, first_filter_in, filter_distance_in, max_freq_in
 s_matrix = To Matrix
 if use_c0_in
  select s
  n = Get number of frames
  c0## = zero## (1, n)
  for i from 1 to n
   c0##[1, i] = Get c0 value in frame: i
  endfor
 c0 = Create simple Matrix from values: "c0", c0##
 selectObject: c0, s_matrix
 sm = Merge (append rows)
 removeObject: c0, s_matrix
 s_matrix = sm
 endif
 removeObject: s
 select s_matrix
endproc

procedure lpc_burg: sound_in, prediction_order_in, window_length_in, time_step_in, preemphasis_frequency_in
 select sound_in
 s = To LPC (burg): prediction_order_in, window_length_in, time_step_in, preemphasis_frequency_in
 s_matrix = Down to Matrix (lpc)
 removeObject: s
 select s_matrix
endproc

procedure cochleagram: sound_in, time_step_in, frequency_resolution_in, window_length_in, forward_masking_time_in
 select sound_in
 s = To Cochleagram: time_step_in, frequency_resolution_in, window_length_in, forward_masking_time_in
 s_matrix = To Matrix
 removeObject: s
 select s_matrix
endproc

procedure normalize: matrix_in, eps_in
 select matrix_in
 mx = Get maximum
 mx = mx + eps_in
 mn = Get minimum
 Formula: "(self[row, col] - mn) / (mx - mn)"
endproc

procedure log: matrix_in, eps_in
 select matrix_in
 mn = Get minimum
 Formula: "log10(self[row, col] - mn + eps_in)"
endproc


## Main script

beginPause: "Specify input and output."
 folder: "input directory", "./"
 word: "file extension (case-sensitive)", "WAV"
 folder: "output directory", "./"
 clicked = endPause: "Continue", 1

beginPause: "Specify the type of spectral analysis."
 choice: "analysis type", 2
  option: "spectrogram"
  option: "mel spectrogram"
  option: "MFCC"
  option: "cochleagram"
  option: "LPC (burg)"
 clicked = endPause: "Continue", 1

if analysis_type$ == "spectrogram"
 beginPause: "Configure spectrogram analysis."
  real: "window length (s)", 0.025
  real: "maximum frequency (Hz)", 8000
  real: "time step (s)", 0.01
  real: "frequency step (Hz)", 20.0
  choice: "window shape", 6
   option: "square (rectangular)"
   option: "Hamming (raised sine-squared)"
   option: "Bartlett (triangular)"
   option: "Welch (parabolic)"
   option: "Hanning (sine-squared)"
   option: "Gaussian"
  clicked = endPause: "Continue", 1
elif analysis_type$ == "mel spectrogram"
 beginPause: "Configure mel spectrogram analysis."
  real: "window length (s)", 0.025
  real: "time step (s)", 0.01
  real: "first filter frequency (mel)", 69
  real: "distance between filters (mel)", 69
  real: "maximum frequency (mel)", 0.0
  clicked = endPause: "Continue", 1
elif analysis_type$ == "MFCC"
 beginPause: "Configure MFCC analysis."
  natural: "number of coefficients", 13
  real: "window length (s)", 0.025
  real: "maximum frequency (Hz)", 8000
  real: "time step (s)", 0.01
  real: "first filter frequency (mel)", 69
  real: "distance between filters (mel)", 69
  real: "maximum frequency (mel)", 0.0
  boolean: "use c0", 1
  clicked = endPause: "Continue", 1
elif analysis_type$ == "LPC (burg)"
 beginPause: "Configure LPC analysis."
  natural: "prediction order", 16
  real: "window length (s)", 0.025
  real: "time step (s)", 0.01
  real: "preemphasis frequency (Hz)", 50
  clicked = endPause: "Continue", 1
elif analysis_type$ == "cochleagram"
 beginPause: "Configure cochleagram analysis."
  real: "time step (s)", 0.01
  real: "frequency resolution (Bark)", 0.1
  real: "window length (s)", 0.025
  real: "forward masking time (s)", 0.025
  clicked = endPause: "Continue", 1
endif

beginPause: "Configure how to post-process the feature matrix."
 boolean: "normalize feature matrix", 1
 boolean: "log feature matrix", 1
 clicked = endPause: "Continue", 1

snd_list = Create Strings as file list: "snd_list", input_directory$ + "/*" + file_extension$

n_snds = Get number of strings
writeFileLine: output_directory$ + "/offsets.csv", "file,offset"
writeFileLine: output_directory$ + "/durations.csv", "file,duration"

for snd_index from 1 to n_snds
 select snd_list
 snd$ = Get string: snd_index
 writeInfoLine: "Extracting features ", snd_index, " out of ", n_snds, ": ", snd$

 snd = Read from file: input_directory$ + "/" + snd$
 duration = Get total duration
 if analysis_type$ == "spectrogram"
  @spec: snd, window_length, maximum_frequency, time_step, frequency_step, window_shape$
 elif analysis_type$ == "mel spectrogram"
  @melspec: snd, window_length, time_step, first_filter_frequency, distance_between_filters, maximum_frequency
 elif analysis_type$ == "MFCC"
  @mfcc: snd, number_of_coefficients, window_length, time_step, first_filter_frequency, distance_between_filters, maximum_frequency, use_c0
 elif analysis_type$ == "LPC (burg)"
  @lpc_burg: snd, prediction_order, window_length, time_step, preemphasis_frequency
 elif analysis_type$ == "cochleagram"
  @cochleagram: snd, time_step, frequency_resolution, window_length, forward_masking_time
 endif
 feature_matrix_sel = selected("Matrix", 1)
 name$ = selected$("Matrix", 1)
 fms_info$ = Info
 offset = extractNumber(fms_info$, "x1:")
 appendFileLine: output_directory$ + "/offsets.csv", name$ + ".txt,", offset
 appendFileLine: output_directory$ + "/durations.csv", name$ + ".txt,", duration

 if normalize_feature_matrix
  @normalize: feature_matrix_sel, 1e-10
 endif
 if log_feature_matrix
  @log: feature_matrix_sel, 1e-10
 endif

 Save as headerless spreadsheet file: output_directory$ + "/" + name$ + ".txt"

 removeObject: feature_matrix_sel
 removeObject: snd

endfor
removeObject: snd_list
appendInfoLine: "Loading all complete."
appendInfoLine: "Duration info saved in " + output_directory$ + "/durations.csv"
appendInfoLine: "Offset info saved in " + output_directory$ + "/offsets.csv"
appendInfoLine: "Features saved as csvs in " + output_directory$