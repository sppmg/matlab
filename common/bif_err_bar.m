function  bif_err_bar(varargin)
	close all;
	if nargin == 0
		[files, path] = uigetfile_sppmg('*.csv') ;
		if ~path
			return ;
		end
		if ~iscell(files)		% MultiSelect will save in cell.
			files={files};
		end
		% col=[0 0 0 ; .2 .2 .2 ; .4 .4 .4; .6 .6 .6]
		
		for nfile = 1:numel(files)
			datafile = importdata(fullfile(path,files{nfile}));
			%xx = linspace(datafile.data(1,1), datafile.data(end,1), 100*size(datafile.data,1) );
			x = datafile.data(:,1);
			y = datafile.data(:,2);
			x_time = datafile.data(:,3);
			%yy=interp1(x, y, xx,'pchip');
			err_down = datafile.data(:,4) ;
			err_up = datafile.data(:,5) ;
			
% 			hold on
% 				plot(xx, yy, 'k-');
% 				errorbar(x, y , err_down, err_up, '.');
% 				tmp_h=refline(0,0);
% 				set(tmp_h,'Color','r'); % ,'LineStyle',':'
% 			hold off
%  			goplot(fig);
%  			[~, file, ext]=fileparts(files{nfile});
%  			save_fig(fig,fullfile(path,['std_',file] ));
			%fprintf('merge %s \n',fullfile(path,files{nfile}));
			fig = figure;
			hold on ;
				bar([1:numel(x)], y, 'grouped', 'FaceColor','none', 'EdgeColor','k' );
				errorbar([1:numel(x)], y , err_down, err_up, '.');
				for n=1:numel(x)
					x_label{n}=sprintf('%0.1f', x_time(n));
				end
				set(gca,'XTick',[1:numel(x)], 'XTickLabel',x_label ) ;
				if numel(x) > 3
					rotateXLabels(gca, 45) ; % from matlab fileexchange(2014b buildin, use ax.XTickLabelRotation = 90;)
				end
				xlim([0,numel(x)+1]); % rotateXLabels may make space in right.
				% http://stackoverflow.com/questions/29775842/white-space-on-the-right-when-using-bar-matlab
				
			hold off ;
			
			
			xlabel('Specific Time (s)');
			ylabel('\Delta P (mmHg)')
			axis square ;
			box on ;
			imgSize = [0 0 400 400] ;
			fontsize = 18;
			set (fig,'PaperUnits','point','PaperPosition',imgSize)
			set(findall(fig,'-property','FontSize'),'FontSize',fontsize);

			[~, file, ext]=fileparts(files{nfile});
			save_fig(fig,fullfile(path,['std_',file] ));
			fprintf('save to %s \n',fullfile(path,['std_',file]))
			
		end
	end
end 	
function save_fig(fig,path)
	% path include path and filename, no ext.
	saveas(fig,path,'fig');
	saveas(fig,path,'epsc2');
	print(fig,'-dpng','-r200', [path,'.png']);
end
		