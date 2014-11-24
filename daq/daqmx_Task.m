classdef daqmx_Task < handle
	properties
		ChanAlias ;
		Mode = 'Single' ; % Mode = 'Single' | 'Finite' | 'Continuous'
		Rate = 1000 ;
		Max = 10 ;
		Min = -10 ;
		DataLayout = 1 ;	% DAQmx_Val_GroupByScanNumber = 1 ;
		SampleNum = 200 ; % little more than 10 Hz update rate.
		Timeout = 5 ;
		ProcPeriod = 0.1 ;
		DataWindowLen = 1000 ; % unit = data number
		CallbackFunc ; 
		
		
	end
	
	properties (SetAccess = private)
		PhyChan ; % eg : 'Dev1/ai0';
		NITaskHandle ; 
		TimerHandle ;
		
		DevName ;  % eg : dev1
		ChanType ; % eg : ai / ao / di / do / etc ....
		ChanNum ;
		ChanOccupancy ; 
		
		DataTime ; % storage time of each data
		DataWindow_prop ; % storage input data.
		
		DataLastTime = 0 ;
		DataLastPartNum = 0 ;
		DataTotalNumPerChan = 0 ; % per channel 
				
		LibHeader = 'NIDAQmx-lite.h';
		LibDll = 'C:\WINDOWS\system32\nicaiu.dll' ;
		LibAlias = 'nidaqmx' ;
		
	end
	methods
%  		function obj = daqmx_Task(varargin)
%  			
%  			
%  			if nargin > 0
%  				for arg_i = 1:nargin
%  					if isobj (varargin{arg_i}) % check function name
%  						% add chan
%  						obj.ChanHandle=[obj.ChanHandle,varargin{arg_i}] ;
%  						obj.ChanType{end+1}=varargin{arg_i}.ChanType ;
%  					end
%  					if iscell
%  						% make chan
%  						obj.ChanHandle=[obj.ChanHandle, ...
%  							daqmx_Chan(varargin{arg_i})  ] ;
%  						%obj.ChanAlias(end+1) = obj.ChanHandle.alias
%  					end
%  				end
%  			end
%  		end
		% ---------------------------------------------
		function obj=daqmx_Task(varargin)
			obj.LibAlias = daqmx_loadlib ;
			ModeAlreadySet = 0 ;
			
			% Load lib
			if ~libisloaded(obj.LibAlias)
				% [daqmx_library_fpath, daqmx_library_fname, daqmx_library_fext] = fileparts(daqmx.set.library) ;
				disp(['Matlab: Loading library from ',library])
				[notfound,warnings] = loadlibrary(library, header,'alias',lib);
			end
			disp('Matlab: dll loaded')
			
			if nargin > 0 % && ~mod(nargin,2) % even nargin
				for arg_i = 1:2:size(varargin,2)
					switch lower( varargin{arg_i} )
						case 'chan'
							obj.PhyChan = varargin{arg_i+1} ;
							% Check 
							% move follow code out of phaser because it will map with alias.
							
						case 'alias'
							% TODO
							% check ChanAlias is unique and mutch PhyChan
							obj.ChanAlias = varargin{arg_i+1} ;
							
						case 'mode'
							% Allow use  s,f,c
							switch lower(varargin{arg_i+1})
								case {'single','s')
									obj.Mode='Single';
								case {'finite','f'}
									obj.Mode = 'Finite' ;
								case {'continuous','c'}
									obj.Mode = 'Continuous' ;
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
							% should > 0.001 s
							obj.ProcPeriod = varargin{arg_i+1} ;
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
				tmp(1:numel(obj.ChanAlias))=obj.ChanAlias
				obj.ChanAlias=tmp;	% <^-- add [] after alias cell array.
			end
			if numel(obj.ChanAlias) > numel(obj.ChanOccupancy)
				error('Alias number more than channel number.');
			end
			obj.ChanNum=numel(obj.ChanOccupancy); % It's for fast get number.
			
			% --------------------------------
			
			switch obj.ChanType
				case 'ai'
					obj.NITaskHandle = DAQmxCreateAIVoltageChan(obj.LibAlias,[],obj.PhyChan ,obj.Min ,obj.Max );
				case 'ao'
					obj.NITaskHandle = DAQmxCreateAOVoltageChan(obj.LibAlias,[],obj.PhyChan ,obj.Min ,obj.Max );
			end
					
		end
		function varargout=start(obj,varargin)
			switch obj.ChanType
				case 'ai'
					%obj.NITaskHandle = DAQmxCreateAIVoltageChan(obj.LibAlias,[], obj.PhyChan ,obj.Min , obj.Max );
					switch obj.Mode
						case 'Single'
							aibg([],[],obj) ;
						case 'Finite'
