function save2csv(varargin)
% save data set to csv file.
% save2csv(file, [data name]_1, var_1, ...
delimiter = char(9) ; % tab = 9
if nargin < 2
	error('Argument at least 2 for file path and variable.');
end
[path, filename, ~] = fileparts(varargin{1}) ;
column_num = 1 ;
n=2 ;
column_info={};
while n <= nargin
	if ischar(varargin{n})
		column_info{column_num} = varargin{n} ;
		n = n +1 ;
	else
		column_info{column_num} = ['Unknown_', num2str(numel(column_info)+1)] ;
	end
	[r, c] = size(varargin{n}) ;
	tmp_c = c ;
	while tmp_c > 1		% copy column_info to multi-column data.
		tmp_c=tmp_c-1;
		column_info{column_num+tmp_c} = column_info{column_num} ;
	end
	
	data(1:r, column_num:column_num+c-1 ) = num2cell(varargin{n}) ;
	column_num = column_num + c ;
	n=n+1;
end
% set to 118.2 because table's VariableNames not allow same string, it's
% not good to 2D variable. So here force use fprintf.
if verLessThan('matlab', '118.2') % 2013b+(8.2) has 'table' type . 
	[r, c] = size(data) ;
	fid = fopen(fullfile(path,[filename,'.csv'] ) ,'w' ) ;
	
	for nc = 1:c-1
		fprintf(fid, '%s%s',column_info{nc} ,delimiter) ;
	end
	fprintf(fid, '%s\n',column_info{c} ) ;
	
	for nr = 1:r
		for nc = 1:c-1
			fprintf(fid, '%s%s',num2str(data{nr,nc}) ,delimiter) ;
		end
		fprintf(fid, '%s\n',num2str(data{nr,c}) ) ;
	end
else
	out = cell2table(data, 'VariableNames', column_info) ; 
	writetable(out , fullfile(path,[filename,'.csv'] ) );
end
