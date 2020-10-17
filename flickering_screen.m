close all

refreshRT = 60;
freq = 40;
timeToRun = 10; %in sec
dt = 1/refreshRT;

binarySteady = binaryStimInit(refreshRT,freq,timeToRun);


%choose colors
colors = 'bw'; %yb for yellow and blue or bw for black and white

if (colors == 'yb')
    cor1 = [1, 1, 0.85];
    cor2 = [0.09,0.09,0.25];
else
    cor1 = "white";
    cor2 = "black";
end

%define figure
f = figure('Name', 'flickering','units', 'normalized', 'position', [0.3 0.3 0.35 0.35]);
set(gca, 'color','black')
set(gca,'LooseInset',get(gca,'TightInset'))% get rid of margines
set(gca,'xtick', [], 'ytick', [])% get rid of axis
set(f,'MenuBar', 'none');%get rid of toolbar
% set(f, 'ToolBar', 'none');



%flicker
t = timeToRun;
count=1;
while(t > 0)
    if binarySteady(count) == 1
        set(gca, 'color',cor1)
    else
        set(gca, 'color',cor2)
    end
    t = t-dt;
    count = count+1;
    pause(dt)
end

