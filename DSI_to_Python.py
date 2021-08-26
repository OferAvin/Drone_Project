# DSI_to_Python v.1.0 BETA The following script can be used to receive DSI-Streamer Data Packets through
# DSI-Streamer's TCP/IP Protocol. It contains an example parser for converting packet bytearrays to their
# corresponding formats described in the TCP/IP Socket Protocol Documentation (
# https://wearablesensing.com/downloads/TCPIP%20Support_20190924.zip). The script involves opening a server socket on
# DSI-Streamer and connecting a client socket on Python.

# As of v.1.0, the script outputs EEG data and timestamps to the command window. In addition, the script is able to
# plot the data in realtime. Keep in mind, however, that the plot functionality is only meant as a demonstration and
# therefore does not adhere to any current standards. The plot function plots the signals on one graph, unlabeled. To
# verify correct plotting, one can introduce an artifact in the data and observe its effects on the plots.

# The sample code is not certified to any specific standard. It is not intended for clinical use.
# The sample code and software that makes use of it, should not be used for diagnostic or other clinical purposes.
# The sample code is intended for research use and is provided on an "AS IS"  basis.
# WEARABLE SENSING, INCLUDING ITS SUBSIDIARIES, DISCLAIMS ANY AND ALL WARRANTIES
# EXPRESSED, STATUTORY OR IMPLIED, INCLUDING BUT NOT LIMITED TO ANY IMPLIED WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, NON-INFRINGEMENT OR THIRD PARTY RIGHTS.
#
# Copyright (c) 2014-2020 Wearable Sensing LLC
import pickle
import socket, struct, time
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import threading
import time
import mne
import signal as sig
from scipy import signal
from lightgbm import LGBMClassifier
import pyttsx3
from sklearn.model_selection import cross_val_score, RepeatedKFold
import datetime
from enum import Enum

class TCPParser:  # The script contains one main class which handles DSI-Streamer data packet parsing.
    def __init__(self, host, port):
        self.host = host
        self.port = port
        self.done = False
        self.data_log = b''
        self.latest_packets = []
        self.latest_packet_headers = []
        self.latest_packet_data = np.zeros((1, 1))
        self.signal_log = np.zeros((1, 20))
        self.time_log = np.zeros((1, 20))
        self.montage = []
        self.fsample = 0
        self.fmains = 0
        self.classifier = None
        self.table = None
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.sock.connect((self.host, self.port))
        self.runOnline = False

    def onlineHandler(self):
        """
        Set the running flag for the online process to false (stop running)
        """
        self.runOnline = False
        sig.signal(sig.SIGINT, sig.SIG_DFL)

    def parse_data(self):
        # parse_data() receives DSI-Streamer TCP/IP packets and updates the signal_log and time_log attributes which
        # capture EEG data and time data, respectively, from the last 100 EEG data packets (by default) into a numpy
        # array.
        while not self.done:
            data = self.sock.recv(921600)
            self.data_log += data
            # The script looks for the '@ABCD' header start sequence to find packets.
            if self.data_log.find(b'@ABCD', 0, len(self.data_log)) != -1:
                # The script then splits the inbound transmission by the header start sequence to collect the
                # individual packets.
                for index, packet in enumerate(self.data_log.split(b'@ABCD')[1:]):
                    self.latest_packets.append(b'@ABCD' + packet)
                for packet in self.latest_packets:
                    self.latest_packet_headers.append(struct.unpack('>BHI', packet[5:12]))
                self.data_log = b''

                for index, packet_header in enumerate(self.latest_packet_headers):
                    # For each packet in the transmission, the script will append the signal data and timestamps to
                    # their respective logs.
                    if packet_header[0] == 1:
                        # The signal_log must be initialized based on the headset and number of
                        # available channels.
                        if np.shape(self.signal_log)[0] == 1:
                            self.signal_log = np.zeros((int(len(self.latest_packets[index][23:]) / 4), 20))
                            self.time_log = np.zeros((1, 20))
                            self.latest_packet_data = np.zeros((int(len(self.latest_packets[index][23:]) / 4), 1))

                        self.latest_packet_data = np.reshape(
                            struct.unpack('>%df' % (len(self.latest_packets[index][23:]) / 4),
                                          self.latest_packets[index][23:]), (len(self.latest_packet_data), 1))
                        self.latest_packet_data_timestamp = np.reshape(
                            struct.unpack('>f', self.latest_packets[index][12:16]), (1, 1))

                        # print("Timestamps: " + str(self.latest_packet_data_timestamp))
                        # print("Signal Data: " + str(self.latest_packet_data))

                        self.signal_log = np.append(self.signal_log, self.latest_packet_data, 1)
                        self.time_log = np.append(self.time_log, self.latest_packet_data_timestamp, 1)
                        self.signal_log = self.signal_log[:, -600:]
                        self.time_log = self.time_log[:, -600:]
                    # Non-data packet handling
                    if packet_header[0] == 5:
                        (event_code, event_node) = struct.unpack('>II', self.latest_packets[index][12:20])
                        if len(self.latest_packets[index]) > 24:
                            message_length = struct.unpack('>I', self.latest_packets[index][20:24])[0]
                        # print("Event code = " + str(event_code) + "  Node = " + str(event_node))
                        if event_code == 9:
                            montage = self.latest_packets[index][24:24 + message_length].decode()
                            montage = montage.strip()
                            # print("Montage = " + montage)
                            self.montage = montage.split(',')
                        if event_code == 10:
                            frequencies = self.latest_packets[index][24:24 + message_length].decode()
                            # print("Mains,Sample = "+ frequencies)
                            mains, sample = frequencies.split(',')
                            self.fsample = float(sample)
                            self.fmains = float(mains)
            self.latest_packets = []
            self.latest_packet_headers = []


if __name__ == "__main__":
    # The script will automatically run the example_plot() method if not called from another script.
    tcp = TCPParser('localhost', 8844)
