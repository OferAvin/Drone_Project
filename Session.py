# decode paradigms from EEG
import pickle
import threading
import time
import datetime
from droneCtrl import Commands
import SSVEPmodel
import bci4als

class Session:
    """
    A class of training and online sessions

    """

    def __init__(self, DSIparser):

        #memebers
        self.modelMI = None
        self.modelSSVEP = None
        self.DSIparser = DSIparser

        #constants
        self.modelMIfn = "TrainedMImodel.pkl"
        self.modelSSVEPfn = "TrainedSSVEPmodel.pkl"
        self.epoch_len_sec = 2
        self.acc_thresh = 0.5 #accuracy threshold

    def trainMImodel(self, load_model = False):
        # TODO:integrate bci4als training here
        return

        if load_model:
            self.modelMI = pickle.load(open(self.modelMIfn, 'rb'))
        else:
            self.modelMI = bci4als.ml_model.MLModel()
            self.modelMI.offline_training()

            with open(self.modelMIfn, 'wb') as file: #save model
                pickle.dump(self.modelMI, file)
        if not self.modelMI:
            raise Exception("*****Something went wrong: MI model not found*****")

    def trainSSVEPmodel(self, load_model = False):
        if load_model:
            self.modelSSVEP = pickle.load(open(self.modelSSVEPfn, 'rb'))
        else:
            data_thread = threading.Thread(target=self.DSIparser.parse_data)
            data_thread.start()
            self.modelSSVEP = SSVEPmodel.trainModel(self.DSIparser,self.epoch_len_sec)
            self.DSIparser.done = True
            data_thread.join()

            with open(self.modelSSVEPfn, 'wb') as file:  # save model
                pickle.dump(self.modelSSVEP, file)
        if not self.modelSSVEP:
            raise Exception("*****Something went wrong: SSVEP model not found*****")

    def run_online(self, CommandsQueue):

        self.DSIparser.runOnline = True

        # Start parse thread
        data_thread = threading.Thread(target=self.DSIparser.parse_data)
        data_thread.start()

        while self.DSIparser.runOnline:  # To exit loop press ctrl+C
            # TODO:  ctrl+C kills the main thread. need to find better solution. (daemon thread?)

            time.sleep(self.epoch_len_sec/2)  # Wait 1 second
            signalArray = self.DSIparser.get_epoch(self.epoch_len_sec)
            if signalArray is None: #epoch samples are not ready yet
                continue

            # Choose the best prediction
            command_pred = Commands.idle

            #TODO:
            # mi_pred, mi_acc = self.modelMI.online_predict(signalArray, self.modelMI)
            mi_acc = 0

            if mi_acc >= self.acc_thresh:
                command_pred = mi_pred
            ssvep_pred, ssvep_acc = SSVEPmodel.predictModel(signalArray, self.modelSSVEP, self.DSIparser)
            if ssvep_acc > mi_acc and ssvep_acc > self.acc_thresh:
                command_pred = ssvep_pred

            # Send prediction
            timeStamp = str(datetime.datetime.now())
            CommandsQueue.put([command_pred, timeStamp])
            print('Classifier output is:  ' + command_pred.name.upper() + '  at time ' + timeStamp)

        # End session and join threads
        self.DSIparser.done = True
        data_thread.join()
