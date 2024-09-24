function [onset, output] = instructions(system, number, t, varargin)
output.instruction = number;
k = 0;
%% positon choice options
chest_w = 60; chest_h = 60;  
% Instruction 1
Screen('DrawTexture', system.w, system.tex.ocean_bottom); % Show the background
% chest graphics
Screen('DrawTexture', system.w, system.tex.chest_sprites{1,1},...
    [], [ system.pos.left.x system.pos.left.y system.pos.left.x+chest_w system.pos.left.y+chest_h] );
Screen('DrawTexture', system.w, system.tex.chest_sprites{1,1},...
    [], [ system.pos.up.x system.pos.up.y system.pos.up.x+chest_w system.pos.up.y+chest_h] );
Screen('DrawTexture', system.w, system.tex.chest_sprites{1,1},...
    [], [ system.pos.right.x system.pos.right.y system.pos.right.x+chest_w system.pos.right.y+chest_h] );

DrawFormattedText(system.w, 'In this task you will be looking for treasure in three treasure chests (push to continue)', ...
    'center', 'center', [255, 255, 255]); % Draw the first instruction
Screen('Flip', system.w); % Display the content on the screen
while k == 0
    [k,rt]= waitForKeyPress(k,'rtbox');
end

% Instruction 2
Screen('Flip', system.w); % Clear the screen
Screen('DrawTexture', system.w, system.tex.ocean_bottom); % Show the background again
% chest graphics
Screen('DrawTexture', system.w, system.tex.chest_sprites{1,1},...
    [], [ system.pos.left.x system.pos.left.y system.pos.left.x+chest_w system.pos.left.y+chest_h] );
Screen('DrawTexture', system.w, system.tex.chest_sprites{1,1},...
    [], [ system.pos.up.x system.pos.up.y system.pos.up.x+chest_w system.pos.up.y+chest_h] );
Screen('DrawTexture', system.w, system.tex.chest_sprites{1,1},...
    [], [ system.pos.right.x system.pos.right.y system.pos.right.x+chest_w system.pos.right.y+chest_h] );

% add keys to chests
Screen('DrawTexture', system.w, system.tex.key,...
    [], [ system.pos.right.x+20 system.pos.right.y+20 system.pos.right.x+chest_w system.pos.right.y+chest_h] );

Screen('DrawTexture', system.w, system.tex.key,...
    [], [ system.pos.left.x+20 system.pos.left.y+20 system.pos.left.x+chest_w system.pos.left.y+chest_h] );

DrawFormattedText(system.w, 'Two keys will appear in front of two of the three chests. You can choose between these two chests with keys  (push to continue)', ...
    'center', 'center', [255, 255, 255]); % Draw the second instruction
Screen('Flip', system.w); % Display the content on the screen
k =0;
while k == 0
    [k,rt]= waitForKeyPress(k,'rtbox');
end


% Instruction 2.5
Screen('Flip', system.w); % Clear the screen
Screen('DrawTexture', system.w, system.tex.ocean_bottom); % Show the background again
% chest graphics
Screen('DrawTexture', system.w, system.tex.chest_sprites{1,1},...
    [], [ system.pos.left.x system.pos.left.y system.pos.left.x+chest_w system.pos.left.y+chest_h] );
Screen('DrawTexture', system.w, system.tex.chest_sprites{1,1},...
    [], [ system.pos.up.x system.pos.up.y system.pos.up.x+chest_w system.pos.up.y+chest_h] );
Screen('DrawTexture', system.w, system.tex.chest_sprites{1,1},...
    [], [ system.pos.right.x system.pos.right.y system.pos.right.x+chest_w system.pos.right.y+chest_h] );

% add keys to chests
Screen('DrawTexture', system.w, system.tex.key,...
    [], [ system.pos.right.x+20 system.pos.right.y+20 system.pos.right.x+chest_w system.pos.right.y+chest_h] );

