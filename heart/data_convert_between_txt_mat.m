% Only for 1 variable 'data' in 1 file.
%clear all;


clearvars -except env*
% if ~exist ('env_dir')
% 	env_dir=uigetdir;
% end
% cd(env_dir);

del_old_file=0;

[file,path]=uigetfile({'*.txt;*.mat';'*.txt';'*.mat'},'MultiSelect', 'on');

if ~iscell(file)		% MultiSelect will save in cell.
	file={file};
end

for fi=1:length(file)
	[f_path,f_name,f_ext]=fileparts(file{fi});
	disp(['process ',f_name,f_ext])
	switch f_ext
		case '.txt'
			disp('ascii -> mat')
			%data=load(fullfile(path,file{fi}));
			
			fid=fopen(fullfile(path,file{fi}),'r')
			tmp_s=fread(fid,inf,'uint8=>char');
			fclose(fid);
			data_col_num=numel(sscanf(strtok(tmp_s,char(10)),'%f'));
			data=sscanf(tmp_s,'%f',[data_col_num,inf])';
			clearvars tmp_s;
			
			save(fullfile(path,[f_name,'.mat']),'data','-mat','-v7');
		case '.mat'
			disp('mat -> ascii')
			load(fullfile(path,file{fi}),'-mat','data');
			save(fullfile(path,[f_name,'.txt']),'data','-ascii');
	end
	if del_old_file == 1 
		delete(fullfile(path,file{fi}));
	end
	disp(['finish ',num2str(floor(100*fi/length(file))),'%']);
end
beep