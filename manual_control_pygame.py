from djitellopy import Tello
import cv2
import pygame
import numpy as np
import time
import warnings
import datetime

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
        # Init pygame
        pygame.init()

        # Creat pygame window
        pygame.display.set_caption("Tello video stream")
        self.screen = pygame.display.set_mode([960, 720])#, pygame.FULLSCREEN)

        # Init Tello object that interacts with the Tello drone
        self.tello = Tello()

        # Drone velocities between -100~100
        self.for_back_velocity = 0
        self.left_right_velocity = 0
        self.up_down_velocity = 0
        self.yaw_velocity = 0
        self.speed = 10

        self.send_rc_control = False

        # create update timer
        pygame.time.set_timer(pygame.USEREVENT + 1, 1000 // FPS)

    def run(self, table):
        countFrame = 0
        self.tello.connect()
        self.tello.set_speed(self.speed)

        # In case streaming is on. This happens when we quit this program without the escape key.
        self.tello.streamoff()
        self.tello.streamon()

        frame_read = self.tello.get_frame_read()

        should_stop = False
        while not should_stop:

            for event in pygame.event.get():
                if event.type == pygame.USEREVENT + 1:
                    #self.update()
                    if table.empty() == True:
                        self.update()
                    else:
                        command = table.get()
                        if command == 3:
                            event.key = 119
                            self.keydown(event.key)
                            self.update()
                            time.sleep(1)
                            self.keyup(event.key)
                            self.update()
                            time.sleep(0.5)
                            self.update()
                            time.sleep(0.5)
                        # elif command == 2:
                        #     event.key = 115
                        #     self.keydown(event.key)
                        #     self.update()
                            # time.sleep(0.5)
                            # self.keyup(event.key)
                            # self.update()
                            # time.sleep(0.5)
                            # self.update()
                            # time.sleep(0.5)


                elif event.type == pygame.QUIT:
                    should_stop = True
                elif event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_ESCAPE:
                        should_stop = True
                    else:
                        self.keydown(event.key)
                elif event.type == pygame.KEYUP:
                    self.keyup(event.key)


            if frame_read.stopped:
                break

            if frame_read.stopped:
                break

            self.screen.fill([0, 0, 0])

            frame = frame_read.frame
            if countFrame % 10 == 0:
                frame[300:375, 825:900, :] = 0
                cv2.arrowedLine(frame, (835, 333), (890, 333), (255, 255, 255), 5, tipLength=0.5)
            if countFrame % 20 == 0:
                frame[300:375, 75:150, :] = 0
                cv2.arrowedLine(frame, (140, 333), (85, 333), (255, 255, 255), 5, tipLength=0.5)
            if countFrame % 16 == 0:
                frame[50:125, 450:525, :] = 0
                cv2.arrowedLine(frame, (485, 115), (485, 60), (255, 255, 255), 5, tipLength=0.5)
            if countFrame % 8 == 0:
                frame[600:675, 450:525, :] = 0
                cv2.arrowedLine(frame, (485, 610), (485, 665), (255, 255, 255), 5, tipLength=0.5)
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
            self.send_rc_control = True
        elif key == pygame.K_l:  # land
            not self.tello.land()
            self.send_rc_control = False

    def update(self):
        """ Update routine. Send velocities to Tello."""
        if self.send_rc_control:
            self.tello.send_rc_control(self.left_right_velocity, self.for_back_velocity,
                self.up_down_velocity, self.yaw_velocity)


def main(table):

    frontend = FrontEnd()

    # run frontend
    frontend.run(table)


if __name__ == '__main__':
    main()
