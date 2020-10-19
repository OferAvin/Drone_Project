%% SSVEP Offline Main Script
% This script runs all the steps in order. Training -- Pre-processing --
% Data segmentation -- Feature extraction -- Model training.
% Two important points:
% 1. Remember the ID number (without zero in the beginning) for each different person
% 2. Remember the Lab Recorder filename and folder.

% Prequisites: Refer to the installation manual for required softare tools.

% This code is part of the BCI-4-ALS Course written by Asaf Harel
% (harelasa@post.bgu.ac.il) in 2020. You are free to use, change, adapt and
% so on - but please cite properly if published.

%% Run stimulation and record EEG data
recordingFolder = SSVEP1_Training_Scaffolding();
disp('Finished stimulation and EEG recording. Stop the LabRecorder and press any key to continue...');
pause;

%% Run pre-processing pipeline on recorded data
SSVEP2_Preprocess_Scaffolding(recordingFolder);
disp('Finished pre-processing pipeline. Press any key to continue...');
pause;

%% Segment data by trials
SSVEP3_SegmentData_Scaffolding(recordingFolder);
disp('Finished segmenting the data. Press any key to continue...');
pause;

%% Extract features and labels
SSVEP4_ExtractFeatures_Scaffolding(recordingFolder);
disp('Finished extracting features and labels. Press any key to continue...');
pause;

%% Train a model using features and labels
SSVEP5_LearnModel_Scaffolding(recordingFolder);
disp('Finished training the model. The offline process is done!');


