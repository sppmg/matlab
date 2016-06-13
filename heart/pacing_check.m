function pacing_check
% hotkey
% 's'   % save figure
% 'b'   % bifurcation, Press the Return key to terminate the input
% 'a'   % Poincare Map of pacing
% 'z'   % check lvp and pacing
% other % Poincare Map of LVPP


%clear all;
%persistent env_
clearvars -except env_*
close all;
global isi lvpp % for analyse outside of this function.(command)
du=0.13 ; % set MINPEAKDISTANCE for findpeaks 

[file, path] = uigetfile_sppmg ;% only select 1 file,plz.
if ~path % cancel
	return;
end
d=load_sppmg(fullfile(path,file)); 
t=d(:,1);
if size(d,2) >= 3
	p=d(:,2); % LVP
	v=d(:,3);
else
	v=d(:,2);
end


rate=round(1/(t(2)-t(1)));

[~,locs]=findpeaks(v,'MINPEAKDISTANCE',round(rate*du),'MINPEAKHEIGHT',0.1); % 0.1
fig1=figure; plot(t,v,'b-',t(locs),v(locs),'r+')
isi=[t(locs(2:end)),diff(t(locs))*1e3];
%round(rate/1e2)
% sp=smooth(smooth(p,50),20); % 10ms
sp=smooth(p,10);

%[~,locs]=findpeaks(sp,'MINPEAKDISTANCE',round(rate*du),'MINPEAKHEIGHT',mean(sp));
[~,locs]=findpeaks(sp,'MINPEAKDISTANCE',round(rate*du),'MINPEAKHEIGHT',20);
tmp_k=1;

for n=2:numel(locs)-1
	% remove not max point(range = -0.3x ~ + 0.4x of du)
	if sp(locs(n)) ~= max(sp(locs(n)-round(rate*0.2*du):locs(n)+round(rate*0.2*du)))
		rmlocs(tmp_k)=n;
		tmp_k=tmp_k+1;
	end
end
if exist('rmlocs', 'var') && numel(rmlocs) > 1
	locs(rmlocs)=[];
	fprintf('Removed %d point from findpeaks.\n',numel(rmlocs));
end


fig2=figure; plot(t,p,'g',t,sp,'b',t(locs),sp(locs),'r*');
lvpp=[t(locs),sp(locs)];
ibi=[lvpp(2:end,1),diff(lvpp(:,1))];
% pisi = [t(locs(2:end)),diff(t(locs))];
% figure; plot(pisi(:,1),pisi(:,2),'r+')
% title('pisi');

fig3=figure;
hl(1)=line(isi(:,1),isi(:,2), ...
	'Color','b', ...
	'LineStyle',':' , ...
	'Marker', '+', ...
	'MarkerEdgeColor', 'r' );
grid on ;
grid minor ;
ylabel('Pacing Cycle Length(ms)','Color','r');
xlabel('Time (s)');

ha(1)=gca;
ha(2)=axes('Position',get(ha(1),'Position'),...
    'XAxisLocation','top',...
    'YAxisLocation','right',...
    'Color','none');
hl(2)=line(lvpp(:,1),lvpp(:,2), ...
	'Parent',ha(2), ...
	'Color','c', ...
	'LineStyle',':' , ...
	'Marker', '*', ...
	'MarkerEdgeColor', 'k' );
ylabel('Left Ventricle Pressure Peak (mmHg)','Color','k');
%set(ha,'ActivePositionProperty','OuterPosition'); % don't put here, can
%not align 2 axes.
linkaxes(ha,'x');
% delete below 2 lines, see saveImg().
%lp=linkprop(ha,'Position'); % for change axes position 
%setappdata(ha(1),'name',lp); % with linkprop


