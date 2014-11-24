% need matlab 2011b upper for matfile func.
clearvars -except env_*
%profile clear;
%profile on;
%tic;

%%%%%% Set user var here %%%%%
	% experiment var
sampling_rate = 40000 ;			% our : rat=4000 ; frog = 500
	% control var (matlab -> true = 1 , false = 0)
start=[0 0 0 50 0 0];
duration = 300;		% sec
addname='_part';

check_peak=1;
figure_keep_in_ram=1;		% keep in RAM == 1 , don't keep == 0
figure_visible=0;	% on == 1 , off == 0 
%%%%%% Set env var here %%%%%
	% set the program version. yyyymmddvv . vv is version in each day.
env_program_version=2014052102;

%%%%%% other setting %%%%%
addpath('./common');
set(0,'DefaultFigureWindowStyle','docked');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

select_files
% display file name with start time.
disp([char(file),repmat(' -> ',length(file),1),num2str(start')])

for fi=1:length(file)
	[f_path,f_name,f_ext]=fileparts(file{fi});
	disp(['processing ',f_name,f_ext,' start at ',num2str(start(fi)) ])
	
	switch f_ext
		case '.txt'
			disp('load ascii format.')
			%data=load(fullfile(path,file{fi}));
			fid=fopen(fullfile(path,file{fi}),'r');
			tmp_s=fread(fid,inf,'uint8=>char');
			fclose(fid);
			%[ext_prog_status, data_row_num]=system(['wc -l < ',fn ] );
			data_col_num=numel(sscanf(strtok(tmp_s,char(10)),'%f'));
			data=sscanf(tmp_s,'%f',[data_col_num,inf])';
			clearvars tmp_s;
			
			data=data( start(fi)*sampling_rate +1 : (start(fi)+duration) *sampling_rate +1,: );
			
			save(fullfile(path,[f_name,'_',num2str(start(fi)),'_',num2str(start(fi)+duration),addname,'.txt']),'-ascii','data');
			
		case '.mat'
			proc_file=matfile(fullfile(path,file{fi}));
			data=proc_file.data(start(fi)*sampling_rate+1 : (start(fi)+duration) *sampling_rate +1 ,:);
			if figure_visible
				figure
				plot(data(:,1),data(:,2));
				title(f_name)
			end
		
			save(fullfile(path,[f_name,addname,'.mat']),'data');
	end
	
	
	
end
beep;