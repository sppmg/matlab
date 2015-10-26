%clear all;
clearvars -except env_*
%profile clear;
%profile on;
tic;

%%%%%% Set user var here %%%%%
%------- experiment var
sampling_rate = 4000 ;			% our : rat=4000 ; frog = 500
peak_interval_min_sec = 0.18 ;	% for findpeak; suggestion rat=0.1*sampling_rate ,frog=0.3*sampling_rate
peak_height_min = 0.1;		% for findpeak ,allowed <0
extremum_drop_condition = 3 ;		% times of sigma

raw_ch_time=1 ;
raw_ch_ecg=0 ;
raw_ch_ecg_ra=2 ;
auto_switch_channel=1 ; 	% auto switch by our usual data format . It's overwrite raw_ch_* var .
%channelName={'Time', 'ECG', 'ECG_RA'};

limiter_ibi=0 ;		% Maxima value, only apply in plotting. Set 0 to disable.
limiter_dibi=0 ;	% <<< Now only support gnuplot and dibi >>>
%------- control var (matlab -> true = 1 , false = 0)
extrasystoles_detection=0 ;	% need ecg channel

check_peak=1;
figure_dont_plot=1;				% no plot == 1 , plot == 0
figure_keep_in_ram=1;		% keep in RAM == 1 , don't keep == 0
figure_visible=0;	% on == 1 , off == 0 
figure_gnuplot=1 ;	% only action when figure_dont_plot=1

thread_num=1 ;
wait_batch=1 ;		% It' will wait all batch done when == 1 .
%%%%%% Set env var here %%%%%
%------- set the program version. yyyymmddvv . vv is version in each day.
env_program_version=2014060202;
env_papp_path=['.' filesep] ;
%%%%%% other setting %%%%%
addpath('./common');
set(0,'DefaultFigureWindowStyle','docked');
%------- check external program existence
% ext_prog_test_cmd store command for test program existence. Usually use help option.
% ext_prog_work_cmd store working command , it map to ext_prog_list. If program in protable path , it will insert './' or '.\'
%	If protable program in protable path subfolder, you should make a .bat or .sh to protable path to execute program.
%	Don't add extension . (eg, .sh/.bat)
% ext_prog_list store exist program name.
% use this get program existence --->   if sum(ismember(ext_prog_list,'progname')) > 0

ext_prog_list={};

ext_prog_test_cmd={ 'busybox' , 'gnuplot -h' } ;
ext_prog_work_cmd={ 'busybox' , 'gnuplot' } ;
if ~isempty(ext_prog_test_cmd)
	for fi=[1:length(ext_prog_test_cmd)]
		% test installed app
		[ext_prog_status,tmp]=system( ext_prog_test_cmd{fi} );	% success => 0
		if ext_prog_status == 0
			ext_prog_list = [ext_prog_list, strtok(ext_prog_test_cmd{fi},' ') ] ;
		else
			% test portable app
			[ext_prog_status,tmp]=system([env_papp_path,ext_prog_test_cmd{fi} ]);	% success => 0	
			if ext_prog_status == 0
				ext_prog_list = [ext_prog_list, strtok(ext_prog_test_cmd{fi},' ') ] ;
				ext_prog_work_cmd{fi} = [ env_papp_path, ext_prog_work_cmd{fi} ]; % insert papp path to work cmd
			else
				ext_prog_work_cmd(fi) = [] ;	% remove working command
			end
		end
		
	end
end

fprintf('Thread number = %d\n',thread_num);
select_files

%------- configure multithread
if verLessThan('matlab','8.3')
	if thread_num > 1
		switch matlabpool('size')
			case 0
				matlabpool(thread_num);
			case thread_num
			otherwise
				matlabpool close;
				matlabpool(thread_num);
		end
	else
		if matlabpool('size') ~= 0
			matlabpool close;
		end
	end
