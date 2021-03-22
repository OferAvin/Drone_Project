import manual_control_pygame as drone
import DSI_to_Python as dsi
import threading, queue
import numpy as np


class Table:
    def __init__(self, size):
        self.size = size
        self.revision = 0
        self.table = np.ones([1, size])
        self.pickup = 0

    def add_prediction(self, prediction):
        self.table[0, self.revision % self.size] = prediction
        self.revision += 1

    def pick_up(self):
        if (self.pickup <= self.revision):
            toRet = self.table[0, self.pickup % self.size]
            self.pickup += 1
            return toRet




if __name__ == "__main__":
    command_size = 1000

    tcp = dsi.TCPParser('localhost', 8844)
    # drone1 = drone.FrontEnd()

    table = queue.Queue(0)
    tDrone = threading.Thread(target=drone.main ,args=(table,))
    tDsi = threading.Thread(target=tcp.example_plot, args=(table,))

    #tcp.example_plot()
    tDrone.start()
    tDsi.start()

