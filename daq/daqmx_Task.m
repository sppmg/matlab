classdef daqmx_Task < handle
	properties
		ChanAlias ;

		Max = 10 ;
		Min = -10 ;
		DataLayout = 1 ;	% DAQmx_Val_GroupByScanNumber = 1 ;
		SampleNum = 200 ; % per channel,little more than 10 Hz update rate.when mode = f , it's total data.
		Timeout = 5 ;
		ProcPeriod = 0.1 ;
		DataWindowLen = 1000 ; % unit = data number
		
		CallbackFunc ; 
		
		CircBuf = 0 ; % Circulary buffer of write (ao)
		BufHead = 1 ; % Head pointer for write buffer, next write data.
		UserData ;
	end
	
	properties (SetAccess = private)
		PhyChan ; % eg : 'Dev1/ai0';
		NITaskHandle ; 
		TimerHandle ;
		
		DevName ;  % eg : dev1
		ChanType ; % eg : ai / ao / di / do / etc ....
		ChanMeas = 'Voltage' ; % Measure eg. V,I
		ChanNum ;
		ChanOccupancy ;
		
		Mode = 'Single' ; % Mode = 'Single' | 'Finite' | 'Continuous'
		Rate = 1000 ;
		
		DataTime ; % storage time of each data
		
		DataLastTime = 0 ;
		DataLastPartNum = 0 ;
		DataTotalNumPerChan = 0 ; % per channel 
		DataStorage ; % storage input data.
		
		LibHeader = 'NIDAQmx-lite.h';
		LibDll = 'C:\WINDOWS\system32\nicaiu.dll' ;
		LibAlias = 'nidaqmx' ;

		%StatusTaskRunning = 0 ;
		
	end
	methods
		function obj=daqmx_Task(varargin)
			%obj.LibAlias = daqmx_loadlib ;
			ModeAlreadySet = 0 ;
			
			% Load lib
			if ~libisloaded(obj.LibAlias)
				% [daqmx_library_fpath, daqmx_library_fname, daqmx_library_fext] = fileparts(daqmx.set.library) ;
				disp(['Matlab: Loading library from ',obj.LibDll ])
				[notfound,warnings] = loadlibrary(obj.LibDll , obj.LibHeader ,'alias',obj.LibAlias );
			end
			disp('Matlab: dll loaded')
			
			if nargin > 0 % && ~mod(nargin,2) % even nargin
				for arg_i = 1:2:size(varargin,2)
					switch lower( varargin{arg_i} )
						case 'chan'
							obj.PhyChan = varargin{arg_i+1} ;
							% Check 
							% move follow code out of phaser because it will map with alias.
						case 'chantype'
							obj.ChanType = varargin{arg_i+1} ;
							switch lower(varargin{arg_i+1})
								case {'ai'}
									obj.ChanType = 'ai';
								case {'ao'}
									obj.ChanType = 'ao' ;
								otherwise
									error('ChanType string not allowed.');
							end
						case 'chanmeas'
							switch lower(varargin{arg_i+1})
								case {'voltage','v'}
									obj.ChanMeas = 'Voltage';
								case {'current','i'}
									obj.ChanMeas = 'Current' ;
								otherwise
									error('ChanMeas string not allowed.')
							end
						
						case 'alias'
							% TODO
							% check ChanAlias is unique and mutch PhyChan
							obj.ChanAlias = varargin{arg_i+1} ;
							
						case 'mode'
							% Allow use  s,f,c
							switch lower(varargin{arg_i+1})
								case {'single','s'}
									obj.Mode='Single';
								case {'finite','f'}
									obj.Mode = 'Finite' ;
								case {'continuous','c'}
									obj.Mode = 'Continuous' ;
								otherwise
									error('Mode string not allowed.');
							end
							ModeAlreadySet = 1 ;
						case 'rate'
							% 'Finite' or 'Continuous' mode , if did not set SampleNum , default is 'Continuous' .
							obj.Rate = varargin{arg_i+1} ;
							if isempty(obj.Mode) || strcmpi(obj.Mode,'Single')
								if ~ModeAlreadySet
									obj.Mode = 'Continuous' ;
								end
								obj.SampleNum = round(obj.Rate/5) ;
								
							end
							if isempty(obj.ProcPeriod)
								obj.ProcPeriod = round(1/obj.Rate) ;
							end
						case 'samplenum'
							% 'Finite' or 'Continuous' mode , default is 'Finite' .
							if isempty(obj.Mode) || strcmpi(obj.Mode,'Single')
								if ~ModeAlreadySet
									obj.Mode = 'Finite' ;
								end
							end
							obj.SampleNum = varargin{arg_i+1} ;
						case 'max'
							obj.Max = varargin{arg_i+1} ;
						case 'min'
							obj.Min = varargin{arg_i+1} ;
						case 'procperiod'
							% should > 0.001 s , matlab timer limit.
							if varargin{arg_i+1} <= 0.001
								obj.ProcPeriod = 0.001 ; 
							else
								obj.ProcPeriod = varargin{arg_i+1} ;
							end
						case 'callbackfunc' % input string
							obj.CallbackFunc = varargin{arg_i+1} ;
						case 'datawindowlen' % data number per channel
							obj.DataWindowLen = varargin{arg_i+1} ;
					end
				end % for each arg
			end % if nargin > 0
			% ----------- PhyChan,Alias parser---------
			if isempty(obj.PhyChan)
				error('Please specify physical channel name. eg, "Dev1/ai0:3" .');
			elseif ischar(obj.PhyChan)
				obj.PhyChan={obj.PhyChan};
			end
			
			if iscellstr(obj.PhyChan)
				tmp=regexpi(obj.PhyChan,'^.+(?=/)','match');
				obj.DevName=unique( [tmp{:}] );
				
				tmp=regexpi(obj.PhyChan,'(?<=/)[a-z]+','match');
				obj.ChanType=unique( [tmp{:}] );
				
				tmp=regexpi(obj.PhyChan,'(?<=/[a-z]+)[0-9:]+','match');
				
				for fi= 1:numel(tmp)
					obj.ChanOccupancy=[ obj.ChanOccupancy,str2num(tmp{fi}{:})];
				end
			else
				error('Wrong channel name.')
			end

			if numel(obj.DevName) > 1
				error('This program not allow use multidevice in one task object.');
			end
			if numel(obj.ChanType) > 1
				error('This program not allow use multi-type (ai,ao ...) in one task object.');
			end
			if numel(obj.ChanOccupancy) ~= numel(unique(obj.ChanOccupancy))
				error('Channel name overlaped.') ;
			end
			if numel(obj.ChanAlias) ~= numel(unique(obj.ChanAlias))
				error('Channel alias name repeated.');
			end
			
			if numel(obj.ChanAlias) > 0 && numel(obj.ChanAlias) <= numel(obj.ChanOccupancy)
				tmp=cell(1,numel(obj.ChanOccupancy));
				tmp(1:numel(obj.ChanAlias))=obj.ChanAlias ;
				obj.ChanAlias=tmp;	% <^-- add [] after alias cell array.
			end
			if numel(obj.ChanAlias) > numel(obj.ChanOccupancy)
				error('Alias number more than channel number.');
			end
			obj.ChanNum=numel(obj.ChanOccupancy); % It's for fast get number.
			
			% --------------------------------
			if iscellstr(obj.ChanType)
				obj.ChanType = obj.ChanType{:} ;
			end
			if iscellstr(obj.DevName)
				obj.DevName = obj.DevName{:} ;
			end
			
			switch [obj.ChanType,obj.ChanMeas]
				% Voltage
				case 'aiVoltage'
					obj.NITaskHandle = DAQmxCreateAIVoltageChan(obj.LibAlias,[],obj.PhyChan ,obj.Min ,obj.Max );
				case 'aoVoltage'
					obj.NITaskHandle = DAQmxCreateAOVoltageChan(obj.LibAlias,[],obj.PhyChan ,obj.Min ,obj.Max );
				% Current
				case 'aiCurrent'
					obj.NITaskHandle = DAQmxCreateAICurrentChan(obj.LibAlias,[],obj.PhyChan ,obj.Min ,obj.Max );
				case 'aoCurrent'
					obj.NITaskHandle = DAQmxCreateAOCurrentChan(obj.LibAlias,[],obj.PhyChan ,obj.Min ,obj.Max );
				otherwise
					error('Wrong in DAQmxCreate*Chan.');
			end
			
			SetTiming(obj);
		end

		% Start task , for mode == f,c
		function varargout=start(obj,varargin)
			obj.DataLastTime = 0 ;
			obj.DataLastPartNum = 0 ;
			obj.DataTotalNumPerChan = 0 ;
			switch obj.ChanType
				case 'ai'
					switch obj.Mode
						case 'Single'
							aibg([],[],obj) ;
						case {'Finite' , 'Continuous'}
							err = calllib(obj.LibAlias,'DAQmxStopTask',obj.NITaskHandle);
							if isempty(obj.TimerHandle)
								SetTiming(obj);
							end
							err = calllib(obj.LibAlias, 'DAQmxStartTask',obj.NITaskHandle);
							start(obj.TimerHandle) ;
					end
				case 'ao'
					switch obj.Mode
						case 'Single'
							aobg([],[],obj) ;
						case {'Finite' , 'Continuous'}
							err = calllib(obj.LibAlias,'DAQmxStopTask',obj.NITaskHandle);
							if isempty(obj.TimerHandle)
								SetTiming(obj);
							end
							err = calllib(obj.LibAlias, 'DAQmxStartTask',obj.NITaskHandle);
							start(obj.TimerHandle) ;
					end
			end
		end

		% Stop task , for mode == f,c
		function stop(obj)
			switch obj.ChanType
				case {'ai','ao'}
					stop(obj.TimerHandle);
					err = calllib(obj.LibAlias,'DAQmxStopTask',obj.NITaskHandle);
			end
		end
		
		function delete(obj)
			obj.stop;
			err = calllib(obj.LibAlias,'DAQmxClearTask',obj.NITaskHandle);
			delete(obj.TimerHandle) ;
		end
		
		% Read last part data.
		function varargout=read(obj,varargin)
			if ~iscellstr(varargin)
				error('Only allow string.') ;
			end
			%if ~strcmpi(obj.Mode,'Single')
			%	error('read method only allow in "single" mode.');
			%end
			switch obj.Mode
				case 'Single'
					% daq read immediately.
					aibg([],[],obj) ;
					DataColumnLgc = ChanSelect(obj,varargin{:}) ; % don;t forget {:}
					varargout{1} = obj.DataStorage(DataColumnLgc) ;
				case 'Finite'
					% outout last part from .DataStorage
					obj.start;
					while numel(obj.DataTotalNumPerChan) <= 1
						pause(0.001); % maybe need wait 0.001 here.(matlab timer delay)
					end
					
					DataColumnLgc = ChanSelect(obj,varargin{:}); % don;t forget {:}
					varargout{1} = obj.DataStorage(end - obj.DataLastPartNum -1 : end  ,DataColumnLgc) ;
				case 'Continuous'
					% outout last part from .DataStorage
					DataColumnLgc = ChanSelect(obj,varargin{:}); % don;t forget {:}
					varargout{1} = obj.DataStorage(end - obj.DataLastPartNum -1 : end  ,DataColumnLgc) ;
			end
		end
		% Write data to .DataStorage (buffer in matlab).
		function varargout=write(obj,varargin)	% For single mode
			if nargin > 2
				%error('"write" only allowd 1 output data for each channel, if you need more please use finite mode.');
				error('"write" only allow 1 data set. Did not support set data for specify channel.')
			end

			if nargin == 1
				% .write() , send last data, it's should stored in obj.DataStorage
								%switch obj.Mode
								%	case 'Single'
								%		aobg([],[],obj) ;
								%	case 'Finite'
								%	case 'Continuous'
								%end
				WriteLastData = 1 ;
			else
				% .write(data) , send specify data.
				WriteLastData = 0 ; 
			end
			
			switch obj.Mode
				case 'Single'
					% daq write immediately.
								%DataColumnLgc = ChanSelect(obj,varargin{:}); % don;t forget {:}
								%varargout = obj.DataStorage(DataColumnLgc) ;
					if ~WriteLastData
						obj.DataStorage = varargin{1} ;
					end
					aobg([],[],obj) ;
				case 'Finite'
					% outout last part from .DataStorage
								%DataColumnLgc = ChanSelect(obj,varargin{:}); % don;t forget {:}
								%varargout = obj.DataStorage(end - obj.DataLastPartNum +1 : end  ,DataColumnLgc) ;
					% append .DataStorage
					if ~WriteLastData
						obj.DataStorage = [obj.DataStorage(obj.BufHead:end,:) ;varargin{1}] ;
					end
					obj.BufHead = 1 ;
					aobg([],[],obj) ;
					obj.start; % don't call .start if running ? because NIstoptask in .start
				case 'Continuous'
					% In continuous mode not support no argument.
					if ~WriteLastData
						if obj.CircBuf
							% overwrite .DataStorage
							obj.DataStorage = varargin{1} ;
							obj.BufHead = 1 ;
						else
							% append .DataStorage
							obj.DataStorage = [obj.DataStorage(obj.BufHead:end,:) ;varargin{1}] ;
							obj.BufHead = 1 ;
						end
					end
			end
			
			% for multichannel function. not support now.
			%if mod(numel(obj.DataStorage), obj.ChanNum)	% it's should stop. Don't put adaptive code.
			%	error('Output data length not same for each channel.');
			%end
		end
		
					% delete this function later
					% Output last part data.
					%function NewData=DataLastPart(obj)
					%	NewData = obj.DataStorage( end - obj.DataLastPartNum -1 : end , :) ;
					%end

		% Get data from .DataStorage , similar read() but different when mode == f,c
		% The aim of similar function is readability in other script..
		function varargout=Data(obj,varargin)
			if ~iscellstr(varargin)
				error('Only allow string.') ;
			end
			switch obj.Mode
				case 'Single'
					% daq read immediately.
					aibg([],[],obj) ;
					DataColumnLgc = ChanSelect(obj,varargin{:}); % don;t forget {:}
					varargout{1} = obj.DataStorage(DataColumnLgc) ;
				case 'Finite'
					% outout all data from .DataStorage
					obj.start;
					DataColumnLgc = ChanSelect(obj,varargin{:}); % don;t forget {:}
					varargout{1} = obj.DataStorage(: ,DataColumnLgc) ;
				case 'Continuous'
					% outout all data from .DataStorage
					DataColumnLgc = ChanSelect(obj,varargin{:}); % don;t forget {:}
					varargout{1} = obj.DataStorage(: ,DataColumnLgc) ;
			end
		end
		
		function ResetDev(obj)
			err=calllib(obj.LibAlias,'DAQmxResetDevice',obj.DevName) ;
		end

		function ChangeMode(obj,str)
			obj.stop;
			switch lower(str)
				case {'single','s'}
					obj.Mode='Single';
				case {'finite','f'}
					obj.Mode = 'Finite' ;
				case {'continuous','c'}
					obj.Mode = 'Continuous' ;
				otherwise
					error('Mode string not allowed.');
			end
			SetTiming(obj);
		end
		function ChangeRate(obj,RateNum)
			obj.stop;
			if isnumeric(RateNum) && numel(RateNum) == 1
				obj.Rate = RateNum ;
			else
				error('Wrong argument.');
			end
			SetTiming(obj);
		end
	end
