
% ============= user setting ==========
debug=0 ; % 0 -> Real , 1 -> has daq but don't output , 2 -> no daq
%daqLVP=daqmx_Task('chan','dev1/ai0');
%daqPace=daqmx_Task('chan','dev1/ao0');
t0 = [0.5,0.3,0.3,0.5];
dt = [0, 0.1,0.2,  0];
count=[8,8,8,8];	%count of pacing,lose first pacing
start_time=10 ;

% =====================================
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

dt_old=0;
t0_old=0;
fprintf('total %d mins\n',sum(count.*t0) );
tmpData=zeros(1,1e5);

sign=1;
pacingTime=0;
expStart=tic;

for ctrlStage = 1:len
	for pace = 1:count(ctrlStage)

		% start T+T-
		if dt(ctrlStage) ~= 0
			peakID=0;
			timeReadStart=tic;
			tmpi=1;
			
			while toc(timeReadStart) < readStopTime(ctrlStage)
				%read data by single mode
				tmpData(tmpi) = rand ;
				tmp=toc(expStart);while (toc(expStart)-tmp ) < 1e-3 end  % reduce read data length. pause() can't handel less then 1e-2. This method can't handle less then 1e-3. if you need short then 1e-3, change daqmx mode to continuous.
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
			log.signTime = {log.signTime{:},toc(expStart)};
			log.sign = {log.sign{:},sign};
			
			
			peak(1)=peak(2);
		end
		% next pacing time
		pacingTime = pacingTime + t0(ctrlStage) + sign*abs( dt(ctrlStage)*0.001 );
		if pacingTime <= toc(expStart)
			error('Pacing time passed ! Maybe Matlab or PC too slow. You can reduce read data duration')
		end
		log.diffTime ={log.diffTime{:},pacingTime - toc(expStart)};

		% wait to paceing time, for wash time
		while toc(expStart) < pacingTime
			%diffTime = pacingTime - toc(expStart);
			%if diffTime > 0.1 ; pause(diffTime*0.7); end
		end
		
		% pace
		if ~debug
			% debug
			log.paceTime = {log.paceTime{:},toc(expStart)};
			%daqPace.write(5);
			%daqPace.write(0);
		end
		if dt(ctrlStage) ~= dt_old || t0(ctrlStage) ~= t0_old
			dt_old = dt(ctrlStage);
			t0_old = t0(ctrlStage);
			fprintf('t0=%f ms\tdt=%f ms in %f\t%f\n',t0(ctrlStage) ,dt(ctrlStage), toc(expStart), toc(expStart)+start_time );
		end


	end
end
disp('All done.');
min([log.diffTime{:}])