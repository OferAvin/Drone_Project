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

    #connect to DSI headset to read epochs
    DSIparser = dsi.TCPParser('localhost', 8844) #make sure that DSI streamer client port 8844 is active
    sig.signal(sig.SIGINT, DSIparser.onlineHandler) # Catch ctrl+C error
    # #run offline
    # DSIparser = None;

    #init eeg decoding session
    eegSession = sess.Session(DSIparser)

    #commands queue
    CommandsQueue = queue.Queue(0)
    CommandsQueue.put([Commands.up, 'AUTO TAKE OFF']) #auto takeoff

    #present main window (now only starts the SSVEP stimuli)
    pFlicker = Process(target=Show_Flashes.main)
    pFlicker.start()

    #train/load models
    ans = input('Train MI model? Y/N')
    load_model_flg = ans.upper() == 'N'
    load_recorded_trials_flg = False
    if load_model_flg == False:
        ans = input('Load trials from file? Y/N')
        load_recorded_trials_flg = ans.upper() == 'Y'
    eegSession.trainMImodel(load_recorded_trials_flg, load_model_flg)
    ans = input('Train SSVEP model? Y/N')
    eegSession.trainSSVEPmodel(ans.upper() == 'N')

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
