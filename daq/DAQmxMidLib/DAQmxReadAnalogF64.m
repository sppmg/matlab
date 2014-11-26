function data = DAQmxReadAnalogF64(lib,taskh,numSampsPerChan,timeout,fillMode,numchan,numsample)
% checked
% this function reads analog inputs from previously setup task
% 
% inputs:
%	lib - .dll or alias (ex. 'myni')
%	taskh - taskhandle of analog inputs
%	numSampsPerChan = DAQmx_Val_Auto ?
%	timeout - in seconds
%	fillMode - DAQmx_Val_GroupByChannel or DAQmx_Val_GroupByScanNumber
%	numchan - number of analog channels to read
%	numsample - number of samples to read
% 
% 
% C functions used:
%	int32 DAQmxReadAnalogF64 (
%		TaskHandle taskHandle,int32 numSampsPerChan,float64 timeout,bool32 fillMode,
%		float64 readArray[],uInt32 arraySizeInSamps,int32 *sampsPerChanRead,bool32 *reserved);
% %	int32 DAQmxStopTask (TaskHandle taskHandle);
% disp('in read')
% whos taskh
% taskh.Value

readarray=ones(numchan,numsample); readarray1_ptr=libpointer('doublePtr',readarray);
sampread=0; sampread_ptr=libpointer('int32Ptr',sampread);
empty=[]; empty_ptr=libpointer('uint32Ptr',empty);

arraylength=numsample*numchan; % more like 'buffersize'

[err,readarray,sampread,empty]=calllib(lib,'DAQmxReadAnalogF64',...
		taskh,numSampsPerChan,timeout,fillMode,...
		readarray1_ptr,arraylength,sampread_ptr,empty_ptr);
DAQmxCheckError(lib,err);

% err = calllib(lib,'DAQmxStopTask',taskh);
% DAQmxCheckError(lib,err);
readarray=readarray1_ptr.Value;
sampread=sampread_ptr.Value;
%size(readarray)
data = readarray(:,1:sampread)';
