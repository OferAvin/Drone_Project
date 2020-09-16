<<<<<<< HEAD
clear all;close all;
vidObj = VideoReader('C:\Users\ofera\Studies\drone_proj\vid.mp4');

th = 180;
i = 1;

%display frame by frame (play video)
currAxes = axes;
while hasFrame(vidObj)
    vidFrame = readFrame(vidObj); %read next frame
    r = vidFrame(:,:,1);
    maxVal(i) = max(max(r(355:365,635:645)));
    %   image(vidFrame, 'Parent',currAxes);
    imshow(vidFrame, 'Parent',currAxes);
    currAxes.Visible = 'off';
    pause(1/vidObj.FrameRate);
    i = i + 1;
end
bwVec = maxVal > th;
changesVec = diff(bwVec);
framePerChange = diff(find(changesVec ~= 0);

allFrames = re(vidObj); %read all frames
size(allFrames)

r = vidFrame(:,:,1);
g = vidFrame(:,:,2);
b = vidFrame(:,:,3);
I = rgb2gray(vidFrame);
=======
clear ; close all; clc

VideoObject = VideoReader("C:\Users\ophir\Desktop\Uni\BCI\Drone_Project\ScreenFlickerCropped.mp4");
i = 0; %Iteration intialization

% video is 34.15 seconds long, divide by 8 is 4.268 seconds in real time.
% 1024 frames divide by 4.268 is 239.92. Approx into 240 FPS.
fps = 240; 

%Allocations
width = VideoObject.Width;
height = VideoObject.Height;
frames_N = VideoObject.NumFrames;
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

>>>>>>> b2d4edeba2418a5fc47f3d95cfdd485ef5b8f7ad
