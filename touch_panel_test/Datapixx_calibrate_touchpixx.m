function [ calibration_matrix ] = Datapixx_calibrate_touchpixx( varargin )
%DATAPIXX_CALIBRATE_TOUCHPIXX [ calibration_matrix ] = Datapixx_calibrate_touchpixx( [display_number] )
%   This function executes a simple calibration process for the resistive
%   touch panel on the VIEWPixx screen. Effectively, it implements the
%   following:
% Fang, W. & Chang, T. (2007 Q3). Calibration in touch-screen systems.
% Analog Application Journal, (3), 5-9, Texas Instruments
% You can call this function in an already-initialised system, or on its
% own.
% Input argument is:
%   -> [optional]: You can specify the display number for stand-alone
%   execution.
% It returns a 2-by-3 calibration matrix, which can be used in subsequent
% applications

    if(isempty(varargin))
        %If no input argument is supplied, we use the highest number
        %display for the window pointer.
        display_number = max(Screen('Screens'));
    else
        display_number = varargin{1}
        if(length(varargin{1}) > 1)
            error('Only a single number is requred for the display number.')
        end
    end
    if(length(varargin) > 1)
        error('This function only takes a single optional argument.')
    end

    %If you want additional points, put them here. The columns (X and Y)
    %are normalised between 0 and 1.
    test_points_set = [
        0.05, 0.05;
        0.95, 0.05;
        0.95, 0.95;
        0.05, 0.95;
        0.5, 0.5;
    ];

    %We have a bunch of other things too:
    touch_cross_size = 32; % This HALF the touch cross size. In pixels.
    touch_cross_line_width = 4; % This is also in pixels.
    touch_cross_colour = [255, 255, 255]; % Cross is white.
    touch_feedback_diameter = 10; % Again, pixels.
    touch_feedback_uncalibrated_colour = [160, 0, 0]; % Red.
    touch_feedback_calibrated_colour = [0, 160, 0]; % Green.
    
    touch_points_measured = zeros(length(test_points_set), 2); %Pre-allocate this array, this is where we save the measured touch points.
    touch_points_corrected = zeros(length(test_points_set), 2); %Pre-allocate this array, this is where we save the restored touch points.

    % Create the touch cross coordinates. Thanks to Peter Scarfe!
    touch_cross_x = [-touch_cross_size, touch_cross_size, 0, 0];
    touch_cross_y = [0, 0, -touch_cross_size, touch_cross_size];
    touch_cross_coordinates = [touch_cross_x; touch_cross_y];

    
    %% Stage 1. Set up Datapixx.
    Datapixx('Open'); % Initialise comms to the hardware
    Datapixx('StopAllSchedules'); % Stop whatever it is doing
    video_status = Datapixx('GetVideoStatus');
     
    % TOUCHPixx
    Datapixx('EnableTouchPixx');
    Datapixx('StartTouchPixxLog'); %Enable logging of touch events.
    Datapixx('SetTouchpixxStabilizeDuration', 0.01); % 10 ms.
    Datapixx('RegWrRd'); % Sync with the device.
    touch_status = Datapixx('GetTouchPixxStatus'); % Get the TOUCHPixx status structure
    
    %% Stage 2. Graphics.
    % Don't mess things up when the graphics window is already open.
    if(isempty(Screen('Windows')))
        %If we got here, the graphics window is not open.
        AssertOpenGL;

        Screen('Preference', 'VisualDebugLevel', 0); % Keep things quiet.
        [w, screen_rectangle] = Screen('OpenWindow', display_number, 0); % 0 is the backround colour, in this case, black.
        kill_graphics_at_the_end = 1; % The window will close at the end of this function
    else
        % If we got here, the display is already initialised.
        w = Screen('Windows');
        if(length(w) > 1)
            error('You seem to have more than one graphics window open simultaneously?')
        end
        screen_rectangle = Screen('Rect', w);
        kill_graphics_at_the_end = 0; % The window will be preserved.
    end
    Screen('TextSize', w, 36);
    Screen('TextFont', w, 'Times New Roman');

    
    screen_x = screen_rectangle(3); % This is from the detected display. On the VIEWPixx, this should be 1920
    screen_y = screen_rectangle(4); % ...and this one should be 1080 on the VIEWPixx.
    
    %% Stage 3. Collect un-calibrated samples.

    for(i = 1:length(test_points_set))
        % As we go through the array, re-calculate the position of the touch
        % cross.
        touch_cross_position = [ (test_points_set(i, 1) * screen_x) ((test_points_set(i, 2) * screen_y))]; 
        % This is the instruction that draws the cross into the frame buffer
        Screen('DrawLines', w, touch_cross_coordinates, touch_cross_line_width, touch_cross_colour, touch_cross_position);
        % ...and this is the instruction that puts the frame buffer to the
        % screen.
        DrawFormattedText(w, 'Touch the crosses. The red dots show the raw, uncalibrated data.\n', 'center', 'center', touch_cross_colour);
        Screen('Flip', w);


        % Now wait to get the touch coordinates.
        while(touch_status.isPressed == 0)
            % We poll the Datapixx to see if there are coordinates. We have
            % valid coordinates, when the screen is touched.
            Datapixx('RegWrRd'); % Sync with the device.
            touch_status = Datapixx('GetTouchPixxStatus'); % Get the TOUCHPixx status structure
        end
        % If we got out of the loop, we have valid touch coordinates.
        touch_points_measured(i, :) = Datapixx('GetTouchPixxCoordinates'); 

        % Provide some visual feedback. The Y axis is inverted, we
        % compensate for that here.
        feedback_circle_center = [touch_points_measured(i, 1) * screen_x, (1-touch_points_measured(i, 2)) * screen_y]; % This is determined as per 'raw' touch panel coordinates
        feedback_position_uncalibrated = [feedback_circle_center(1) - touch_feedback_diameter, feedback_circle_center(2) - touch_feedback_diameter, feedback_circle_center(1) + touch_feedback_diameter, feedback_circle_center(2) + touch_feedback_diameter];
        DrawFormattedText(w, 'Touch the crosses. The red dots show the raw, uncalibrated data.\n', 'center', 'center', touch_cross_colour);
        Screen('FillOval', w, touch_feedback_uncalibrated_colour, feedback_position_uncalibrated);
        Screen('Flip', w);

        % Now we wait for the touch panel to be released.
        pause(0.5); % Wait a bit.
        while(touch_status.isPressed == 1)
            % We poll the Datapixx to see if there are coordinates. We have
            % valid coordinates, when the screen is touched.
            Datapixx('RegWrRd'); % Sync with the device.
            touch_status = Datapixx('GetTouchPixxStatus'); % Get the TOUCHPixx status structure
        end    
    end
    
    %% Stage 4: Do some number crunching!
    % Texas Instruments have some really cool literature about this. I wish I
    % had known these when I was a teenager, as my touch devices would have
    % been so much better.
    % I like the five-point example so much, I will do it literally as it was
    % described. It can be done simpler, but this is aesthetic.

    x_display_normalised_coordinates = test_points_set(:, 1);
    y_display_normalised_coordinates = test_points_set(:, 2);

    % This 'A' matrix is the measured touch coordinates, with a bunch on ones whacked on column 3 
    A_matrix = cat(2, touch_points_measured, ones(5, 1));

    % Now we use this to calculate the error vectors. This takes both scalingm
    % angles, and shifts into account. Brilliant. First column is X, second
    % column is Y.
    calibration_matrix(:, 1) = (A_matrix' * A_matrix)^(-1) * A_matrix' * x_display_normalised_coordinates;
    calibration_matrix(:, 2) = (A_matrix' * A_matrix)^(-1) * A_matrix' * y_display_normalised_coordinates;
    
    %% Stage 5: Feedback.
    no_of_test_touches = 3;
    for(i = 1:no_of_test_touches) 
        % As we go through the array, re-calculate the position of the touch
        % cross.
        DrawFormattedText(w, 'Please verify calibration.\n\n\n Call this function again if something is wrong.\n\n', 'center', 'center', touch_cross_colour);
        Screen('Flip', w);


        % Now wait to get the touch coordinates.
        while(touch_status.isPressed == 0)
            % We poll the Datapixx to see if there are coordinates. We have
            % valid coordinates, when the screen is touched.
            Datapixx('RegWrRd'); % Sync with the device.
            touch_status = Datapixx('GetTouchPixxStatus'); % Get the TOUCHPixx status structure
        end
        % If we got out of the loop, we have valid touch coordinates.
        touch_points_measured(i, :) = Datapixx('GetTouchPixxCoordinates');

        % Now we can restore the coordinates. I have separated this, because it
        % will most probably be a function later-on
        uncalibrated_touch_x = touch_points_measured(i, 1);
        uncalibrated_touch_y = touch_points_measured(i, 2);
        touch_points_corrected(i, 1) = calibration_matrix(1, 1) * uncalibrated_touch_x + calibration_matrix(2, 1) * uncalibrated_touch_y + calibration_matrix(3, 1);
        touch_points_corrected(i, 2) = calibration_matrix(1, 2) * uncalibrated_touch_x + calibration_matrix(2, 2) * uncalibrated_touch_y + calibration_matrix(3, 2);


        % Provide some visual feedback.
        feedback_circle_center = [touch_points_corrected(i, 1) * screen_x, touch_points_corrected(i, 2) * screen_y]; % This is determined as per 'raw' touch panel coordinates
        feedback_position_calibrated = [feedback_circle_center(1) - touch_feedback_diameter, feedback_circle_center(2) - touch_feedback_diameter, feedback_circle_center(1) + touch_feedback_diameter, feedback_circle_center(2) + touch_feedback_diameter];
        Screen('FillOval', w, touch_feedback_calibrated_colour, feedback_position_calibrated);
        DrawFormattedText(w, sprintf('%d/%d', i, no_of_test_touches), 'center', 'center', touch_cross_colour);
        Screen('Flip', w);

        % Now we wait for the touch panel to be released.
        pause(0.5); % Wait a bit.
        while(touch_status.isPressed == 1)
            % We poll the Datapixx to see if there are coordinates. We have
            % valid coordinates, when the screen is touched.
            Datapixx('RegWrRd'); % Sync with the device.
            touch_status = Datapixx('GetTouchPixxStatus'); % Get the TOUCHPixx status structure
        end    
    end
    %% Clean up.
    
    Screen('Flip', w); %Clear the screen.
    DrawFormattedText(w, 'All done, calibration matrix generated.', 'center', 'center', touch_cross_colour);
    Screen('Flip', w);
    pause(3);
    Screen('Flip', w);
    if(kill_graphics_at_the_end == 1)
        % If this function was executed stand-alone, kill the graphics.
        sca;
        Datapixx('Close');
    end
    
end