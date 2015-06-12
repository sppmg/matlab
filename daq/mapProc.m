function mapProc(daq)
	persistent mon ana ui pl ;
	% ui for GUI headle , ana for all analysis variable, .rt_ for real time , .lt_ for long time.
	if nargin == 0
	% Section action by direct run this function file. Only define daq object and run it.
        % delete(timerfind); close all; clear classes;
		daq = daqmx_Task('chan','dev4/ai0','rate',1000,'callbackfunc','mapProc','ProcPeriod',2);
		daq.DataWindowLen = 1*60*daq.Rate ;			% store 120 sec. data in object.
		% daq.SampleNum=round(3*daq.Rate*daq.ProcPeriod);	% 3 times ProcPeriod buffer. Should be default setting in last daqmx_Task.
		daq.ResetDev;
		daq.start;
		%pause(10); daq.stop;
	else
	% Section action by daq object callback
		% Careful , this section variable scope is different with above. <-- maybe used clear all ?
		if daq.DataTotalNumPerChan > 0
			if isempty(ui) %~isa(mon,'monitor')
				% Initialization
				ana.rt_plotLenSec_sig = 10 ; % for raw signal in plot
				ana.rt_msdDataLen = 5 ; % movingstd window. number of data.
				ana.rt_peakHigh = 0.1 ; %
				ana.rt_peakMinInterval = 0.05 ; % sec.
				ana.lt_a_updatePeriod = 30 ; % lt_a_ for 10 sec.
				ana.lt_a_updateTime = ana.lt_a_updatePeriod ;
				ana.lt_a_dataLenSec = 60 ; %sec

				ui.plotPlace = figure('Renderer','OpenGL','MenuBar', 'none','ToolBar', 'none','Units','normalized','Position',[0.6,0.035,0.4,0.91]) ;
				ui.peakHigh_edt = uicontrol('style','edit','string',ana.rt_peakHigh,'Parent',ui.plotPlace,'DeleteFcn',{@delme,daq});
				x=[1:4]; y=x; u=x; v=x;
				subplot(2,1,1);
				pl.lvpl = line(x,y,'Color','b','LineStyle','-');
				pl.lvpp = line(x,y,'LineStyle','none','Marker','+','MarkerEdgeColor',[1,0,0]);

				subplot(2,1,2);
				hold on;
				pl.q=quiver(x,y,u,v,'k');
				pl.h=gca;
				pl.la=plot(x,y,'b:');
				pl.lb=plot(x,y,'r*');
				hold off;
			else
				% Action when every loop , call by timer .
				
				ana.rt_peakHigh = str2num(get(ui.peakHigh_edt,'string')) ;
				%[pks,locs] = findpeaks( sign(ana.rt_peakHigh)*daq.data, 'MINPEAKHEIGHT', abs(ana.rt_peakHigh), 'MINPEAKDISTANCE', ana.rt_peakMinInterval * daq.Rate);
				[pks,locs] = findpeaks( daq.data,'MINPEAKDISTANCE',ana.rt_peakMinInterval * daq.Rate,'MINPEAKHEIGHT',mean(daq.data));
				pks=pks(2:end-1);
				if numel(pks) > 4
					set(pl.lvpl,'XData',daq.DataTime, 'YData', daq.data);
					set(pl.lvpp,'XData',daq.DataTime(locs), 'YData', pks);
					if numel(pks) > 30
						plotNum=25;
					else
						plotNum=1;
					end
					x=pks(end-plotNum:end-2);
					y=pks(end-plotNum+1:end-1);
					u=[diff(x);0];
					v=[diff(y);0];
					set(pl.q,'XData',x,'YData',y,'UData',u,'VData',v);
					set(pl.la,'XData',x,'YData',y);
					set(pl.lb,'XData',x,'YData',y);
					drawnow;
% 					hold on;
% 					quiver(x,y,u,v,'k');
% 					plot(x,y,'b:',x,y,'r*');
% 					hold off;
					
					
				
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