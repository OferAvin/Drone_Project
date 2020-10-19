<<<<<<< HEAD
fs = 512; % Sampling frequency (samples per second) 
dt = 1/fs; % seconds per sample 
StopTime = 10; % seconds 
t = (0:dt:StopTime)'; % seconds 
F = 2; % Sine wave frequency (hertz) 

f = figure('Name', 'flickering','units', 'normalized', 'position', [0.3 0.3 0.35 0.35]);
set(gca, 'color','black')
set(gca,'LooseInset',get(gca,'TightInset'))% get rid of margines
set(gca,'xtick', [], 'ytick', [])% get rid of axis
set(f,'MenuBar', 'none');%get rid of toolbar
% set(f, 'ToolBar', 'none');

for i = 1:length(t)
    data = sin(2*pi*F*t);
    if data(i) > 0
        set(gca, 'color',cor1)
    else
        set(gca, 'color',cor2)
    end
end

%%For one cycle get time period
T = 1/F ;
% time step for one time period 
tt = 0:dt:T+dt ;
d = sin(2*pi*F*tt) ;
plot(tt,d) ;
=======
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
>>>>>>> 788e853611a90a85654eb1d7ce5ec23843dcf922