set(fig3,'KeyPressFcn',{@keyfunc,lvpp,isi,fig3,file} );
% del set(fig3,'ButtonDownFcn',{@pMap,lvpp,fig3,file} );
title(sprintf('%s',file),'Interpreter', 'none')
% set(gca,'YTickLabelMode','auto');set(gca,'YTickLabel',{get(gca,'YTick')})
%  tmp=[log.paceTime{:}];
%  tmp=diff(tmp);
%  a=(tmp(tmp>mean(tmp)));
%  figure;plot(a)
%  std(a)
%fig4=figure;
%set(fig4,'KeyPressFcn',@pMap(fig4,lvpp));
fig_pr=figure;
hl_pr(1)=line(isi(:,1),isi(:,2), ...
	'Color','b', ...
	'LineStyle',':' , ...
	'Marker', '+', ...
	'MarkerEdgeColor', 'r' );
grid on ;
grid minor ;
ylabel('Pacing Cycle Length(ms)','Color','r');
xlabel('Time (s)');

ha_pr(1)=gca;
ha_pr(2)=axes('Position',get(ha_pr(1),'Position'),...
    'XAxisLocation','top',...
    'YAxisLocation','right',...
    'Color','none');
hl_pr(2)=line(ibi(:,1),ibi(:,2)*1e3, ...
	'Parent',ha_pr(2), ...
	'Color','c', ...
	'LineStyle',':' , ...
	'Marker', '+', ...
	'MarkerEdgeColor', 'k' );
ylabel('Left Ventricle period (ms)','Color','k');
% title('ipi and ibi');
title(sprintf('%s pacing response',file),'Interpreter', 'none')
%set(ha,'ActivePositionProperty','OuterPosition'); % don't put here, can
%not align 2 axes.
linkaxes(ha_pr,'xy');
set(fig_pr,'KeyPressFcn',{@keyfunc,lvpp,isi,fig_pr,file} );

