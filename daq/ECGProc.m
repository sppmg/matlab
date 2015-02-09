function ECGProc(daq)
	persistent mon ana ui ;
	% ui for GUI headle , ana for all analysis variable, .rt_ for real time , .lt_ for long time.
	if nargin == 0
	% Section action by direct run this function file. Only define daq object and run it.
        % delete(timerfind); close all; clear classes;
		daq = daqmx_Task('chan','dev1/ai1','rate',5000,'callbackfunc','ECGProc','ProcPeriod',1);
		daq.DataWindowLen = 120*daq.Rate ;			% store 120 sec. data in object.
		% daq.SampleNum=round(3*daq.Rate*daq.ProcPeriod);	% 3 times ProcPeriod buffer. Should be default setting in last daqmx_Task.
		daq.ResetDev;
		daq.start;
		%pause(10); daq.stop;
	else
	% Section action by daq object callback
		% Careful , this section variable scope is different with above. <-- maybe used clear all ?
		if daq.DataTotalNumPerChan > 0
			if ~isa(mon,'monitor')
				% Initialization
				ana.rt_plotLenSec_sig = 5 ; % for raw signal in plot
				ana.rt_msdDataLen = 5 ; % movingstd window. number of data.
				ana.rt_peakHigh = 0.2 ; %
				ana.rt_peakMinInterval = 0.18 ; % sec.
				ana.lt_a_updatePeriod = 30 ; % lt_a_ for 10 sec.
				ana.lt_a_updateTime = ana.lt_a_updatePeriod ;
				ana.lt_a_dataLenSec = 60 ; %sec

				ui.plotPlace = figure('Renderer','OpenGL','MenuBar', 'none','ToolBar', 'none') ;
				ui.peakHigh_edt = uicontrol('style','edit','string',ana.rt_peakHigh,'Parent',ui.plotPlace,'DeleteFcn',{@delme,daq});
				mon = monitor(ui.plotPlace,daq.DataTime,daq.data);
			else
				% Action when every loop , call by timer .
				ana.rt_peakHigh = str2num(get(ui.peakHigh_edt,'string')) ;
				[pks,locs] = findpeaks( sign(ana.rt_peakHigh)*daq.data, 'MINPEAKHEIGHT', abs(ana.rt_peakHigh), 'MINPEAKDISTANCE', ana.rt_peakMinInterval * daq.Rate);
				if length(locs) > 2
					ibi=[daq.DataTime(locs(2:end)), diff(daq.DataTime(locs),1)];
					if numel(ibi) > (2* ana.rt_msdDataLen+1)  % check for movingstd ()
						mstd=movingstd(ibi(:,2), ana.rt_msdDataLen,'c');
					else
						mstd=ibi(:,2);
					end
				else
					ibi=[0,0];
					mstd=ibi(:,2);
				end

                part_start=numel(daq.DataTime)- ana.rt_plotLenSec_sig* daq.Rate ; % for raw signal in plot
                if part_start < 1
                    part_start = 1;
                end
                d=daq.data;

                mon.plot(ui.plotPlace, ...
					{daq.DataTime(part_start:end),ibi(:,1),ibi(:,1)}, ...
					{d(part_start:end),ibi(:,2),mstd });

				if daq.DataTime(end) > ana.lt_a_updateTime
					ana.dataSS = ibi(:,1) > ( daq.DataTime(end) - ana.lt_a_dataLenSec );
					fprintf('IBI = %f \t HRV = %e \n',mean(ibi(ana.dataSS ,2)),std(ibi(ana.dataSS ,2))  );
					ana.lt_a_updateTime = ana.lt_a_updateTime + ana.lt_a_updatePeriod
				end
			end
		end
	end
end

function delme(a,b,daq)
	daq.stop;
	delete(timerfind);
	%daq.delete; % can't work now.
	clear classes;
end