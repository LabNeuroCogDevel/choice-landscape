function [key,RT] = waitForKey(acceptkeysidx,timeout)
% WAITFORKEY -- wait for given key index (e.g from KbName()) until timeout 
%   return key=0 and RT=-Inf if no acceptable key push given before timeout
%   originally from https://github.com/LabNeuroCogDevel/audodd/blob/master/waitForKey.m
%
% Usage:
%  % 2 seconds to respond a (return k=1) or b (return k=2)
%  % no response, k=0, rt=-Inf
%  [k rt] = waitForKey( KbName({'a','b'}), GetSecs() + 2);
% 
%  % wait forever for the scanner to send a trigger (trg key is = )
%  [k rt] = waitForKey( KbName({'=+'}), Inf);
%
% Note:
%  accepts multiple keys down as response endorsing first acceptable key


  % no response can be meaningful if too fast
  % wait 60ms before trying to record a response
  % TODO: determine more approprate min response time limit
  % also reduce hold over from previous trial errors
  fastestResponseTime=.06;
  WaitSecs(fastestResponseTime);
 
  key=0;
  RT=-Inf;
  % continue until we get a keypress we like
  % or we run out of time
  while(RT<=0 && GetSecs() < timeout )
      [keyPressed, thisRT, keyCode] = KbCheck;
      if keyPressed && any( keyCode(acceptkeysidx)  )
         RT=thisRT;

         %NB! we only pick the first (in order of acceptkeys)
         % if subject is holding down more than one key, will not record both!
         % will warn to screen about mutliple pushes though
         key=acceptkeysidx(find(keyCode(acceptkeysidx) ,1)); % this needs the value of the key (80, 79, or 82) not 1,2,3 for right left and up, otherwise it was always saying the score was 0 cause the incorrect key was pressed - SM
         if(nnz(keyCode(acceptkeysidx) ) > 1)
           fprintf('WARNING: multple good button pushes! reporting first button is pushed\n');
         end
      end
  end
end
