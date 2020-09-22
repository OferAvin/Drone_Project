clear ; close all; clc
curPath = pwd;
vidPath = [curPath '\vid.mp4'];
VideoObject = VideoReader(vidPath);
i = 0; %Iteration intialization

% video is 34.15 seconds long, divide by 8 is 4.268 seconds in real time.
% 1024 frames divide by 4.268 is 239.92. Approx into 240 FPS.
fps = 30; 

freqR = 6; %in HZ
freqL = 5;
freqU = 10;
freqD = 3;

%Allocations
width = VideoObject.Width;
height = VideoObject.Height;
frames_N = floor(VideoObject.Duration*VideoObject.FrameRate);
grayFrames = zeros(height, width, frames_N);

%Creating Frames array
while hasFrame(VideoObject)
    i = i + 1; %Iteration count
    currentFrame = readFrame(VideoObject);
    if mod(i, fps/freqL) == 0
        currentFrame(360:379,10:29,1) = 200;
        currentFrame(360:379,10:29,2) = 40;
        currentFrame(360:379,10:29,3) = 140;
    end
    
    if mod(i, fps/freqR) == 0
    currentFrame(360:379,1250:1269,1) = 200;
    currentFrame(360:379,1250:1269,2) = 40;
    currentFrame(360:379,1250:1269,3) = 140;
    end

    if mod(i, fps/freqU) == 0
    currentFrame(10:29,640:659,1) = 200;
    currentFrame(10:29,640:659,2) = 40;
    currentFrame(10:29,640:659,3) = 140;
    end

    if mod(i, fps/freqD) == 0
    currentFrame(690:709,640:659,1) = 200;
    currentFrame(690:709,640:659,2) = 40;
    currentFrame(690:709,640:659,3) = 140;
    end

    grayFrames(:,:,i) = rgb2gray(currentFrame); 
    imshow(currentFrame)
end

%Total values of the matrix (the higher it is, the whiter it is)
totValues = squeeze(sum(grayFrames, [1,2]));

%Visualizing
figure(2)
plot((0:frames_N-1)/fps, totValues); xlim([0,frames_N/fps]); 

%Peaks locations
[~,pks] = findpeaks(totValues);

%Number of frames between peaks
difference = diff(pks);

%FFT
[signal_fft , f] = myFFT(totValues,[1,50], fps);
figure(2)
plot(f, signal_fft)

