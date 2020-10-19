clear ; close all; clc
curPath = pwd;
vidPath = [curPath '\10_Hz_oculus.mp4'];
VideoObject = VideoReader(vidPath);
i = 0; %Iteration intialization

%Video FPS (normal is usually 30 FPS, slowmo is 240 FPS)
fps = 30; 



%Allocations
width = VideoObject.Width;
height = VideoObject.Height;
frames_N = floor(VideoObject.Duration*VideoObject.FrameRate);
grayFrames = zeros(height, width, frames_N);

%Creating Frames array
while hasFrame(VideoObject)
    i = i + 1; %Iteration count
    currentFrame = readFrame(VideoObject);
    grayFrames(:,:,i) = rgb2gray(currentFrame); 
end

%Total values of the matrix (the higher it is, the whiter it is)
totValues = squeeze(sum(grayFrames, [1,2]));

%Visualizing
figure(1)
plot((0:frames_N-1)/fps, totValues);
xlim([0,frames_N/fps]); 
xlabel('Frame'); ylabel('Total gray scale pixels value')
title('Video signal by pixels values')

%Peaks locations
[~,pks] = findpeaks(totValues);

%Number of frames between peaks
difference = diff(pks);

%FFT
[signal_fft , f] = myFFT(totValues,[1,fps/2], fps);
figure(2)
plot(f, signal_fft)
xlabel('Frequency [Hz]'); ylabel('Power [dB]')
title('FFT Power spectrum')