figure(fig3); % move window to top
end
function keyfunc(~,event,lvpp,isi,fig,file)
	plen=30;
	switch event.Key
		case 's'	%save figure
			saveImg(fig);
		case 'b'	% bifurcation
			%Press the Return key to terminate the input
			
			bin_num=100; % 100
			bin_size=0.1; % 0.1 mmHg (0.01 too small)
			
			y_range=0; % set 0  == auto
			[x, y] = ginput;
			if ~numel(x)
				return ;
			end
			his_n(bin_num,numel(x))=0;
			his_c(bin_num,numel(x))=0;
			dmax=0; % set limit of histgram, 0 == auto
			lastFolder=numel(strfind(tempname,filesep));
			[~,filename, ~] = fileparts(file);
			
			for n=numel(x):-1:1
				% xlabel of bifurcation, pacing interval.
				[~,tStart_inx]=min(abs(isi(:,1)-x(n))) ;
				[tmp_mu, ~] = normfit(isi(tStart_inx:tStart_inx+plen,2)) ; 
					% mean() of T+T- may shift by pacing , so use normfit
				isi_num(n) = round(tmp_mu) ; % for csv file
				isi_time(n) = isi(tStart_inx,1) ; % ginput click time
				isi_label{n}=sprintf('%g@%0.1fs',isi_num(n), isi_time(n));
				% fail -> isi_label{n}={sprintf('%g',isi_num(n)); sprintf('@%0.1fs',isi(tStart_inx,1))} ;
				isi_time(n)=isi(tStart_inx,1); % for csv file 
				
				lvpp_sel = exportData(lvpp, x(n),plen);
				tmp_hp=pMap(lvpp_sel, file, x(n));
				
				imgSize = [0 0 400 400] ;
				axis square ;
				set (tmp_hp,'PaperUnits','point','PaperPosition',imgSize)  %should use pixels
				
				
				
				if ispc 
					% filesep == escape char
					tmp_fname=[regexprep(tempname,filesep,[filesep,filesep,sprintf('%06.2f',x(n)),'_'],lastFolder),'.png']; 
				else
					tmp_fname=[regexprep(tempname,filesep,[filesep,sprintf('%06.2f',x(n)),'_'],lastFolder),'.png'];
				end
				%fprintf('poincare Map saved to here :%s\n',tmp_fname );
				% print(tmp_hp,'-dpng',[tmp_fname,'.png']) ;
				% saveImg(tmp_hp);
				saveas(tmp_hp,fullfile(tempdir,[filename,'_p_',sprintf('%04.0f',x(n)),'s']),'fig');
				saveas(tmp_hp,fullfile(tempdir,[filename,'_p_',sprintf('%04.0f',x(n)),'s']),'png');
				saveas(tmp_hp,fullfile(tempdir,[filename,'_p_',sprintf('%04.0f',x(n)),'s']),'epsc2');
				% export to csv
				export_figure_data(fullfile(tempdir,[filename,'_p_',sprintf('%04.0f',x(n)),'s.fig'])) ;
				
				close(tmp_hp);
				lvpp_sel_set(:,n) = lvpp_sel -mean(lvpp_sel); % save lvpps for next loop
			end
			for n=1:numel(x)
				
				if ~dmax % find limit of all data for hist
					dmax=ceil( max(max(lvpp_sel_set)))+1;
					dmin=floor(min(min(lvpp_sel_set)))-1;
					clearvars his_n his_c his_mean_up his_mean_down his_sd_up his_sd_down;
				end
				if ~bin_size
					[nelements,centers]=hist(lvpp_sel_set(:,n) , ...
						linspace(dmin,dmax,bin_num));
				else
					[nelements,centers]=hist(lvpp_sel_set(:,n) , ...
						[floor(dmin):bin_size:ceil(dmax)] );
					bin_num = numel([floor(dmin):bin_size:ceil(dmax)] );
				end
				
				his_n(:,n)=nelements;
				his_c(:,n)=centers; % center of each bin
				
				[his_mean_up(n), his_sd_up(n)] = normfit(lvpp_sel_set( lvpp_sel_set(:,n)>0, n) );
				[his_mean_down(n), his_sd_down(n)] = normfit(lvpp_sel_set( lvpp_sel_set(:,n)<0, n) );
				
				if (his_mean_up(n)-his_mean_down(n)) < 2*(his_sd_up(n)+his_sd_down(n))
					% period 1
					[his_mean_up(n), his_sd_up(n)] = normfit(lvpp_sel_set(:, n) );
					his_mean_up(n) = 0;
					his_mean_down(n) = 0;
					his_sd_down(n) = his_sd_up(n) ;
				end
				
			end
			fig_bif_err = figure;
			tmp_y_dp = his_mean_up-his_mean_down ; % Y data (dp) in this figure
			%global xx x y ;
			if numel(unique(isi_num)) == numel(isi_num)
				xx=linspace(isi_num(1), isi_num(end),100*numel(isi_num));
				x=isi_num;
				y=tmp_y_dp;
				yy=interp1(isi_num, tmp_y_dp, xx,'pchip');
				hold on
					plot(xx,yy,'k-');
					errorbar(isi_num, tmp_y_dp , his_sd_down, his_sd_up,'.');
					tmp_h=refline(0,0);
					set(tmp_h,'Color','r');
				hold off
				set(gca,'XDir','reverse');
				title(sprintf('Bifurcation of %s',file),'Interpreter', 'none')
				xlabel('Pacing Cycle Length(ms)');
			else % for compare alternans size of same T0 but different time.
				hold on ;
				bar([1:numel(x)], tmp_y_dp,'grouped', 'FaceColor','none', 'EdgeColor','k' );
				errorbar([1:numel(x)], tmp_y_dp , his_sd_down, his_sd_up, ... 
					'.') % ,'LineWidth',3,'MarkerSize', 20);
				if numel(unique(isi_num)) == 1
					for n=1:numel(x)
						isi_label{n}=sprintf('%0.1f', isi_time(n));
					end
					set(gca,'XTick',[1:numel(x)], 'XTickLabel',isi_label ) ;
					if numel(x) > 3
						rotateXLabels(gca, 45) ; % from matlab fileexchange(2014b buildin, use ax.XTickLabelRotation = 90;)
					end
					xlim([0,numel(x)+1]); % rotateXLabels may make space in right.
					% http://stackoverflow.com/questions/29775842/white-space-on-the-right-when-using-bar-matlab
					xlabel('Specific Time (s)');
				else
					set(gca,'XTick',[1:numel(x)], 'XTickLabel',isi_label ) ;
					rotateXLabels(gca, 90) ; % from matlab fileexchange(2014b buildin)
					xlabel('Pacing Cycle Length (ms)');
				end
				
				hold off ;
				title(sprintf('%s',file),'Interpreter', 'none')
			end
	
			ylabel('\Delta P (mmHg)')
			box on ;
			set(fig_bif_err,'KeyPressFcn',{@saveImg,'bif_err', ... 
				'x', isi_num', 'y', tmp_y_dp', 'x_time', isi_time', ...
				'SD_down', his_sd_down', 'SD_up', his_sd_up'} );
			
			figure;
			% hc=ribbon(rescalec(his_n));
			colormap(flipud(colormap('gray')));
			hc=pcolor([0:numel(x)+1], his_c(:,1) , ...
				[zeros(bin_num,1),rescalec(his_n),zeros(bin_num,1)]);
			shading flat ;
			%set(gca,'XTick',[1:numel(x)], 'XTickLabel',isi_label ) ;
			
			% Did not need this figure now.
