function [ button_status ] = Datapixx_check_button_status( din_no, varargin )
%DATAPIXX_CHECK_BUTTON_STATUS
%[ button_status ] = Datapixx_check_button_status( din_no, [OPTIONAL]din_values )
% Since I got sick of bitbanging every damn time I need to check a button,
% here is a function that returns the status of the button.
% IMPORTANT: You must make sure that the DataPixx is actually turned on and
% initialised correctly!
% Input argument is:
%   -> din_no is the DIN line number, as per the RESPONSEPixx,
%       -DIN 0: Red button
%       -DIN 1: Yellow button
%       -DIN 2: Green button
%       -DIN 3: Blue button
%       -DIN 4: White button 
%   -> din_values is an optional input argument, the decimal representation
%       of the statuses of the DIN lines, which you get with:
%       Datapixx('GetDinValues');
%       If you are using this function in a render loop, make sure you call
%       Datapixx('RegWrRdVideoSync'); and then call the function as:
%       button_status = Datapixx_check_button_status( din_no, Datapixx('GetDinValues'));
%       Otherwise, you might get race conditions preventing your data from
%       being read out.
% Return value is:
%   din_status: 1 for button pressed, and 0 for button not pressed.

    % Sanity checks
    if(length(varargin) == 0)
        %no input argument was given
        poll_datapixx = 1; % We have to sync with the device within the function
    else
        poll_datapixx = 0; % din_status was given externally.
        
        if(isnumeric(varargin{1}) == 1)
        % assign the din values from the input argument, if they look right
        din_values = varargin{1};
        else
            error('The optional input argument for this function has to be a number, which is the decimal representation of the DIN lines.')
        end
    end
    
    if(length(varargin) > 1)
        % Did we get a single optional argument?
        error('This function only handles exactly 1 extra input argument.');
    end
    
    
    % I do this manually, so I can add other things should I ever decide to
    % make custom hardware.
    button_mask = 0; % We will use this for selecting the correct DIN line.
    switch( din_no )
        case 0
            button_mask = hex2dec('00001'); % DIN0 is bit 1
            
        case 1
            button_mask = hex2dec('00002'); % DIN1 is bit 2
            
        case 2
            button_mask = hex2dec('00004'); % DIN2 is bit 3
            
        case 3
            button_mask = hex2dec('00008'); % DIN3 is bit 4
        
        case 4
            button_mask = hex2dec('00010'); % DIN4 is but 5
        otherwise
            fprintf('Selected DIN is %d\n', din_no)
            warning('The selected DIN line is not matched to any buttons!')
    end
    %fprintf('Button mask is %d\n', button_mask) %Debug
    
    if(poll_datapixx == 1)
        % Only execute this bit when we have to poll the datapixx for the
        % latest values, within this function.
        if(Datapixx('IsReady'))
            % If the device is initialised, then:
            Datapixx('RegWrRd');
            din_values = Datapixx('GetDinValues');
        else
            error('Can''t connect to the Datapixx. Is it initialised?')
        end
    end

    if(bitand(din_values, button_mask))
        %fprintf('The button is not pressed.\n'); %Again, debug
        button_status = 0;
    else
        %fprintf('The button is pressed.\n'); %Debug
        button_status = 1;
    end
    

end

