function ECGProc(obj)
	persistent mon fig peakhigh old_sd_time;
	if nargin == 0
		% Action by direct run this function file.

        %delete(timerfind); close all; clear classes;
		daq = daqmx_Task('chan','dev1/ai1','rate',5000,'callbackfunc','ECGProc','ProcPeriod',1);
		daq.DataWindowLen = 120*daq.Rate ;			% store 120 sec. data in object.
		% daq.SampleNum=round(3*daq.Rate*daq.ProcPeriod);	% 3 times ProcPeriod buffer. Should default setting in last daqmx_Task.
		daq.ResetDev;
		daq.start;
		%pause(10);
		%figure; plot(daq.DataTime , daq.data); % plot 3 lines of each channel .
		%figure; plot(daq.DataTime , daq.data('a') ); % plot ecg_ra only .
		%daq.stop;
	else
		% Careful , this section variable scope is different with above. <-- because used clear all .
		if obj.DataTotalNumPerChan > 0
			if ~isa(mon,'monitor')
				% Initialization
				fig=figure('Renderer','OpenGL') ;
				peakhigh=uicontrol('style','edit','string','0.2','Parent',fig,'DeleteFcn',{@delme,obj});
				old_sd_time=0;
				mon=monitor(fig,obj.DataTime,obj.data);
			else
				% Action when every loop , call by timer .
				if obj.DataTime(end) > 1
					
					peak_high=str2num(get(peakhigh,'string')) ;
					[pks,locs] =findpeaks(sign(peak_high)*obj.data,'MINPEAKHEIGHT',abs(peak_high),'MINPEAKDISTANCE',0.18*obj.Rate);
					ibi=[obj.DataTime(locs(2:end)), diff(obj.DataTime(locs),1)];
					if length(ibi)<(2*5+1)
						ibi=[0,0];
						mstd=ibi(:,2);
						
					else
						mstd=movingstd(ibi(:,2),5,'c');
					end
					%mstd=ibi(:,2);
				else
					ibi=[0,0];
					mstd=ibi(:,2);
                end

                part_start=numel(obj.DataTime)-5*obj.Rate;
                if part_start < 1
                    part_start = 1;
                end
                d=obj.data;
                mon.plot(fig,{obj.DataTime(part_start:end),ibi(:,1),ibi(:,1)},{d(part_start:end),ibi(:,2),mstd });
				if obj.DataTime(end) > old_sd_time+5
					fprintf('Mean = %f \t HRV = %f \n',mean(ibi(:,2)),std(ibi(:,2))  );
					%fprintf('HRV = %f \n',));
					old_sd_time=old_sd_time+5;
				end
					
				%mon.plot(fig,{obj.DataTime,ibi(:,1),ibi(:,1)},{obj.data,ibi(:,2),mstd });
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