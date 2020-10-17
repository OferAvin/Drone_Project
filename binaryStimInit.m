function [binarySteady] = binaryStimInit(refreshRate,freqList,stimTime,figureFlag)
%% This function creats 3 vectors containing a binary sequence of sine waves 
% freqList - list of frequencies to create [Hz]
% refreshRate - refresh rate for the monitor [Hz]
% stimTime - overall time of binary sequence [sec]
% figureFlag - would you like to show the output waves?


%% Default visualization to zero
if nargin<4
    figureFlag = 0;
elseif nargin<3
    disp('Missing time variable (or function input order is messed up...)');
    return
end

% Initialize variables
dt = 1/refreshRate;
time  = 0:dt:stimTime;                 % overall stim time
binarySteady = [];

%% Create sine wave
for freq = 1:length(freqList) 
    binarySteady(freq,:) = cos(2*pi*freqList(freq).*time);  
end

%% Change to binary signal (0 & 1) for total dark and total white
binarySteady(binarySteady>0) = 1;
binarySteady(binarySteady<0) = 0;

%% Visualization for debugging
if figureFlag
    figure;
    stem(time,binarySteady);
    xlabel('sec');
end
