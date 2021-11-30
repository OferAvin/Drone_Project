#train, predict SSVEP model

import mne
from scipy import signal
from lightgbm import LGBMClassifier
import pyttsx3
import numpy as np
import pandas as pd
import time
from droneCtrl import Commands

def signalProc(signalArray, DSIparser):
    """
    "Signal processing function" that responsible for cleaning,  channel selection,  feature extraction
      input:data chunk nparray(n_channels , n_samples), DSIparser
      output:  features vector
    """

    #filtering params
    low_pass = 4
    high_pass = 40
    #pwelch params
    nperseg = 500
    noverlap = 450
    #electrodes of interest
    electrodes = ["O1"]#, "O2"]

    # Get electrode indeces from the montage
    elec = []
    for el in electrodes:
        elec.append(DSIparser.montage.index(el))

    # Filter the data
    Filtered = mne.filter.filter_data(signalArray[elec,:], sfreq=DSIparser.fsample, l_freq=low_pass, h_freq=high_pass, verbose=0)
    # PSD
    _, Pxx_den = signal.welch(Filtered, fs=DSIparser.fsample, nperseg=nperseg, noverlap=noverlap, scaling='spectrum', axis=1)

    # use the whole PSD as features
    featuresDF = pd.DataFrame(Pxx_den.flatten())

    return featuresDF

def predictModel(signalArray, model, DSIparser):
    """
    model prediction
    input: signalArray, model, DSIparser
    output: prediction, accuracy
    """

    # Process the data
    curTrialData = signalProc(signalArray, DSIparser)
    # Predict
    pred  = model.predict(curTrialData.transpose())
    pred_prob  = model.predict_proba(curTrialData.transpose())
    return Commands(pred), pred_prob.max()

def trainModel(DSIparser, epoch_len_sec):
    """
    Calibration and creation of new model by offline training of SSVEP Paradigm
    input: DSIparser
    output: trained model - output is written into the queue
    """

    # Parameters
    trials_N = 15  # Trials per condition
    target_frq = [6, 7.5, 11] # Used frequencies
    frq_N = len(target_frq)
    action = [Commands.idle, Commands.up, Commands.down, Commands.flip]

    # Text to speech engine
    engine = pyttsx3.init()
    triggerText = ['Do not focus on the blinks', 'Focus on the upper blink',
                   'focus on the bottom blink', 'Close your eyes']

    # Allocation
    labels = np.zeros((frq_N + 1) * trials_N)
    featuresDF = pd.DataFrame()

    # Collecting labeled data
    for i in range(frq_N + 1):
        # Say the current stimuli to focus on
        engine.say(triggerText[i])
        engine.runAndWait()
        iTrial = 0
        while iTrial < trials_N:

            time.sleep(epoch_len_sec/2)  # Wait 1 second
            signalArray = DSIparser.get_epoch(epoch_len_sec)
            if signalArray is None: #epoch samples are not ready yet
                continue

            # Process the data
            curTrialData = signalProc(signalArray, DSIparser)
            # Append to the data frame
            featuresDF = pd.concat([featuresDF, curTrialData], axis=1)
            # Save current trial label
            labels[iTrial + trials_N * (i - 1)] = action[i].value

            print('Collecting SSVEP training data:  ' + str(action[i]) + ' trial #' + str(iTrial))

            iTrial += 1

    # Say training session is over
    engine.say('Open your eyes')
    engine.runAndWait()

    # Train classifier
    model = LGBMClassifier()
    model.fit(featuresDF.transpose(), labels)

    return model
