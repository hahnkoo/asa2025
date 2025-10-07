# A Praat script for unsupervised phonetic segmentation based on spectro-temporal representation 

The Praat script (```phonetic_segmentation.praat```) aims to segment an input recording into phone-sized intervals. It does so by converting the recording into a spectro-temporal representation, measures how the representation differs between either side of each frame in the recording, and draws boundaries at peaks of the difference measure. The user can choose from various types of representation (e.g. mel spectrogram, cochleagram) and measure (e.g. cosine distance, spectral transition measure) as well as configure how they are computed and interpreted for peak detection. The segmentation result is saved as a TextGrid file with one interval tier named "phones" in which interval boundaries correspond to segment boundaries. Given that the goal here is segmentation not transcription, the intervals are not labeled. 

## Usage

Run [Praat](https://www.fon.hum.uva.nl/praat/), ```Open Praat script...```, and select ```phonetic_segmentation.praat``` on your computer.

