%
clear all; close all;

addpath('..\..\..\DOC');
addpath(genpath('..\..\..\nft'));

fp = 'D:\My Files\Work\BGU\Datasets\drone BCI\';
electrodes_fn = [fp 'electrodes\Standard-10-20-Cap19.ced'];
NON_EEG_ELECTRODES = {'A1','A2','X1','X2','X3','TRG','Pz_CM'};

% project_params = doc_nft_params();
fs = 300;

spatial_fit_flg = true;
plot_flg = false;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[fn, in_fp] = uigetfile([fp '*.mat'], 'select trainig data');
train_data = load([in_fp fn]);

labels = unique(train_data.labels);
for Label = labels %group data by labels

    %convert to EEGLAB format
    EEG = [];
    EEG.setname = ['Training_Dat: label #' num2str(Label)];
    EEG.srate = fs;
    EEG.data = permute(train_data.trials(train_data.labels==Label,:,:), [3,2,1]);
    [EEG.nbchan,EEG.pnts,EEG.trials] = size(EEG.data);
    EEG.times = [0:(EEG.pnts-1)]/EEG.srate*1000;
    EEG.xmin = 0;
    EEG.xmax = EEG.times(end)/1000;
    EEG.ref        = [];
    EEG.icawinv    = [];
    EEG.icasphere  = [];
    EEG.icaweights = [];
    EEG.icaact     = [];
    EEG.chanlocs   = [];
    EEG = eeg_checkset(EEG);
    EEG.chanlocs = readlocs(electrodes_fn);
    EEG = pop_select(EEG, 'nochannel', NON_EEG_ELECTRODES);
    
%     figure; topoplot([],EEG.chanlocs, 'style', 'blank',  'electrodes', 'labelpoint', 'chaninfo', EEG.chaninfo);
%     pop_eegplot(EEG, 1, 0, 0, [], 'srate',EEG.srate, 'winlength',60, 'eloc_file',[]);
%     figure; pop_spectopo(EEG, 1, [], 'EEG', 'freqrange',[0 EEG.srate/2], 'percent',10, 'electrodes','off');
    
    %clean data
    LOW_PASS_HZ = 45;
    %
    bad_chan_in_epoch_percent = 0.1; %percent of bad channels in epoch to consider it bad
    epoch_noise_zScore_th = 7; %-> play with it .  channel zscore in epoch, to consider channel bad. Should be at least twice than avalanche detection zThresh
    minimal_nof_bad_pnts_epoch_chan = 1; %minimal number of threshold crossed points in epoch in channel in order to reject it
    %
    bad_channel_zScore_th = 3;
    bad_channel_time_percent = 0.15; %part of bad data in channel to mark it bad
    minimal_interchannel_correlation = 0.6;

    %low-pass filter
    EEG = pop_eegfiltnew(EEG, [], LOW_PASS_HZ);

    EEG.bad_channels = [];
    EEG = eeg_checkset(EEG);

    EEGclean = eeglab_pipeline(EEG, project_params.pipelineParams, 0, 0);

    

    %fit
    Results = [];
    Results.Name = EEG.setname;
    try
        [Results.NFTparams, Spectra] = fit_nft(EEG, spatial_fit_flg, plot_flg);
        Results.Chisq = struct('chisq_fit',Spectra.chisq_fit, 'chisq_typical',Spectra.chisq_typical);
    catch
        error([fn ':  fit_nft error']);
    end

    %augment
    %play with parameters
    [EEGsim, SpatialSpectra] = simulate_nft(Results.NFTparams, Spectra, plot_flg);

end

%save EEGsim with labels in the correct format
