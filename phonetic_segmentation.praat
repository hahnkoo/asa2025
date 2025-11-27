# Title: A Praat script for unsupervised phonetic segmentation using spectro-temporal features
# Author: Hahn Koo (hahn.koo@sjsu.edu)
# Last updated: 11/26/2025

clearinfo

## Procedures

procedure load_sound:
 snd$ = chooseReadFile$: "Choose a sound file."
 if snd$ <> ""
  snd = Read from file... 'snd$'
 endif
 select snd
endproc

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

procedure pad: table_in, pad_size_in, pad_side_in$
 select table_in
 p = Copy: "padded"
 n_rows = Get number of rows
 for i from 1 to pad_size_in
  n_cols = Get number of columns
  if pad_side_in$ == "left"
   ci = 1
   vi = 2
  elif pad_side_in$ == "right"
   ci = n_cols + 1
   vi = n_cols
  endif
  Insert column (index): ci
  for j from 1 to n_rows
   v = Get value: j, vi
   Set value: j, ci, v
  endfor
 endfor
endproc

procedure delta: table_in, width_in
 @pad: table_in, width_in, "left"
 tp_left = selected("TableOfReal", 1)
 @pad: tp_left, width_in, "right"
 tp = selected("TableOfReal", 1)
 d = Copy: "delta"
 n_rows = Get number of rows
 n_cols = Get number of columns
 for i from 1 to n_rows
  for j from width_in+1 to n_cols-width_in
   vn = 0
   vd = 0
   select tp
   for k from 1 to width_in
    l = Get value: i, j-k
    r = Get value: i, j+k
    vn = vn + k * (r - l)
    vd = vd + 2 * k^2
   endfor
   v = vn / vd
   select d
   Set value: i, j, v 
  endfor
 endfor
 removeObject: tp_left, tp
 select d
 for j from 1 to width_in
  n_col = Get number of columns
  Remove column (index): n_col
  Remove column (index): 1
 endfor
endproc

procedure spectral_transition_measure: matrix_in, width_in
 select matrix_in
 t = To TableOfReal
 @delta: t, width_in
 d0 = selected("TableOfReal", 1)
 Formula: "self[row, col]^2"
 Formula: "if row > 1 then self[row-1, col] + self[row, col] else self fi"
 n_rows = Get number of rows
 Extract rows by number: {n_rows}
 d = selected("TableOfReal", 1)
 Formula: "self[row, col] / n_rows"
 removeObject: t, d0
 select d
endproc

procedure ngrams: table_in, n_in
 select table_in
 ngt = Copy: "ngrams"
 for i from 1 to n_in-1
  n_cols = Get number of columns
  Remove column (index): n_cols
 endfor
 ngm = To Matrix
 for i from 1 to n_in-1
  select table_in
  tempt = Copy: "temp"
  for j from 1 to i
   Remove column (index): 1
  endfor
  for k from i+1 to n_in-1
   n_cols = Get number of columns
   Remove column (index): n_cols
  endfor
  tempm = To Matrix
  selectObject: ngm, tempm
  ng = Merge (append rows)
  removeObject: tempt, tempm, ngm
  ngm = ng
 endfor
 removeObject: ngt
 select ngm
endproc

procedure dot_product: table_in_1, table_in_2
 select table_in_1
 n_rows = Get number of rows
 n_cols = Get number of columns
 m1## = zero##(n_rows, n_cols)
 for i from 1 to n_rows
  for j from 1 to n_cols 
   val = Get value: i, j
   m1##[i, j] = val
  endfor
 endfor
 select table_in_2
 n_rows = Get number of rows
 n_cols = Get number of columns
 m2## = zero##(n_rows, n_cols)
 for i from 1 to n_rows
  for j from 1 to n_cols
   val = Get value: i, j 
   m2##[i, j] = val
  endfor
 endfor
 m## = m1## * m2##
 dp = Create TableOfReal: "dot_product", n_rows, n_cols
 for i from 1 to n_rows
  for j from 1 to n_cols
   Set value: i, j, m##[i, j]
  endfor
 endfor
 Formula: "if row > 1 then self[row, col] + self[row-1, col] else self fi"
 dp_row = Extract rows by number: {n_rows}
 removeObject: dp
 select dp_row
endproc

procedure norm: table_in
 select table_in
 table = Copy: "table"
 Insert row (index): 1
 Formula: "if row > 1 then (self[row, col])^2 + self[row-1, col] else self fi"
 norm = Extract rows by number: {n_rows+1}
 removeObject: table
 select norm
 Formula: "sqrt(self[row, col])"
 Rename: "norm"
endproc

