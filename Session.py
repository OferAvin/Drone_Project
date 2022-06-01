# decode paradigms from EEG

from enum import Enum
class SessionType(Enum):
    Online = 0
    OfflineExpSSVEP = 1
    OfflineExpMI = 2
    OfflineTrainCspMI = 3
    OfflineTrainLdaMI = 4

import pickle
import time
import datetime
from droneCtrl import Commands
import SSVEPmodel

import sys
sys.path.append('../bci4als/')
from examples.offline_training import offline_experiment
import src.bci4als.eeg as eeg

class Session:
    """
    A class of training and online sessions

    """

    def __init__(self, DSIparser, num_trials):

        #memebers
        self.modelMI = None
        self.modelSSVEP = None
        self.DSIparser = DSIparser

        #constants
        self.modelMIfn = "TrainedMImodel.pkl"
        self.modelSSVEPfn = "TrainedSSVEPmodel.pkl"
        self.epoch_len_sec = 2
        self.acc_thresh = 0.5 #accuracy threshold

        self.eeg = eeg.EEG(DSIparser, self.epoch_len_sec)

    def train_model(self, sessType: SessionType):
        if sessType == SessionType.Online:
            raise Exception("run Online directly with run_online!")
        elif sessType == SessionType.OfflineExpSSVEP:
            self.eeg.on()
            self.modelSSVEP = SSVEPmodel.trainModel(self.DSIparser,self.epoch_len_sec)
            self.eeg.off()
            with open(self.modelSSVEPfn, 'wb') as file:  # save SSVEP model
                pickle.dump(self.modelSSVEP, file)
        else:
            self.modelMI = pickle.load(open(self.modelMIfn, 'rb'))
            if not self.modelMI and sessType != SessionType.OfflineExpMI:
                raise Exception("*****Something went wrong: MI/SSVEP model not found*****")
            self.modelMI = offline_experiment(self.eeg, self.modelMI, sessType)
            with open(self.modelMIfn, 'wb') as file: #save MI model
                pickle.dump(self.modelMI, file)

    def run_online(self, CommandsQueue):

        playback_flg = False

        self.modelMI = pickle.load(open(self.modelMIfn, 'rb'))
        self.modelSSVEP = pickle.load(open(self.modelSSVEPfn, 'rb'))
        if not self.modelMI or not self.modelSSVEP:
            raise Exception("*****Something went wrong: MI/SSVEP model not found*****")

        self.DSIparser.runOnline = True
        self.eeg.on()

        if playback_flg:
            with open('SSVEPtraindata.pkl', 'rb') as file:
                recordedSignal = pickle.load(file)
                featuresDF = pickle.load(file)
                labels = pickle.load(file)
            cnt = 0

        while self.DSIparser.runOnline:  # To exit loop press ctrl+C
            # TODO:  ctrl+C kills the main thread. need to find better solution. (daemon thread?)

            time.sleep(self.epoch_len_sec/2)  # Wait 1 second

            if playback_flg:
                signalArray = recordedSignal[cnt, :, :]
                print('  played label is: ' + Commands(labels[cnt]).name.upper())
                cnt += 1
                if cnt >= len(labels):
                    break
            else:
                signalArray = self.eeg.get_board_data()
                if signalArray is None: #epoch samples are not ready yet
                    continue

            # Choose the best prediction
            command_pred = Commands.idle
            mi_pred, mi_acc = self.modelMI.online_predict(signalArray, self.eeg) # see bci4als/src/bci4als/experiments/online.py, try bci4als/examples/online_training.py
            if mi_acc >= self.acc_thresh:
                command_pred = mi_pred
            ssvep_pred, ssvep_acc = SSVEPmodel.predictModel(signalArray, self.modelSSVEP, self.DSIparser)
            if ssvep_acc > mi_acc and ssvep_acc > self.acc_thresh:
                command_pred = ssvep_pred

            # Send prediction
            timeStamp = str(datetime.datetime.now())
            CommandsQueue.put([command_pred, timeStamp])
            print('Classifier output is:  ' + command_pred.name.upper() + '  at time ' + timeStamp)

        self.eeg.off()
