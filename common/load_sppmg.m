function data = load_sppmg(file)
% for fast load ascii data file.
% it can load mat file also.

[f_path,f_name,f_ext]=fileparts(file);

switch f_ext
	case '.txt'
		fid=fopen(file,'r');
		tmp_s=fread(fid,inf,'uint8=>char');
		fclose(fid);
		data_col_num=numel(sscanf(strtok(tmp_s,char(10)),'%f'));
		data=sscanf(tmp_s,'%f',[data_col_num,inf])';
		clearvars tmp_s;
	case '.mat'
		load(fullfile(path,file{fi}),'-mat','data');
end