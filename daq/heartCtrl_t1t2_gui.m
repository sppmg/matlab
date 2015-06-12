function heartCtrl_t1t2_gui()
global expInfo log debug ui tmpData
expInfo.scrStartTime=tic ; % script start time
% ============= user setting ==========
debug=0 ; % 0 -> Real , 1 -> has daq but don't output , 2 -> no daq
%daqLVP=daqmx_Task('chan','dev1/ai0');
%daqPace=daqmx_Task('chan','dev1/ao0');
useGUI=1;
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

heartCtrl_gui_tmp();


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

for ctrlStage = 1:len
	pace(t0(ctrlStage),dt(ctrlStage),count(ctrlStage),readStopTime(ctrlStage) );
end
disp('All done.');
min([log.diffTime{:}])
v=[log.paceTime{:}];
plot(v(2:end),diff(v),'b+:')
grid on

end % this function file

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


