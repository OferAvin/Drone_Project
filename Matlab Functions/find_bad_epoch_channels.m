% find_bad_epoch_channels - automaticaly finds noisy channels in epochs
%
% params:
%       channels_data
% options:
%       'minimal_nof_bad_pnts' - minimal number of threshold crossed points in epoch in channel in order to reject it
%       'chan_z_score_thresh' - threshold for a noisy point in a channel
%       'max_amp_score_thresh' - threshold for an outrageos epoch mean compared to other epochs mean
%       'max_std_thresh','min_std_thresh' - thresholds for epoch std compared to full channel
%
% return:
%       bad_epoch_chan - matrix of bad channels in epochs
%
function bad_epoch_chan = find_bad_epoch_channels(channels_data, varargin)

[n_chan,n_pts,n_epoch] = size(channels_data);
bad_epoch_chan = zeros(n_chan,n_epoch);

%defaults
minimal_nof_bad_pnts = 1;
chan_z_score_thresh = 5;
max_amp_score_thresh = 1;
max_std_thresh = 2;
min_std_thresh = 1/2;

%parse input
if nargin <= 1
    warning('find_bad_epoch_channels had no action');
    help find_bad_epoch_channels;
    return;
end

for i = 1:2:length(varargin)
    Param = varargin{i};
    Value = varargin{i+1};

    switch Param
        case 'minimal_nof_bad_pnts'
            minimal_nof_bad_pnts = Value;
        case 'chan_z_score_thresh'
            chan_z_score_thresh = Value;
        case 'max_amp_score_thresh'
            max_amp_score_thresh = Value;
        case 'max_std_thresh'
            max_std_thresh = Value;
        case 'min_std_thresh'
            min_std_thresh = Value;
        otherwise
            warning(['Unknown input parameter ''' Param ''' ???'])
            help find_bad_epoch_channels;
            return;
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
channels_data_concat = reshape(channels_data,n_chan, []);
fullMean = median(channels_data_concat,2);
fullStd = std(channels_data_concat,[],2);
meanEpochs = squeeze(mean(channels_data,2));
stdEpochs = squeeze(std(channels_data,[],2));

%compare different channels in epoch
meanZScore = abs(meanEpochs - repmat(median(meanEpochs,1),n_chan,1))./repmat(median(stdEpochs,1),n_chan,1);
bad_epoch_chan(meanZScore > max_amp_score_thresh) = 1;
stdScore = stdEpochs./repmat(median(stdEpochs,1),n_chan,1);
bad_epoch_chan(stdScore > max_std_thresh | stdScore < min_std_thresh) = 1;

%compare different epochs in channels
meanZScore = abs(meanEpochs - repmat(median(meanEpochs,2),1,n_epoch))./repmat(median(stdEpochs,2),1,n_epoch);
bad_epoch_chan(meanZScore > max_amp_score_thresh) = 1;
stdScore = stdEpochs./repmat(median(stdEpochs,2),1,n_epoch);
bad_epoch_chan(stdScore > max_std_thresh | stdScore < min_std_thresh) = 1;

%detect each channel outliers
fullZScore = abs(channels_data - repmat(fullMean,1,n_pts,n_epoch))./repmat(fullStd,1,n_pts,n_epoch);
totalOutliersEpochs = squeeze(sum(fullZScore > chan_z_score_thresh,2));
bad_epoch_chan(totalOutliersEpochs >= minimal_nof_bad_pnts) = 1;
