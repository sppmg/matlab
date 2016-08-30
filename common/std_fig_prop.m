function std_fig_prop(varargin)
% It's for mythesis figure, set format.

	if nargin == 0
		[files, path] = uigetfile_sppmg('*.fig') ;
		if ~path
			return ;
		end
		if ~iscell(files)		% MultiSelect will save in cell.
			files={files};
		end
		for nfile = 1:numel(files)
			fig = open(fullfile(path,files{nfile}));
			set(fig, 'Visible', 'on');
			change_prop(fig);
			[~, file, ext]=fileparts(files{nfile});
			save_fig(fig,fullfile(path,['std_',file] ));
		end

	else
		fig = varargin;
		for nfig = 1:numel(fig)
			change_prop(fig{nfig});
		end
	end
end


function change_prop(fig)
	title(''); % remove
	ha=findobj(fig,'type','axes');
%  	switch numel(ha)
%  		case 2
%  			setappdata(ha(1),'name',linkprop(ha(2),'Position')); % link 'Position' of 2 axes
%  			
%  	end

	

	%  p=get(gca,'Position');
	%  o=get(gca,'OuterPosition');
	%  t=get(gca,'TightInset');
	%  l=get(gca,'LooseInset');
	%  set(gca,'LooseInset', t); % remove outer space.
	%set(findall(fig,'-property','ActivePositionProperty'), ...
	%	'ActivePositionProperty','Position')
	%box on;
	fp = get(gcf,'PaperPosition');
%  	switch fp(3)
%  		case 400
%  			imgSize = [0 0 400 400] ;
%  			fontsize = 18;
%  			if numel(ha) > 1
%  				for n = 1:numel(ha)
%  					axes(ha(n));
%  					axis square ;
%  				end
%  			else




%  				axis square ;
%  			end
%  		case 1000
%  			imgSize = [0 0 1000 700] ;
%  			fontsize = 20;
%  			axis normal;
%  		otherwise
			imgSize = [0 0 400 400] ;
			fontsize = 18;
%  			axis square ;
%  			%axis normal;
%  	end
%  	
	set (fig,'PaperUnits','point','PaperPosition',imgSize)
	set(findall(fig,'-property','FontSize'),'FontSize',fontsize);

% pmap
%  hr = refline(1);
%  set(hr,'color',[.7 .7 .7]);
%  xlabel('P_n (mmHg)')
%  ylabel('P_{n+1} (mmHg)')
%  axis square ;

data = [ get(findobj(gcf,'Marker','*'),'xdata') , ...
	get(findobj(gcf,'Marker','*'),'ydata') ];
axis_lim = round([ min(data) , max(data) ]+ [-1 1])
xlim = axis_lim; ylim = axis_lim;
xlim
%  	switch numel(ha)
%  		case 1
%  			set(ha,'LooseInset', get(ha,'TightInset'));
%  		case 2
%  			t=get(ha,'TightInset');
%  			tt=[t{1};t{2}]
%  			set(ha(2),'LooseInset', tt(2,:))
%  			set(ha(1),'LooseInset', tt(1,:))
%  			set(ha(1),'LooseInset', [tt(1,1:2) max(tt(:,3:4))])
%  			set(ha(2),'LooseInset', [tt(2,1:2) max(tt(:,3:4))])
%  			set(ha(2),'OuterPosition',[0 0 0.95 0.95]);
%  			set(ha(1),'Position', get(ha(2),'Position'));
%  	end

		
end

function save_fig(fig,path)
	% path include path and filename, no ext.
	saveas(fig,path,'fig');
	saveas(fig,path,'epsc2');
	print(fig,'-dpng','-r200', [path,'.png']);
end