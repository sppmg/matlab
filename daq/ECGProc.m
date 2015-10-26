function ECGProc(daq)
	% need monitor.m before 2015/04/10
	persistent mon ana ui ;
	% ui for GUI headle , ana for all analysis variable, .rt_ for real time , .lt_ for long time.
	if nargin == 0
	% Section action by direct run this function file. Only define daq object and run it.
        % delete(timerfind); close all; clear classes;
		daq = daqmx_Task('chan','dev1/ai1','rate',5000,'callbackfunc',mfilename,'ProcPeriod',1);
		daq.DataStorageLen = 120*daq.Rate ;			% store 120 sec. data in object.
		daq.resetDev;
		daq.start;
		ana.taskTime = tic ;
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

				ui.plotPlace = figure('Renderer','OpenGL','MenuBar', 'none','ToolBar', 'none', 'Units','normalized','Position',[0.6,0.035,0.4,0.91]) ;
				ui.peakHigh_edt = uicontrol('style','edit','string',ana.rt_peakHigh,'Parent',ui.plotPlace,'DeleteFcn',{@delme,daq});
				mon = monitor(ui.plotPlace,daq.DataTime,daq.data);
			else
				% Action when every loop , call by timer .
				ana.rt_peakHigh = str2double(get(ui.peakHigh_edt,'string')) ;
				[~,locs] = findpeaks( sign(ana.rt_peakHigh)*daq.data, 'MINPEAKHEIGHT', abs(ana.rt_peakHigh), 'MINPEAKDISTANCE', ana.rt_peakMinInterval * daq.Rate);
				if numel(locs) > 2 % need rewrite this line in 2+ channel.
					ibi=[daq.DataTime(locs(2:end)), diff(daq.DataTime(locs),1)];
					if length(ibi) > (2* ana.rt_msdDataLen+1)  % check for movingstd () , use length here , not numel.
						mstd=movingstd(ibi(:,2), ana.rt_msdDataLen,'c');
					else
						mstd=ibi(:,2);
					end
				else
					ibi=ones(2);
					mstd=ibi(:,2);
				end

                part_start=numel(daq.DataTime)- ana.rt_plotLenSec_sig* daq.Rate ; % for raw signal in plot
                if part_start < 1
                    part_start = 1;
                end
                d=daq.data;

				% check BS
				ibi_rate_last=ibi(2:end,2)./ibi(1:end-1,2);% daq.DataTime(end-length(ibi_rate_last)+1:end) == ibi(2:end,1)
				ibi_rate_mean=ibi(2:end,2)/mean(ibi(:,2));
				if ~isnumeric(ibi_rate_last) ; ibi_rate_last=0; end
				if ~isnumeric(ibi_rate_mean) ; ibi_rate_mean=0; end
%,daq.DataTime(end-length(ibi_rate_mean)+1:end)
% ...
% daq.DataTime(end-length(ibi_rate_last)+1:end)
% ibi(:,1)
% ibi_rate_last
% ibi_rate_mean

                mon.plot(ui.plotPlace, ...
					{daq.DataTime(part_start:end),ibi(:,1),ibi(:,1),daq.DataTime(end-length(ibi_rate_last)+1:end),daq.DataTime(end-length(ibi_rate_mean)+1:end)}, ...
					{d(part_start:end),ibi(:,2),mstd ,ibi_rate_last,ibi_rate_mean});

				if daq.DataTime(end) > ana.lt_a_updateTime
					ana.dataSS = ibi(:,1) > ( daq.DataTime(end) - ana.lt_a_dataLenSec );
					fprintf('Time = %d \t IBI = %f \t HRV = %e \n',toc(ana.taskTime) ,mean(ibi(ana.dataSS ,2)),std(ibi(ana.dataSS ,2))  );
					% time func--> datestr(now)
					ana.lt_a_updateTime = ana.lt_a_updateTime + ana.lt_a_updatePeriod ;
				end
			end
		end
	end
end

function delme(~,~,daq)
	%daq.stop;
	%delete(timerfind);
	daq.delete; % can't work now.
	%clear classes;
end