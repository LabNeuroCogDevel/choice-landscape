function x = fix_status_channel(x)
%FIX_STATUS_CHANNEL adjust status channel to be those sent by the task
%   Status channel values are large negative integers. 
%   readjust by min of timseries, replace extreme vals w/0
%   also see https://lncd.pitt.edu/wiki/doku.php?id=tools:eeg_remark
 x = x - min(x);
 x(x>65000) = 0;
end
