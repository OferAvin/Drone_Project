from moviepy.editor import VideoFileClip, clips_array, vfx
import os
import pygame


def main():
    x = 930
    y = 60
    os.environ['SDL_VIDEO_WINDOW_POS'] = "%d,%d" % (x, y)

    pygame.init()
    pygame.display.set_mode((100, 100))
    clip1 = VideoFileClip('croped_6Hz.mp4').margin(10)
    clip2 = VideoFileClip('croped_7.5Hz.mp4').margin(10)
    clipArray = clips_array([[clip1],[clip2]])
    clipArray.preview()

if __name__ == '__main__':
    main()

