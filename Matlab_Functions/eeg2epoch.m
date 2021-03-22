function EEG = eeg2epoch(EEG,win)
%EEG = eeg2epoch(EEG,win) win is in seconds
if ~exist('win','var')
    EEG.epoch_length = size(EEG.data,2);
    EEG.data = EEG.data(:,:);
    EEG.trials = 1;
    EEG.pnts = size(EEG.data,2);
    EEG.xmax = (EEG.pnts-1)/EEG.srate;
    EEG.times = 0:1/EEG.srate:EEG.xmax;
else
    T = length(EEG.data);
    swin = win*EEG.srate;
    k = floor(T/swin);
    
    %erase events field if it exists
    EEG.event = '';
    [EEG.event(1,1:k).type] = deal(1);
    temp = num2cell(1:swin:T);
    [EEG.event(1,1:k).latency] = temp{:};
    [EEG.event(1,1:k).urevent] = deal(1);
    
    %create k win sec epochs
    % EEG = pop_epoch( EEG, {'1'}, [0  win-1/EEG.srate], 'newname', 'splice epochs','epochinfo', 'yes');
    EEG.data = reshape(EEG.data(:,1:k*swin),[EEG.nbchan,swin,k]);
    EEG.times = EEG.times(1:swin);
    EEG.xmax = (swin-1)/EEG.srate;
    EEG.trials = k;
    EEG.pnts = swin;
    if ~isempty(EEG.icaact)
        EEG.icaact = reshape(EEG.icaact(:,1:k*swin),[size(EEG.icaact,1),swin,k]);
    end
    % EEG = eeg_checkset( EEG );
end