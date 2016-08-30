% This is for fix resolution error from recorder.
%function fix_pacing_interval(varargin)
close all;
new_path = '/run/shm/tmp/test/new' ; % save output figure

%  if nargin
%  	[path, name, ext] = fileparts(varargin{1});
%  	file = [name,ext];
%  else
%  	[file, path] = uigetfile_sppmg('*.fig') ;
%  	if ~path
%  		return ;
%  	end
%  end

[files, path] = uigetfile_sppmg('*.fig') ;
if ~path
	return ;
end
if ~iscell(files)		% MultiSelect will save in cell.
	files={files};
end

for file_i = 1:numel(files)
	file = files{file_i};



	fig = open(fullfile(path,file));
	set(fig, 'Visible', 'on');
	ha=findobj(fig,'type','axes');
%  	switch numel(ha)
%  		case 2
%  			setappdata(ha(1),'name',linkprop(ha(2),'Position')); % link 'Position' of 2 axes
%  	end

	% fix pacing

	line_pacing = findobj(fig,'marker','+'); % Type = line
	range_x = get(get(line_pacing, 'Parent'), 'XLim'); % Type = axes
	data_x = get(line_pacing, 'XData');
	data_y_orig = get(line_pacing, 'YData'); % will rewrite, use differ name
	% Limit data only in visible range
	visible_range_idx = data_x >= range_x(1) & data_x <= range_x(2) ;
	%data_x = data_x(visible_range_idx);
	data_y = data_y_orig(visible_range_idx);

	% select range for fix
	[ tmp_x, ~] = ginput(2);
	ex_proc_range = tmp_x 
	ex_proc_range_idx = data_x >= min(ex_proc_range) & data_x <= max(ex_proc_range) ;
	numel(ex_proc_range_idx)
	numel(visible_range_idx)
	visible_range_idx = xor(visible_range_idx, ex_proc_range_idx) ;
	data_y = data_y_orig(visible_range_idx);
	
	%hist_th = 100;
	hv = [floor(min(data_y)):ceil(max(data_y))] ;
	hn = hist(data_y, hv );
	hist_th = sum(hn)*.05
	val = hv( hn > hist_th )


	d=data_y;
	for n = 1:numel(d)
		[~,mi] = min(abs(val-d(n))) ;
		d(n) = val(mi) ;

	end
	data_y = d;
	%  figure; plot(d,'+')
	%  return;
	%
	%  window_len = 10 ;
	%  window = [1:window_len:numel(data_y)] ;
	%  window(end) = numel(data_y) ;
	%
	%  for n = 1:numel(window)-1
	%  	m = round( mean( data_y(window(n):window(n+1)) ) );
	%  	% get index of each part.
	%  	data_y_up_idx = ( data_y > m+eps );
	%  	data_y_down_idx = ( data_y < m-eps );
	%  	data_y_mid_idx = ~( data_y_up_idx | data_y_down_idx );
	%  end
	%  return;
	%  eps = 0.9 ;
	%  m = round( mean(data_y) );
	%  % get index of each part.
	%  data_y_up_idx = ( data_y > m+eps );
	%  data_y_down_idx = ( data_y < m-eps );
	%  data_y_mid_idx = ~( data_y_up_idx | data_y_down_idx );
	%
	%  smooth_length = 5 ;
	%  data_y_up_fix = smooth( data_y(data_y_up_idx), smooth_length) ;% fixed pacing data
	%  data_y_mid_fix = smooth( data_y(data_y_mid_idx), smooth_length) ;
	%  data_y_down_fix = smooth( data_y(data_y_down_idx), smooth_length) ;
	%  % for debug
	%   figure; plot(round(data_y_up_fix),'+g');
	%   figure; plot(round(data_y_mid_fix),'+g');
	%   figure; plot(round(data_y_down_fix),'+g');
	%
	%  data_y(data_y_up_idx) = data_y_up_fix ;
	%  data_y(data_y_mid_idx) = data_y_mid_fix ;
	%  data_y(data_y_down_idx) = data_y_down_fix ;
	%
	%
	%
	%  data_y = round(data_y);

	data_y_orig(visible_range_idx) = data_y ;
	set(line_pacing, 'YData', data_y_orig);
	% change axis Y range
	range_y = get(get(line_pacing, 'Parent'), 'YLim'); % Type = axes
	mady = max(data_y) ;
	midy = min(data_y) ;
	space = ( mady - midy ) * 0.1 /2 ;
	if range_y <= space
		set(get(line_pacing, 'Parent'), 'YLim', [floor(midy-space), ceil(mady+space)]);
	end

	
	std_fig_prop(fig);
	% save to new dir
	%
	[~, filename, ext]=fileparts(file);
	saveas(fig,fullfile(new_path,filename),'fig');
	saveas(fig,fullfile(new_path,filename),'epsc2');
	print(fig,'-dpng','-r200',fullfile(new_path,[filename,'.png']))
	%
	disp(['figure saved to ',fullfile(new_path,filename)]);
end
% Visible = off

%  r=findobj(fig,'-property','XData')
%  figure;plot(get(r(1),'XData'), get(r(1),'YData'), 'g+');


