# Eufonia

Eufonia is an audio recording and analysis iOS application, helps users record voice samples and analyze various audio characteristics, providing raw audio statistics and machine learning evaluations of tempo and pitch, along volume classification, in order to better understand their vocal delivery. This app also includes VoiceOver support and clear labels for visually impaired users.

Eufonia is aimed at anyone needing to record and examine their voice characteristics, whether for practice sessions, linguistic research, or simply for better self-awareness of their vocal attributes.

![Simulator Screenshot - iPhone 16 Pro - 2024-12-18 at 23 55 41](https://github.com/user-attachments/assets/540aef02-cbc4-46c2-a7ce-25ec506803b7)


![Simulator Screenshot - iPhone 16 Pro - 2024-12-18 at 23 57 46](https://github.com/user-attachments/assets/88c45333-3d6a-495c-9c5d-0febe1d12756)

## Features
1.	Record and Save Audio Samples.
2.	View All Recordings.
3.	Editing and Deletion of Recordings:
Users can rename recordings to maintain an organized library and delete unwanted recordings through a convenient editing mode.

4.	Audio Analysis (Tempo, Pitch, Volume):
After stopping a recording, the app analyzes the audio to compute:
	•	Tempo (BPM): Detects and estimates the rhythmic tempo from the recorded voice.
	•	Pitch (Hz): Estimates the fundamental frequency, giving insights into how high or low the voice sounds.
	•	Volume (dBFS): Measures the loudness level of the recording, classifying it as low, moderate, or high volume.

5.	Machine Learning and Numerical Evaluations and Classification:
The app uses integrated ML models to provide evaluations based on the analyzed tempo and pitch, as well as numerical volume classification.

## Installation
1. Clone this repository: `git clone <https://github.com/DannyJr08/Eufonia.git`>
2. Open the project in Xcode.
3. Run the app on a simulator or connected device.

## Additional Information
It was also needed to code in Python in order to preprocess audio data for training models in Create ML. It traverses a directory of .wav files, extracts audio features (tempo, RMS energy, and fundamental frequency), and assigns numerical labels based on predefined criteria. The results are stored in CSV files. The model training was using the tabular regression approach.

## Credits
- [Kaggle Dataset]([https://github.com/realm/SwiftLint](https://www.kaggle.com/datasets/uwrfkaggler/ravdess-emotional-speech-audio?resource=download)) that served to collect data to train the ML models.
- Special thanks to my mentor Matteo Altobello.