Screen('DrawTexture', system.w, system.tex.key,...
    [], [ system.pos.left.x+20 system.pos.left.y+20 system.pos.left.x+chest_w system.pos.left.y+chest_h] );

DrawFormattedText(system.w, 'Button 1 will go LEFT. Buttons 2 and 3 will go UP. Button 4 will go RIGHT (push to continue)', ...
    'center', 'center', [255, 255, 255]); % Draw the second instruction
Screen('Flip', system.w); % Display the content on the screen
k =0;
while k == 0
    [k,rt]= waitForKeyPress(k,'rtbox');
end


% Instruction 2.7
Screen('Flip', system.w); % Clear the screen
Screen('DrawTexture', system.w, system.tex.ocean_bottom); % Show the background again
% chest graphics
Screen('DrawTexture', system.w, system.tex.chest_sprites{1,1},...
    [], [ system.pos.left.x system.pos.left.y system.pos.left.x+chest_w system.pos.left.y+chest_h] );
Screen('DrawTexture', system.w, system.tex.chest_sprites{1,1},...
    [], [ system.pos.up.x system.pos.up.y system.pos.up.x+chest_w system.pos.up.y+chest_h] );
Screen('DrawTexture', system.w, system.tex.chest_sprites{1,1},...
    [], [ system.pos.right.x system.pos.right.y system.pos.right.x+chest_w system.pos.right.y+chest_h] );

% add keys to chests
Screen('DrawTexture', system.w, system.tex.key,...
    [], [ system.pos.right.x+20 system.pos.right.y+20 system.pos.right.x+chest_w system.pos.right.y+chest_h] );

Screen('DrawTexture', system.w, system.tex.key,...
    [], [ system.pos.left.x+20 system.pos.left.y+20 system.pos.left.x+chest_w system.pos.left.y+chest_h] );

DrawFormattedText(system.w, 'But be quick. You only have 2 seconds to choose a chest (push to continue)', ...
    'center', 'center', [255, 255, 255]); % Draw the second instruction
Screen('Flip', system.w); % Display the content on the screen
k =0;
while k == 0
    [k,rt]= waitForKeyPress(k,'rtbox');
end



% Instruction 3
Screen('Flip', system.w); % Clear the screen
Screen('DrawTexture', system.w, system.tex.ocean_bottom); % Show the background again
DrawFormattedText(system.w, 'The odds that a chest has treasure will be different. Your task is to learn which chest is most likely to have treasure  (push to continue)', ...
    'center', 'center', [255, 255, 255]); % Draw the third instruction
Screen('Flip', system.w); % Display the content on the screen

k =0;
while k == 0
    [k,rt]= waitForKeyPress(k,'rtbox');
end

% Instruction 4
Screen('Flip', system.w); % Clear the screen
Screen('DrawTexture', system.w, system.tex.ocean_bottom); % Show the background again
DrawFormattedText(system.w, 'The green bar at the bottom of the task lets you know how much longer in the task you have (push to continue)', ...
    'center', 'center', [255, 255, 255]); % Draw the third instruction
Screen('Flip', system.w); % Display the content on the screen

k=0;
while k == 0
    [k,rt]= waitForKeyPress(k,'rtbox');
end

% Instruction 5
Screen('Flip', system.w); % Clear the screen
Screen('DrawTexture', system.w, system.tex.ocean_bottom); % Show the background again
DrawFormattedText(system.w, 'Push any key twice to start', ...
    'center', 'center', [255, 255, 255]); % Draw the final instruction
Screen('Flip', system.w); % Display the content on the screen
k=0;
while k == 0
    [k,rt]= waitForKeyPress(k,'rtbox');
end

% Ready to run the task
onset = Screen('Flip', system.w, 0); % Final screen flip, getting the onset time

% Wait for a key press to start the task
k=0;
while k == 0
    [k,rt]= waitForKeyPress(k,'rtbox');
end

end
