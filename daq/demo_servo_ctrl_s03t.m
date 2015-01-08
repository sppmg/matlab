% It't show how to use pulse train control servo .
% Here I use NIDAQmx with GWS S03T STD for test.
% In my test, max high pulse duration is 2.46 ms, min is 0.77 ms .
% current about 0.2A~0.3A(when start), less then 0.4 A.

% Set the servo.highTimeMax and servo.highTimeMin ,and you can control
% servo by drag slider. You will need my DAQmxMidLib and set in PATH.
% Maybe you will see error when you draging . Don't worry , it cause
% by slider send new angle fast then one pulse period. angle will be
% correct (almost , XD ).

% Have fun :)
% By sppmg     sm.sppmg {at} gmail.com     https://github.com/sppmg

%-------------  http://www.pololu.com/product/507/faqs   ----------
% Most standard radio control servos (and all RC servos we sell) have
% three wires, each a different color. Usually, they are either
% black, red, and white, or they are brown, red, and orange/yellow:

%    brown or black = ground (GND, battery negative terminal)
%    red = servo power (Vservo, battery positive terminal)
%    orange, yellow, white, or blue = servo control signal line

% You can find a servo's limits if you use a servo controller that
% can send pulses outside of the standard range To find the limits,
% use the lowest possible supply voltage at which the servo moves,
% and gradually increase or decrease the pulse width until the servo
% does not move any further or you hear the servo straining.
% Once the limit is reached, immediately move away from it to avoid
% damaging the servo, and configure your controller to never go past
% the limit.

function demo_servo_ctrl_s03t(guiobj,event)
	persistent LibHeader LibDll lib hf hs ht th servo ;
	if ~nargin
		LibHeader = 'NIDAQmx-lite.h';
		LibDll = 'C:\WINDOWS\system32\nicaiu.dll' ;
		lib = 'nidaqmx' ;
		if ~libisloaded(lib)
			[notfound,warnings] = loadlibrary(LibDll , LibHeader ,'alias',lib );
		end
		% All time unit is second.
		servo.highTimeMax = 2.46e-3 ; % Set max/min pulse width of high status.
		servo.highTimeMin = 0.77e-3 ;
		servo.pulsePeriod = 20e-3 ; % Set pulse train period.

		servo.highTimeRange=servo.highTimeMax - servo.highTimeMin ;
		servo.highTime = (servo.highTimeMax+servo.highTimeMin)/2 ;
		servo.lowTime = servo.pulsePeriod - servo.highTime ;

		calllib(lib,'DAQmxResetDevice','Dev1') ;
		th=DAQmxCreateCOPulseChanTime(lib, [], '/Dev1/ctr0', servo.lowTime, servo.highTime);

		DAQmxCfgImplicitTiming(lib,th,10123,1) % 10123 set to continuous
		err = calllib(lib, 'DAQmxStartTask',th) ;

		% change pulse width after task start.
		DAQmxWriteCtrTimeScalar (lib, th, 3, servo.highTime, servo.lowTime) ; % 3 set timeout(sec)

		hf=figure('Position', [100, 100, 300, 60],'MenuBar', 'none');
		hs=uicontrol('Parent', hf,'style','slider','units','normalized','Position',[0,0.5,1,0.5],'max',100,'min',0,'value',50,'sliderstep',[0.1 0.1],'DeleteFcn',{@stop_demo_servo_ctrl_s03t,lib,th});
		ht=uicontrol( 'Parent', hf, 'Style','text', 'units','normalized','Position', [0,0,1,0.5], 'Background', 'y' );

		set(ht,'String', ...
			{ sprintf('ratio = %f %%',get(hs,'value')) , ...
			sprintf('highTime = %f %%',servo.highTime ) } );

		% Set continuous slider callback by drag instead of callback in uicontrol.
		% Ref. http://undocumentedmatlab.com/blog/continuous-slider-callback
		try    % R2014a and newer
			addlistener(hs,'ContinuousValueChange',@demo_servo_ctrl_s03t);
		catch  % R2013b and older
			addlistener(hs,'ActionEvent',@demo_servo_ctrl_s03t);
		end
	else
		servo.highTime = get(guiobj,'value')*0.01*servo.highTimeRange+servo.highTimeMin ;
		servo.lowTime = servo.pulsePeriod - servo.highTime ;

		set(ht,'String', ...
			{ sprintf('ratio = %f %%',get(guiobj,'value')) , ...
			sprintf('highTime = %f ms',servo.highTime *1e3 ) } );

		DAQmxWriteCtrTimeScalar (lib, th, 3, servo.highTime , servo.lowTime);
	end
end

function stop_demo_servo_ctrl_s03t(guiobj,event,lib,th)
	err = calllib(lib, 'DAQmxStopTask',th);
	disp('stop task')
end