procedure average_matrix: matrix_in, window_size_in
 t = To TableOfReal
 tc = Copy: "average"
 @pad: t, window_size_in-1, "right"
 tp = selected("TableOfReal", 1)
 for i from 1 to window_size_in-1
  select tc
  n_rows = Get number of rows
  n_cols = Get number of columns
  for r from 1 to n_rows
   for c from 1 to n_cols
    select tp
    v = Get value: r, c+i
    select tc
    vc = Get value: r, c
    Set value: r, c, v + vc
   endfor
  endfor
 endfor
 removeObject: t, tp
 select tc
 Formula: "self[row, col] / window_size_in"
 @pad: tc, window_size_in, "left"
 left_table = selected("TableOfReal", 1)
 Rename: "left_table"
 for i from 1 to window_size_in
  n_cols = Get number of columns
  Remove column (index): n_cols
 endfor
 select tc
 @pad: tc, window_size_in, "right"
 right_table = selected("TableOfReal", 1)
 Rename: "right_table"
 for i from 1 to window_size_in
  Remove column (index): 1
 endfor
 removeObject: tc
 selectObject: left_table, right_table
endproc

procedure cosine_distance: left_in, right_in
 @dot_product: left_in, right_in
 dp = selected("TableOfReal", 1)
 @norm: left_in
 left_norm = selected("TableOfReal", 1)
 @norm: right_in
 right_norm = selected("TableOfReal", 1)
 n_cols = Get number of columns
 cd = Create TableOfReal: "cosine_distance", 1, n_cols
 for i from 1 to n_cols
  select dp
  dpi = Get value: 1, i
  select left_norm
  lni = Get value: 1, i
  select right_norm
  rni = Get value: 1, i
  select cd
  Set value: 1, i, 1 - dpi / (lni * rni)
 endfor
 select cd
 removeObject: dp, left_norm, right_norm
endproc

procedure find_peaks: distance_in, height_in
 select distance_in
 n_cols = Get number of columns
 peaks# = zero# (n_cols)
 for i from 2 to n_cols-1
  left = Get value: 1, i-1
  middle = Get value: 1, i
  right = Get value: 1, i+1
  if middle > left and middle > right and middle > height_in
    peaks#[i] = 1
  endif
 endfor
 pt = Create TableOfReal: "peaks", 1, n_cols
 for i from 1 to n_cols
  Set value: 1, i, peaks#[i]
 endfor
 select pt
endproc

procedure create_textgrid: sound_in
 select sound_in
 textgrid = To TextGrid: "phones", ""
 select textgrid
endproc

procedure create_textgrid_without_sound: peaks_in, frame_shift
 select peaks_in
 n_frames = Get number of columns
 et = frame_shift * (n_frames + 1)
 textgrid = Create TextGrid: 0.0, et, "phones", ""
 select textgrid
endproc

procedure add_to_textgrid: textgrid_in, peaks_in, frame_shift, offset
 select peaks_in
 n_cols = Get number of columns
 for i from 1 to n_cols
  select peaks_in
  is_peak = Get value: 1, i
  if is_peak == 1
   select textgrid_in
   Insert boundary: 1, (i-1) * frame_shift + offset
  endif
 endfor
 select textgrid_in
endproc

procedure table_silences: snd_in, pitch_floor_in, silence_threshold_in, minimum_silent_interval_in, minimum_sounding_interval_in
 select snd_in
 stg = To TextGrid (silences): pitch_floor_in, 0.0, silence_threshold_in, minimum_silent_interval_in, minimum_sounding_interval_in, "silent", "sounding"
 stb = Down to Table: "no", 6, "yes", "no"
 removeObject: stg
 select stb
endproc

procedure remove_silent_boundaries: segmented_textgrid_in, silence_table_in, boundary_margin_in
 selectObject: segmented_textgrid_in, silence_table_in
 ptg = selected("TextGrid", 1)
 stb = selected("Table", 1)
 select stb
 n_stb_rows = Get number of rows
 n_sil = 0
 for i from 1 to n_stb_rows
  t$ = Get value: i, "text"
  if t$ == "silent"
   ss[n_sil+1, 1] = Get value: i, "tmin"
   ss[n_sil+1, 2] = Get value: i, "tmax"
   n_sil = n_sil + 1
  endif
 endfor
 if n_sil > 0
  select ptg
  et = Get end time
  pb = Down to Table: "no", 6, "yes", "yes"
  n_ptg_rows = Get number of rows
  pbi = 1
  ssi = 1
  n_removed = 0
  more_to_check = 1
  while more_to_check
   select pb
   ptmax = Get value: pbi, "tmax" 
   if ptmax > ss[ssi, 1] - boundary_margin_in and ptmax <= ss[ssi, 2] + boundary_margin_in
    select ptg
    Remove right boundary: 1, pbi - n_removed
    n_removed = n_removed + 1
    pbi = pbi + 1
   elif ptmax < ss[ssi, 1] 
    pbi = pbi + 1
   endif
   if ptmax >= ss[ssi, 2]
    ssi = ssi + 1
   endif
   if pbi >= n_ptg_rows or ssi > n_sil
    more_to_check = 0
   endif
  endwhile
  select ptg
  for i from 1 to n_sil
   if ss[i, 1] > 0
    Insert boundary: 1, ss[i, 1]
   endif
   if ss[i, 2] < et - boundary_margin_in
    Insert boundary: 1, ss[i, 2]
   endif
  endfor
 removeObject: pb
 endif
 select ptg
