function taskh = DAQmxCreateAIVoltageChan(lib,taskh,PhysicalChannel,Vmin,Vmax)
%checked
% this function creates a task and adds analog input channel(s) to the task
% C functions used:
%	int32 DAQmxCreateTask (const char taskName[],TaskHandle *taskHandle);
%	int32 DAQmxCreateAIVoltageChan (TaskHandle taskHandle,const char physicalChannel[],
%		const char nameToAssignToChannel[],int32 terminalConfig,float64 minVal,
%		float64 maxVal,int32 units,const char customScaleName[]);
%	int32 DAQmxTaskControl (TaskHandle taskHandle,int32 action);
% 

if isempty(taskh)
	% create task 
    
	arch=computer ;
	switch arch
		case 'PCWIN'
			taskh=uint32(0);
			taskh=libpointer('uint32Ptr',taskh);
		case 'PCWIN64'
			taskh=uint64(0);
			taskh=libpointer('uint64Ptr',taskh);
		otherwise
				% disp error
	end
    
	name_task = '';	% recommended to avoid problems
	[err] = calllib(lib,'DAQmxCreateTask',name_task,taskh);
    %taskh=var2ptr(taskh);
   % taskh=libpointer('uint64Ptr',taskh);
	DAQmxCheckError(lib,err);
	
end
 
DAQmx_Val_Task_Verify =2; % Verify
[err]=calllib(lib,'DAQmxTaskControl',taskh,DAQmx_Val_Task_Verify );

% Task will auto start when created.


% create AI voltage channel(s) and add to task
DAQmx_Val_RSE =10083;  % RSE
DAQmx_Val_Volts= 10348; % measure volts
name_channel = '';
%regexprep(PhysicalChannel,'/','_')	% recommended to avoid problems

if ~iscell(PhysicalChannel)	% just 1 channel to add to task (maybe no need)
	[err,b,c,d] = calllib(lib,'DAQmxCreateAIVoltageChan',taskh,...
		PhysicalChannel,name_channel,...
		DAQmx_Val_RSE,Vmin,Vmax,DAQmx_Val_Volts,'');
	DAQmxCheckError(lib,err);
else % more than 1 channel to add to task
	if length(Vmin)==1
		Vmin=repmat(Vmin,1,numel(PhysicalChannel));
	end
	if length(Vmax)==1
		Vmax=repmat(Vmax,1,numel(PhysicalChannel));
	end
	
	for m = 1:numel(PhysicalChannel)
		[err,b,c,d] = calllib(lib,'DAQmxCreateAIVoltageChan',taskh,...
			PhysicalChannel{m},name_channel,...
			DAQmx_Val_RSE,Vmin(m),Vmax(m),DAQmx_Val_Volts,'');
		DAQmxCheckError(lib,err);
	end
end
%err = calllib(lib,'DAQmxStopTask',taskh);