else
	poolobj = gcp('nocreate'); % If no pool, do not create new one.
	if isempty(poolobj)
		poolsize = 0;
	else
		poolsize = poolobj.NumWorkers ;
	end

	if thread_num > 1
		switch poolsize
			case 0
				parpool (thread_num);
			case thread_num
			otherwise
				delete(gcp('nocreate'))
				parpool (thread_num);
		end
	else
		if poolsize ~= 0
			delete(gcp('nocreate'))
		end
	end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ana_log=[];	% store mean and sd of each file.

if ~figure_dont_plot
	fh_max=1;
	%fh(fh_max)=figure('visible','off','Renderer','OpenGL');
	if figure_visible==1
		fh(fh_max)=figure('visible','on');
	else
		fh(fh_max)=figure('visible','off');
	end
end
	

for fi=1:length(file)
	[f_path,f_name,f_ext]=fileparts(file{fi});
	disp(['processing ',f_name,f_ext])
	
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
			dataChannelNum=data_col_num;
			clearvars tmp_s;
		case '.mat'
			disp('load mat format.')
			load(fullfile(path,file{fi}),'-mat','data');
	end
	
	if auto_switch_channel
		raw_ch_time=1 ;
		switch  numel(data(1,:))
			case 2
				raw_ch_ecg=0;
				raw_ch_ecg_ra=2;
				channelName={'Time', 'ECG_RA'};
			case 3
				raw_ch_ecg=2;
				raw_ch_ecg_ra=3;
				channelName={'Time', 'ECG', 'ECG_RA'};
			otherwise
				error('Wrong data file format.');
		end
	end

	%data(:,2)=-data(:,2);
	%data(:,2)=data(:,3); % <-- don't use this line now.
