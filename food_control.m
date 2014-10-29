function food_control(op)
	persistent f
	clf;
	%op='k';
	switch op
		case 's'
			if ~isobject(f)
				clear f;
			end
	% 		f(1)=food('color',[1,0,0],'shape','2d');
	% 		f(2)=food('color',[0,0,0],'shape','2D');
			for fi=1:6
				f(fi)=food('shape','3d');
			end

			set(gcf,'Renderer','OpenGL');
			for fi=1:length(f)
				f(fi).start;
			end
	% delete
		case 'k'
			for fi=1:length(f)
				f(fi).stop;
				wait(f(fi));
				pause(0.3) ;
				delete(f(fi).TimerHandle);
			end
			clear classes ;
			delete(timerfind);
	end
end
