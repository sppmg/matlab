function ECGProc(obj)
	persistent mon fig uiPeakHigh analyze ;
	if nargin == 0
		% Action by direct run this function file.
        % delete(timerfind); close all; clear classes;
		daq = daqmx_Task('chan','dev1/ai1','rate',5000,'callbackfunc','ECGProc','ProcPeriod',1);
		daq.DataWindowLen = 120*daq.Rate ;			% store 120 sec. data in object.
		% daq.SampleNum=round(3*daq.Rate*daq.ProcPeriod);	% 3 times ProcPeriod buffer. Should be default setting in last daqmx_Task.
		daq.ResetDev;
		daq.start;
		%pause(10);
		%figure; plot(daq.DataTime , daq.data); % plot 3 lines of each channel .
		%figure; plot(daq.DataTime , daq.data('a') ); % plot ecg_ra only .
		%daq.stop;
	else
		% Careful , this section variable scope is different with above. <-- maybe used clear all ?
		if obj.DataTotalNumPerChan > 0
			if ~isa(mon,'monitor')
				% Initialization
				analyze.rt_msdDataLen = 5 ; % movingstd window. number of data.
				analyze.rt_peakHigh = 0.2 ; %
				analyze.rt_peakMinInterval = 0.18 ; % sec.
				analyze.LastTime = 0 ;
				analyze.data_length = 60 ; %sec
				analyze.period = 10 ;

				fig=figure('Renderer','OpenGL','MenuBar', 'none','ToolBar', 'none') ;
				uiPeakHigh=uicontrol('style','edit','string',analyze.rt_peakHigh,'Parent',fig,'DeleteFcn',{@delme,obj});
				mon=monitor(fig,obj.DataTime,obj.data);
			else
				% Action when every loop , call by timer .
				if obj.DataTime(end) > 1	% Analyze after 1 sec.
					analyze.rt_peakHigh=str2num(get(uiPeakHigh,'string')) ;
					[pks,locs] =findpeaks(sign(analyze.rt_peakHigh)*obj.data,'MINPEAKHEIGHT',abs(analyze.rt_peakHigh), 'MINPEAKDISTANCE', analyze.rt_peakMinInterval * obj.Rate);
					ibi=[obj.DataTime(locs(2:end)), diff(obj.DataTime(locs),1)];
					if length(ibi)<(2* analyze.rt_msdDataLen+1)  % check for movingstd ()
						%ibi=[0,0];
						mstd=ibi(:,2);
					else
						mstd=movingstd(ibi(:,2), analyze.rt_msdDataLen,'c');
					end
				else
					ibi=[0,0];
					mstd=ibi(:,2);
                end

                part_start=numel(obj.DataTime)-5*obj.Rate; % for raw signal in plot
                if part_start < 1
                    part_start = 1;
                end
                d=obj.data;

                mon.plot(fig, ...
					{obj.DataTime(part_start:end),ibi(:,1),ibi(:,1)}, ...
					{d(part_start:end),ibi(:,2),mstd });

				if obj.DataTime(end) > analyze.LastTime + analyze.period
					analyze.data_ss = ibi(:,1) > obj.DataTime(end) - analyze.data_length ;

					fprintf('IBI = %f \t HRV = %e \n',mean(ibi(analyze.data_ss ,2)),std(ibi(analyze.data_ss ,2))  );

					analyze.LastTime = analyze.LastTime + analyze.period
				end
			end
		end
	end
end

function delme(a,b,obj)
	obj.stop;
	delete(timerfind);
	%obj.delete; % can't work now.
	clear classes;
end