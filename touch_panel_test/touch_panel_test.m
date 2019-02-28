% This script checks touch panel.

clear all;

clc;

display_number = max(Screen('Screens'));
touch_feedback_diameter = 10;
touch_feedback_colour = [0, 0, 160]; % Blue.
%% Start screen

AssertOpenGL;

Screen('Preference', 'VisualDebugLevel', 0); % Keep things quiet.
[w, screen_rectangle] = Screen('OpenWindow', display_number, 0); % 0 is the backround colour, in this case, black.
Screen('TextSize', w, 36);
Screen('TextFont', w, 'Times New Roman');

    
screen_x = screen_rectangle(3); % This is from the detected display. On the VIEWPixx, this should be 1920
screen_y = screen_rectangle(4); % ...and this one should be 1080 on the VIEWPixx.


%% Create calibration matrix

calibration_matrix = Datapixx_calibrate_touchpixx();

%% Show touches.
while(1)
    
    % Get the touch coordinates.
    [screen_is_touched, feedback_circle_center] = Datapixx_get_touch_coordinates(calibration_matrix);
   
    % Provide some visual feedback.
    feedback_position = [feedback_circle_center(1) - touch_feedback_diameter, feedback_circle_center(2) - touch_feedback_diameter, feedback_circle_center(1) + touch_feedback_diameter, feedback_circle_center(2) + touch_feedback_diameter];
    if(screen_is_touched)
        % If the touch screen is pressed, draw the circle.
        Screen('FillOval', w, touch_feedback_colour, feedback_position);
    end
    Screen('Flip', w);
end