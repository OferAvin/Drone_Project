function vidObj = vector2avi(vec, FPS, fileName)

%Defualt FPS is 30
if nargin < 2
    FPS = 30;
end

%Allocation
grayMat = zeros(1000,1000,length(vec));

%Draw frame by frame and save it
% DO NOT TOUCH THE FIGURE WHILE RUNNING!
for i = 1:length(vec)
     grayMat(:,:,i) = vec(i);
    imshow(grayMat(:,:,i))
    vidVector(i) = getframe;
end


%Create video object
vidObj = VideoWriter(fileName);
vidObj.FrameRate = FPS; %set your frame rate

%Write the avi file
open(vidObj);
writeVideo(vidObj,vidVector);
close(vidObj);