%  	if figure_keep_in_ram
%  		fh_max=fh_max+1;
%  		if figure_visible
%  			fh(fh_max)=figure('visible','on');
%  		else
%  			fh(fh_max)=figure('visible','off');
%  		end
%  	end
	disp('start findpeaks')
	peaksPointLast = 0 ;
	for targetChannel = 2:dataChannelNum
		if thread_num == 1
			[pks,locs] =findpeaks(sign(peak_height_min) * data(:,targetChannel),'MINPEAKDISTANCE',peak_interval_min_sec*sampling_rate ,'MINPEAKHEIGHT',abs(peak_height_min));
		else
			part=round(linspace(1,length(data(:,targetChannel)),thread_num+1));
			tmp_locs_all=[];
			parfor f_thread_i = 1:thread_num
				[tmp_pks,tmp_locs]=findpeaks(sign(peak_height_min) * data(part(f_thread_i):part(f_thread_i+1),targetChannel),'MINPEAKDISTANCE',peak_interval_min_sec*sampling_rate ,'MinPeakHeight',abs(peak_height_min) );
				tmp_locs_all=[tmp_locs_all;tmp_locs+part(f_thread_i)-1];
			end

			locs=sort(tmp_locs_all);
		end

		peaks_point=[data(locs,raw_ch_time), data(locs,targetChannel)];
		if data(locs(end),raw_ch_time) > peaksPointLast
			% for gunplot to match x range between multiplot
			peaksPointLast=data(locs(end),raw_ch_time);
		end



		% get IBI
		ibi=[data(locs(2:end),raw_ch_time), diff(data(locs,raw_ch_time),1)];
		[mu_hat, sigma_hat] = normfit(ibi(:,2));


		
		% drop IBI data more then sigma
		ibi_outliers=[];
		ibi_outliers_inx=find(abs(ibi(:,2) - mu_hat ) > extremum_drop_condition*sigma_hat );
		if ~isempty(ibi_outliers_inx)
			fprintf('droped %d data of ibi\n',length(ibi_outliers_inx)) ;
			ibi_outliers=ibi(ibi_outliers_inx,:);
			ibi( ibi_outliers_inx ,:)=[];
			[mu_hat, sigma_hat] = normfit(ibi(:,2));
		end

		% get ratio of IBI, for BS. put code before drop IBI outlier
		% should move , but for lazy code , put here. or need - outlier number or save to  another file
		% use t2/t1, so find 0.6x
		ibiRatio=[ ibi(1,1),1; ibi(2:end,1) , ibi(2:end,2)./ibi(1:end-1,2) ];

		% plot ibi variation in matlab
		if ~figure_dont_plot
			clf;
			if isempty(ibi_outliers_inx)
				plot( ibi(:,1), ibi(:,2), 'b:', ...
					ibi(:,1),ibi(:,2), 'r*');
			else
				plot( sort( [ibi(:,1);ibi_outliers(:,1)] ), sort( [ibi(:,2);ibi_outliers(:,2)] ), 'b:', ...
					ibi(:,1),ibi(:,2), 'r*', ...
					ibi_outliers(:,1), ibi_outliers(:,2),'kx');
			end
			ylim_now=ylim;	% set y axis start from 0
			ylim([0,ylim_now(2)]);
			title(file{fi},'Interpreter', 'none');
			grid on;
			set (gcf,'PaperUnits','point','PaperPosition',[0 0 (length(ibi(:,1))*0.5) 400]);
			print(gcf,'-dpng',fullfile(path,['ibi_variation_',f_name,'.png']));

			if figure_keep_in_ram
				fh_max=fh_max+1;
				if figure_visible==1
					fh(fh_max)=figure('visible','on');
				else
					fh(fh_max)=figure('visible','off');
				end
			end
		end

		% moving SD for IBI -> dIBI
		dibi=[ibi(:,1), movingstd(ibi(:,2),50,'c')];
		% drop dIBI data more then sigma
		[mu_hat_dibi, sigma_hat_dibi] = normfit(dibi(:,2));
		dibi_outliers_inx=find(abs(dibi(:,2) - mu_hat_dibi ) > extremum_drop_condition*sigma_hat_dibi );
		if isempty(dibi_outliers_inx)
			dibi( dibi_outliers_inx ,:)=[];
		end

		% dIBI / IBI
		dibipibi=[ibi(:,1), dibi(:,2)./ibi(:,2)];

		% save together : Time , IBI , dIBI , dIBI / IBI , ibi ratio
		tidp=[ibi(:,1), ibi(:,2), dibi(:,2), dibipibi(:,2),ibiRatio(:,2)] ;
		save(fullfile(path,['tidp_',channelName{targetChannel},'_',f_name,'.txt']),'tidp','-ascii');

		save(fullfile(path,['peaks_',channelName{targetChannel},'_',f_name,'.txt']),'peaks_point','-ascii');
		%save(fullfile(path,['ibi_of_',f_name,'.txt']),'ibi','-ascii');
		save(fullfile(path,['ibi_outlier_',channelName{targetChannel},'_',f_name,'.txt']),'ibi_outliers','-ascii');
		%save(fullfile(path,['dibi_of_',f_name,'.txt']),'dibi','-ascii');
		%save(fullfile(path,['dibipibi_of_',f_name,'.txt']),'dibipibi','-ascii');

		% totel mean and sd of IBI
		fprintf('%s \t mean , sd = %f\t%f\n',channelName{targetChannel},mu_hat,sigma_hat)
		ana_log=[ana_log;[mu_hat, sigma_hat, length(ibi_outliers) ]];

		
		
		% plot histgram with normal dist for IBI.
		if ~figure_dont_plot
			h=histfit(ibi(:,1),100);
			set(h(1),'FaceColor',[.8 .8 1])
			xlim=[0.4 0.55];
			x_range=get(gca,'XLim');
			y_range=get(gca,'yLim');
			xlabel('IBI(s)');
			ylabel('count');
			text_x=x_range(1)+0.05*(x_range(2)-x_range(1));
			text_y=y_range(2)-0.20*(y_range(2)-y_range(1));
			text(text_x,text_y,strcat('\mu =',num2str(mu_hat),'\newline','\sigma =',num2str(sigma_hat)));
			title(file{fi},'Interpreter', 'none');

			set (gcf,'PaperUnits','point','PaperPosition',[0 0 400 400])  %should use pixels
			print(gcf,'-dpng',fullfile(path,[f_name,'.png']));
		end
	
	end % for channel

	
	% plot
	if figure_gnuplot && sum(ismember(ext_prog_list,'gnuplot')) > 0
		
		fid=fopen( fullfile(path,['tip_var_',f_name,'.gp']) ,'w');
		%set multiplot later
		% follow line write to gnuplot script
		fprintf(fid,'inBaseDir="%s"\n',regexprep(path,'\\','/')); % gnuplot use '/' in win. not affect to linux.
		fprintf(fid,'outBaseDir="%s"\n\n',regexprep(path,'\\','/'));
		
		for tmpGpDataFile=2:dataChannelNum
			fprintf(fid,'datafile%d="%s"\n',tmpGpDataFile,['tidp_',channelName{tmpGpDataFile},'_',f_name,'.txt']);
		end
		fprintf(fid,'outfile1="%s"\n\n',['tip_var_',f_name,'.png']);

		for tmpGpDataFile=2:dataChannelNum
			fprintf(fid,'dataPath%d=sprintf("%%s/%%s",inBaseDir,datafile%d)\n',tmpGpDataFile,tmpGpDataFile);
		end
		fprintf(fid,'outPath1=sprintf("%%s/%%s",outBaseDir,outfile1)\n\n');
		
		fprintf(fid,'set term png size %d,%d \n', length(ibi(:,1)), 600*(dataChannelNum-logical(raw_ch_time))*2); % 600 for each subplot
		fprintf(fid,'set output outfile1\n');
		fprintf(fid,'set logscale y2\n');
		fprintf(fid,'set grid\n');
		fprintf(fid,'set xtics 100\n');
		fprintf(fid,'set ytics nomir\n');
		fprintf(fid,'set y2tics\n');
		fprintf(fid,'set yr [0:1]\n');
		fprintf(fid,'set xr [0:%f]\n',peaksPointLast);
		fprintf(fid,'\n');

		fprintf(fid,'set multiplot layout %d,1 \n',(dataChannelNum-logical(raw_ch_time))*2 ); % channel + ibi ratio
		fprintf(fid,'set bmargin 0 \n');
		fprintf(fid,'set format x "" \n');
		fprintf(fid,'set ylabel "IBI (s)  %s" \n',channelName{raw_ch_ecg_ra});
		fprintf(fid,'set y2label "dIBI/IBI" \n');
		% should use loop in here
		fprintf(fid,'plot datafile%d u 1:4 title "dIBI/IBI" w lp lc rgb "#00DC00" axis x1y2 , \\\n\t "" u 1:2 title "" w l lc rgb "#BFD9FF" axis x1y1 , \\\n\t "" u 1:2 title "IBI" w p pt 1 lc rgb "#FF0000" axis x1y1 \n\n' ,raw_ch_ecg_ra) ;
		% plot ecg
		fprintf(fid,'set tmargin 0 \n');
		fprintf(fid,'set ylabel "IBI (s)  %s" \n',channelName{raw_ch_ecg});
		fprintf(fid,'set y2label "dIBI/IBI"\n');
		fprintf(fid,'plot datafile%d u 1:4 title "dIBI/IBI" w lp lc rgb "#00DC00" axis x1y2 , \\\n\t "" u 1:2 title "" w l lc rgb "#BFD9FF" axis x1y1 , \\\n\t "" u 1:2 title "IBI" w p pt 1 lc rgb "#FF0000" axis x1y1 \n\n' ,raw_ch_ecg) ;

		% plot ibi ratio
		fprintf(fid,'set yr [0:3]\n');
		
		fprintf(fid,'set ylabel "IBI ratio  %s" \n',channelName{raw_ch_ecg_ra});
		fprintf(fid,'plot datafile%d u 1:5 title "" w l lc rgb "#BFD9FF" axis x1y1 , \\\n\t "" u 1:5 title "IBI ratio" w p pt 1 lc rgb "#FF0000" axis x1y1 , 0.6 title "ratio == 0.6" w 1 lc rgb "#0000FF" axis x1y1 \n\n' ,raw_ch_ecg_ra) ;
		
		fprintf(fid,'set xlabel "Time (s)"\n');
		fprintf(fid,'set bmargin \n');
		fprintf(fid,'set format x "%%g" \n');
		
		fprintf(fid,'set ylabel "IBI ratio  %s" \n',channelName{raw_ch_ecg});
		fprintf(fid,'plot datafile%d u 1:5 title "" w l lc rgb "#BFD9FF" axis x1y1 , \\\n\t "" u 1:5 title "IBI ratio" w p pt 1 lc rgb "#FF0000" axis x1y1 , 0.6 title "ratio == 0.6" w 1 lc rgb "#0000FF" axis x1y1 \n\n' ,raw_ch_ecg) ;

		%fprintf(fid,'set title "%s"\n',f_name);
		fprintf(fid,'unset multiplot \n');
			
			if limiter_dibi || limiter_ibi
				if  limiter_ibi && max(ibi(:,2)) > limiter_ibi
					fprintf(fid,'set yr [*:%f]\n',limiter_ibi);
				end
				if limiter_dibi && max(dibi(:,2)) > limiter_dibi
					fprintf(fid,'set y2r [*:%f]\n',limiter_dibi);
				end
			end
			fprintf(fid,'\n');
			

		fclose(fid) ;
		% gnuplot_shell_cmd=['gnuplot ', fullfile(path,['tip_var_',f_name,'.gp']) ] ;
		% add
		% gnuplot_shell_cmd=['C:\data\brian\matsh\gnuplot\bin\gnuplot ', fullfile(path,['tip_var_',f_name,'.gp']) ] ;

		tmp_ext_cmd=ext_prog_work_cmd{find(ismember(ext_prog_list,'gnuplot') ) };
		gnuplot_shell_cmd=[tmp_ext_cmd,' ', fullfile(path,['tip_var_',f_name,'.gp']) ] ;

		j_tip_var(fi)=batch(@system,1,{gnuplot_shell_cmd});

	end

	if check_peak==1		%save finded peaks plot
		if figure_dont_plot
			if figure_gnuplot && sum(ismember(ext_prog_list,'gnuplot')) > 0
				% write data and call gnuplot
				fid=fopen( fullfile(path,['check_',f_name,'.gp']) ,'w');
				% follow line write to gnuplot script
				fprintf(fid,'inBaseDir="%s"\n',regexprep(path,'\\','/')); % gnuplot use '/' in win. not affect to linux.
				fprintf(fid,'outBaseDir="%s"\n\n',regexprep(path,'\\','/'));
				
				fprintf(fid,'datafile0="%s"\n',[,f_name,'.txt']);
				for tmpGpDataFile=2:dataChannelNum
					fprintf(fid,'datafile%d="%s"\n',tmpGpDataFile,['peaks_',channelName{tmpGpDataFile},'_',f_name,'.txt']);
				end
				fprintf(fid,'outfile1="%s"\n\n',['check_',f_name,'.png']);

				for tmpGpDataFile=2:dataChannelNum
					fprintf(fid,'dataPath%d=sprintf("%%s/%%s",inBaseDir,datafile%d)\n',tmpGpDataFile,tmpGpDataFile);
				end
				fprintf(fid,'outPath1=sprintf("%%s/%%s",outBaseDir,outfile1)\n\n');
				fprintf(fid,'set term png size %d,800 \n',length(peaks_point)*10 );
				fprintf(fid,'set output outfile1\n');
				fprintf(fid,'set grid\n');
				fprintf(fid,'set xtics 100\n\n');
				
				fprintf(fid,'set multiplot layout %d,1 \n',dataChannelNum-logical(raw_ch_time) );
				fprintf(fid,'set bmargin 0 \n');
				fprintf(fid,'set format x "" \n');
				fprintf(fid,'set ylabel "%s" \n',channelName{raw_ch_ecg_ra});
				
				% should use loop in here
				fprintf(fid,'plot datafile%d u 1:2 w p pt 3 ps 1 lc rgb "#FF0000" , datafile0 u %d:%d w l lc rgb "#0000FF" \n', ...
						raw_ch_ecg_ra,raw_ch_time, raw_ch_ecg_ra);

				fprintf(fid,'set bmargin \n');
				fprintf(fid,'set tmargin 0 \n');
				fprintf(fid,'set format x "%%g" \n');
				fprintf(fid,'set xlabel "Time (s)"\n');
				fprintf(fid,'set ylabel "%s" \n',channelName{raw_ch_ecg});
				fprintf(fid,'plot datafile%d u 1:2 w p pt 3 ps 1 lc rgb "#FF0000" , datafile0 u %d:%d w l lc rgb "#0000FF" \n', ...
						raw_ch_ecg,raw_ch_time, raw_ch_ecg);
				
				fprintf(fid,'unset multiplot \n');
				%fprintf(fid,'set title "%s"\n',f_name);
				%fprintf(fid,'set ylabel ""\n');
				fclose(fid) ;
				% gnuplot_shell_cmd=['gnuplot ', fullfile(path,['check_',f_name,'.gp']) ] ;
				% add
				% gnuplot_shell_cmd=['C:\data\brian\matsh\gnuplot\bin\gnuplot ', fullfile(path,['check_',f_name,'.gp']) ] ;

				tmp_ext_cmd=ext_prog_work_cmd{find(ismember(ext_prog_list,'gnuplot') ) };
				gnuplot_shell_cmd=[tmp_ext_cmd,' ', fullfile(path,['check_',f_name,'.gp']) ] ;

				j_check(fi)=batch(@system,1,{gnuplot_shell_cmd}); % change to no batch

			end
		else

			%disp('save check figure');
			plot(data(:,raw_ch_time),data(:,raw_ch_ecg_ra),'b-',data(locs,raw_ch_time),pks,'r*');
			title(file{fi},'Interpreter', 'none');
			set(gcf,'PaperUnits','point','PaperPosition',[0 0 (length(peaks_point)*10) 400]);
			print(gcf,'-dpng',fullfile(path,['check_',f_name,'.png']));

			if figure_keep_in_ram
				fh_max=fh_max+1;
				if figure_visible
					fh(fh_max)=figure('visible','on');
				else
					fh(fh_max)=figure('visible','off');
				end
			end

			%fh(fh_max)=figure('visible','off','Renderer','OpenGL');
		end
	end
	
	disp(['finish ',num2str(floor(100*fi/length(file))),'%']);
