function ECGProc(obj)
	persistent mon fig peakhigh;
	if nargin == 0
		% Action by direct run this function file.
		close all;
		clear classes;
		daq = daqmx_Task('chan','dev1/ai1','rate',1000,'callbackfunc','ECGProc','ProcPeriod',0.2);
		daq.DataWindowLen = 120*daq.Rate ;			% store 120 sec. data in object.
		daq.SampleNum=3*daq.Rate*daq.ProcPeriod;	% 3 times ProcPeriod buffer.
		daq.ResetDev;
		daq.start;
		%pause(10);
		%figure; plot(daq.DataTime , daq.Data); % plot 3 lines of each channel .
		%figure; plot(daq.DataTime , daq.Data('a') ); % plot ecg_ra only .
		%daq.stop;
	else
		% Careful , this section variable scope is different with above.
		if obj.DataTotalNumPerChan > 0
			if ~isa(mon,'monitor')
				% Initialization
				fig=figure('Renderer','OpenGL') ;
				peakhigh=uicontrol('style','edit','string','0.5');
				mon=monitor(fig,obj.DataTime,obj.Data);
			else
				% Action when every loop , call by timer .
				if obj.DataTime(end) > 10
					peak_high=str2num(get(peakhigh,'string')) ;
					[pks,locs] =findpeaks(sign(peak_high)*obj.Data,'MINPEAKHEIGHT',abs(peak_high),'MINPEAKDISTANCE',0.18*obj.Rate);
					ibi=[obj.DataTime(locs(2:end)), diff(obj.DataTime(locs),1)];
					mstd=movingstd(ibi(:,2),5,'c');
					%mstd=ibi(:,2);
				else
					ibi=[0,0];
					mstd=ibi(:,2);
				end
				mon.plot(fig,{obj.DataTime,ibi(:,1),ibi(:,1)},{obj.Data,ibi(:,2),mstd });
			end
		end
	end
end