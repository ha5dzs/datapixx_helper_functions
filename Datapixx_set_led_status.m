function Datapixx_set_led_status( din_no, status )
%DATAPIXX_SET_LED_STATUS 
%Datapixx_set_led_status( din_no )
% This function turns a DIN line to the desired status. I use this to
% illuminate the LEDs on the RESPONSEPixx.
% IMPORTANT: The Datapixx device must be properly initialised AND the DIN
% lines must be set to be outputs, otherwise this function will do nothing!
% The DIN lines are mapped as:
%   -DIN16: Red LED
%   -DIN17: Yellow LED
%   -DIN18: Green LED
%   -DIN19: Blue LED
%   -DIN20: White LED
% Input arguments are:
%   -> din_no is the DIN line number you want to set the status of.
%   -> status is 0 for off, and 1 for on. It's digital.


    
    if(Datapixx('IsReady'))
        %sanity check on the input arguments.
        if( (din_no < 0) || (din_no > Datapixx('GetDinNumBits')) )
            fprintf('DIN number requested: %d\n', din_no)
            error('Incorrect DIN number is requested.')
        end
        if( (status ~= 0) && (status ~= 1) )
            fprintf('status is %d\n', status)
            error('Status can only be 0 or 1.')
        end 
        % Since this can be called from anywhere, we better sync ourselves.
        % It's dirty, but it works!
        Datapixx('RegWrRd');
        din_values = Datapixx('GetDinValues');
        Datapixx('RegWrRd');
        if(status == 1)
            din_values = bitor(din_values, 2^din_no); % This bitwise-or expression turns the chosen din line on.
        end
        
        if(status == 0)
            din_values = bitand(din_values, ( (2^(Datapixx('GetDinNumBits'))-1) - 2^din_no) ); %clear the chosen bit,
        end
        
        Datapixx('SetDinDataOut', din_values); % Update the DIN values!
        Datapixx('RegWrRd'); % Sync with device.
    else
        error('Can''t connect to the Datapixx. Is it initialised?')
    end

    

end

