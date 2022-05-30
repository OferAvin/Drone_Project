%creates EEGLAB structure for the data
%cleans the data
%
function EEG = EEGLAB_clean(train_data, fn, fp, Label, project_params, OP_MODE, plot_flg)

%convert to EEGLAB format
EEG = [];
EEG.setname = ['Training_Dat: label #' num2str(Label)];
EEG.filename = [fn(1:end-3) 'set'];
EEG.filepath = fp;
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

%set electrodes
chanlocs = readlocs(project_params.electrodes_fn);
if EEG.nbchan == length(chanlocs)
    EEG.chanlocs = chanlocs;
    EEG = pop_select(EEG, 'nochannel', project_params.NON_EEG_ELECTRODES);
else %EEG.nbchan < length(chanlocs)
    chanlocs(contains({chanlocs.labels}, project_params.NON_EEG_ELECTRODES)) = [];
    chanlocs = chanlocs(1:EEG.nbchan);
    EEG.chanlocs = chanlocs;
end

%plot "raw" train data
if plot_flg 
    figure; topoplot([],EEG.chanlocs, 'style', 'blank',  'electrodes', 'labelpoint', 'chaninfo', EEG.chaninfo);
    pop_eegplot(EEG, 1, 0, 0, [], 'srate',EEG.srate, 'winlength',6, 'eloc_file',[]);
end

%clean data
if ~strcmp(OP_MODE,'CSP_SOURCE_AUG')
    EEG = eeglab_pipeline(EEG, project_params.pipelineParams, 0, 0);

    %plot cleaned data
    if plot_flg
        EEGplot = pop_eegfiltnew(EEG, 0.1, []);
        pop_eegplot(EEGplot, 1, 0, 0, [], 'srate',EEG.srate, 'winlength',6, 'eloc_file',[]);
        figure; pop_spectopo(EEG, 1, [], 'EEG', 'freqrange',[0 EEG.srate/2], 'percent',10, 'electrodes','off');
        channel_map_topoplot(eeg2epoch(EEG), [], false);
    end
end
