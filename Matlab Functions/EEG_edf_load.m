function data =  EEG_edf_load(filePath, lowCutoff, highCutoff)


%% EEG stuff

% EEGlab load
eeglab
EEG = pop_biosig(filePath);

%Channel select
EEG = pop_select( EEG, 'channel',{'EEG O1-Pz'});

%Low and high pass filter
EEG = pop_eegfiltnew(EEG, 'locutoff' ,lowCutoff ,'hicutoff' ,highCutoff ,'plotfreqz',0);
vidStartTime = EEG.event(2).latency;
vidEndTime = EEG.event(3).latency;

data.filtered = EEG.data; %Full recording.
data.before = data.filtered(vidStartTime - 5*EEG.srate : vidStartTime); %Take 5 seconds before the video starts.
data.after = data.filtered(vidEndTime : vidEndTime + 5*EEG.srate); %Take 5 seconds after the video ends.
data.video = data.filtered(vidStartTime : vidEndTime); %Take the video time signal.
 clearvars -except data