end

% Background analog intput
function varargout=aibg(TimerObj,event,ChanObj)
	NewData = DAQmxReadAnalogF64(ChanObj.LibAlias ,ChanObj.NITaskHandle, -1 , ChanObj.Timeout, ChanObj.DataLayout, ChanObj.ChanNum, ChanObj.SampleNum) ; % -1 == DAQmx_Val_Auto
	% NewData is 1D data. Follow "if" block format to 2D data.
	% Put each channel data to column(or "_y").
	if strcmpi(ChanObj.Mode,'Single')
		ChanObj.DataStorage = NewData ;% add ' ?
	else
		ChanObj.DataTotalNumPerChan = ChanObj.DataTotalNumPerChan + size(NewData,1) ;
		ChanObj.DataLastTime=(ChanObj.DataTotalNumPerChan-1)/ChanObj.Rate  ; % time of last data
		ChanObj.DataStorage=[ChanObj.DataStorage ; NewData ]; 
		DataWindow_y=size(ChanObj.DataStorage , 1) ;
		
		if DataWindow_y > ChanObj.DataWindowLen
			ChanObj.DataStorage=ChanObj.DataStorage(end-ChanObj.DataWindowLen+1 : end , :) ;
			DataWindow_y=ChanObj.DataWindowLen;
		end
		ChanObj.DataLastPartNum=size(NewData,1); % for get last part data (last NewData) by index.

		ChanObj.DataTime=[ ChanObj.DataLastTime- (DataWindow_y-1) /ChanObj.Rate   : 1/ChanObj.Rate   : ChanObj.DataLastTime ]' ;
		
		if strcmpi(ChanObj.Mode,'Finite')
			if ChanObj.DataTotalNumPerChan >= ChanObj.SampleNum
				obj.stop;
			end
		end
	end
	%varargout={ChanObj};
	if ~isempty(ChanObj.CallbackFunc)
		feval(ChanObj.CallbackFunc, ChanObj) % call user's function
	end
	
