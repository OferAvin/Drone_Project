import manual_control_pygame as drone
import DSI_to_Python as dsi
import threading

if __name__ == "__main__":
    tcp = dsi.TCPParser('localhost', 8844)
    tcp.example_plot()
    t = threading.Thread(target=drone.main())
    t.start()