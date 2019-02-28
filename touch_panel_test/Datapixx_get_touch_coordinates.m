function [ screen_is_touched, touch_coordinates ] = Datapixx_get_touch_coordinates( varargin )
%DATAPIXX_GET_TOUCH_COORDINATES [ screen_is_touched, touch_coordinates ] = Datapixx_get_touch_coordinates( calibration_matrix, [OPTIONAL]display_resolution )
%   This function fetches touch data, and converts it to screen coordinates
%   using the supplied calibration matrix.
% Input arguments are:
%   -> calibration_matrix is a 3-by-2 matrix, generated by Datapixx_calibrate_touchpixx.
%   -> [OPTIONAL] screen_resolution is a 1-by-2 vector containing the X and Y resolution. By default it's set to 1920x1080, but if you use something weird or exotic, you can change it here.
% Returns:
% - screen_is_touched, which is a boolean.
% - touch_coordinates, which is an X-Y vector.
% When 'screen_is_touched' is 'true', the touch coordinates are valid.
    
    %% Sanity checks.
    % Too many input arguments
    if(length(varargin) > 2)
        error('This function can only up to two input arguments: the calibration matrix and the screen dimensionss. Run Datapixx_calibrate_touchpixx() to make it!')
    end
    % No input argument
    if(length(varargin) == 0)
        warning('No calibration matrix was specified. Displaying raw coordinate data.')
        calibration_matrix = [1, 1; 1, 1; 0, 0; ]; % This one will do nothing with the coordinates.
    end
    % Weird matrix.
    [rows, columns] = size(varargin{1});
    if( (rows ~= 3) || (columns ~=2))
        error('The calibration marix is incorrect. It should have 3 rows and 2 columns.')
    else
        % If it is the right shape, just accept it as working.
        calibration_matrix = varargin{1};
        display_resolution = [1920, 1080]; % This is the default for the VIEWPixx monitor.
    end
    % Do we have a custom resolution? Is it correct?
    if(length(varargin) == 2)
        if(length(varargin{2}) == 2)
            %If we got here, we can assign the display resolution. Guess we could check if the numbers are correct.
            display_resolution = varargin{2};
        else
            error('display_resolution should be a 2-element array.')
        end
    end
    % Do we even have a Datapixx?
    if(~Datapixx('IsReady'))
        error('This function needs the datapixx to be present and initialised.')
    end
    
    
    %% Main course.
    Datapixx('RegWrRdVideoSync'); % Sync with the device at video sync
    touch_status = Datapixx('GetTouchPixxStatus');
    
    if(touch_status.isPressed == 1)
        screen_is_touched = true;
        touch_raw_data = Datapixx('GetTouchPixxCoordinates');
    else
        screen_is_touched = false;
        touch_raw_data = [0, 0];
    end
    % Calculate the return coordinates.
    touch_coordinates(1) = calibration_matrix(1, 1) * touch_raw_data(1) + calibration_matrix(2, 1) * touch_raw_data(1) + calibration_matrix(3, 1);
    touch_coordinates(2) = calibration_matrix(1, 2) * touch_raw_data(2) + calibration_matrix(2, 2) * touch_raw_data(2) + calibration_matrix(3, 2);

    % Scale up with the display resolution
    touch_coordinates = touch_coordinates .* display_resolution; % ...and this makes the results in pixels.
end

