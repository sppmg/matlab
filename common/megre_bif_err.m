function megre_bif_err(varargin)
	if nargin == 0
		[files, path] = uigetfile_sppmg('*.csv') ;
		if ~path
			return ;
		end
		if ~iscell(files)		% MultiSelect will save in cell.
			files={files};
		end
		% col=[0 0 0 ; .2 .2 .2 ; .4 .4 .4; .6 .6 .6]
		fig = figure;
		for nfile = 1:numel(files)
			datafile = importdata(fullfile(path,files{nfile}));
			xx = linspace(datafile.data(1,1), datafile.data(end,1), 100*size(datafile.data,1) );
			x = datafile.data(:,1);
			y = datafile.data(:,2);
			yy=interp1(x, y, xx,'pchip');
			err_down = datafile.data(:,4) ;
			err_up = datafile.data(:,5) ;
			
			hold on
				plot(xx, yy, 'k-');
				errorbar(x, y , err_down, err_up, '.');
				tmp_h=refline(0,0);
				set(tmp_h,'Color','r'); % ,'LineStyle',':'
			hold off
%  			goplot(fig);
%  			[~, file, ext]=fileparts(files{nfile});
%  			save_fig(fig,fullfile(path,['std_',file] ));
			fprintf('merge %s \n',fullfile(path,files{nfile}));
		end
		
		set(gca,'XDir','reverse');
		xlabel('Pacing Cycle Length(ms)');
		ylabel('\Delta P (mmHg)')
		axis square ;
		box on ;
		imgSize = [0 0 400 400] ;
		fontsize = 18;
		set (fig,'PaperUnits','point','PaperPosition',imgSize)
		set(findall(fig,'-property','FontSize'),'FontSize',fontsize);

		[~, file, ext]=fileparts(files{1});
		save_fig(fig,fullfile(path,['merge_',file] ));
		fprintf('save to %s \n',fullfile(path,['merge_',file]))
	else
		fig = varargin;
		for nfig = 1:numel(fig)
			change_prop(fig{nfig});
		end
	end
end

function save_fig(fig,path)
	% path include path and filename, no ext.
	saveas(fig,path,'fig');
	saveas(fig,path,'epsc2');
	print(fig,'-dpng','-r200', [path,'.png']);
end