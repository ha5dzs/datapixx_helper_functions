function [ din_status ] = Datapixx_check_button_status( din_no )
%DATAPIXX_CHECK_BUTTON_STATUS
%[ din_status ] = Datapixx_check_button_status( din_no )
% Since I got sick of bitbanging every damn time I need to check a button,
%here is a function that returns the status of the button.
%IMPORTANT: You must make sure that the DataPixx is actually turned on and
%initialised correctly!
% Input argument is:
%   -> din_no is the DIN line number, as per the RESPONSEPixx,
%       -DIN 0: Red button
%       -DIN 1: Yellow button
%       -DIN 2: Green button
%       -DIN 3: Blue button
%       -DIN 4: White button 
% Return value is:
%   din_status: 1 for button pressed, and 0 for button not pressed.

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
    
    if(Datapixx('IsReady'))
        % Since this can be called from anywhere, we better sync ourselves.
        % It's dirty, but it works!
        Datapixx('RegWrRd');
        din_values = Datapixx('GetDinValues');
        Datapixx('RegWrRd');
        %din_values = Datapixx('GetDinValues');
    else
        error('Can''t connect to the Datapixx. Is it initialised?')
    end

    if(bitand(din_values, button_mask))
        %fprintf('The button is not pressed.\n'); %Again, debug
        din_status = 0;
    else
        %fprintf('The button is pressed.\n'); %Debug
        din_status = 1;
    end
    

end