% 			fig_b = figure;
% 			colormap(flipud(colormap('gray')));
% 			%colormap(1-gray(1024))
% 			[~,hc]=contourf([0:numel(x)+1], his_c(:,1) , ...
% 				[zeros(bin_num,1),rescalec(his_n),zeros(bin_num,1)], ...
% 				500);
% 			set(hc,'LineStyle','none');
% 			set(gca,'XTick',[0:numel(x)+1],'XTickLabel',cellstr([' ';num2str([1:numel(x)]');' '])')
% 			
% 			set(gca,'XTickLabel',{' ',isi_label{:},' '} )
% 			if y_range
% 				ylim([-y_range,y_range]);
% 			end
% 			title(sprintf('Bifurcation of %s',file),'Interpreter', 'none')
% 			xlabel('Pacing Cycle Length(ms)');
% 			ylabel('pressure (mmHg)')
% 			set(fig_b,'KeyPressFcn',{@saveImg,'bif', ... 
% 				'x', isi_num', 'y', his_c(:,1), 'z', rescalec(his_n) } );
		
		case 'a' % Poincare Map of pacing
			[x, y] = ginput(1);
			pMap(exportData(isi, x,plen) ,file, x,'Pacing Map')
			
		case 'z' % check lvp and pacing
			[x, y] = ginput(2);
			%exportData(isi, x,plen)
			if ~numel(x)
				return ;
			end
			%plen=500;
			[~,tStart_inx]=min(abs(lvpp(:,1)-x(1))) ;
			[~,tend_inx]=min(abs(lvpp(:,1)-x(2))) ;
			tmp_data = lvpp(tStart_inx:tend_inx, :);
			dlvpp=[tmp_data(2:end,1),diff(tmp_data(:,2))];  % p(n)-p(n-1)
			
			%[~,tStart_inx]=min(abs(isi(:,1)-x)) ;
			%tmp_data = isi(tStart_inx:tStart_inx+plen, :);
			
			[~,tStart_inx]=min(abs(isi(:,1)-x(1))) ;
			[~,tend_inx]=min(abs(isi(:,1)-x(2))) ;
			tmp_data = isi(tStart_inx:tend_inx, :);
			[tmp_mu, ~] = normfit(tmp_data(:,2)) ; 
			t0 = round(tmp_mu) ;
			dpcl=[tmp_data(:,1),sign(round(tmp_data(:,2)-t0))];
			
			while dpcl(1,1) < dlvpp(1,1) % make sure LVP(1) time < PCL(1) 
				dpcl(1,:) = [] ; 
			end
			tmp = min([size(lvpp,1),size(dpcl,1)]);
			dlvpp = dlvpp(1:tmp,:);
			dpcl = dpcl(1:tmp,:);
			%dlvpp = [dlvpp(1:tmp,1), rescalec(dlvpp(1:tmp,2))];
			%dpcl = [dpcl(1:tmp,1),dpcl(1:tmp,2)/3];
			
			fig_dlvpp_dpcl = figure;
			%h_dlvpp_dpcl = bar([dlvpp(:,2),dpcl(:,2)]);
			%set(h_dlvpp_dpcl(1),'FaceColor',[0,0,1]);
			%set(h_dlvpp_dpcl(2),'FaceColor',[1,0,0]);
			mycolor=([1,0,0;0,1,0;0,0,1]);
			colormap(mycolor);
			scatter(dlvpp(:,1),dlvpp(:,2),25,dpcl(:,2),'filled');
			colorbar;
			refline(0,0);
			title('Check LVPP and given pacing');
			ylabel('\Delta P (mmHg)');
			xlabel('Time (s)');
			
			%set(fig_dlvpp_dpcl,'KeyPressFcn',{@saveImg,'bif_err', ... 
			%	'x', isi_num', 'y', tmp_y_dp', 'x_time', isi_time', ...
			%	'SD_down', his_sd_down', 'SD_up', his_sd_up'} );
			%set(fig_dlvpp_dpcl,'KeyPressFcn',{@keyfunc,~,~,fig_pr,~} );
		otherwise
			% Poincare Map of LVPP
			[x, y] = ginput(1);
			pMap(exportData(lvpp, x,plen) ,file, x );
				%for n=1:numel(x)
				%subplot(numel(x),n,1);
				
% 				fig_hist=figure;
% 				set(fig_hist,'Position',[100,100,1500,300])
% 				colormap('cool');
% 				bar(his_c,his_n);
% 				title(sprintf('histram of %s',file) )
% 				for n=1:numel(x)
% 					tmp_leg{n}=sprintf('%0.2f (s)',x(n) );
% 				end
% 				legend(tmp_leg);
				
% 				figure;
% 				colormap(flipud(colormap('gray')));
% 				%colormap(1-gray(1024))
% 				%contourf(his_n);
% 				size(his_n)
% 				hp=pcolor([1:numel(x)+1],his_c(:,1),[his_n,zeros(bin_num,1)]);
% 				set(hp,'LineStyle','none');
%  				set(gca,'XTick',[1:numel(x)],'XTickLabel',[1:numel(x)])
% 				title(sprintf('histram of %s',file),'Interpreter', 'none' )
% 				
% 				figure;
% 				colormap(flipud(colormap('gray')));
% 				%colormap(1-gray(1024))
% 				[~,hc]=contourf([1:numel(x)],his_c(:,1),his_n,500);
% 				set(hc,'LineStyle','none');
% 				set(gca,'XTick',[1:numel(x)])
% 				title(sprintf('histram of %s',file),'Interpreter', 'none' )

	end
		
end

function out=rescalec(mat)
% rescale mat to [-1,1]
% out=mat;
switch numel(size(mat))
	case 1
		out = mat/max(mat) ; 
	case 2
		out=bsxfun(@rdivide,mat,max(mat));
	%out=mat./max(mat);
% 	for n=1:size(mat,2)
% 		out(:,n)=mat(:,n)./max(mat(:,n));
% 	end
	otherwise
		error('Only allow 1D/2D mat.');
end
end

function outData = exportData(origData,x,dataLen)
	% origData has 2 col , 1st = time, 2nd = data.
	if size(origData,2) ~= 2
		error('origData should has 2 column , 1st = time, 2nd = data.');
	end
	[~,tStart_inx]=min(abs(origData(:,1)-x)) ;
	if tStart_inx + dataLen > size(origData,1)
		warning('Data number not enough, click in %0.5g',x);
		tEnd_inx = size(origData,1);
	else
		tEnd_inx = tStart_inx + dataLen -1 ;
	end
	outData = origData(tStart_inx:tEnd_inx , 2) ;
end

function varargout=pMap(data, file, time, varargin)	
	if nargin > 3
		given_title = varargin{1};
	else
		given_title = 'Poincare Map';
	end
	
	% n point is 'used poing from input data. but poincare map will -1
	% point to make figure.
	fig_p = poincareMap(data , ...
		sprintf('%s of %s at %0.2f (s) (%d points)', given_title, file ,time,numel(data) ) );
	%refline(1,0);
	%set(fig_p,'KeyPressFcn',{@saveImg} );
	set(fig_p,'KeyPressFcn',{@keyfuncPmap,fig_p} );
	if nargout > 0
		varargout{1} = fig_p;
	end
end

function keyfuncPmap(~, event, fig)
	disp('d');
	switch event.Key
		case 'q' % close figure
			close;
		otherwise	%save figure
			saveImg(fig,'emptyarg'); % need 2 arg here.
	end
end

function saveImg(varargin)
	% src,event == varargin{1}, varargin{2}
	% src = figure handle
	% event.Key = lowercase
	
	[filename, path] = uiputfile_sppmg('*.fig;*.png;*.eps');
	if ~path
		return ;
	end
	[~,filename] = fileparts(filename);
	
	if nargin > 2
		switch varargin{3}
			case 'bif'
				% export to csv
				save2csv( fullfile(path, filename), ... 
					varargin{4:end}) ;
			case 'bif_err'
				fig = varargin{1} ; 
				% copyobj have bug , it can't copy bar ( someone say bar with 
				% 'hist' style will work. below is error message :
				% Error using getProxyValueFromHandle (line )
				% Input must be a valid handle.
				
				% export to csv
				save2csv( fullfile(path, filename), ... 
					varargin{4:end}) ;
			otherwise
				% export to csv
				export_figure_data(fullfile(path,[filename,'fig'])) ;
		end
	end
	if ~exist('fig','var')
		fig = copyobj(varargin{1}, 0); % clone figure for change property.
		set(fig, 'Visible', 'off');
	end
	set(findall(fig,'-property','ActivePositionProperty'), ... 
		'ActivePositionProperty','OuterPosition'); % Include title when change PaperPosition
	
	
	if nargin > 1	% call by int(pMap)
		%event = varargin{2};
		imgSize = [0 0 400 400] ;
		set(findall(fig,'-property','FontSize'),'FontSize',18);
		box on;
		axis square ;
	else
		imgSize = [0 0 1000 700] ; fontsize=20;
		%imgSize = [0 0 400 400] ; fontsize=18;
		%title('shit')
		ha=get(fig,'Children');
		%set (fig,'Position',[0 0 400 400]);
		set(findall(fig,'-property','FontSize'),'FontSize',fontsize);
		%linkprop(get(fig,'Children'),'OuterPosition')
		lp=linkprop(get(fig,'Children'),'Position'); % align 2 axes
		setappdata(ha(1),'name',lp);
		% Don't use it with setappdata when axes creation, it
		% will force 'ActivePositionProperty' to 'Position' ,
		% so cut title when change figure size.
		set(ha,'LineWidth',1);
		%set (fig,'PaperUnits','point','PaperPosition',imgSize)
		axis normal  ; % use it 
	end
	
	

	set (fig,'PaperUnits','point','PaperPosition',imgSize)  %should use pixels
	set(findall(fig,'-property','ActivePositionProperty'), ... 
		'ActivePositionProperty','OuterPosition');
	drawnow
	%fullfile(path,filename)
	saveas(fig,fullfile(path,filename),'fig');
	saveas(fig,fullfile(path,filename),'epsc2');
	print(fig,'-dpng','-r200',fullfile(path,[filename,'.png']))
	if fig ~= varargin{1}	% Only close figure which creat by copyobj.
		close(fig);
	end
	
	
	%saveas(fig,fullfile(path,filename),'png');
% 	tmpDir = '/run/shm/';
% 	switch event.Key
% 		case 'p'
% 			fprintf('poincare Map saved to here :%s\n',[tempname,'.png']);
% 			print(src, '-dpng',[tempname,'.png']) ;
% 	end
end

