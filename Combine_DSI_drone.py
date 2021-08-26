import manual_control_pygame as drone
import DSI_to_Python as dsi
import threading
import queue
import Show_Flashes
from multiprocessing import Process
import signal as sig
from ModelDSI import trainingSession, onlineSession
import pickle
from manual_control_pygame import Commands

if __name__ == "__main__":
    tcp = dsi.TCPParser('localhost', 8844)
    # Catch ctrl+C error
    sig.signal(sig.SIGINT, tcp.onlineHandler)
    # Create queue
    q = queue.Queue(0)
    # q.put([Commands(6), None, 0])
    # q.put([Commands(6), None, 0])
    # q.put([Commands(69), None, 0])
    # q.put([Commands(7), None, 0])
    # q.put([Commands(7), None, 0])

    # Thread and process
    tDrone = threading.Thread(target=drone.main, args=(q,))
    pFlicker = Process(target=Show_Flashes.main)

    # Start training + Flicker process
    pFlicker.start()
    ans = input('Trainn ew model? Y/N')
    if ans.upper() == 'Y':
        model = trainingSession(tcp)    # Check for model existence
    else:
        model = pickle.load(open("TrainedLGBM.pkl", 'rb'))
    if not model:
        raise Exception("*****No model found in queue after training session*****")
    #TODO add option to load model

    # After model is acquired, start the online session and the drone control.
    tDsiOnline = threading.Thread(target=onlineSession, args=(tcp, model, q))
    tDsiOnline.start()
    tDrone.start()


