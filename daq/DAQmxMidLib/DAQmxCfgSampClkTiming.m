function  DAQmxCfgSampClkTiming(lib,taskh,sampleMode,rate,sampsPerChanToAcquire)
%checked
%int32 DAQmxCfgSampClkTiming (TaskHandle taskHandle, const char source[], float64 rate, int32 activeEdge, int32 sampleMode, uInt64 sampsPerChanToAcquire); 
%	
%	source		To use the internal clock of the device, use NULL or use OnboardClock.
%	rate		sampling rate
%	activeEdge	DAQmx_Val_Rising or DAQmx_Val_Falling
%	sampleMode	DAQmx_Val_FiniteSamps ,DAQmx_Val_ContSamps ,DAQmx_Val_HWTimedSinglePoint
%	sampsPerChanToAcquire	for DAQmx_Val_FiniteSamps. when ContSamps, NI-DAQmx determine the buffer size.
%[long, cstring] DAQmxCfgSampClkTiming(ulong, cstring, double, long, long, uint64)
source=''; %internal clock 
DAQmx_Val_Rising = 10280; % Rising
DAQmx_Val_Falling =10171; % Falling

[err,b]=calllib(lib,'DAQmxCfgSampClkTiming',taskh,source,rate,DAQmx_Val_Rising,sampleMode,sampsPerChanToAcquire);
