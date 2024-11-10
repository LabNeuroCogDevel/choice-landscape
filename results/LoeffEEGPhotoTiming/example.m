% parsing TTL/Status triggers of Habit Task (choice-landscape)
% Loeff EEG version
%
% for example task see:
% https://labneurocogdevel.github.io/choice-landscape/out/index.html#landscape=ocean&timing=random
%                 left up right
% left+up=3       13   14
% left+right=4    15       17
% up+right=5           16  18

%
% 20221010WF - init
% 20241110WF - small plotting updates

%% setup
% hera, fix_status_channel
addpath('/Volumes/Hera/Projects/7TBrainMech/scripts/eeg/eog_cal/')
% fieldtrip
addpath(hera('/Projects/7TBrainMech/scripts/fieldtrip-20220104'))
ft_defaults
ft_test % add fieldtrip to path

%% example files
f_eeg = hera('/Raw/EEG/Habit/11882_20220826/11882_20220826_habit.bdf');
f_tsv = hera('/Projects/7TBrainMech/scripts/eeg/Shane/Habit/11882_20220826_run_893726.18.tsv');

%% load task info
task_all = readtable(f_tsv, 'FileType', 'text', 'TreatAsEmpty','NA');
% keep only onset (timing) columns
task_time = task_all(:,contains(task_all.Properties.VariableNames,"_onset"));
% remove '_onset' from names
task_time.Properties.VariableNames = regexprep(task_time.Properties.VariableNames,'_onset','');
% adjust to very first iti_onset. and move from ms to seconds
task_time{:,:} = (table2array(task_time) - task_time{1,1})./1000; 

% other useful columns to have around
task_status= task_all(:,{'trial','score','rt','picked_unified','picked_prob','avoided_prob'});


%% load eeg
h = ft_read_header(f_eeg);
% extract status channel to get TTL values, eventually 0-255
ttl_ch_idx = cellfun(@(x) strmatch(x, h.label), {'Status'});
ttl = ft_read_data(f_eeg, 'header', h, 'chanindx', ttl_ch_idx);
% adjusts Status by x-min(x) (negative trigger values)
% where min is -6799616; max(ttl)-min(ttl)==65664
ttl_adj = fix_status_channel(ttl);

%% events
e = ft_read_event(f_eeg, 'eventformat','biosemi_bdf'); % eventformat does't seem to help

% adjust event trigger values.
% NB [e.values] drops missing values (2 in this example).
%    need to track "good" non-empty indexs (gidx)
% expected values: PD=1, buttons 2-4. iti 10. ...
gidx_lgc = ~cellfun(@isempty,{e.value});
events = e(gidx_lgc);
e_adj = fix_status_channel([events.value]); % remove min

for i=1:length(events)
    events(i).value = e_adj(i); 
end
% remove back to zero values
events = events(find([events.value]));

% unique([events.value])
%     1     2     3     4             % PD, buttons
%    10                               % iti
%    13    14    15                   % choice
%    23    24    25                   % 
%    73                               % timeout
%   128                               % start
%   163   164   166   167   168       % waiting (+150)
%   213   214   216   217   218       % feedback noscore, score (+200)
%   223   224   226   227   228  
%   230                               % finished/survey/catchall


%% task to ttl-ish values
ntrial = 5;
nsample = 45;
task_long = stack(task_time(1:ntrial,:),1:5,'IndexVariableName','event','NewDataVariableName','onset');
lookup = struct('iti',10, 'chose',20,'waiting',150,'feedback',200, 'timeout',70);
task_long.ttl = cellfun(@(f) lookup.(f), string(task_long.event));

etime_secs = ([events(1:nsample).sample]-events(1).sample)/h.Fs
event_ttl = [events(1:nsample).value]
labels = string(task_long.event)
hold off
xline(task_long.onset(idx),'-', labels(idx) )
hold on
scatter(etime_secs, event_ttl, 'r.');
gscatter(task_long.onset,task_long.ttl, task_long.event)

%% another view
cuts = [0,       2,     5,   11,       30,      127,    129,...
        170    ,229,       256];
labs = {'Photo','Button', 'iti','choice','timeout','start',...
        'waiting','feedback','survey'}
ttl_label = discretize(event_ttl,cuts,labs);
pd_idx = event_ttl == 1;
hold off
gscatter(etime_secs, event_ttl, ttl_label');
L = legend; L.AutoUpdate = 'off'; 
hold on
scatter(task_long.onset,task_long.ttl, 'k.')
xline(etime_secs(pd_idx),'c-' )



%%% Shanes try
% shift event onset to be prevoius photodiode onset
addpath('/opt/ni_tools/matlab_toolboxes/eeglab2024.2/')

EEG = pop_biosig(f_eeg);

% fix stimus channel again. reuse work from above
for i=1:length(events)
    EEG.event(i).type = e_adj(i); 
    EEG.urevent(i).type = e_adj(i); 
end

% also see
% EEG = pop_loadset('11882_20220826_run_893726.18.tsv_Rem.set', '/Volumes/Hera/Projects/Habit/eeg/ShaneHabit/');

%% move task info onto closest photodiode timing event 
[eexx, ttl_delta] = pd2taskEEGLAB(EEG.event);

[eexx(1:10).type; eexx(1:10).latency]' % adjusted
[EEG.event(1:10).type; EEG.event(1:10).latency]' % orig

%  adjusted         %    ORIG
%    0         313  %    0         313
%    4         813  %    4         813
%  128         839  %  128         839
%   23        1242  %   23        1232
%                   %-   1        1242
%    3        1263  %    3        1263
%  164        1397  %  164        1362
%                   %-   1        1397
%  214        1514  %  214        1486
%                   %-   1        1514


%% explore difference between photodoide onset (screen flip) and task sent info
% task knows what it wants to do (and sends ttl) before it can get the browser to show it on the screen
%  ev_grp   meandiff       std
%       0    20.9254    6.6620
%     100    34.1963    6.0792
%     200    25.0186    2.8596
ttl_event = floor(ttl_delta(:,1)/100)*100;
ttl_group = findgroups(ttl_event);
delta_mean_std = splitapply(@(x) [mean(x) std(x)], ttl_delta(:,2), ttl_group);
[unique(ttl_event) delta_mean_std];
hold on
for ei=unique(ttl_event)'
    grpidx = ttl_event==ei;
    d = ttl_delta(grpidx, 2);
    histogram(d)
end
legend({'choice','wait', 'feedback'})
hold off
title('onsets shift from PD correction histogram by even type')
xlabel('onset shift (ms)')
ylabel('n')
saveas(gcf,'img/PDshift_histogram.png')

%% update EEG with new PD derived timing
EEG.event = eexx; 
for i = 1:length(EEG.event)
    EEG.event(i).urevent= i; 
end
EEG.urevent = rmfield(EEG.event, 'urevent'); 

%EEG = pop_saveset( EEG, 'filename','11882_20220826_run_893726.18.tsv_Rem_take2.set','filepath', hera('/Projects/7TBrainMech/scripts/eeg/Shane/Habit/'));

% start habitCheckERPs here