%  							if isempty(obj.TimerHandle)
%  								obj.TimerHandle = timer('TimerFcn',{@aibg,obj},'ExecutionMode','fixedRate','Period',obj.ProcPeriod);
%  							end
%  							err = calllib(obj.LibAlias,'DAQmxStopTask',obj.TimerHandle);
%  							
%  							DAQmxCfgSampClkTiming(obj.LibAlias, obj.TimerHandle, 10178, obj.Rate ,obj.SampleNum); % DAQmx_Val_FiniteSamps = 10178 % Finite Samples
%  							
%  							err = calllib(obj.LibAlias, 'DAQmxStartTask',obj.TimerHandle);
%  							%obj.time=tic ;
%  							start(obj.TimerHandle) ;
						case 'Continuous'
							err = calllib(obj.LibAlias,'DAQmxStopTask',obj.NITaskHandle);
							
							if ~isempty(obj.TimerHandle)
								delete(obj.TimerHandle) ;
							end
							obj.TimerHandle = timer('TimerFcn',{@aibg,obj},'ExecutionMode','fixedRate','Period',obj.ProcPeriod) ;
							
							DAQmxCfgSampClkTiming(obj.LibAlias, obj.NITaskHandle, 10123, obj.Rate ,obj.SampleNum); % DAQmx_Val_ContSamps = 10123 % Continuous Samples
							
							err = calllib(obj.LibAlias, 'DAQmxStartTask',obj.NITaskHandle);
							%obj.time=tic ;
							%aibg(1,2,obj)
							start(obj.TimerHandle) ;
						
					end
				case 'ao'
					obj.NITaskHandle = DAQmxCreateAOVoltageChan(obj.LibAlias,[], obj.PhyChan ,obj.min , obj.max );
					switch obj.Mode
						case 'Single'
							aobg(obj) ;
						case 'Finite'
%  							if isempty(obj.TimerHandle)
%  								obj.TimerHandle = timer('TimerFcn',{@aibg,obj},'ExecutionMode','fixedRate','Period',obj.ProcPeriod);
%  							end
%  							err = calllib(obj.LibAlias,'DAQmxStopTask',obj.TimerHandle);
%  							
%  							DAQmxCfgSampClkTiming(obj.LibAlias, obj.TimerHandle, 10178, obj.Rate ,obj.SampleNum); % DAQmx_Val_FiniteSamps = 10178 % Finite Samples
%  							
%  							err = calllib(obj.LibAlias, 'DAQmxStartTask',obj.TimerHandle);
%  							%obj.time=tic ;
%  							start(obj.TimerHandle) ;
						case 'Continuous'
