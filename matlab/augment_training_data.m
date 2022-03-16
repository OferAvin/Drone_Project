%
clear all; close all;

addpath('..\..\..\DOC');
addpath(genpath('..\..\..\nft'));

NON_EEG_ELECTRODES = {'A1','A2','X1','X2','X3','TRG','Pz_CM'};

project_params = augmentation_params();

spatial_fit_flg = true;
plot_flg = false;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[fn, in_fp] = uigetfile([project_params.data_fp '\*.mat'], 'select trainig data');
train_data = load([in_fp fn]);
augmented_data.trials = [];
augmented_data.labels = [];

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
    
%     figure; topoplot([],EEG.chanlocs, 'style', 'blank',  'electrodes', 'labelpoint', 'chaninfo', EEG.chaninfo);
%     pop_eegplot(EEG, 1, 0, 0, [], 'srate',EEG.srate, 'winlength',6, 'eloc_file',[]);
%     figure; pop_spectopo(EEG, 1, [], 'EEG', 'freqrange',[0 EEG.srate/2], 'percent',10, 'electrodes','off');
    
    %clean data
    EEGclean = eeglab_pipeline(EEG, project_params.pipelineParams, 0, 0);
    EEG.rejTrials = EEGclean.rejTrials;
    EEG = pop_rejepoch(EEG, EEG.rejTrials,0);
    EEG.bad_channels = EEGclean.bad_channels;
    EEG = pop_select(EEG, 'nochannel',EEG.bad_channels);
    EEG = eeg_interp(EEG, EEGclean.chanlocs);
    EEG = eeg_checkset(EEG);   

    %fit
    trial_len_sec = EEG.pnts/EEG.srate;
    EEG_epochsConcat = eeg2epoch(EEG);
    project_params.psd.window_sec = trial_len_sec;
    try
        [NFTparams, Spectra] = fit_nft(EEG_epochsConcat, project_params, spatial_fit_flg, plot_flg);
    catch
        error([fn ':  fit_nft error']);
    end

    %augment
    project_params.minSectLenSec = project_params.augmentation_factor * sum(train_data.labels==Label) * trial_len_sec;
    [EEG, ~] = simulate_nft(NFTparams, Spectra, project_params, plot_flg);
    %post-processing
    EEG = pop_resample(EEG, project_params.fs);
    EEG = eeg2epoch(EEG,trial_len_sec);

    %concatenate augmented data
    augData = permute(EEG.data, [3,2,1]);
    augLabels = Label*int32(ones(1,EEG.trials));
    augmented_data.trials = cat(1,augmented_data.trials, augData);
    augmented_data.labels = cat(2,augmented_data.labels, augLabels);

end

%save
train_data_trials = train_data.trials;
train_data_labels = train_data.labels;
augmented_data_trials = augmented_data.trials;
augmented_data_labels = augmented_data.labels;
save([in_fp 'augmented_train_data.mat'],'train_data_trials','train_data_labels','augmented_data_trials','augmented_data_labels');
