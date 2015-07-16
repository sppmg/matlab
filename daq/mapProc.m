function mapProc(daq)
	persistent mon ana ui pl ;
	% ui for GUI headle , ana for all analysis variable, .rt_ for real time , .lt_ for long time.
	if nargin == 0
	% Section action by direct run this function file. Only define daq object and run it.
		% delete(timerfind); close all; clear classes;
		% batch(@t1t2,1);
		ui=gui;
		return;
		%batch(@heartCtrl_t1t2_gui,1);
		daq = daqmx_Task('chan','dev4/ai0:1','rate',5000,'callbackfunc','mapProc','ProcPeriod',2);
		daq.DataStorageLen = 30*daq.Rate ;			% store 120 sec. data in object.
		daq.resetDev;
		daq.start;
	else
	% Section action by daq object callback
		% Careful , this section variable scope is different with above. <-- maybe used clear all ?
		if daq.DataTotalNumPerChan > 0
			if isempty(ana) %~isa(mon,'monitor')
				% Initialization
				ana.rt_plotLenSec_sig = 10 ; % for raw signal in plot
				ana.rt_msdDataLen = 5 ; % movingstd window. number of data.
				ana.rt_peakHigh = 0.1 ; %
				ana.rt_peakMinInterval_lvp = 0.3 ; % sec.
				ana.rt_peakMinHeight_pace = 0.1 ;
				ana.rt_peakMinInterval_pace = 0.3 ;
				ana.histPace = zeros(2);
				ana.histLVP = zeros(2);
				%ana.lt_a_updatePeriod = 30 ; % lt_a_ for 10 sec.
				%ana.lt_a_updateTime = ana.lt_a_updatePeriod ;
				%ana.lt_a_dataLenSec = 60 ; %sec

				%ui.peakMinInterval_edt = uicontrol('style','edit','string',ana.peakMinInterval_lvp,'Parent',ui.fig,'DeleteFcn',{@delme,daq});
				
				x=[1:4]; y=x; u=x; v=x;
				% history of LVP peaks and pacing interval . make yy plot.
				pl.histLVP = line(x,y, ...
					'Parent',ui.plotAxes_hist(1), ...
					'Color','b', ...
					'LineStyle',':' , ...
					'Marker', '+', ...
					'MarkerEdgeColor', 'r');
				pl.histPace = line(x,y, ...
					'Parent',ui.plotAxes_hist(2), ...
					'Color','c', ...
					'LineStyle',':' , ...
					'Marker', '*', ...
					'MarkerEdgeColor', 'k');
				
				% check findpeaks
				pl.lvpl = line(x,y,'Color','b','LineStyle','-', 'Parent',ui.plotPlace_checkPeak_lvp);
				pl.lvpp = line(x,y,'LineStyle','none','Marker','+','MarkerEdgeColor',[1,0,0], 'Parent',ui.plotPlace_checkPeak_lvp);
				pl.lvpa = gca;
				pl.pacel = line(x,y,'Color','b','LineStyle','-', 'Parent',ui.plotPlace_checkPeak_pace);
				pl.pacep = line(x,y,'LineStyle','none','Marker','+','MarkerEdgeColor',[1,0,0], 'Parent',ui.plotPlace_checkPeak_pace);
				pl.pacea = gca;

				% Poincare map
				pl.q=quiver(x,y,u,v,'k', 'Parent',ui.plotPlace_Pmap);
				pl.l=line(x,y,'Color','b', 'LineStyle',':', ...
					'Marker','*','MarkerEdgeColor','r', ...
					'Parent',ui.plotPlace_Pmap );
				pl.a=gca;

			else
				% Action when every loop , call by timer .
				% daq -> col 1 == LVP , col2 == pace
				
				ana.rt_peakMinInterval_lvp = str2double(get(ui.peakMinInterval_lvp,'string')) ;
				
				%[pks,locs] = findpeaks( sign(ana.rt_peakHigh)*daq.data, 'MINPEAKHEIGHT', abs(ana.rt_peakHigh), 'MINPEAKDISTANCE', ana.peakMinInterval_lvp * daq.Rate);
				% pacing interval
				[~,locsp] = findpeaks(daq.DataStorage(:,2), 'MINPEAKDISTANCE', round( ana.rt_peakMinInterval_lvp * daq.Rate), 'MINPEAKHEIGHT' ,ana.rt_peakMinHeight_pace );
				if ~isempty(locsp)
					tmp = [ana.histPace; [daq.DataTime(locsp(2:end)),diff(daq.DataTime(locsp))] ];
					%[~,ic,~] = unique(tmp, stable');
					[~,ic,~] = unique(tmp(:,1),'first');
					ana.histLVP = tmp(ic,:) ;
					%ana.histPace = [ana.histPace; [daq.DataTime(locs(2:end)),diff(daq.DataTime(locs))] ];
				end
				
				
				sp=smooth(daq.DataStorage(:,1),round(daq.Rate/1e2) ); % 10ms
				[pks,locs] = findpeaks( sp,'MINPEAKDISTANCE',ana.rt_peakMinInterval_lvp * daq.Rate,'MINPEAKHEIGHT',mean(sp));
				if ~isempty(locs)
					tmp = [ana.histLVP;[daq.DataTime(locs),sp(locs)] ];
					%[~,ic,~] = unique(tmp, stable');
					[~,ic,~] = unique(tmp(:,1),'first');
					ana.histLVP = tmp(ic,:) ;
					%ana.histLVP = [ana.histLVP;[daq.DataTime(locs),sp(locs)] ];
				end
				
				% plot history
				set(pl.histPace, 'XData', ana.histPace(:,1),'YData', ana.histPace(:,2));
				set(pl.histLVP, 'XData', ana.histLVP(:,1),'YData', ana.histLVP(:,2));

				% set x,y range
				
				% set(ha(n),'YLim',[min(tmp(ctrlStart:ctrlStop)) max(tmp(ctrlStart:ctrlStop))]);
				tmp = get(ui.histXrange,'string') ;
				if strcmpi(tmp,'auto')
					set(ui.plotAxes_hist,'XLimMode','auto');
					%set(pl.histLVP,'XLimMode','auto');
				else
					switch numel(str2num(tmp))
						case 1
							set(ui.plotAxes_hist,'XLim',[str2num(tmp) , ana.histLVP(end-1,1)]);
							%xlim(pl.histLVP,[str2num(tmp) , ana.histPace(end,1)] );
						case 2
							set(ui.plotAxes_hist,'XLim',str2num(tmp));
							%xlim(pl.histLVP,str2num(tmp) );
					end
				end
				tmp = get(ui.histYrange,'string') ;
				if strcmpi(tmp,'auto')
					set(ui.plotAxes_hist,'YLimMode','auto');
					%set(pl.histLVP,'YLimMode','auto');
				else
					switch numel(str2num(tmp))
						%case 1
							%ylim(pl.histPace,[str2num(tmp) , ana.histPace(end,1)] );
							%xlim(pl.histLVP,[str2num(tmp) , ana.histPace(end,1)] );
						case 2
							set(ui.plotAxes_hist,'YLim',str2num(tmp) );
							%xlim(pl.histLVP,str2num(tmp) );
					end
				end
				

				pks=pks(2:end-1);
				if numel(pks) > 4
					set(pl.lvpl,'XData',daq.DataTime, 'YData', sp);
					set(pl.lvpp,'XData',daq.DataTime(locs(2:end-1)), 'YData', pks);
					set(pl.lvpa,'xlim',[daq.DataTime(1),daq.DataTime(end)] );
					set(pl.pacel,'XData',daq.DataTime, 'YData', daq.DataStorage(:,2) );
					set(pl.pacep,'XData',daq.DataTime(locsp(2:end-1)), 'YData', daq.DataStorage(locsp(2:end-1),2));
					set(pl.pacea,'xlim',[daq.DataTime(1),daq.DataTime(end)] );
					if numel(pks) > 25
						plotNum=25;
					else
						plotNum=1;
					end
					x=pks(end-plotNum:end-2);
					y=pks(end-plotNum+1:end-1);
					u=[diff(x);0];
					v=[diff(y);0];
					set(pl.q,'XData',x,'YData',y,'UData',u,'VData',v);
					set(pl.l,'XData',x,'YData',y);
					set(pl.a,'XLimMode','auto');
					drawnow;
					
					
				end

                
			end
		end
	end
end

function delme(a,b,daq)
	daq.stop;
	delete(timerfind);
	daq.delete;
	clear classes;
end

function ui=gui()
%global ui;
defFontSize=18 ;
ui.fig = figure('MenuBar', 'none','ToolBar', 'none','Units','normalized','Position',[0.6,0.035,0.4,0.91]) ; % 'Renderer','OpenGL',


ui.layBase = uiextras.VBox('Parent',ui.fig,'Spacing', 3);
	ui.layHist = uiextras.HBox('Parent',ui.layBase,'Spacing', 0);
		ui.plotPlace_hist = uipanel('Parent', ui.layHist, 'BorderType','none','BorderWidth',0);
		ui.plotAxes_hist(1) = axes( 'Parent', ui.plotPlace_hist, ...
					'DrawMode', 'fast', ...
					'LooseInset', [0.05, 0.1, 0.05, 0.1]); %'LooseInset'
		ui.plotAxes_hist(2) = axes( 'Parent', ui.plotPlace_hist, ...
					'Position',get(ui.plotAxes_hist(1),'Position'),...
					'XAxisLocation','top',...
					'YAxisLocation','right',...
					'Color','none' , ...
					'DrawMode', 'fast');
			linkprop([ui.plotAxes_hist(1), ui.plotAxes_hist(2)],'Position');
			% can't updata data in axes after linkaxes.
			% because 'Xlimmode' will change to manual, use 'set' set to auto every loop.
			% linkaxes([ ui.plotAxes_hist(1), ui.plotAxes_hist(2)],'x');
		ui.layHistCtrl = uiextras.VBox('Parent',ui.layHist,'Spacing', 3);
			uicontrol( 'Parent',ui.layHistCtrl, 'Style','text','FontSize',defFontSize, 'String', 'Y range');
			ui.histYrange = uicontrol( 'Parent',ui.layHistCtrl, 'Style','edit','FontSize', defFontSize, 'String', 'auto');
			uiextras.Empty( 'Parent', ui.layHistCtrl);

			uicontrol( 'Parent',ui.layHistCtrl, 'Style','text','FontSize',defFontSize, 'String', 'X range');
			ui.histXrange = uicontrol( 'Parent',ui.layHistCtrl, 'Style','edit','FontSize', defFontSize, 'String', 'auto');
			set(ui.layHistCtrl, 'Sizes', [30 ,30, -1, 30, 30]);
		set(ui.layHist, 'Sizes', [-1, 130]);
	ui.layRT = uiextras.HBox('Parent',ui.layBase,'Spacing', 3);
		ui.layRTCheck = uiextras.Grid('Parent',ui.layRT,'Spacing', 3);
			
			uiextras.Empty( 'Parent', ui.layRTCheck);
			uicontrol( 'Parent',ui.layRTCheck, 'Style','text','FontSize',defFontSize*0.6, 'String', {'Peak', 'height'});
			uicontrol( 'Parent',ui.layRTCheck, 'Style','text','FontSize',defFontSize*0.6, 'String', {'Peak', 'distence(s)'});
			
			ui.plotPlace_checkPeak_lvp = axes( 'Parent', ui.layRTCheck, 'LooseInset', [0,0,0,0]);
			ui.peakMinHeight_lvp = uicontrol( 'Parent',ui.layRTCheck, 'Style','edit','FontSize', defFontSize, 'String', 'auto','Enable','off');
			ui.peakMinInterval_lvp = uicontrol( 'Parent',ui.layRTCheck, 'Style','edit','FontSize', defFontSize, 'String', '0.20');

			ui.plotPlace_checkPeak_pace = axes( 'Parent', ui.layRTCheck, 'LooseInset', [0,0,0,0]);
			ui.peakMinHeight_pace = uicontrol( 'Parent',ui.layRTCheck, 'Style','edit','FontSize', defFontSize, 'String', 0.1);
			ui.peakMinInterval_pace = uicontrol( 'Parent',ui.layRTCheck, 'Style','edit','FontSize', defFontSize, 'String', '0.20');
			
			set(ui.layRTCheck, 'ColumnSizes', [80 -1 -1], 'RowSizes', [-1 40 40] );
		
			
		ui.plotPlace_Pmap = axes( 'Parent', ui.layRT, 'LooseInset', [0,0,0,0]);
		set(ui.layRT, 'Sizes', [-1, -1]);
		% 'LooseInset --> http://undocumentedmatlab.com/blog/axes-looseinset-property
end