%
clear all; close all;

addpath('..\..\..\DOC');
addpath(genpath('..\..\..\nft'));

project_params = augmentation_params();

OP_MODE = 'CSP_SOURCE_AUG'; % EEG_CLEAN_ONLY  RAW_EEG_AUG  CSP_SOURCE_AUG

if strcmp(OP_MODE,'CSP_SOURCE_AUG')
    project_params.nftfit.freqBandHz = [8 29];
    out_fn = 'augmented_source_data.mat';
elseif strcmp(OP_MODE,'RAW_EEG_AUG')
    orig_grid_edge = project_params.nftsim.grid_edge;
    out_fn = 'augmented_train_data.mat';
else %EEG_CLEAN_ONLY
    out_fn = 'clean_train_data.mat';
end
project_params.nftsim.grid_edge = 1;

plot_flg = false;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[fn, in_fp] = uigetfile([project_params.data_fp '\*.mat'], 'select trainig data');
train_data = load([in_fp fn]);
clean_train_data.trials = [];
clean_train_data.labels = [];
augmented_data.trials = [];
augmented_data.labels = [];

% poolobj = gcp; %parpool
datetime(now,'ConvertFrom','datenum');

labels = unique(train_data.labels);
for Label = labels %group data by labels

    EEG = EEGLAB_clean(train_data, fn, in_fp, Label, project_params, OP_MODE, plot_flg);
    if strcmp(OP_MODE,'CSP_SOURCE_AUG')
        EEGclean = EEG;
    else
        EEGclean = eeg_interp(EEG, readlocs(project_params.electrodes_fn));
    end
    cleanData = permute(EEGclean.data, [3,2,1]);
    cleanLabels = Label*int32(ones(1,EEGclean.trials));
    clean_train_data.trials = cat(1,clean_train_data.trials, cleanData);
    clean_train_data.labels = cat(2,clean_train_data.labels, cleanLabels);
    if strcmp(OP_MODE,'EEG_CLEAN_ONLY')
        continue;
    end

    %for normalization
%     chanPower = bandpower(eeg2epoch(EEG).data' ,EEG.srate, project_params.nftfit.freqBandHz);
    chanAVs = mean(EEG.data,[2 3]);
    chanSTDs = std(EEG.data,0,[2 3]);

    trial_len_sec = EEG.pnts/EEG.srate;
    project_params.psd.window_sec = trial_len_sec;
    project_params.minSectLenSec = round(project_params.augmentation_factor * length(train_data.labels)/length(labels)) * trial_len_sec;

    EEGaug = [];
    for iChan=1:EEG.nbchan %augment each channel separately
        %fit
        try
            [NFTparams, Spectra] = fit_nft(eeg2epoch(EEG), project_params, iChan, 0);
        catch
            error([fn ':  fit_nft error']);
        end
        %simulate
        if iChan == 1 
            if strcmp(OP_MODE,'CSP_SOURCE_AUG')
                EEGaug.data = [];
                EEGaug.chanlocs = EEG.chanlocs; 
            else
                project_params.nftsim.grid_edge = orig_grid_edge; 
                [EEGaug, ~, ~, ~] = simulate_nft(NFTparams, Spectra, project_params, iChan, 0);
                EEGaug.data = EEGaug.data*0;
                EEGaug.bad_channels = [];
                project_params.nftsim.grid_edge = 1;
            end
        end
        
        [~, ~, central_chan_data, isSimSuccess] = simulate_nft(NFTparams, Spectra, project_params, iChan, 0);
        if ~isSimSuccess
            s=rng; rng(randi(100));
            [~, ~, central_chan_data, isSimSuccess] = simulate_nft(NFTparams, Spectra, project_params, iChan, 0);
            rng(s);
        end
        %normalize
        central_chan_data = zscore(central_chan_data) * chanSTDs(iChan) + chanAVs(iChan);
%         central_chan_data = (central_chan_data - mean(central_chan_data)) * ...
%             sqrt(chanPower(iChan) / bandpower(central_chan_data, project_params.fs, project_params.nftfit.freqBandHz))...
%             + chanAVs(iChan);
        %place in EEGaug
        if isSimSuccess
            EEGaug.data(strcmp({EEGaug.chanlocs.labels},EEG.chanlocs(iChan).labels), :) = central_chan_data;
        else
            if strcmp(OP_MODE,'CSP_SOURCE_AUG')
                error('Augmentation Failure!');
            end
            EEGaug.bad_channels = [EEGaug.bad_channels {EEG.chanlocs(iChan).labels}];
        end        
    end
    
    %interpolate bad channels
    if strcmp(OP_MODE,'RAW_EEG_AUG')
        EEGaug = pop_select(EEGaug, 'nochannel',EEGaug.bad_channels);
        EEGaug = eeg_interp(EEGaug, readlocs(project_params.electrodes_fn));
    end
       
    %plot augmented data
    if plot_flg && strcmp(OP_MODE,'RAW_EEG_AUG')
        EEGplot = pop_select(EEGaug, 'nochannel', project_params.NON_EEG_ELECTRODES);
        EEGplot = pop_eegfiltnew(EEGplot, 0.1, []);
        pop_eegplot(EEGplot, 1, 0, 0, [], 'srate',EEGaug.srate, 'winlength',6, 'eloc_file',[]);
        figure; pop_spectopo(EEGaug, 1, [], 'EEG', 'freqrange',[0 EEGaug.srate/2], 'percent',10, 'electrodes','off');
        channel_map_topoplot(EEGaug, [], false);
    end

    %concatenate augmented data
    nAugTrials = project_params.minSectLenSec/trial_len_sec;
    augData = reshape(EEGaug.data,[size(EEGaug.data,1),EEG.pnts,nAugTrials]);
    augData = permute(augData, [3,2,1]);
    augLabels = Label*int32(ones(1,nAugTrials));
    augmented_data.trials = cat(1,augmented_data.trials, augData);
    augmented_data.labels = cat(2,augmented_data.labels, augLabels);

end
datetime(now,'ConvertFrom','datenum');
% delete(poolobj);

%save
train_data_trials = clean_train_data.trials;
train_data_labels = clean_train_data.labels;
augmented_data_trials = augmented_data.trials;
augmented_data_labels = augmented_data.labels;
save([in_fp out_fn],'train_data_trials','train_data_labels','augmented_data_trials','augmented_data_labels');