endproc


## Main script

beginPause: "Specify input and output."
 folder: "input directory", "./"
 choice: "input type", 1
  option: "sound file"
  option: "comma-separated file"
 word: "file extension (case-sensitive)", "WAV"
 folder: "output directory", "./"
 clicked = endPause: "Continue", 1

if input_type$ == "sound file"
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
endif

if input_type$ == "comma-separated file"
 beginPause: "Specify parameters for the file."
  real: "time step (s)", 0.01
  real: "offset (time of first frame in seconds)", 0.0
  clicked = endPause: "Continue", 1
endif

beginPause: "Configure how to post-process the feature matrix."
 boolean: "normalize feature matrix", 1
 boolean: "log feature matrix", 1
 clicked = endPause: "Continue", 1

beginPause: "Configure distance measure and peak finding."
 choice: "distance measure", 1
  option: "delta (spectral transition measure)"
  option: "cosine distance"
 natural: "window size", 2
 boolean: "normalize distance measure", 1
 real: "peak height", 0.05
 clicked = endPause: "Continue", 1

beginPause: "Configure silence filter."
 boolean: "apply silence filter", 0
 real: "pitch floor (Hz)", 100
 real: "silence threshold (dB)", -25.0
 real: "minimum silent interval (s)", 0.1
 real: "minimum sounding interval (s)", 0.1
 real: "boundary margin (s)", 0.02
 clicked = endPause: "Continue", 1

if input_type$ == "sound file"
 snd_list = Create Strings as file list: "snd_list", input_directory$ + "/*" + file_extension$
elif input_type$ == "comma-separated file"
 snd_list = Create Strings as file list: "snd_list", input_directory$ + "/*" + file_extension$
endif

n_snds = Get number of strings
for snd_index from 1 to n_snds
 select snd_list
 snd$ = Get string: snd_index
 writeInfoLine: "Segmenting ", snd_index, " out of ", n_snds, ": ", snd$

 if input_type$ == "comma-separated file"
  snd = Read Table from comma-separated file: input_directory$ + "/" + snd$
  Down to Matrix
  feature_matrix_sel = selected("Matrix", 1)
  name$ = selected$("Matrix", 1)
 elif input_type$ == "sound file"
  snd = Read from file: input_directory$ + "/" + snd$
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
 endif

 if normalize_feature_matrix
  @normalize: feature_matrix_sel, 1e-10
 endif
 if log_feature_matrix
  @log: feature_matrix_sel, 1e-10
 endif

 if distance_measure$ == "delta (spectral transition measure)"
  @spectral_transition_measure: feature_matrix_sel, window_size
 elif distance_measure$ == "cosine distance"
  @average_matrix: feature_matrix_sel, window_size
  left_sel = selected("TableOfReal", 1)
  right_sel = selected("TableOfReal", 2) 
  @cosine_distance: left_sel, right_sel
  removeObject: left_sel, right_sel
 endif

 distm_sel = selected("TableOfReal", 1)
 distmm_sel = To Matrix
 removeObject: distm_sel
 if normalize_distance_measure
  @normalize: distmm_sel, 1e-10
 endif
 distm_sel = To TableOfReal
 @find_peaks: distm_sel, peak_height
 peaks_sel = selected("TableOfReal", 1)
 if input_type$ == "sound file"
  @create_textgrid: snd
 elif input_type$ == "comma-separated file"
  @create_textgrid_without_sound: peaks_sel, time_step
 endif
 textgrid_sel = selected("TextGrid", 1)
 @add_to_textgrid: textgrid_sel, peaks_sel, time_step, offset

 if apply_silence_filter
  @table_silences: snd, pitch_floor, silence_threshold, minimum_silent_interval, minimum_sounding_interval
  silence_table_sel = selected("Table", 1)
  @remove_silent_boundaries: textgrid_sel, silence_table_sel, boundary_margin
  removeObject: silence_table_sel
 endif

 Save as text file: output_directory$ + "/" + name$ + ".TextGrid"
 removeObject: feature_matrix_sel, distmm_sel, distm_sel, peaks_sel
 removeObject: snd, textgrid_sel


endfor
removeObject: snd_list
appendInfoLine: "Segmentation all complete.", newline$, "TextGrids saved in " + output_directory$









