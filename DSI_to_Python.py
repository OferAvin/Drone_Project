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

import socket, struct, time
import numpy as np
import matplotlib.pyplot as plt
import threading
import time
import mne
import scipy
from scipy import signal
import statistics
import math


def find_nearest(array, value):
    array = np.asarray(array)
    idx = (np.abs(array - value)).argmin()
    return idx


def get_bandpower(x, target, f, stride):
    idx = find_nearest(f, target)
    power_val = np.zeros([2, 1])
    power_val[:, 0] = np.mean(x[:, idx - stride: idx + stride + 1], axis=1)
    return power_val


def get_maxpower(x, target, f, stride):
    idx = find_nearest(f, target)
    # power_val = np.zeros([2, 1])
    power_val = np.max(x[:, idx - stride: idx + stride + 1], axis=1)
    return power_val


# Bandpower function
def bandpower(x, fs, fmin, fmax):
    f, Pxx = scipy.signal.periodogram(x, fs=fs)
    ind_min = scipy.argmax(f > fmin) - 1
    ind_max = scipy.argmax(f > fmax) - 1
    return scipy.trapz(Pxx[ind_min: ind_max], f[ind_min: ind_max])


def feature_extract(frq, Pxx_den, f, harmonics_N):
    """
    Sum the power of the frequency with the harmonics
    """
    harm_frq = np.multiply(range(2, harmonics_N + 2), frq)
    frq = np.append(frq, harm_frq)
    stride = 0
    feature = np.zeros([1, len(frq)])
    for i in range(len(frq)):
        feature[0, i] = get_maxpower(Pxx_den, frq[i], f, stride)
    main_power = np.sum(feature)
    return main_power


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

    def example_plot(self, table):
        # example_plot() uses the threading Python library and matplotlib to plot the EEG data in realtime. The plots
        # are unlabeled but users can refer to the TCP/IP Socket Protocol Documentation to understand how to discern
        # the different plots given their indices. Ideally, each EEG plot should have its own subplot but for
        # demonstrative purposes, they are all plotted on the same figure.
        data_thread = threading.Thread(target=self.parse_data)
        data_thread.start()
        self.table = table
        refresh_rate = 0.03
        duration = 60  # The default plot duration is 60 seconds.
        runtime = 0
        Hz = 300
        low_pass = 4
        high_pass = 40
        chunk_t = 2
        # SSVEP = np.load(r"C:\Users\ophir\Desktop\Uni\BCI\Drone_Project\NumpyFiles\feature_mat.npy")
        # SSVEP_labels = np.load(r"C:\Users\ophir\Desktop\Uni\BCI\Drone_Project\NumpyFiles\labels.npy")
        # classifier = lgbm.sklearn.LGBMClassifier()
        # classifier.fit(SSVEP, SSVEP_labels)
        time.sleep(chunk_t * 2)
        elec = np.zeros((1, 2))
        elec[0, 0] = self.montage.index('O1')
        elec[0, 1] = self.montage.index('O2')
        elec = elec.astype(int)
        target_frq = [6, 7.5, 11]

        """
        Add here the calibration at the beggining of the recording in order to choose
        the thershold for classification
        """

        count = 0
        calibration_t = 0.5  # Time in minutes for calibration
        chunk_N = round(calibration_t * 60 / chunk_t)

        # First Data sampling

        # Filtering the data
        Filtered = mne.filter.filter_data(self.signal_log, sfreq=Hz, l_freq=low_pass, h_freq=high_pass, verbose=0)
        # Getting wanted electrodes
        mysignal = Filtered[elec[0], -chunk_t * Hz:]  # Pull 2 seconds
        # Welch
        f, FFT = signal.welch(mysignal, Hz, nperseg=500, noverlap=450, scaling='spectrum')
        # Mean the occipital electrodes power
        FFT = np.expand_dims(np.mean(FFT, 0), 0)

        while count < chunk_N:
            time.sleep(chunk_t)
            # Filtering the data
            Filtered = mne.filter.filter_data(self.signal_log, sfreq=Hz, l_freq=low_pass, h_freq=high_pass, verbose=0)
            # Getting wanted electrodes
            mysignal = Filtered[elec[0], -chunk_t * Hz:]  # Pull 2 seconds
            # Welch
            f, Pxx_den = signal.welch(mysignal, Hz, nperseg=500, noverlap=450, scaling='spectrum')
            # Mean the occipital electrodes power
            Pxx_den = np.expand_dims(np.mean(Pxx_den, 0), 0)

            # Add the computed FFt and add one to count
            FFT = np.append(FFT, Pxx_den, 0)
            count += 1

        # Compute mean an std for all frequencies
        FFT_std = np.std(FFT, 0)
        FFT_mean = np.mean(FFT, 0)

        # Get threshold per frequency

        threshold = np.zeros((1, len(target_frq)))
        for i in range(len(target_frq)):
            # if target_frq[i] == 10:
            #     high_limit = FFT_mean + (2.5 * FFT_std)
            #     idx = find_nearest(f, target_frq[i])
            #     threshold[0, i] = high_limit[idx]
            # else:
            high_limit = FFT_mean + (2 * FFT_std)
            idx = find_nearest(f, target_frq[i])
            threshold[0, i] = high_limit[idx]

        # Send command when calibration has ended
        self.table.put(999)

        while True:  # runtime < duration/refresh_rate:
            time.sleep(chunk_t)  # Wait 2 seconds

            # Filtering the data
            Filtered = mne.filter.filter_data(self.signal_log, sfreq=Hz, l_freq=low_pass, h_freq=high_pass, verbose=0)

            # Getting wanted electrodes
            mysignal = Filtered[elec[0], -chunk_t * Hz:]  # Pull 2 seconds
            # Welch
            f, Pxx_den = signal.welch(mysignal, Hz, nperseg=500, noverlap=450, scaling='spectrum')
            # Mean the two occipital electrodes
            Pxx_den = np.expand_dims(np.mean(Pxx_den, 0), 0)

            # Get features

            main_power = np.zeros((1, len(target_frq)))
            for i in range(len(target_frq)):
                main_power[0, i] = feature_extract(target_frq[i], Pxx_den, f, 1)

            # Predict
            # TODO: make generic
            if main_power[0, 0] > threshold[0, 0] and main_power[0, 1] > threshold[0, 1]\
                    or (main_power[0, 0] > threshold[0, 0] and main_power[0, 2] > threshold[0, 2])\
                    or (main_power[0, 1] > threshold[0, 1] and main_power[0, 2] > threshold[0, 2]):
                y_pred = 0
            elif main_power[0, 0] > threshold[0, 0]:
                y_pred = 6
            elif main_power[0, 1] > threshold[0, 1]:
                y_pred = 7
            elif main_power[0, 2] > 2 * threshold[0, 2]:
                y_pred = 69  # Flip
            else:
                y_pred = 0

            self.table.put(y_pred)
            print(y_pred)

            # Plots
            plt.clf()
            try:
                idx_40 = find_nearest(f, 40)
                plt.plot(f[1:idx_40], np.transpose(Pxx_den[:, 1:idx_40]), label='Line1')
                plt.plot(f[1:idx_40], high_limit[1:idx_40], label="Line2")
            except:
                pass
            plt.gca().legend(['Power', 'Limit'])
            plt.xlabel('Frequency [Hz]')
            plt.ylabel('Power')
            plt.title('DSI-Streamer Power Spectrum')
            plt.xlim(1, 40)
            plt.ylim(0, 100)
            plt.pause(refresh_rate)
            print()
            runtime += 1

        plt.show()

        self.done = True
        data_thread.join()


if __name__ == "__main__":
    # The script will automatically run the example_plot() method if not called from another script.
    tcp = TCPParser('localhost', 8844)
    tcp.example_plot()
