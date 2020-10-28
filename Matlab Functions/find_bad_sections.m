% find_bad_sections - automaticaly finds noisy sections in the data and returns their indeces
%
% params:
%       channels_data
%       fs
% options:
%       'window_length_sec' - moving window that smooth (make continues) rejected points along time
%       'reject_score_thresh' - minimal number of channels that should be marked as noisy in a single point in order to reject it
%       'z_score_thresh' - threshold for a noisy point in a channel
%
% return:
%       regected_sections - matrix of start and end indeces of noise sections
%
function regected_sections = find_bad_sections(channels_data, fs, varargin)

regected_sections = [];

%defaults
window_length = floor(1 * fs); %1 sec window default
reject_score_thresh = 1;
z_score_thresh = 3;


%parse input
if nargin <= 2
    warning('find_bad_sections had no action');
    help find_bad_sections;
    return;
end
if mod(nargin,2) == 1
    warning('Odd number of input arguments. find_bad_sections had no action')
    help find_bad_sections;
    return;
end

for i = 1:2:length(varargin)
    Param = varargin{i};
    Value = varargin{i+1};
    %         if ~isstr(Param)
    %             error('Flag arguments must be strings')
    %         end
    %         Param = lower(Param);
    switch Param
        case 'window_length_sec'
            window_length = floor(Value * fs);
        case 'reject_score_thresh'
            reject_score_thresh = Value;
        case 'z_score_thresh'
            z_score_thresh = Value;
        otherwise
            warning(['Unknown input parameter ''' Param ''' ???'])
            help find_bad_sections;
            return;
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

data_len = size(channels_data,2);
rejected_vector_scores_v = zeros(1,data_len);

%calc z score
%dataMean_m = repmat(mean(channels_data,2),1,data_len);
dataMed_m = repmat(median(channels_data,2),1,data_len);
dataStd_m = repmat(std(channels_data,[],2),1,data_len);
zScore_m = abs(channels_data - dataMed_m)./dataStd_m;
high_zScore_v = sum(zScore_m > z_score_thresh,1); % add 1 to the score for each channel that crossed the threshold
%high_zScore_v = sum(zScore_m(zScore_m > z_score_thresh),1); % sum the scores of all the channels that crossed the threshold
rejected_vector_scores_v = rejected_vector_scores_v + high_zScore_v;

%prepare reject points vector
rejected_vector_points_v = (rejected_vector_scores_v > reject_score_thresh);
rejected_vector_points_v = (filter(ones(1,window_length),1,rejected_vector_points_v) > 0); %merge short sections
rejected_vector_points_v(1:window_length) = true;
rejected_vector_points_v(end-window_length+1:end) = true;

%prepare reject sections matrix
sections_limits = [1 diff(rejected_vector_points_v) -1];
regected_sections_short_intervals = find(sections_limits == 1)';
regected_sections_short_intervals = [regected_sections_short_intervals  find(sections_limits == -1)' - 1];

%merge noise section with short clean intervals inbetween
regected_sections = [];
last_long_session = regected_sections_short_intervals(1,:);
for i=2:size(regected_sections_short_intervals,1)
    if regected_sections_short_intervals(i,1)-last_long_session(2) <= window_length
        last_long_session(2) = regected_sections_short_intervals(i,2);
    else
        regected_sections = [regected_sections; last_long_session];
        last_long_session = regected_sections_short_intervals(i,:);
    end
end
regected_sections = [regected_sections; last_long_session];