end % for file
%toc;

if ~figure_dont_plot && figure_visible
	disp('visible on');
	if figure_keep_in_ram
		set(fh,'visible','on'); % 'Renderer','OpenGL'
	else
		for fi=1:length(fh_max)
			set(fi,'visible','on'); % 'Renderer','OpenGL'
		end
	end
end

format long
ana_log
toc;
beep
% wait all batch job
if wait_batch
	batch_finish_rate=0;
	while batch_finish_rate < 100
		pause(0.3);
		tmp_old_state_rate=batch_finish_rate;
		batch_finish_state=ismember({j_check.State , j_tip_var.State},'finished');
		batch_finish_rate=sum(batch_finish_state)/numel(batch_finish_state)*100 ;
		if batch_finish_rate ~= tmp_old_state_rate
			fprintf('Batch jobs %0.2f%% finished.\n',batch_finish_rate);
		end
	end
	toc;
	beep;
end
delete([j_check , j_tip_var]);
% check running jobs
% j(3)=batch(@system,1,'xxxx');
% sum(ismember({j.Status},'running'));
%-------------
% batjob={j_check.State , j_tip_var.State};
% while sum(ismember({j_check.State , j_tip_var.State},'running')) == 0
% 	pause(0.5);
% end

% for fi=1:length(file)
% 	wait(j_check(fi));
% 	wait(j_tip_var(fi));
% end


% delete(j) % in 2014a
%destroy(j) % in 2011b ?
%matlabpool close