%  							if isempty(obj.TimerHandle)
%  								obj.TimerHandle = timer('TimerFcn',{@aibg,obj},'ExecutionMode','fixedRate','Period',obj.ProcPeriod);
%  							end
%  							err = calllib(obj.LibAlias,'DAQmxStopTask',obj.TimerHandle);
%  							
%  							DAQmxCfgSampClkTiming(obj.LibAlias, obj.TimerHandle, 10123, obj.Rate ,obj.SampleNum); % DAQmx_Val_ContSamps = 10123 % Continuous Samples
%  							
%  							err = calllib(obj.LibAlias, 'DAQmxStartTask',obj.TimerHandle);
%  							%obj.time=tic ;
%  							start(obj.TimerHandle) ;
					end
			end
		end
		
		function varargout=stop(obj,varargin)
			switch obj.ChanType
				case 'ai'
					stop(obj.TimerHandle);
					delete(obj.TimerHandle) ;
					err = calllib(obj.LibAlias,'DAQmxStopTask',obj.NITaskHandle);
					err = calllib(obj.LibAlias,'DAQmxClearTask',obj.NITaskHandle);
					
			end
		end
		function varargout=read(obj,varargin)	% For single mode , read and output to argout .
			if ~iscellstr(varargin)
				error('Only allow string.') ;
			end
			aibg([],[],obj) ;
			if nargin > 1
				DataColumnLgc = logical(zeros(1,ChanNum)) ;
				for arg_i = 1:(nargin-1)
					DataColumnLgc = DataColumnLgc | (sort(obj.ChanOccupancy) == obj.ChanOccupancy(strcmpi(obj.ChanAlias,varargin{arg_i} )) ) ;
				end
			else
				DataColumnLgc = logical(ones(1,ChanNum)) ;
			end
			varargout = ChanObj.DataWindow_prop(DataColumnLgc) ;
		end
		
		function varargout=write(obj,varargin)	% For single mode
			if nargin > obj.ChanNum+1
				error('"write" only allowd 1 output data for each channel, if you need more please use finite mode.');
			end
			
		end
		% Output last part data.
		function NewData=DataLastPart(obj)
			NewData = obj.DataWindow_prop( end - obj.DataLastPartNum -1 : end , :) ;
		end
		
		function out=DataWindow(obj,varargin)
			if nargin == 1
				out=obj.DataWindow_prop;
			else
				MatchChanID=find(strcmpi(obj.ChanAlias,varargin{1}));
				out=obj.DataWindow_prop(:,MatchChanID);
			end
		end
		
		function ResetDev(obj)
			err=calllib(obj.LibAlias,'DAQmxResetDevice',obj.DevName) ;
		end
	end
end

function varargout=aibg(TimerObj,event,ChanObj)
	NewData = DAQmxReadAnalogF64(ChanObj.LibAlias ,ChanObj.NITaskHandle, -1 , ChanObj.Timeout, ChanObj.DataLayout, ChanObj.ChanNum, ChanObj.SampleNum) ; % -1 == DAQmx_Val_Auto
	% NewData is 1D data. Follow "if" block format to 2D data.
	% Put each channel data to column(or "_y").
	if strcmpi(ChanObj.Mode,'Single')
		ChanObj.DataWindow_prop = NewData ;
	else
		ChanObj.DataTotalNumPerChan = ChanObj.DataTotalNumPerChan + size(NewData,1) ;
		ChanObj.DataLastTime=(ChanObj.DataTotalNumPerChan-1)/ChanObj.Rate  ; % time of last data
		ChanObj.DataWindow_prop=[ChanObj.DataWindow_prop ; NewData ]; 
		DataWindow_y=size(ChanObj.DataWindow_prop , 1) ;
		
		if DataWindow_y > ChanObj.DataWindowLen
			ChanObj.DataWindow_prop=ChanObj.DataWindow_prop(end-ChanObj.DataWindowLen+1 : end , :) ;
			DataWindow_y=ChanObj.DataWindowLen;
		end
		ChanObj.DataLastPartNum=size(NewData,1); % for get last part data (last NewData) by index.

		ChanObj.DataTime=[ ChanObj.DataLastTime- (DataWindow_y-1) /ChanObj.Rate   : 1/ChanObj.Rate   : ChanObj.DataLastTime ]' ;
	end
	%varargout={ChanObj};
	if ~isempty(ChanObj.CallbackFunc)
		feval(ChanObj.CallbackFunc, ChanObj) % call user's function
	end
	
end

function aobg
	if strcmpi(ChanObj.Mode,'Single')
		%ChanObj.DataWindow_prop = NewData ;
	else
	end
end