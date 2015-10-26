function varargout = uigetfile_sppmg(varargin)
persistent env_lastDir
% open window for select files , better then matlab's uigetfile :D
% input FilterSpec same as uigetfile()
% output = file or [file, path] 
% cancel will output 0

switch nargin
	case 0
		filepatten='*.txt;*.mat';
	otherwise
		filepatten=varargin{:};
end

if verLessThan('matlab', '8.1')
	% strsplit provide after 2013a
	filepatten_part=regexp(filepatten, ';', 'split');
else
	filepatten_part=strsplit(filepatten,';');
end

filepatten_filter=[filepatten;filepatten_part'];

if ischar(env_lastDir) && isdir(env_lastDir)
			path_orig=pwd;
			cd(env_lastDir);
end

[file,path]=uigetfile(filepatten_filter,'MultiSelect', 'on');
if path		% path == 0 , cancel
	env_lastDir = path;
elseif ~isnumeric(file) && ~iscell(file)		% MultiSelect will save in cell.
	file={file};
end
	
if exist('path_orig','var') && ~isempty(path_orig)
	cd(path_orig);
end

switch nargout
	case {0,1}
		varargout{1} = file ;
	case 2
		varargout = {file, path} ;
%  	otherwise
%  		varargout =
end