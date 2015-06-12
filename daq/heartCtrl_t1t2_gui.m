function heartCtrl_t1t2_gui()
global expInfo log debug ui tmpData t0 dt count
expInfo.scrStartTime=tic ; % script start time
% ============= user setting ==========
debug=0 ; % 0 -> Real , 1 -> has daq but don't output , 2 -> no daq
%daqLVP=daqmx_Task('chan','dev1/ai0');
%daqPace=daqmx_Task('chan','dev1/ao0');
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
		set(ui.ctrlPad.perBtnStart, 'String', 'Stop')
		tmp=get(ui.ctrlPad.timingTable,'Data');
		t0=tmp(:,1);
		dt=tmp(:,2);
		count=tmp(:,3);
		preProc();
	else
		set(ui.ctrlPad.perBtnStart, 'String', 'Start')
		error('Stoped bu user.')
	end
end
function btnSend(~,~)
	global expInfo log debug ui tmpData t0 dt count
	expInfo.manTiming = 1 ;
	expInfo.manT0 = str2double(get(ui.ctrlPad.RTSetT0, 'String'));
	expInfo.manDt = str2double(get(ui.ctrlPad.RTSetDt, 'String'));
	expInfo.readStopTime = ( expInfo.manT0 - expInfo.manDt .* 1e-3 )* 0.8 - 1e-3 ;
end

function preProc()
	global expInfo log debug ui tmpData t0 dt count
	len_t0 = length(t0) ;
	len_dt = length(dt) ;
	len_count = length(count) ;
	readStopTime= ( t0 - dt.*1e-3 )* 0.8 -1e-3; % read time interval of each LVP peak

	log.sign={};
	log.signTime={};
	log.paceTime={};
	log.diffTime={};
	log.signDetTime={};

	if (len_t0 == len_dt ) || ( len_dt == len_count )
		len=len_t0 ;
	else
		error('error:difference length t0,dt,count');
	end

	expInfo.old_dt=0;
	expInfo.old_t0=0;
	fprintf('total %d mins\n',sum(count.*t0) );
	tmpData=zeros(1,1e5);
	expInfo.nextPacingTime=0;
	expInfo.preProcTime = toc(expInfo.scrStartTime) ;
	expInfo.startTime=tic; % pacing start time
	ctrlStage = 1;
	while ctrlStage <= len
		if expInfo.manTiming
			btnSend(1,2); % get t0
			pace(expInfo.manT0, expInfo.manDt, inf, expInfo.readStopTime );
			if expInfo.manT0 < 1e-5
				expInfo.manTiming = ~expInfo.manTiming;
			end
		else
			if t0(ctrlStage) < 1e-5
				expInfo.manTiming = ~expInfo.manTiming;
				continue;
			end
			pace(t0(ctrlStage), dt(ctrlStage), count(ctrlStage), readStopTime(ctrlStage) );
			ctrlStage = ctrlStage +1;

		end
	end
	disp('All done.');
	min([log.diffTime{:}])
	v=[log.paceTime{:}];
	plot(v(2:end),diff(v),'b+:')
	grid on
end


function pace(t0,dt,count,readStopTime)
	global expInfo log debug tmpData
	% for each ctrlStage
	for pacei = 1:count

		% start T+T-
		if dt ~= 0
			peakID=0;
			timeReadStart=tic;
			tmpi=1;

			while toc(timeReadStart) < readStopTime
				%read data by single mode
				tmpData(tmpi) = rand ;
				tmp=toc(expInfo.startTime);while (toc(expInfo.startTime)-tmp ) < 1e-3 end  % reduce read data length. pause() can't handel less then 1e-2. This method can't handle less then 1e-3. if you need short then 1e-3, change daqmx mode to continuous.
				tmpi=tmpi+1;
			end
			peak(2)=max(smooth(tmpData,10));
			signDetTime=tic;

				if peak(2) < peak(1) %sign -1 first in if. case sign=1 have more time.
					sign=-1 ;
				elseif peak(2) > peak(1)
					sign=1 ;
				else
					sign=0 ;
					fprintf('dt = 0 \n');
				end
			log.signDetTime={log.signDetTime{:},toc(signDetTime)};
			% debug
			log.signTime = {log.signTime{:},toc(expInfo.startTime)};
			log.sign = {log.sign{:},sign};


			peak(1)=peak(2);
		else
			sign = 0;
		end
		% next pacing time
		expInfo.nextPacingTime = expInfo.nextPacingTime + t0 + sign*abs( dt*0.001 );
		if expInfo.nextPacingTime <= toc(expInfo.startTime)
			error('Pacing time passed ! Maybe Matlab or PC too slow. You can reduce read data duration')
		end
		log.diffTime ={log.diffTime{:},expInfo.nextPacingTime - toc(expInfo.startTime)};

		% wait to paceing time, for wash time
		while toc(expInfo.startTime) < expInfo.nextPacingTime
			%diffTime = expInfo.nextPacingTime - toc(expInfo.startTime);
			%if diffTime > 0.1 ; pause(diffTime*0.7); end
		end

		% pace
		if ~debug
			% debug
			log.paceTime = {log.paceTime{:},toc(expInfo.startTime)};
			%daqPace.write(5);
			%daqPace.write(0);
		end
		if dt ~= expInfo.old_dt || t0 ~= expInfo.old_t0
			expInfo.old_dt = dt;
			expInfo.old_t0 = t0;
			fprintf('t0=%f ms\tdt=%f ms in %f\t%f\n',t0 ,dt, toc(expInfo.startTime), toc(expInfo.startTime)+ expInfo.preRecoedTime + expInfo.preProcTime );
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
ui.GenTime.edit= [ uicontrol( 'Parent', ui.GenTime.layBase, 'Style','edit','FontSize',defFontSize, 'String' ,0.5 ) , ...
	uicontrol( 'Parent', ui.GenTime.layBase, 'Style','edit','FontSize',defFontSize, 'String' ,8 ) , ...
	uicontrol( 'Parent', ui.GenTime.layBase, 'Style','edit','FontSize',defFontSize, 'String' ,16 ) , ...
	uicontrol( 'Parent', ui.GenTime.layBase, 'Style','edit','FontSize',defFontSize, 'String' ,0.3 ) , ...
	uicontrol( 'Parent', ui.GenTime.layBase, 'Style','edit','FontSize',defFontSize, 'String' ,'0.1 , 0.2' ) , ...
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
		ui.ctrlPad.timingTable = uitable('Parent',ui.ctrlPad.layPreSet, 'Data',magic(2),'ColumnEditable',true , 'ColumnWidth', 'auto', 'ColumnName', {'t0', 'dt', 'count'} );
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
