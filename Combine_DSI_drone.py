import manual_control_pygame as drone
import DSI_to_Python as dsi
import threading, queue
import Show_Flashes
from multiprocessing import Process


if __name__ == "__main__":
    # TODO: Threads!! which thread is running when and how?
    tcp = dsi.TCPParser('localhost', 8844)
    # drone1 = drone.FrontEnd()


    table = queue.Queue(0)
    tDsiTraining = threading.Thread(target=tcp.trainingSession, args=(table,))
    tDrone = threading.Thread(target=drone.main, args=(table,))
    pFlicker = Process(target=Show_Flashes.main)

    tDsiTraining.start()
    pFlicker.start()

    # TODO: is it smart? at the moment it is the best solution i have found to time the threads.
    # Do not continue to the drone control and online session, without having a model from the training session.
    model = None
    while not model:
        model = table.get()
    # TODO: Make sure the threads got killed.

    # After model is acquired, start the online session and the drone control.
    tDsiOnline = threading.Thread(target=tcp.trainingSession, args=(table, model))
    tDsiOnline.start()
    tDrone.start()


