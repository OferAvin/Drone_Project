import pickle
import numpy as np
import pandas as pd
import threading
import time
import mne
from scipy import signal
from lightgbm import LGBMClassifier
import pyttsx3
import datetime
from droneCtrl import Commands

def signalProc(signalArray, elecMonatage):
    """
    "Signal processing function" that responsible for cleaning,  channel selection,  feature extraction
      input:data chunk nparray(n_channels , n_samples), electrode montage
      output:  Pandas DataFrame of Features
    """
    # TODO: Parameters should come from a YAML file
    low_pass = 4
    high_pass = 40
    Hz = 300
    # Choosing electrodes (Using only occipital)
    elec = np.zeros((1, 2))
    # TODO: the electrodes indexes are in the DSI object (what does it mean to the function signature?)
    #  should we pass the object?  it cannot come from a YAML, because the montage is set in the DSI object.
    elec[0, 0] = elecMonatage.index('O1')
    elec[0, 1] = elecMonatage.index('O2')
    elec = elec.astype(int)

    # Choose electrodes
    signalArray = signalArray[elec[0], :]
    # Filtering the data
    Filtered = mne.filter.filter_data(signalArray, sfreq=Hz, l_freq=low_pass, h_freq=high_pass, verbose=0)
    # Welch
    # TODO: Enter the welch parameters to the YAML file as well.
    f, Pxx_den = signal.welch(Filtered, Hz, nperseg=500, noverlap=450, scaling='spectrum')

    # Flatten the power spectrum
    features = Pxx_den.flatten()
    # Convert to data frame
    featuresDF = pd.DataFrame(features)
    # Return data frame
    return featuresDF


def trainModel(dataFrame, labels):
    # Create model object
    model = LGBMClassifier()

    # Fit
    model.fit(dataFrame.transpose(), labels)

    # Save model file TODO: How do we want to save the model, should we add a default parameter?
    pkl_filename = "TrainedLGBM.pkl"
    with open(pkl_filename, 'wb') as file:
        pickle.dump(model, file)

    return model


def predictModel(dataFrame, model):
    # Predict
    pred = model.predict(dataFrame.transpose())

    # Convert to ENUM
    pred = Commands(pred)

    # Return prediction value
    return pred

def trainingSession(DSIparser):
    """
    Calicration and creation of new model by offline trainging of SSVEP Paradigm
    input: table - queue
    output: trained model - output is written into the queue
    """
    data_thread = threading.Thread(target=DSIparser.parse_data)
    data_thread.start()
    # TODO: Ofer is making a YAML file, will be implanted here instead of all those parameters
    Hz = 300
    chunk_t = 2
    trials_N = 15  # Trials per condition

    # Let the signal accumulate before start
    time.sleep(chunk_t * 2)

    # Used frequencies
    target_frq = [6, 7.5, 11]
    action = [0, 6, 7, 69]  # Idle, Up, Down, Flip

    # Number of frequencies
    frq_N = len(target_frq)

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
        for trial in range(trials_N):
            # Save current trial label
            labels[trial + trials_N * (i - 1)] = action[i]
            # Wait for needed time
            time.sleep(chunk_t)
            # Take wanted samples (from the start of the trial until now)
            signalArray = DSIparser.signal_log[:, -chunk_t * Hz:]

            # Process the data
            curTrialData = signalProc(signalArray, DSIparser.montage)
            # Append to the data frame
            featuresDF = pd.concat([featuresDF, curTrialData], axis=1)

    # Say training session is over
    engine.say('Open your eyes')
    engine.runAndWait()

    # Train classifier
    model = trainModel(featuresDF, labels)

    # End recording and join threads
    DSIparser.done = True
    data_thread.join()

    # Write the model
    return model

    # TODO: Kill the thread? the DSI object is still needed....

def onlineSession(DSIparser, model, q):
    DSIparser.runOnline = True
    # TODO: Debug the threads things, something feels fishy
    # Start parse thread
    data_thread = threading.Thread(target=DSIparser.parse_data)
    data_thread.start()
    DSIparser.table = q

    # #DEBUG
    # coms = [Commands.up, Commands.up, Commands.stop]#, Commands.down, Commands.flip, Commands.up, Commands.flip, Commands.idle, Commands.stop]
    # i=0

    # TODO: All the parameters should come from a YAML file
    chunk_t = 2
    Hz = 300
    # TODO: Need to check what the ctrl+C kills, is it this thread or the entire run
    #  i checked, it kills the main thread. need to find better solution. (daemon thread?)
    while DSIparser.runOnline:  # To exit loop press ctrl+C
        time.sleep(chunk_t)  # Wait 2 seconds

        # Take wanted samples (from the start of the trial until now)
        signalArray = DSIparser.signal_log[:, -chunk_t * Hz:]

        # Process the data
        curTrialData = signalProc(signalArray, DSIparser.montage)
        # Append to the data frame
        y_pred = predictModel(curTrialData, model)

        # # DEBUG
        # y_pred = coms[i]
        # i += 1


        # Send prediction
        timeStamp = str(datetime.datetime.now())
        # Send to queue list of [ENUM1, ENUM2, TimeStamp]
        DSIparser.table.put([y_pred, None, timeStamp])
        print('Classifier output is: ' + str(y_pred) + 'at time ' + timeStamp)

        # # DEBUG
        # if i >= len(coms):
        #     break

    # End recording and join threads
    DSIparser.done = True
    data_thread.join()
