function [signal_fft , f] = myFFT (signal , Frequency , Fs)
%Matlab R2019b

%outputs:
% signal_dft - signal power in selected frequencies.
% f -  selected frequencies spectrum.
%
% inputs:
% signal - raw signal.
% Frequency - 1X2 vector with desired frequencies spectrum limits.
% Fs - Sampling rate in Hz.


L  = length(signal);  % Number of sampels
f  = (0:L-1)./(L/Fs); % Frequencies

%fft
signal_fft = fft(signal);

%power fft and noramlizing
signal_fft = (abs(signal_fft)/L);
signal_fft = signal_fft.^2;

%taking relevevant frequency spectrum
signal_fft = signal_fft(f>=Frequency(1) & f<=Frequency(2));
f = f(f>=Frequency(1) & f<=Frequency(2));