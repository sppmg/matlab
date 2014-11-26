function DAQmxClearTask(lib,taskh)
%stop task
err = calllib(lib,'DAQmxStopTask',taskh);
%% clear all tasks
[err] = calllib(lib,'DAQmxClearTask',taskh);
% 
% % loop to clear all taskhandles
% tasknames = fieldnames(taskh);
% numtasks = numel(tasknames);
% for m = 1:numtasks
% 	[err] = calllib(lib,'DAQmxClearTask',taskh.(tasknames{m}));
% 	DAQmxCheckError(lib,err);
% end


%% unload library
%if libisloaded(lib) % checks if library is loaded
%	unloadlibrary(lib)
%end
