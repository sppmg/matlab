function food_control(op)
% start -> food_control('s')
% stop -> food_control('k')
	persistent f th;
	clf;
	%op='k';
	switch op
		case 's'
			if ~isobject(f)
				clear f;
			end
% 			f(1)=food('color',[1,0,0],'shape','2D');
% 			f(2)=food('color',[0,1,0],'shape','2D');
% 			f(3)=food('color',[0,0,1],'shape','2D');
% 			f(4)=food('color',[0,0,0],'shape','3D');
% 			f(5)=food('color',[1,1,1],'shape','3D');
			for fi=1:20
				f(fi)=food('shape','3d');
			end

			set(gcf,'Renderer','OpenGL','MenuBar', 'none','ToolBar', 'none');
			
			% use outside single timer for better performance.
			th=timer('TimerFcn',{@bg,f},'ExecutionMode','fixedRate','Period',0.01) ;
			start(th)
% 			for fi=1:length(f)
% 				%f(fi).start;
% 			end
	
		case 'k'
			% delete
			stop(th)
			%for fi=1:length(f)
				%f(fi).stop;
				%wait(f(fi));
				%pause(0.3) ;
				%delete(f(fi).TimerHandle);
			%end
			clear classes ;
			delete(timerfind);
		case 'kick'
			f(1).kick;
% 			for fi=1:length(f)
% 				f(fi).kick;
% 			end
		end
		
end

function bg(a,b,f)
	for fi=1:length(f)
		f(fi).move;
	end
end
