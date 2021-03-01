function [FFT, frq_vec] = meanFFT(EEG,events_time,Fs,frq)



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

events_N = length(events_time)-1;
for i = 1 : events_N
    current_dat = EEG(events_time(i):events_time(i+1));
    [FFT(i,:), frq_vec] = myFFT(current_dat, frq, Fs);
end
    