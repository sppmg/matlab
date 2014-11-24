%didn't checked after updata code.
clear all;

% set the program version. yyyymmddvv . vv is version in each day.
program_version=2012121801;
%save(fullfile(path,'program_version'),'peaks_point','-ascii');

[file,path]=uigetfile({'*.txt;*.mat';'*.txt';'*.mat'},'MultiSelect', 'on');
check_peak=1;
check_plot=0;
if ~iscell(file)
	%check_peak=1;
	file={file};
end
% file
% whos
% return

if check_plot==1
	set(0,'DefaultFigureWindowStyle','docked');
else
	set(gcf,'Visible','off');
end
%figure;
for fi=1:length(file)
	[f_path,f_name,f_ext]=fileparts(file{fi});
	disp(['processing ',f_name,f_ext])

	switch f_ext
		case '.txt'
			disp('load ascii format.')
			data=load(fullfile(path,file{fi}));
			
		case '.mat'
			disp('load mat format.')
			load(fullfile(path,file{fi}),'-mat','data');
	end
	%tmp=data(floor(length(data)/2):end,:);
	%data=tmp;
	%save(fullfile(path,[f_name,'_half.txt']),'data','-ascii');
	[pks,locs] =findpeaks(data(:,2),'MINPEAKDISTANCE',4000*0.15,'MINPEAKHEIGHT',mean(data(:,2)));
	%[pks,locs] =findpeaks(data(:,2),'MINPEAKDISTANCE',4000*0.1,'MINPEAKHEIGHT',20);
% 	if see==1
% 		figure()
% 		%subplot(1,2,1);
% 		title(file{fi},'Interpreter', 'none');
% 		%set (gcf,'PaperUnits','point','PaperPosition',[0 0 1024 768])
% 		plot(data(:,1),data(:,2),data(locs,1),data(locs,2),'r*');
% 		
% 		
% 	end
	
	if check_peak==1		%save finded peaks plot
		if check_plot==1
			figure;
		end
		plot(data(:,1),data(:,2),data(locs(2:end-1),1),pks(2:end-1),'r*')
		title(f_name,'Interpreter', 'none');
		set(gcf,'PaperUnits','point','PaperPosition',[0 0 (length(data(:,1))/200) 400]);
		print(gcf,'-dpng',fullfile(path,['check_',file{fi},'.png']));
	end
	
	if check_plot==1
		figure;
	else
		clf;
		%h=figure(1);
	end


	%checked here.%%%%%%%%%%%%%%%%%%%%%%%%%%
	
	%subplot(1,2,2);
	hold on;
	
 	pks=pks(2:end-1);
% 	x=pks(1:end-1);
% 	y=pks(2:end);
% 	u=[diff(x);0];
% 	v=[diff(y);0];
% 	quiver(x,y,u,v,'k');
 	x=pks(1:end-2);
	y=pks(2:end-1);
	z=pks(3:end);
	u=[diff(x);0];
	v=[diff(y);0];
	w=[diff(z);0];
	quiver3(x,y,z,u,v,w,'k');

	
	plot3(x,y,z,'b:',x,y,z,'r*');
	
	%plot(x,y,'b:',x,y,'r+');
	title(f_name,'Interpreter', 'none');
	xlabel('peak(n) mmHg');
	ylabel('peak(n+1) mmHg');
	zlabel('peak(n+2)');
	hold off;
	set (gcf,'PaperUnits','point','PaperPosition',[0 0 400 400])  %should use pixels
	%print(h,'-djpeg',files(file).name)
	print(gcf,'-dpng',fullfile(path,[f_name,'.png']))
	% save x,y here !
	disp(['finish ',num2str(floor(100*fi/length(file))),'%']);
end
beep;