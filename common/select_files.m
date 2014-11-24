%function [env_dir,path,file]=select_files()
% open window for select files 

filepatten='*.txt;*.mat';
if verLessThan('matlab', '8.1')
	% strsplit provide after 2013a
	filepatten_part=regexp(filepatten, ';', 'split');
else
	filepatten_part=strsplit(filepatten,';');
end
filepatten_filter=[filepatten;filepatten_part'];

if exist('env_dir','var')
	if ischar(env_dir)
		if isdir(env_dir)
			path_orig=pwd;
			cd(env_dir);
		end
	end
end

%[file,path]=uigetfile({'*.txt;*.mat';'*.txt';'*.mat'},'MultiSelect', 'on');
[file,path]=uigetfile(filepatten_filter,'MultiSelect', 'on');
if ~ischar(path)
	% cencel in select file.
	if ~isempty(path_orig)
		cd(path_orig);
	end
	error('cenceled');
elseif exist('path_orig','var')
	if ~isempty(path_orig)
		cd(path_orig);
	end
end
env_dir=path;

if ~iscell(file)		% MultiSelect will save in cell.
	file={file};
end

%end