end

% ======== NI Buffer size ========
% Buffered writes require a minimum buffer size of 2 samples. If you do not configure the buffer size using DAQmxCfgOutputBuffer, NI-DAQmx automatically configures the buffer when you configure sample timing.
% If the acquisition is finite , NI-DAQmx allocates a buffer equal in size to the value of samples per channel. 
% If the acquisition is continuous, NI-DAQmx will allocate a buffer according to the following table: (S == Scan)
% Sample Rate			Buffer Size
% 0 - 100 S/s				1 kS
% 100 - 10,000 S/s 			10 kS
% 10,000 - 1,000,000 S/s 	100 kS
% > 1,000,000 S/s 			1 MS

% Background analog outout
function aobg(TimerObj,event,ChanObj)
	% suppose mod(numel(obj.DataStorage), obj.ChanNum) == 0
	% Only write from .DataStorage in this function.
	% For performance reason, .DataStorage should prepared in call function (write() )
	switch obj.Mode
		case 'Single'
			%if numel(obj.DataStorage) < obj.ChanNum
			%	obj.DataStorage=[obj.DataStorage, zeros(1,obj.ChanNum-numel(obj.DataStorage))] ;
			%else
			%	obj.DataStorage=obj.DataStorage(1:obj.ChanNum); ;
			%end
			WrittenNum = DAQmxWriteAnalogF64(ChanObj.LibAlias, ChanObj.NITaskHandle, ChanObj.ChanNum, ChanObj.Timeout ,ChanObj.DataLayout, obj.DataStorage);
		case 'Finite'
			WrittenNum = DAQmxWriteAnalogF64(ChanObj.LibAlias, ChanObj.NITaskHandle, ChanObj.ChanNum, ChanObj.Timeout ,ChanObj.DataLayout, obj.DataStorage(obj.BufHead:end,:) );
			obj.BufHead = obj.BufHead + WrittenNum ;
			%TODO: put check task done here.
		case 'Continuous'
			if obj.CircBuf
				BufLen=length(obj.DataStorage);
				WrittenNum = DAQmxWriteAnalogF64(ChanObj.LibAlias, ChanObj.NITaskHandle, ChanObj.ChanNum, ChanObj.Timeout ,ChanObj.DataLayout, circshift(obj.DataStorage,-obj.BufHead) );
				obj.BufHead = mod(obj.BufHead+WrittenNum,BufLen);
			else
				WrittenNum = DAQmxWriteAnalogF64(ChanObj.LibAlias, ChanObj.NITaskHandle, ChanObj.ChanNum, ChanObj.Timeout ,ChanObj.DataLayout, obj.DataStorage(obj.BufHead:end,:) );
				obj.BufHead = obj.BufHead + WrittenNum ;
			end
	end
	% TODO : should reshape or sort data ?
	if ~isempty(ChanObj.CallbackFunc)
		feval(ChanObj.CallbackFunc, ChanObj) % call user's function
	end
