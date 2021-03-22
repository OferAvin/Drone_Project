
% %Load the data set if needed
% locutoff = 0.5;
% hicutoff = 40;
% %lets assume the EDF file is on the working directory
% cur_dir = pwd;
% file_name = '15H_30sec_rfrt60_real_M_filtered.edf';
% 
% if  exist('EEG', 'var') == 0 || isempty(EEG)
%     [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
%     EEG = pop_biosig([pwd '\' file_name]);
%     [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'gui','off');
%     %High low pass
%     EEG = pop_eegfiltnew(EEG, 'locutoff',0.5,'hicutoff',40,'plotfreqz',0);
%     [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'gui','off');
% end


%Start and end times of wanted window in seconds.
start_time = 12;
end_time = 17;
%Choose the electrodes (by number)
elec_idx = [15];
%Desired frequency range (length 2 vector)
frq_rng = [1,40];
%pwelch time window and overlap (in sec)
pwlc_wind = 0.75;
pwlc_ovlap = 0.5;

%Extract the desired signal
data = EEG.data(elec_idx, start_time*EEG.srate:end_time*EEG.srate);
%If more then one electrode is selected mean between them
if length(elec_idx) > 1
    data = mean(data);
end

%Plots
%FFT
[FFT,frq] = myFFT(dat,0.5:40,EEG.srate);
figure(3)
plot(frq,FFT)

%pwelch
% figure(2)
% pwelch(data,pwlc_wind*EEG.srate,pwlc_ovlap*EEG.srate,frq,EEG.srate)
fftPSD(data,EEG.srate,1);