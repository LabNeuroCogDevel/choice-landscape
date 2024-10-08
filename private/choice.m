function [onset, output] = choice(system, t, varargin)

allkeys = [system.keys.left, system.keys.up,  system.keys.right];
keys = [];

ideal = GetSecs()+t.onset;
Screen('DrawTexture', system.w, system.tex.ocean_bottom); % Show the background again
Screen('DrawTexture', system.w, system.tex.astronaut{1,1},...
    [], [system.pos.character.x system.pos.character.y system.pos.character.x+60 system.pos.character.y+80] );

progressBar(system, t);


if t.i < 3
    correctTrials = 0;

else

    correctTrials = varargin{1}(t.i-2).output.correctTrials;

end

totalCount(system, correctTrials);
coinPile(system, correctTrials)



%% positon choice options
chest_w = 60; chest_h = 60;  %TODO: use sprite
% TODO: use DrawTextures (many at once)

[screenWidth, screenHeight] = Screen('WindowSize', system.w);

% Define the size of the white box (e.g., 100x100 pixels)
boxWidth = 200;
boxHeight = 200;

% Calculate the position of the box in the lower right corner
% The coordinates are in the form [left, top, right, bottom]
boxRect = [screenWidth - boxWidth, screenHeight - boxHeight, screenWidth, screenHeight];

% Define the color white (white = [255 255 255])
black = [0 0 0];

% Draw the white box
Screen('FillRect', system.w, black, boxRect);

% chest graphics
Screen('DrawTexture', system.w, system.tex.chest_sprites{1,1},...
    [], [ system.pos.left.x system.pos.left.y system.pos.left.x+chest_w system.pos.left.y+chest_h] );
Screen('DrawTexture', system.w, system.tex.chest_sprites{1,1},...
    [], [ system.pos.up.x system.pos.up.y system.pos.up.x+chest_w system.pos.up.y+chest_h] );
Screen('DrawTexture', system.w, system.tex.chest_sprites{1,1},...
    [], [ system.pos.right.x system.pos.right.y system.pos.right.x+chest_w system.pos.right.y+chest_h] );

% add keys to chests
if ismember('right', t.choices)
    Screen('DrawTexture', system.w, system.tex.key,...
        [], [ system.pos.right.x+20 system.pos.right.y+20 system.pos.right.x+chest_w system.pos.right.y+chest_h] );
    keys = [keys system.keys.right];

end

if ismember('left', t.choices)
    Screen('DrawTexture', system.w, system.tex.key,...
        [], [ system.pos.left.x+20 system.pos.left.y+20 system.pos.left.x+chest_w system.pos.left.y+chest_h] );
    keys = [keys system.keys.left];


end

if ismember('up', t.choices)
    Screen('DrawTexture', system.w, system.tex.key,...
        [], [ system.pos.up.x+20 system.pos.up.y+20 system.pos.up.x+chest_w system.pos.up.y+chest_h] );
    keys = [keys system.keys.up];


end


onset = Screen('Flip', system.w, ideal);

[daq_flag, HID] = find_daq();
daq_on = 255;
daq_off = 0;
send_trigger(daq_flag,daq_on,HID);
send_trigger(daq_flag,daq_off,HID) %Turn off DAQ
% [k rt] = waitForKeys(keys, onset + t.max_rt);

% RTBox('ClockRatio', 5);
RTBox('clear')
k=0;
timeout = onset + t.max_rt;
while (~ismember(k, keys) && GetSecs() < timeout)
    [k,rt] = waitForKeyPress(k,'rtbox');    
end

    if rt > 0
        idx = find(allkeys == k,1);
        fprintf('choice %d, key %d',idx, k)
        well_prob = t.chance(idx);
        output.score = (rand(1) <= well_prob);
        if k == 1
            output.pick = 'left';

        elseif k == 2 || k ==3
            output.pick = 'up';

        elseif k == 4
            output.pick = 'right';

        end
    else
        output.score = 0;
        output.pick = 'none';
    end
    output.onset_ideal = ideal;
    output.key = k;
    output.rt = rt;




end
