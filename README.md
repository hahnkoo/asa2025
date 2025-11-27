# A Praat script for unsupervised phonetic segmentation based on spectro-temporal representation 

The Praat script (```phonetic_segmentation.praat```) aims to segment an input recording into phone-sized intervals. It does so by converting the recording into a spectro-temporal representation, measures how the representation differs between either side of each frame in the recording, and draws boundaries at peaks of the difference measure. The user can choose from various types of representation (e.g. mel spectrogram, MFCCs) and measure (e.g. cosine distance, spectral transition measure) as well as configure how they are computed and interpreted for peak detection. The segmentation result is saved as a TextGrid file with one interval tier named "phones" in which interval boundaries correspond to segment boundaries. Given that the goal here is segmentation not transcription, the intervals are not labeled. 

## Usage

Run [Praat](https://www.fon.hum.uva.nl/praat/), ```Open Praat script...```, and select ```phonetic_segmentation.praat``` on your computer.

## Arguments 

Upon starting the program, you will be prompted for arguments to the script in a series of pop-up windows.

### Input and output

Specify where the input files are and where to save the output TextGrid files. In addition, specify the type of input files and their file extension. The file type is about whether each input file is a proper ```sound file``` (e.g. ```wav``` or ```mp3``` files) or a ```comma-separated file``` containing a table of numbers (see below). The file extension is a suffix (e.g. ```wav```, ```csv```) following a period common to all input files. Note that this field is case-sensitive (e.g. ```wav``` and ```WAV``` are different) and that the period should not be specified at the beginning (e.g. ```wav``` rather than ```.wav```). 

#### Comma-separated files as input

This option allows you to use representations not available in Praat for segmentation: e.g. representations from semi-supervised models for automatic speech recognition such as Wav2Vec2 (Baevski et al., 2020) and Whisper (Radford et al., 2023) as well as spectro-temporal representations other audio-processing softwares such as [librosa](https://librosa.org/). Each comma-separated file should specify a table listing of feature vectors representing some audio recording frame by frame: one row per frame and one column per feature vector dimension. The table must have a header specifying what each dimension (column) is although it can be arbitrary or as simple as a mere listing of column indices. Of course, the columns must be separated by commas. 

### Spectro-temporal analysis 

For sound files as input, specify the type of spectro-temporal analysis to run followed by the analysis parameters. Currently, the script allows the following types of spectro-temporal analysis available in Praat:

 * To Spectrogram... 
 * To MelSpectrogram... 
 * To MFCC... 
 * To LPC (burg)... 
 * To Cochleagram... 

For comma-separated files as input, specify the parameters for translating frame indices to time in seconds:

 * time step 
 * offset (time of first frame in seconds) 

Accordingly, the time associated with the nth frame would be $(n-1) \times \text{time step} + \text{offset}$ seconds.

### Post-processing

Each input file is represented as a feature matrix as a result of running some spectro-temporal analysis in Praat or directly loading it from a comma-separated file. It may be beneficial to further process the values in the matrix. Specify 

 * whether to normalize the values so that they are between 0 and 1 (```normalize feature matrix```)
 * whether to convert the values to the log of values (```log feature matrix```)

Values are normalized by $\frac{x - \min}{\max - \min + 10^{-10}}$ for some value $x$ where $\min$ and $\max$ are the minimum and maximum of all values. The small constant $10^{-10}$ is added to prevent the zero division error. Values are converted to the log of values by $\log_{10} (x - \min + 10^{-10})$ with the small constant added to prevent the math domain error. If both options are turned on, the normalization applies before the log conversion. 

### Distance measure and peak finding

For each column vector in the feature matrix, the script measures the distance between the vectors to the left and the vectors to the right. Specify

 * which distance measure to use (```distance measure```)
 * how many vectors on each side (```window size```)

Currently, two options are available for the distance measure: delta (to be precise, spectral transition measure; Furui, 1986; Dusan & Rabiner, 2006) and cosine distance. The spectral transition measure computes the mean of squares of deltas across the vector dimensions. The cosine distance is 1 minus the cosine similarity between the mean of left vectors and the mean of right vectors.

It may be beneficial to normalize the distance measures, especially when using the spectral transition measure. So specify

 * whether to normalize the distance measures so that they are between 0 and 1 (```normalize distance measure```) 

To identify peaks in the distance measures across the frames (column vectors), specify

 * threshold peak height (```peak height```)

A distance measure is considered a peak if it is larger than the values to the left and right as well as larger than the threshold.

### Silence filtering

Specify whether to use Praat's silence detection command ```Sound: To TextGrid (silences)``` to revise boundaries: add silent interval boundaries and remove any boundaries within a silent interval. To do so, specify the parameters for the silence detection command: 

 * pitch floor in Hz to smooth the intensity curve (```pitch floor```)
 * maximum silence intensity value in dB (```silence threshold```)
 * minimum duration for an interval to be considered silent (```minimum silent interval```)
 * minimum duration for an interval to be considered not silent (```minimum sounding interval```)

Comparable silent interval boundaries may have already been added but located a little differently. To avoid such redundancies, existing boundaries on either side of a silent interval within a margin are removed. So in addition, specify 

 * width of the margin in seconds (```boundary margin```)

## Performance

Performance varies with different settings. The following seemed to yield the best performance when evaluated on the standard test set of the TIMIT corpus (1,680 recordings, 62,465 manually identified phone-level boundaries):

 * analysis type: mel spectrogram
 * window length (s): 0.025
 * time step (s): 0.01
 * first filter frequency (mel): 69
 * distance between filters (mel): 69
 * maximum frequency (mel): 0
 * normalize feature matrix: yes
 * log feature matrix: yes
 * distance measure: delta (spectral transition measure)
 * window size: 2
 * normalize distance measure: yes
 * peak height: 0.05
 * apply silence filter: no

Defining a hit as a hypothesized boundary occurring within 20 milliseconds of a reference boundary in the TIMIT corpus, the above resulted in precision = 0.826, recall = 0.735, F-score = 0.778, and R-value (Räsänen et al., 2009) = 0.802.

## References

Baevski, A., Zhou, Y., Mohamed, A., & Auli, M. (2020). Wav2vec 2.0: A framework for self-supervised learning of speech representations. *Advances in Neural Information Processing Systems, 33,* 12449-12460.

Dusan, S., & Rabiner, L. (2006). On the relation between maximum spectral transition positions and phone boundaries. In *Proceedings of INTERSPEECH 2026* (pp. 645-648).

Furui, S. (1986). On the role of spectral transition for speech perception. *The Journal of the Acoustical Society of America, 80*(4), 1016-1025.

Radford, A., Kim, J. W., Xu, T., Brockman, G., McLeavey, C., & Sutskever, I. (2023). Robust speech recognition via large-scale weak supervision. In *Proceedings of the International Conference on Machine Learning* (pp. 28492-28518).

Räsänen, O. J., Laine, U. K., & Altosaar, T. (2009). An improved speech segmentation quality measure: the r-value. In *Proceedings of INTERSPEECH 2009* (pp. 1851-1854).
