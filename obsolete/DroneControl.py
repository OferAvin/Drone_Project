from djitellopy import Tello
import cv2
import pygame
import numpy as np
import time
import os
import warnings
import datetime
from enum import Enum


# TODO: Class is copied here and in the DSI, need to make it global.
class Commands(Enum):
    idle = 0
    up = 6
    down = 7
    flip = 69
    stop = 'Stop'

# Speed of the drone
S = 30
# Frames per second of the pygame window display
# A low number also results in input lag, as input information is processed once per frame.
FPS = 120

class FrontEnd(object):
    """ Maintains the Tello display and moves it through the keyboard keys.
        Press escape key to quit.
        The controls are:
            - T: Takeoff
            - L: Land
            - Arrow keys: Forward, backward, left and right.
            - A and D: Counter clockwise and clockwise rotations (yaw)
            - W and S: Up and down.
    """

    def __init__(self):
        x = 10
        y = 60
        os.environ['SDL_VIDEO_WINDOW_POS'] = "%d,%d" % (x, y)
        # Init pygame
        pygame.init()

        # Creat pygame window
        pygame.display.set_caption("Tello video stream")
        self.screen = pygame.display.set_mode([960, 720])  # , pygame.FULLSCREEN)

        # Init Tello object that interacts with the Tello drone
        self.tello = Tello()

        # Drone velocities between -100~100
        self.for_back_velocity = 0
        self.left_right_velocity = 0
        self.up_down_velocity = 0
        self.yaw_velocity = 0
        self.speed = 10

        self.rc_control_flg = False

        # create update timer
        # pygame.time.set_timer(pygame.USEREVENT + 1, 1000 // FPS) # Change 1000 to 0.

    def run(self, table):
        countFrame = 0
        self.tello.connect()
        self.tello.set_speed(self.speed)

        # In case streaming is on. This happens when we quit this program without the escape key.
        self.tello.streamoff()
        self.tello.streamon()

        frame_read = self.tello.get_frame_read()
        flight_flag = False
        should_stop = False
        while not should_stop:
            command = table.get()
            self.tello.commandDone = False
            while self.tello.commandDone == False:
                timeStamp = str(datetime.datetime.now())
                print('Command for Drone: ' + str(command[0]) + ' at time ' + timeStamp)
                # Up
                if command[0] == Commands.up:
                    if flight_flag:
                        # self.tello.move_up(50)
                        self.tello.send_rc_control(0, 0, 30, 0)
                        time.sleep(1)
                        self.tello.send_rc_control(0, 0, 0, 0)
                    else:
                        self.tello.takeoff()
                        flight_flag = True
                        time.sleep(1.95)
                # Down
                elif command[0] == Commands.down:
                    # self.tello.move_down(50)
                    self.tello.send_rc_control(0, 0, -30, 0)
                    time.sleep(1)
                    self.tello.send_rc_control(0, 0, 0, 0)
                    # Flip
                elif command[0] == Commands.flip:
                    self.tello.flip_back()
                    time.sleep(1.95)
                elif command[0] == Commands.stop:
                    should_stop = True

            if frame_read.stopped:
                break

            self.screen.fill([0, 0, 0])

            # Display next frame
            frame = frame_read.frame
            text = "Battery: {}%".format(self.tello.get_battery())
            cv2.putText(frame, text, (5, 720 - 5),
                        cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 0, 255), 2)
            frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            frame = np.rot90(frame)
            frame = np.flipud(frame)

            frame = pygame.surfarray.make_surface(frame)
            self.screen.blit(frame, (0, 0))
            pygame.display.update()
            countFrame += 1
            time.sleep(1 / FPS)

        # Call it always before finishing. To deallocate resources.
        self.tello.end()

    def keydown(self, key):
        """ Update velocities based on key pressed
        Arguments:
            key: pygame key
        """
        print(key)
        if key == pygame.K_UP:  # set forward velocity value = 1073741906
            self.for_back_velocity = S
        elif key == pygame.K_DOWN:  # set backward velocity
            self.for_back_velocity = -S
        elif key == pygame.K_LEFT:  # set left velocity
            self.left_right_velocity = -S
        elif key == pygame.K_RIGHT:  # set right velocity
            self.left_right_velocity = S
        elif key == pygame.K_w:  # set up velocity
            self.up_down_velocity = S
        elif key == pygame.K_s:  # set down velocity
            self.up_down_velocity = -S
        elif key == pygame.K_a:  # set yaw counter clockwise velocity
            self.yaw_velocity = -S
        elif key == pygame.K_d:  # set yaw clockwise velocity
            self.yaw_velocity = S

    def keyup(self, key):
        """ Update velocities based on key released
        Arguments:
            key: pygame key
        """
        if key == pygame.K_UP or key == pygame.K_DOWN:  # set zero forward/backward velocity
            self.for_back_velocity = 0
        elif key == pygame.K_LEFT or key == pygame.K_RIGHT:  # set zero left/right velocity
            self.left_right_velocity = 0
        elif key == pygame.K_w or key == pygame.K_s:  # set zero up/down velocity
            self.up_down_velocity = 0
        elif key == pygame.K_a or key == pygame.K_d:  # set zero yaw velocity
            self.yaw_velocity = 0
        elif key == pygame.K_t:  # takeoff
            self.tello.takeoff()
            self.rc_control_flg = True
        elif key == pygame.K_l:  # land
            not self.tello.land()
            self.rc_control_flg = False

    def update(self):
        """ Update routine. Send velocities to Tello."""
        if self.rc_control_flg:
            self.tello.send_rc_control(self.left_right_velocity, self.for_back_velocity,
                                       self.up_down_velocity, self.yaw_velocity)


def main(table):
    frontend = FrontEnd()

    # run frontend
    frontend.run(table)


if __name__ == '__main__':
    main()
