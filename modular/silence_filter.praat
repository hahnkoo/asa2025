# Title: A Praat script for removing phone boundaries within silence intervals
# Author: Hahn Koo (hahn.koo@sjsu.edu)
# Last updated: 12/4/2025

clearinfo

## Procedures

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
 folder: "input sound directory", "./"
 word: "sound file extension (case-sensitive)", "WAV"
 folder: "input textgrid directory", "./"
 word: "textgrid file extension (case-sensitive)", "TextGrid"
 folder: "output directory", "./"
 clicked = endPause: "Continue", 1

beginPause: "Configure silence filter."
 real: "pitch floor (Hz)", 100
 real: "silence threshold (dB)", -25.0
 real: "minimum silent interval (s)", 0.1
 real: "minimum sounding interval (s)", 0.1
 real: "boundary margin (s)", 0.02
 clicked = endPause: "Continue", 1

snd_list = Create Strings as file list: "snd_list", input_sound_directory$ + "/*" + sound_file_extension$

n_snds = Get number of strings
for snd_index from 1 to n_snds
 select snd_list
 snd$ = Get string: snd_index
 snd = Read from file: input_sound_directory$ + "/" + snd$
 name$ = selected$("Sound", 1)
 writeInfoLine: "Processing ", snd_index, " out of ", n_snds, ": ", name$
 grd$ = name$ + "." + textgrid_file_extension$
 grd = Read from file: input_textgrid_directory$ + "/" + grd$
 @table_silences: snd, pitch_floor, silence_threshold, minimum_silent_interval, minimum_sounding_interval
 silence_table_sel = selected("Table", 1)
 @remove_silent_boundaries: grd, silence_table_sel, boundary_margin
 Save as text file: output_directory$ + "/" + name$ + ".TextGrid"
 removeObject: snd, grd, silence_table_sel
endfor
removeObject: snd_list
appendInfoLine: "Silence filtering all complete.", newline$, "Revised TextGrids saved in " + output_directory$