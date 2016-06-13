function export_figure_data(varargin)
% clear all
% /run/shm/tmp/matlab/
if nargin
	[path, name, ext] = fileparts(varargin{1});
	file = [name,ext];
else
	[file, path] = uigetfile_sppmg('*.fig') ;
	if ~path
		return ;
	end
end
load(fullfile(path,file), '-mat');

data_set_num = numel(hgS_070000.children) ;
column_num = 1 ;
for data_set=1:data_set_num
	column_info{column_num}=['x',num2str(data_set)] ;
	d = hgS_070000.children(data_set).children(1).properties.XData' ;
	% hg(matlab7fmt).axes_number.layout
	if isfield(hgS_070000.children(data_set).properties, 'XLim')
		x_lim = hgS_070000.children(data_set).properties.XLim ; % axes xlim
		range_idx = d>x_lim(1) & d < x_lim(2) ;
	else
		range_idx = logical(d);
	end
	num_point = sum(range_idx) ;
	% remove points out of x-axes
	data(1:num_point, column_num) = num2cell(d(range_idx));
	column_num = column_num +1 ;
	
	column_info{column_num}=['y',num2str(data_set)] ;
	d = hgS_070000.children(data_set).children(1).properties.YData' ;
	
	data(1:num_point, column_num) = num2cell(d(range_idx));
	column_num = column_num +1 ;
end

out = cell2table(data, 'VariableNames', column_info) ;
[~, name, ~] = fileparts(file);
writetable(out , fullfile(path,[name,'.csv'] ) );

end % this function