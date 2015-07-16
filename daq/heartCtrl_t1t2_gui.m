function heartCtrl_t1t2_gui()
global expInfo log debug ui tmpData t0 dt count daq
%gui;
expInfo.configFile='heartCtrl_t1t2_cfg.mat'
expInfo.scrStartTime=tic ; % script start time
% ============= user setting ==========
debug=0 ; % 0 -> Real , 1 -> has daq but don't output , 2 -> no daq
daq.LVP = daqmx_Task('dev1/ai0');
daq.Pace = daqmx_Task('dev1/ao0');
useGUI=1;
expInfo.manTiming=0; %manual time from GUI.
autoPrePace = 0 ;	% prepace section for decrease pacing interval, adapt pace section for heart adaption.
	prePace.t0_i= 0.5 ;
	prePace.t0_f= 0.3 ;
	prePace.countPre=8 ;
	prePace.countAdp=16 ;
t0 = [0.5,0.3,0.3,0.5];
dt = [0, 0.1,0.2,  0];
count=[8,8,8,8];	%count of pacing,lose first pacing
expInfo.preRecoedTime=10 ; % time(s) of record to start this script.

% =====================================
if exist( expInfo.configFile, 'file')
	load(expInfo.configFile);
end

if autoPrePace && ~useGUI
	tmpT0 = [linspace(prePace.t0_i, prePace.t0_f, prePace.countPre),ones(1,prePace.countAdp)*prePace.t0_f ] ;
	t0 = [tmpT0,t0];
	dt = [ zeros(1,length(tmpT0)) , dt] ;
	count = [ ones(1,length(tmpT0)) , count] ;
end


gui();

end % this function file


function btnStart(~,~)
	global expInfo log debug ui tmpData t0 dt count
	if get(ui.ctrlPad.perBtnStart, 'Value') % == 1, pushed
		expInfo.run = 1;
		set(ui.ctrlPad.perBtnStart, 'String', 'Stop')
		tmp=get(ui.ctrlPad.timingTable,'Data');
		t0=tmp(:,1);
		dt=tmp(:,2);
		count=tmp(:,3);
		preProc();
	else
		expInfo.run = 0;
		set(ui.ctrlPad.perBtnStart, 'String', 'Start')
		error('Stoped by user.')
	end
end
function btnSend(~,~)
	global expInfo log debug ui tmpData t0 dt count
	expInfo.manTiming = 1 ;
	expInfo.manT0 = str2double(get(ui.ctrlPad.RTSetT0, 'String'));
	expInfo.manDt = str2double(get(ui.ctrlPad.RTSetDt, 'String'));
	expInfo.readStopTime = ( expInfo.manT0 - expInfo.manDt * 1e-3 )* 0.8 - 1e-3 ;
	set(ui.ctrlPad.RTSchedule,'Value',0);
end


function btnSchedule(~,~)
	global expInfo log debug ui tmpData t0 dt count
	if get(ui.ctrlPad.RTSchedule, 'Value') % == 1, pushed
		expInfo.manTiming = 0 ;
	else
		expInfo.manTiming = 1 ;
	end
	%expInfo.readStopTime = ( expInfo.manT0 - expInfo.manDt .* 1e-3 )* 0.8 - 1e-3 ;
end

function preProc()
	global expInfo log debug ui tmpData t0 dt count
	len_t0 = length(t0) ;
	len_dt = length(dt) ;
	len_count = length(count) ;
	readStopTime= ( t0 - dt.*1e-3 )* 0.7 -1e-3; % read time interval of each LVP peak

	%log.peak={};
	%log.sign={};
	%log.signTime={};
	%log.paceTime={};
	%log.diffTime={};
	%log.signDetTime={};

	if (len_t0 == len_dt ) || ( len_dt == len_count )
		len=len_t0 ;
	else
		error('error:difference length t0,dt,count');
	end

	expInfo.old_dt=0;
	expInfo.old_t0=0;
	fprintf('total %d mins\n',sum(count.*t0) );
	tmpData(1e5)=0; % fast memory allocation
	expInfo.nextPacingTime=0;
	expInfo.preProcTime = toc(expInfo.scrStartTime) ;
	expInfo.startTime=tic; % pacing start time
	ctrlStage = 1;
	while ctrlStage <= len
		if expInfo.manTiming
			btnSend(1,2); % get t0
			pace(expInfo.manT0, expInfo.manDt, 1e7, expInfo.readStopTime );
			%if expInfo.manT0 < 1e-5
			%	expInfo.manTiming = ~expInfo.manTiming;
			%end
		else
			% old method, set t0 to togget manTiming
			%if t0(ctrlStage) < 1e-5
			%	expInfo.manTiming = ~expInfo.manTiming;
			%	continue;
			%end
			pace(t0(ctrlStage), dt(ctrlStage), count(ctrlStage), readStopTime(ctrlStage) );
			ctrlStage = ctrlStage +1;

		end
	end
	disp('All done.');
	%min([log.diffTime{:}])
	%v=[log.paceTime{:}];
	%plot(v(2:end),diff(v),'b+:')
	%grid on
