from moviepy.editor import VideoFileClip, clips_array
from moviepy.video.fx import all
import os
import pygame


def main():
    x = 1000
    y = 90
    os.environ['SDL_VIDEO_WINDOW_POS'] = "%d,%d" % (x, y)

    pygame.init()
    pygame.display.set_mode((100, 100))
    clip1 = VideoFileClip('croped_6Hz.mp4').margin(10)
    clip2 = VideoFileClip('croped_7.5Hz.mp4').margin(10)
    clip1 = clip1.loop(n=1000)
    clip2 = clip2.loop(n=1000)
    clipArray = clips_array([[clip1], [clip2]])
    clipArray.preview()

if __name__ == '__main__':
    main()

