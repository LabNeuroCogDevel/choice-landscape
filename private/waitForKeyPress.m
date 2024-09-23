function [keyPressed,timeOfPress] = waitForKeyPress(keyPressed,mode)
    
    timeOfPress = -1;
    if strcmpi(mode,'keyboard')
        % fill this out
        [keyIsDown, secs, keyCode] = KbCheck;
        if any(keyCode)
            keyName = KbName(keyCode);
        else
            keyName = -1;
        end
        switch keyName
            case {'1' '2' '3' '4'}
                timeOfPress = secs;
                keyPressed = str2num(keyName);
                keyStillDown = 1;
                while keyStillDown == 1
                    keyStillDown = KbCheck;
                end
        end
        
    elseif strcmpi(mode,'rtbox')
        buttonStates = [RTBox('ButtonDown','1') RTBox('ButtonDown','2') RTBox('ButtonDown','3') RTBox('ButtonDown','4')];
        if any(buttonStates)
            timeOfPress = GetSecs;
            thisButton = find(buttonStates,1);
            buttonReleased = 0;
            while buttonReleased == 0
                if ~RTBox('ButtonDown',num2str(thisButton))
                    buttonReleased = 1;
                    keyPressed = thisButton;
                end
            end
        end
            
    else
        error('waitForKeyPress mode not recognized. Use ''keyboard'' or ''rtbox''.')
    end
    
end