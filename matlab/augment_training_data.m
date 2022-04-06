%
clear all; close all;

addpath('..\..\..\DOC');
addpath(genpath('..\..\..\nft'));

NON_EEG_ELECTRODES = {'A1','A2','X1','X2','X3','TRG','Pz_CM'};

project_params = augmentation_params();
orig_grid_edge = project_params.nftsim.grid_edge;

plot_flg = false;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[fn, in_fp] = uigetfile([project_params.data_fp '\*.mat'], 'select trainig data');
train_data = load([in_fp fn]);
augmented_data.trials = [];
augmented_data.labels = [];

poolobj = gcp; %parpool
datetime(now,'ConvertFrom','datenum');

labels = unique(train_data.labels);
for Label = labels %group data by labels

    %convert to EEGLAB format
    EEG = [];
    EEG.setname = ['Training_Dat: label #' num2str(Label)];
    EEG.filename = [fn(1:end-3) 'set'];
    EEG.filepath = in_fp;
    EEG.srate = project_params.fs;
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
    EEG.bad_channels = [];
    EEG = eeg_checkset(EEG);
    EEG.chanlocs = readlocs(project_params.electrodes_fn);
    EEG = pop_select(EEG, 'nochannel', NON_EEG_ELECTRODES);
    
    if plot_flg %plot "raw" train data
        figure; topoplot([],EEG.chanlocs, 'style', 'blank',  'electrodes', 'labelpoint', 'chaninfo', EEG.chaninfo);
        pop_eegplot(EEG, 1, 0, 0, [], 'srate',EEG.srate, 'winlength',6, 'eloc_file',[]);  
    end
    
    %clean data
    EEGclean = eeglab_pipeline(EEG, project_params.pipelineParams, 0, 0);
    EEG.rejTrials = EEGclean.rejTrials;
    EEG = pop_rejepoch(EEG, EEG.rejTrials,0);
    EEG.bad_channels = EEGclean.bad_channels;
    EEG = pop_select(EEG, 'nochannel',EEG.bad_channels);
    EEG = eeg_interp(EEG, EEGclean.chanlocs);
    EEG = eeg_checkset(EEG); 

    if plot_flg %plot preprocessed data
        EEGplot = pop_eegfiltnew(EEG, 0.1, []);
        pop_eegplot(EEGplot, 1, 0, 0, [], 'srate',EEG.srate, 'winlength',6, 'eloc_file',[]);
        figure; pop_spectopo(EEG, 1, [], 'EEG', 'freqrange',[0 EEG.srate/2], 'percent',10, 'electrodes','off');
        channel_map_topoplot(eeg2epoch(EEG), [], false);
    end

    %for normalization
%     chanPower = bandpower(eeg2epoch(EEG).data' ,EEG.srate, project_params.nftfit.freqBandHz);
    chanAVs = mean(EEG.data,[2 3]);
    EEG_filtered = pop_eegfiltnew(EEG, project_params.pipelineParams.passBandHz{1}, project_params.pipelineParams.passBandHz{2});
    chanSTDs = std(EEG_filtered.data,0,[2 3]);

    trial_len_sec = EEG.pnts/EEG.srate;
    project_params.psd.window_sec = trial_len_sec;
    project_params.minSectLenSec = project_params.augmentation_factor * sum(train_data.labels==Label) * trial_len_sec;
    project_params.nftsim.grid_edge = orig_grid_edge; 

    for iChan=1:EEG.nbchan %augment each channel separately
        project_params.nftfit.CZname = EEG.chanlocs(iChan).labels;
        %fit
        try
            [NFTparams, Spectra] = fit_nft(eeg2epoch(EEG), project_params, 0);
        catch
            error([fn ':  fit_nft error']);
        end
        %simulate
        if iChan == 1
            [EEGaug, ~, ~] = simulate_nft(NFTparams, Spectra, project_params, iChan, 0);
            EEGaug.data = EEGaug.data*0;
            EEGaug.srate = project_params.fs;
        end
        project_params.nftsim.grid_edge = 1;
        [~, ~, central_chan_data] = simulate_nft(NFTparams, Spectra, project_params, iChan, 0);
        %normalize
        EEGaug.data(strcmp({EEGaug.chanlocs.labels},project_params.nftfit.CZname), :) ...
           = zscore(central_chan_data) * chanSTDs(iChan) + chanAVs(iChan);
%         = (central_chan_data - mean(central_chan_data)) * ...
%             sqrt(chanPower(iChan) / bandpower(central_chan_data, project_params.fs, project_params.nftfit.freqBandHz))...
%             + chanAVs(iChan); 

    end
    
    if plot_flg %plot augmented data
        EEGplot = pop_select(EEGaug, 'nochannel', NON_EEG_ELECTRODES);
        EEGplot = pop_eegfiltnew(EEGplot, 0.1, []);
        pop_eegplot(EEGplot, 1, 0, 0, [], 'srate',EEGaug.srate, 'winlength',6, 'eloc_file',[]);
        figure; pop_spectopo(EEGaug, 1, [], 'EEG', 'freqrange',[0 EEGaug.srate/2], 'percent',10, 'electrodes','off');
        channel_map_topoplot(EEGaug, [], false);
    end

    %concatenate augmented data
    EEGaug = eeg2epoch(EEGaug,trial_len_sec);
    augData = permute(EEGaug.data, [3,2,1]);
    augLabels = Label*int32(ones(1,EEGaug.trials));
    augmented_data.trials = cat(1,augmented_data.trials, augData);
    augmented_data.labels = cat(2,augmented_data.labels, augLabels);

end
datetime(now,'ConvertFrom','datenum');
delete(poolobj);

%save
train_data_trials = train_data.trials;
train_data_labels = train_data.labels;
augmented_data_trials = augmented_data.trials;
augmented_data_labels = augmented_data.labels;
save([in_fp 'augmented_train_data.mat'],'train_data_trials','train_data_labels','augmented_data_trials','augmented_data_labels');
