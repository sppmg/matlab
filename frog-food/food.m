classdef food < handle
	properties
		size;
		pos;
		a=[0 0];
		v=[0 0];
		color ;
		shape ;
		TimerHandle;
		ItemHandle;
	end
	methods
		function obj=food(varargin)
			if nargin > 0
				for arg_i = 1:2:size(varargin,2)
					switch lower( varargin{arg_i} )
						case 'color'
							obj.color=varargin{arg_i+1} ;
						case 'shape'
							obj.shape=varargin{arg_i+1} ;
					end
				end
			end
			obj.pos=rand(1,2)*0.8;
			obj.size=(repmat(rand,1,2)+1)*0.1;
			%check_boundary(obj);
			
			obj.TimerHandle = timer('TimerFcn',{@bg,obj},'ExecutionMode','fixedRate','Period',0.01) ;
		end
		function move(obj)
			t=0.1 ; % t==dt
			c=3.5;	%3.5		
			obj.a=obj.a-c*obj.v.^3 ;
			obj.pos=obj.pos+(obj.v*t+0.5*obj.a*t^2);
			obj.v=obj.v+obj.a*t;
			obj.a=-c*obj.v.^3;
			
			check_boundary(obj);
			draw(obj)
			obj.kick(-1.5);
		end
		function kick(obj,varargin)
			
			if nargin > 1
				level=varargin{1} ;
			else
				level=-2 ;
			end
			if abs(obj.v) < 1e-3
				level=level+1;
			end
			obj.a=obj.a+(rand(1,2)-0.5)*10^level;
		end
		function start(obj)
			start(obj.TimerHandle);
			obj.kick;
		end
		function stop(obj)
			stop(obj.TimerHandle);
		end
% 		function delete(obj)
%			% can't work!!!
% 			delete(obj.TimerHandle)
% 			delete(obj.ItemHandle)
% 			clear obj;
% 		end
	end
end

function bg(timerobj,event,obj)
	obj.move ;
end

function draw(obj)
	persistent cs cn ;
	%cm=colormap('lines');
	
	if isempty(obj.ItemHandle)
		cs=['r','g','b','k','w'];
		cn=[ 1,0,0 ; 0,1,0 ; 0,0,1 ; 0,0,0 ; 1,1,1 ] ;
		ss={'none','phong'} ; % 2D, 3D . this is FaceLighting value of 3D sphere
		
		obj.ItemHandle=axes('Units','normalized','Position',[obj.pos,obj.size], ...
			'Visible','off', ...
			'PlotBoxAspectRatioMode','manual');
		
		if isempty(obj.color)
			obj.color= cn(ceil(rand*length(cn(:,1))),:) ;
			
		end
		
		if isempty(obj.shape)
			obj.shape=ss{ceil(rand*length(ss))};
		else
			switch lower(obj.shape)
				case '2d'
					obj.shape=ss{1};
					% other method
% 					t = [0:0.01:2*pi];
% 					x = sin(t)*obj.size(1);
% 					y = cos(t)*obj.size(1);
% 					fill(x,y,obj.color) ;
				case '3d'
					obj.shape=ss{2};
					
				otherwise
					obj.shape=ss{ceil(rand*length(ss))};
			end
		end
		[x,y,z]=sphere(10);
		surf(x,y,z,'EdgeColor','none','FaceColor',obj.color,'FaceLighting',obj.shape);
		camlight;
			
		set(obj.ItemHandle,'Visible','off','PlotBoxAspectRatioMode','manual');
	else
		if (obj.pos+obj.size <= 1) & (obj.pos>=0) % use & not && , because it's array
			set(obj.ItemHandle,'Position',[obj.pos,obj.size]);
		end
	end
end

function check_boundary(obj)
	for fi=1:2
		if(obj.pos(fi)+obj.size(fi) > 1)
			%obj.pos(fi)=2-(obj.pos(fi)+obj.size(fi));
			obj.v(fi)=-obj.v(fi);
		end
		
		if(obj.pos(fi) < 0)
			%obj.pos(fi)=0+abs(obj.pos(fi));
			obj.v(fi)=-obj.v(fi);
		end
	end
end
