function [ x, y ] = Datapixx_wait_for_touch_coordinates( varargin )
%DATAPIXX_WAIT_FOR_TOUCH_COORDINATES [ x, y ] = Datapixx_get_first_touch_coords( [calibration_matrix], [screen_resolution] )
% This function repeatedly checks the Datapixx, to see if there is any
% touch event, It holds execution until the screen is touched.
% Input arguments are:
%   -> [optional]: You should always specify a calibration matrix. You can
%       make do without, but the coordinates will be most likely off. You
%       can generate a calibration matrix using the function
%       Datapixx_calibrate_touchpixx().
%   -> [optional]: the screen resoltion as a 2-entry array, example [800, 600]
%       If this argument is not specified, it will default to 1920x1080.
% Output values are:
% x and y are the touch point coordinates, rounded to the nearest pixel.
    if(isempty(varargin))
        screen_resolution = [1920, 1080]; % Hard-code this resolution
        calibration_matrix = []; % No calibration matrix is given.
    end
    % If only one argument is given
    if(length(varargin) == 1)
        [rows, columns] = size(varargin{1});
        if((rows == 3) && (columns == 2))
            calibration_matrix = varargin{1};
            screen_resolution = [1920, 1080]; % Hard-code this resolution
        else
            error('Improper argument given: The calibration matrix should be a 3-by-2 matrix.')
        end
    end
    
    %If two arguments are given
    if(length(varargin) == 2)
        %Check if calibration matrix is valid.
        [rows, columns] = size(varargin{1});
        if((rows == 3) && (columns == 2))
            calibration_matrix = varargin{1};
        else
            error('Improper argument given: The calibration matrix should be a 3-by-2 matrix.')
        end
        %Check if screen resolution valid
        if(length(varargin{2}) == 2)
            screen_resolution = varargin{2};
        else
            error('Improper argument given: The screen resolution should be a two-element vector.')
        end
    end
    
    if(length(varargin) > 2)
        error('This function only can handle two optional arguments.')
    end
    
    screen_is_touched = 0;
    
    if(Datapixx('IsReady'))
        % Since this can be called from anywhere, we better sync ourselves.
        % It's dirty, but it works!
        while(~screen_is_touched)
            Datapixx('RegWrRd');
            touch_status = Datapixx('GetTouchPixxStatus');
        
            if(touch_status.isPressed == 1)
                screen_is_touched = 1;
                % If we had a touch, scale the coordinates, and round them to
                % the nearest pixel.
                if(isempty(calibration_matrix))
                    x = round(touch_status.touchX * screen_resolution(1));
                    y = round((1-touch_status.touchY) * screen_resolution(2)); % Y axis is inverted.
                    warning('No calibration matrix is specified. The touch data is most likely off!')
                else
                    % Now we can restore the coordinates using the
                    % calibration matrix.
                    uncalibrated_touch_x = touch_status.touchX;
                    uncalibrated_touch_y = touch_status.touchY;
                    % X_c = alpha_x * X + beta_x * X + delta_x
                    x = calibration_matrix(1, 1) * uncalibrated_touch_x + calibration_matrix(2, 1) * uncalibrated_touch_y + calibration_matrix(3, 1);
                    % Y_c = alpha_y * Y + beta_y * Y + delta_y
                    y = calibration_matrix(1, 2) * uncalibrated_touch_y + calibration_matrix(2, 2) * uncalibrated_touch_y + calibration_matrix(3, 2);
                    
                    % ..and now, we can scale things up with the screen
                    % resolution. Round to the nearest pixel.
                    x = round(x * screen_resolution(1));
                    y = round(y * screen_resolution(2));
                end
            
            end
        end
        
    else
        error('Can''t connect to the Datapixx. Is it initialised?')
    end
end


