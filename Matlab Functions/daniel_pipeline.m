
LOW_PASS_HZ = 45;
HIGH_PASS_HZ = 0.2;

fs = 128;

badchan_window_step_length_sec = 10;
badchan_time_percent = 0.15;
chan_z_score_thresh = 7; %threshold for a noisy point in a channel
epoch_max_std_thresh = 2.5; %max threshold for epoch std compared to full channel
epoch_min_std_thresh = 0.1; %min threshold for epoch std compared to full channel

max_badchannel_percent = 0.1;
minimal_interchannel_correlation = 0.5;
asr_birst = 5; %burst std or 'off' to avoid ASR

badsect_window_length_sec = 1;
badsect_reject_score_thresh = 1;
if isnumeric(asr_birst)
    badsect_z_score_thresh = asr_birst+1;
else
    badsect_z_score_thresh = 3;
end

EEG.bad_channels = [];

EEG = pop_eegfiltnew(EEG, HIGH_PASS_HZ, LOW_PASS_HZ); %band-pass
EEG = pop_resample(EEG, fs); %resample
EEG = eeg_checkset(EEG);

%BAD CHANNELS
%find bad chanels in epochs
EEG_epoched = eeg2epoch(EEG,badchan_window_step_length_sec);
bad_epoch_chan = find_bad_epoch_channels(EEG_epoched.data, 'chan_z_score_thresh', chan_z_score_thresh,...
    'max_std_thresh', epoch_max_std_thresh, 'min_std_thresh', epoch_min_std_thresh);
bad_channels = find(sum(bad_epoch_chan,2)/size(bad_epoch_chan,2) > badchan_time_percent);
EEG.bad_channels = [EEG.bad_channels {EEG.chanlocs(bad_channels).labels}];
EEG = pop_select(EEG, 'nochannel',bad_channels);

%ASR and badly correlated channels
for iChCorr=1:2 %run 2 times in case of too many bad channels
    [EEG_clean,~,~,bad_channels] = clean_artifacts(EEG, ...
        'ChannelCriterion', minimal_interchannel_correlation,...
        'ChannelCriterionMaxBadTime', badchan_time_percent*2 ,...
        'NoLocsChannelCriterion', 'off',...
        'NoLocsChannelCriterionExcluded', 'off',...
        'LineNoiseCriterion', 'off',...
        'FlatlineCriterion', 'off',...
        'BurstCriterion', asr_birst,...
        ...%'BurstCriterionRefMaxBadChns', 'off',...
        ...%'BurstCriterionRefTolerances', 'off',...
        'BurstRejection', 'off',...
        'WindowCriterion', badsect_reject_score_thresh/EEG.nbchan,...
        'WindowCriterionTolerances', 'off',...
        'Highpass', 'off',...
        'MaxMem',512);
    bad_channels = find(bad_channels);
    if length(EEG.bad_channels)+length(bad_channels) > max_badchannel_percent*length(VALID_ELECTRODES)
        minimal_interchannel_correlation = 0; %give up channel correlation test
    else
        break;
    end
end
EEG.bad_channels = [EEG.bad_channels {EEG.chanlocs(bad_channels).labels}];
%EEG.bad_channels = unique(EEG.bad_channels);
if isnumeric(asr_birst) %if ASR is on
    %         %debug plot
    %         vis_artifacts(EEG_clean,EEG);
    EEG = EEG_clean;
else
    EEG = pop_select(EEG, 'nochannel',bad_channels);
end
EEG = eeg_checkset(EEG);

%BAD SECTIONS
EEG = pop_reref(EEG,[]); %average-reference

regected_sections = find_bad_sections(EEG.data, EEG.srate, 'window_length_sec', badsect_window_length_sec, 'reject_score_thresh',...
    badsect_reject_score_thresh, 'z_score_thresh', badsect_z_score_thresh);
%remove bad sections
EEG = pop_select(EEG, 'nopoint', regected_sections);
EEG = eeg_checkset(EEG);

out_fn = [fp out_folder fn(1:end-4) '_' num2str(EEG.srate) 'Hz'];
EEG = pop_saveset(EEG, 'filename',[out_fn '.set'], 'savemode','onefile');