end

% set Task timing and make matlab timer.
function SetTiming(obj)
	if ~isempty(obj.TimerHandle)
		delete(obj.TimerHandle) ;
	end
	if strcmpi(obj.Mode,'Single')
		return ;
	end
	switch obj.ChanType
		case 'ai'
			TimerFcn_Handle=@aibg ;
		case 'ao'
			TimerFcn_Handle=@aobg ;
	end
	switch obj.Mode
		case 'Finite'
			obj.TimerHandle = timer('TimerFcn',{TimerFcn_Handle,obj},'ExecutionMode','fixedRate','Period',obj.ProcPeriod,'TasksToExecute',ceil(obj.SampleNum/obj.Rate/obj.ProcPeriod));
			DAQmxCfgSampClkTiming(obj.LibAlias, obj.TimerHandle, 10178, obj.Rate ,obj.SampleNum); % DAQmx_Val_FiniteSamps = 10178 % Finite Samples , Total data number set in SampleNum
		case 'Continuous'
			
			obj.TimerHandle = timer('TimerFcn',{TimerFcn_Handle,obj},'ExecutionMode','fixedRate','Period',obj.ProcPeriod) ;
			
			DAQmxCfgSampClkTiming(obj.LibAlias, obj.NITaskHandle, 10123, obj.Rate ,obj.SampleNum); % DAQmx_Val_ContSamps = 10123 % Continuous Samples
	end
end

% Localize selected channel column from read data set. 
function DataColumnLgc = ChanSelect(obj,varargin)
	if nargin > 1
		DataColumnLgc = logical(zeros(1,obj.ChanNum)) ;
		for arg_i = 1:(nargin-1)
			DataColumnLgc = DataColumnLgc | (sort(obj.ChanOccupancy) == obj.ChanOccupancy(strcmpi(obj.ChanAlias,varargin{arg_i} )) ) ;
		end
	else
		DataColumnLgc = logical(ones(1,obj.ChanNum)) ;
	end
end