function [data , trials_N] = seekout_trials(folder_name, lowCutoff, highCutoof)
%MATLAB R2019b
%
% © Ophir Almagor - 2020
%
%Seeking for fitted data files in data directory, giving number of files to
%analyze and the ID of trial with file path.
%
%data - Structure with the filtered EEG recording for each trial, with
%condition (Full, Before video, While video, After video).
%
%trials_N - number of trials to be analyzed
%
%folder_name - data directory name
%
%lowCutoff - Low edge cutoff for filter.
%
%highCutoff - High edge cutoff for filter.
%
%--------------------------------------------------------------------------------

data_files = dir(folder_name);
N_files = length(data_files); %number of files in data_dir.
trials_N = 0; % will be number of subjects after checking the files.

%% Saving relevant files data in cell

%Make sure data is saved with template ['SSVEP_trial_(trial#).edf'])


for data_i = 1:N_files
    current_file = data_files(data_i).name;
    if regexp(current_file ,'SSVEP_trial_\d*')
        trials_N = trials_N + 1; %Adding +1 to subjects count.
        ID(trials_N) = str2double(regexp(current_file , '\d*'  , 'match'));  %Getting trial ID
        filePath = [data_files(trials_N).folder ,'\', current_file]; %EEG recording file location
        trial_data = EEG_edf_load(filePath, lowCutoff, highCutoof); %Load, filter and trim each recording.
        data.filtered{trials_N} = trial_data.filtered;
        data.before{trials_N} = trial_data.before ;
        data.after{trials_N} = trial_data.after;
        data.video{trials_N} = trial_data.video;
        
    end
end

clearvars -except data trials_N ID

%Making sure the subjects are in correct order.
[~,order] = sort(ID);
data.filtered = data.filtered(order);
data.before = data.before(order);
data.after = data.after(order);
data.video = data.video(order);

