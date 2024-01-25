# LPC Speech Synthesis

This MATLAB project implements Linear Predictive Coding (LPC) speech synthesis, a technique commonly used in speech processing. LPC synthesis involves analyzing the speech signal, estimating parameters, and then resynthesizing speech. The provided code reads an input audio file, processes it through LPC analysis, and synthesizes a speech signal based on the estimated parameters.

## Usage

1. **Prerequisites**: Ensure you have MATLAB

2. **Input Audio**: I have provided an audio file "G&VAdvanced_05.wav", but you can replace it with your desired audio file. Make sure the audio file is in the same directory as the script.

3. **Run the Script**: Execute the script in MATLAB.

4. **Listen to Synthesized Speech**: The script will play the synthesized speech and save it as a new audio file named "synth_{your_audiofile_name}.wav" in the same directory.

## Code Structure

- `main.m`: Main function that orchestrates the entire process.
- `processFrames.m`: Handles frame extraction, preemphasis, windowing, and pitch period estimation.
- `applyPreemphasis.m` and `applyHammingWindow.m`: Preemphasis and Hamming window application functions.
- `estimatePitchPeriod.m` and `calculateMDF.m`: Pitch period estimation using Minimum Difference Function (MDF).
- `LPCAnalysis.m`: LPC analysis to obtain LPC coefficients and residual signals.
- `decideVoicing.m`: Voicing decision based on zero-crossing rate and energy.
- `LPCSynthesis.m`: LPC synthesis to generate the final synthesized speech.
- `generateVoicedExcitation.m` and `generateUnvoicedExcitation.m`: Functions to generate voiced and unvoiced excitation signals.

## Parameters

- `frame_length`: Length of each analysis frame in seconds.
- `frame_shift`: Time shift between consecutive frames in seconds.
- `order`: LPC order (number of coefficients).
- `voiced_threshold_zc` and `voiced_threshold_energy`: Thresholds for voicing decision.

Enjoy experimenting with LPC speech synthesis! If you encounter any issues or have suggestions, please feel free to open an issue or contribute to the project.
