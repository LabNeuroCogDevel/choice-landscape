function timing = load_events(varargin)

% fprintf('# loading event timing\n');

nblocks = 4;
ntrials = [36,36,72,72];
% TODO: shuffle left and up so left doesn't always start as bad
block_probabilities = [ ...
   ...  left, up, up, right; since rtbox has 2 options for up
  .2,.5,.5,1;
  0.5,0.2,0.2,1;
  0.75,0.75,0.75,0.75;
  1,1,1,1];
i = 0;

for block = 1:nblocks
    block_choices = gen_choices(ntrials(block));
    for trial = 1:ntrials(block)

        % Randomly select two different options from 'left', 'up', and 'right'
        all_choices = {'left', 'up', 'right'};
        %selected_choices = datasample(all_choices, 2, 'Replace', false); % Randomly select 2 options without replacement
        selected_choices = [all_choices(block_choices(trial,1)), all_choices(block_choices(trial,2))];

        i = i+1;
        timing(i).event_name = 'choice';
        timing(i).func = @choice;
        timing(i).dur = 2;

        % Set chance values depending on the block
        timing(i).chance = block_probabilities(block,:);

        timing(i).max_rt = timing(i).dur;
        timing(i).i = i;
        timing(i).choices = selected_choices; % Assign the random choices to this trial

        if i>1
            timing(i).onset = timing(i-1).onset + timing(i-1).dur; % as soon as choice ends
        else
            timing(i).onset = 0;
        end


        i=i+1;
        timing(i).event_name = 'isi';
        timing(i).dur = .52;
        timing(i).cross_color = [0,0,255]; % blue
        timing(i).func = @moveCharacter;
        timing(i).onset = timing(i-1).onset + timing(i-1).dur; % as soon as choice ends
        timing(i).i = i;

        i=i+1;
        timing(i).event_name = 'feedback';
        timing(i).dur = .52;
        timing(i).func = @feedback;
        timing(i).onset = timing(i-1).onset + timing(i-1).dur;
        timing(i).i = i;

        i=i+1;
        timing(i).event_name = 'iti';
        timing(i).dur = 1;
        timing(i).cross_color = [255,255,255]; % white
        timing(i).func = @fixation;
        timing(i).onset = timing(i-1).onset + timing(i-1).dur;
        timing(i).i = i;

    end
end

end

