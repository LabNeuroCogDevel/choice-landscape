% Port 'habit_seeg' webUI+python bridge to Psychopy
% 20240717WF - init

function info = habit(patientID, varargin)
Screen('CloseAll')
KbName('UnifyKeyNames');
%%
system = load_system(varargin{:});sca

timing = load_events(varargin{:});
system.w = setup_screen(varargin{:});
system.pos = setup_pos(system.w, varargin{:});
system.tex = load_textures(system.w, varargin{:});
correctTrials = 0;

%% instructions
[onset, output] = instructions(system, 1);

%% start timing and data collection
record(length(timing)) = struct();
system.starttime = GetSecs();


%% run through events
for i=1:length(timing)
    t = timing(i); % undoing the fixed onsets
    if i == 1 || strcmp(t.event_name, 'isi') % want to move to isi immediatly after they click a choice.
        t.onset = 0;
    else
        t.onset= timing(i-1).dur;
    end
    [onset, output] = t.func(system, t, record, correctTrials);
    record(i).event_name = t.event_name;
    record(i).output = output;
    record(i).onset = onset;
    fprintf('%s %f\n', t.event_name, onset)

    info.record = record;
    info.system = system;
    folder = '/home/abel_lab/luna_habit/results/patientResults/';
    save(fullfile([folder patientID '.mat']), 'info'); 


end


closedown();
end

