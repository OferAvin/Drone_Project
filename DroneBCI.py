#main script of droneBCI project

import droneCtrl as drone
import DSI_to_Python as dsi
import threading
import queue
import Show_Flashes
from multiprocessing import Process
import signal as sig
import Session as sess
from droneCtrl import Commands

if __name__ == "__main__":

    ans = input('Select Session Type:     0:Online   1:SSVEP training  2:MI training   3:Train MI Csp from file   4:Train MI Lda from file ')
    sessType = sess.SessionType(int(ans))
    # sessType = sess.SessionType.OfflineTrainCspMI

    if sessType == sess.SessionType.OfflineTrainCspMI or sessType == sess.SessionType.OfflineTrainLdaMI:
        eegSession = sess.Session(DSIparser=None)
        eegSession.train_model(sessType)

    else:

        #connect to DSI headset to read epochs
        DSIparser = dsi.TCPParser('localhost', 8844) #make sure that DSI streamer client port 8844 is active
        sig.signal(sig.SIGINT, DSIparser.onlineHandler) # Catch ctrl+C error

        #init eeg decoding session
        eegSession = sess.Session(DSIparser)

        if sessType == sess.SessionType.OfflineExpMI:
            eegSession.train_model(sessType)

        else:

            #start the SSVEP stimuli
            pFlicker = Process(target=Show_Flashes.main)
            pFlicker.start()

            if sessType == sess.SessionType.OfflineExpSSVEP:
                eegSession.train_model(sessType)

            else: #Online

                #commands queue
                CommandsQueue = queue.Queue(0)
                CommandsQueue.put([Commands.up, 'AUTO TAKE OFF']) #auto takeoff

                #start the online session
                tOnline = threading.Thread(target=eegSession.run_online, args=(CommandsQueue,))
                tOnline.start()

                #connect drone (drone video should apear together with the flickers while training)
                tDrone = threading.Thread(target=drone.run, args=(CommandsQueue,))
                tDrone.start()

                #stops with ctrl+C
                pFlicker.join() #kill
                tOnline.join()
                tDrone.join()
    # sys.exit()