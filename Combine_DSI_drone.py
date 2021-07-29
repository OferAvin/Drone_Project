import manual_control_pygame as drone
import DSI_to_Python as dsi
import threading
import queue
import Show_Flashes
from multiprocessing import Process
import signal as sig

if __name__ == "__main__":
    # TODO: Threads!! which thread is running when and how?
    tcp = dsi.TCPParser('localhost', 8844)
    # drone1 = drone.FrontEnd()
    sig.signal(sig.SIGINT, tcp.onlineHandler)

    q = queue.Queue(0)
    # TODO : thread is not needed for training
    tDsiTraining = threading.Thread(target=tcp.trainingSession, args=(q,))
    tDrone = threading.Thread(target=drone.main, args=(q,))
    pFlicker = Process(target=Show_Flashes.main)
    # try:
    tDsiTraining.start()
    pFlicker.start()

    # TODO: is it smart? at the moment it is the best solution i have found to time the threads.
    # Do not continue to the drone control and online session, without having a model from the training session.


    # Stop the main code until training session thread has ended
    tDsiTraining.join()
    model = q.get()
    if not model:
        raise Exception("*****No model found in queue after training session*****")
    # except Exception as err:
    #     print(err)

    print('everything seems fine till now')
    # After model is acquired, start the online session and the drone control.
    tDsiOnline = threading.Thread(target=tcp.onlineSession, args=(model, q))
    tDsiOnline.start()
    tDrone.start()


