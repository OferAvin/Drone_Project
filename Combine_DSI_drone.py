import droneCtrl as drone
import DSI_to_Python as dsi
import threading
import queue
import Show_Flashes
from multiprocessing import Process
import signal as sig
from ModelDSI import trainingSession, onlineSession
import pickle

if __name__ == "__main__":
    tcp = dsi.TCPParser('localhost', 8844) #make sure that DSI streamer client port 8844 is active
    # Catch ctrl+C error
    sig.signal(sig.SIGINT, tcp.onlineHandler)
    # Create queue
    q = queue.Queue(0)

    # Thread and process
    tDrone = threading.Thread(target=drone.run, args=(q,))
    pFlicker = Process(target=Show_Flashes.main)

    # Start training + Flicker process
    pFlicker.start()
    ans = input('Train the model? Y/N')
    if ans.upper() == 'Y':
        model = trainingSession(tcp)    # Check for model existence
    else:
        model = pickle.load(open("TrainedLGBM.pkl", 'rb'))
    if not model:
        raise Exception("*****No model found in queue after training session*****")

    # After model is acquired, start the online session and the drone control.
    tDsiOnline = threading.Thread(target=onlineSession, args=(tcp, model, q))
    tDsiOnline.start()
    tDrone.start()

    # stops with ctrl+C
    pFlicker.join() #kill
    tDsiOnline.join()
    tDrone.join()
