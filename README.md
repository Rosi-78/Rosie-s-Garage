# Rosie-s-Garage
---
## Project1

A Project involveds a acoustic dataset of 0-9 3D models, data preprocessing code and a 2D CNN Model with 5-Fold Verification.

### Layout & Setup
0-9 3D print Models have their own various acoustic feature in a special ** Acoustic Field **. We place their respectively in an enclosed box, where lay a Speaker and a rotating platform equiped with microphone and a buzzer, but without beam.

### Raw Date Collection
A application based on a single-chip Microcomputer was developed to manipulate those equipements mentioned above. Parameter configurations are 3000Hz waveform,4500 Hz sound frequency of the Buzzer, 0.25r/s rotating speed of the platform. Each .wav file lasts for 60s.

### Dataset Construction
Firstly, 'AcousticFilter_Visulization.py' is responsible for sound filting and slicing. And 'Wav2Mat.py' turn these sound slices into numpy matrix for the subsequence CNN training.

### Model Training and Verification
Then it's the 'Train_CNN_2D.py' that constructs a simple CNN model to bridge these 3D Models to their own waveform. And we did a 5-Fold Test.

### Wed Presentation
'inference_api.py' is back end supporting 'index.html' front end to read user's file and feedback the classification result. It's necessary to click the 'echoEngine.bat' to activate conda env before using the web.  
---
