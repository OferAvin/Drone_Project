clear; close all; clc;



curPath = pwd;
vidPath = [pwd '\OferVid.mp4'];
VideoObject = VideoReader(vidPath);

FPS = round(VideoObject.FrameRate);
Rate = 7.5; %in Hz

figure('Position', [0 0 1 1], 'Units', 'Normalized')
for i = 1:VideoObject.NumFrames
    currentFrame = readFrame(VideoObject);
    if mod(i,FPS/Rate) == 0
        currentFrame(20:80,20:80) = 1;
    end
    imshow(currentFrame)
end
