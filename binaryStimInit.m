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