end


function pace(t0,dt,count,readStopTime)
	global expInfo log debug tmpData daq 
	% for each ctrlStage
	warn_paceLate = false ;
	pacei = 1;
	while pacei < count
		if expInfo.manTiming
			t0 = expInfo.manT0 ;
			dt = expInfo.manDt ;
		end
		pause(0.001); % For interrupt/callback , must > 1ms
		if ~expInfo.run
			error('Stoped by user.');
		end
		% start T+T-
		if dt  % dt ~= 0
			timeReadStart=tic;
			tmpi=1;
			while toc(timeReadStart) < readStopTime
				%read data by single mode
				%tmpData(tmpi) = rand ;
				tmpData(tmpi) = daq.LVP.read;
				tmp=toc(expInfo.startTime);while (toc(expInfo.startTime)-tmp ) < 1e-3 ; end  % reduce read data length. pause() can't handel less then 1e-2. This method can't handle less then 1e-3. if you need short then 1e-3, change daqmx mode to continuous.
				tmpi=tmpi+1;
			end
			
			peak(2)=max(smooth(tmpData(1:tmpi),10));
			%peak(2)=rand ;
			%log.peak={log.peak{:},peak(2)};
			%ldd=round(length(dd)*.2/2);
			%[~,inx]=max(dd);
			%m=max(smooth(dd(inx-ldd:inx+ldd),ldd));
			
			%signDetTime=tic;
			if peak(2) < peak(1) %sign -1 first in if. case sign=1 have more time.
				signv=-1 ;
			elseif peak(2) > peak(1)
				signv=1 ;
			else
				signv=0 ;
				fprintf('dt = 0 \n');
			end
			%fprintf('peak(1) = %g \t peak(2) = %g \t sign = %g \n',peak(1),peak(2),signv);
			%log.signDetTime={log.signDetTime{:},toc(signDetTime)};
			% debug
			%log.signTime = {log.signTime{:},toc(expInfo.startTime)};
			%log.sign = {log.sign{:},signv};
			peak(1)=peak(2);
		else
			signv = 0;
		end

		% next pacing time
		expInfo.nextPacingTime = expInfo.nextPacingTime + t0 + signv * abs( dt*0.001 );
		if expInfo.nextPacingTime <= toc(expInfo.startTime)
			warn_paceLate = true ;

		end
		%log.diffTime ={log.diffTime{:},expInfo.nextPacingTime - toc(expInfo.startTime)};
		
		% wait to paceing time, for wash time
		%t_wh=tic;
		while toc(expInfo.startTime) < expInfo.nextPacingTime
			%if (expInfo.nextPacingTime - toc(expInfo.startTime)) > 0.1
				%pause(0); %1 ms
			%end
			%toc(t_wh)
		end

		% pace
		%if ~debug
			% debug
			%log.paceTime = {log.paceTime{:},toc(expInfo.startTime)};
			%daq.Pace.write(5);
			%daq.Pace.write(0);
			%fprintf('.');
		%end
		if dt ~= expInfo.old_dt || t0 ~= expInfo.old_t0
			expInfo.old_dt = dt;
			expInfo.old_t0 = t0;
			fprintf('t0=%f ms\tdt=%f ms in %f\t%f\n',t0 ,dt, toc(expInfo.startTime), toc(expInfo.startTime)+ expInfo.preRecoedTime + expInfo.preProcTime );
		end
		if warn_paceLate
			warning('Pacing time passed !)
		end
		if expInfo.manTiming
			pacei = count -1 ; % Terminate this loop from schedule.
		else
			pacei = pacei +1 ;
		end
	end
end


%%% GUI

function gui()
global ui
% for test gui
defFontSize=20 ;
ui.GenTime.fig = figure('MenuBar', 'none','ToolBar', 'none','Visible','off');
ui.GenTime.layBase = uiextras.Grid('Parent',ui.GenTime.fig,'Spacing', 3);
ui.GenTime.txt= [ uicontrol( 'Parent', ui.GenTime.layBase, 'Style','text','FontSize',defFontSize, 'String' ,'pre pacing t0' ) , ...
	uicontrol( 'Parent', ui.GenTime.layBase, 'Style','text','FontSize',defFontSize, 'String' ,'pre pacing count' ) , ...
	uicontrol( 'Parent', ui.GenTime.layBase, 'Style','text','FontSize',defFontSize, 'String' ,'adapt pacing count' ) , ...
	uicontrol( 'Parent', ui.GenTime.layBase, 'Style','text','FontSize',defFontSize, 'String' ,'t0' ) , ...
	uicontrol( 'Parent', ui.GenTime.layBase, 'Style','text','FontSize',defFontSize, 'String' ,'dt' ) , ...
	uicontrol( 'Parent', ui.GenTime.layBase, 'Style','text','FontSize',defFontSize, 'String' ,'count' ) ] ;
ui.GenTime.edit= [ uicontrol( 'Parent', ui.GenTime.layBase, 'Style','edit','FontSize',defFontSize, 'String' ,0.4 ) , ...
	uicontrol( 'Parent', ui.GenTime.layBase, 'Style','edit','FontSize',defFontSize, 'String' ,8 ) , ...
	uicontrol( 'Parent', ui.GenTime.layBase, 'Style','edit','FontSize',defFontSize, 'String' ,16 ) , ...
	uicontrol( 'Parent', ui.GenTime.layBase, 'Style','edit','FontSize',defFontSize, 'String' ,0.25 ) , ...
	uicontrol( 'Parent', ui.GenTime.layBase, 'Style','edit','FontSize',defFontSize, 'String' ,'1,2,3' ) , ...
	uicontrol( 'Parent', ui.GenTime.layBase, 'Style','edit','FontSize',defFontSize, 'String' ,8) ] ;
uiextras.Empty( 'Parent', ui.GenTime.layBase);
uiextras.Empty( 'Parent', ui.GenTime.layBase);
uiextras.Empty( 'Parent', ui.GenTime.layBase);
uiextras.Empty( 'Parent', ui.GenTime.layBase);
uiextras.Empty( 'Parent', ui.GenTime.layBase);
ui.GenTime.ok=uicontrol( 'Parent', ui.GenTime.layBase,'Style', 'pushbutton','FontSize',defFontSize, 'String', 'OK', 'Callback',{@genTime,ui});
set(ui.GenTime.layBase, 'ColumnSizes', [-1 -1 100])

ui.ctrlPad.fig = figure('Renderer','OpenGL','MenuBar', 'none','ToolBar', 'none');
ui.ctrlPad.layBase = uiextras.VBox('Parent',ui.ctrlPad.fig,'Spacing', 3);
	ui.ctrlPad.layPreSet = uiextras.HBox('Parent',ui.ctrlPad.layBase,'Spacing', 3);
		ui.ctrlPad.timingTable = uitable('Parent',ui.ctrlPad.layPreSet, 'Data',magic(3),'ColumnEditable',true , 'ColumnWidth', 'auto', 'ColumnName', {'t0', 'dt', 'count'} );
		ui.ctrlPad.layPreBtn = uiextras.VBox('Parent',ui.ctrlPad.layPreSet,'Spacing', 3);
			ui.ctrlPad.perBtnSmart = uicontrol( 'Parent', ui.ctrlPad.layPreBtn,'Style', 'pushbutton','FontSize',defFontSize, 'String', 'Smart Set', 'Callback',{@openGentimeFig,ui});
			ui.ctrlPad.perBtnStart = uicontrol( 'Parent', ui.ctrlPad.layPreBtn,'Style', 'togglebutton','FontSize',defFontSize , 'String', 'Start', 'Callback',{@btnStart});
			uiextras.Empty( 'Parent',ui.ctrlPad.layPreBtn);
			ui.ctrlPad.perBtnDec = uicontrol( 'Parent', ui.ctrlPad.layPreBtn,'Style', 'pushbutton','FontSize',defFontSize , 'String', '-', 'Callback',{@timingDec,ui} );
			ui.ctrlPad.perBtnInc = uicontrol( 'Parent', ui.ctrlPad.layPreBtn,'Style', 'pushbutton','FontSize',defFontSize , 'String', '+', 'Callback',{@timingInc,ui});
		set(ui.ctrlPad.layPreSet, 'Sizes', [-1, 200]);
	ui.ctrlPad.layRTSet = uiextras.HBox('Parent',ui.ctrlPad.layBase,'Spacing', 3);
		uicontrol( 'Parent',ui.ctrlPad.layRTSet, 'Style','text','FontSize',defFontSize, 'String', 't0 (s)');
		ui.ctrlPad.RTSetT0 = uicontrol( 'Parent',ui.ctrlPad.layRTSet, 'Style','edit','FontSize', defFontSize, 'String', 0.3);
		uicontrol( 'Parent',ui.ctrlPad.layRTSet, 'Style','text','FontSize',defFontSize, 'String', 'dt (ms)');
		ui.ctrlPad.RTSetDt = uicontrol( 'Parent',ui.ctrlPad.layRTSet, 'Style','edit','FontSize',defFontSize, 'String', 3);
		ui.ctrlPad.RTSetBtn = uicontrol( 'Parent', ui.ctrlPad.layRTSet,'Style', 'pushbutton','FontSize',defFontSize, 'String', 'Send', 'Callback',{@btnSend});
		ui.ctrlPad.RTSchedule = uicontrol( 'Parent', ui.ctrlPad.layRTSet,'Style', 'togglebutton','FontSize',defFontSize, 'String', 'Schedule','Value', 1, 'Callback',{@btnSchedule});
		set(ui.ctrlPad.layRTSet, 'Sizes', [-1, -1 , -1, -1 130 130]);
	ui.ctrlPad.layTimingState = uiextras.HBox('Parent',ui.ctrlPad.layBase,'Spacing', 3);
		ui.ctrlPad.TimingStateTxt = uicontrol( 'Parent', ui.ctrlPad.layTimingState, 'Style','text','FontSize',defFontSize, 'String' ,'dt=0' ) ;
	set(ui.ctrlPad.layBase, 'Sizes', [-1, 30 , 30]);
end
%Callback
function openGentimeFig(~,~,ui)
	global ui;
	set(ui.GenTime.fig, 'Visible','on')
end

function genTime(~,~,ui)
	global ui;
	tmpDt=str2num(get(ui.GenTime.edit(5),'String'));
	t0 = [linspace( str2num(get(ui.GenTime.edit(1),'String')) , ...
			str2num(get(ui.GenTime.edit(4),'String')) , ...
			str2num(get(ui.GenTime.edit(2),'String'))  ) , ...
		str2num(get(ui.GenTime.edit(4),'String')) , ...
		ones(1,length(tmpDt)) * str2num(get(ui.GenTime.edit(4),'String')) , ...
		str2num(get(ui.GenTime.edit(4),'String')) ] ;
  	dt= [ zeros(1, str2num(get(ui.GenTime.edit(2),'String')) ) , ...
  		0 , ...
  		tmpDt , ...
  		0 ] ;
	count = [ ones(1, str2num(get(ui.GenTime.edit(2),'String'))) , ...
		str2num(get(ui.GenTime.edit(3),'String')) , ...
		ones(1,length(tmpDt)+1) * str2num(get(ui.GenTime.edit(6),'String')) ] ;

	set(ui.GenTime.fig, 'Visible','off')
	set(ui.ctrlPad.timingTable,'Data',[t0',dt',count']);

end
function timingInc(~,~,ui)
	set(ui.ctrlPad.timingTable,'Data',[get(ui.ctrlPad.timingTable,'Data'); zeros(1,3)]);
end
function timingDec(~,~,ui)
	tmp=get(ui.ctrlPad.timingTable,'Data');
	set(ui.ctrlPad.timingTable,'Data',tmp(1:end-1,:));
end
