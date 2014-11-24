function proc(obj)

persistent PlotObj cm;
if obj.DataTotalNum <= 0 
	clearvars PlotObj ;
	return ;
end
dx={obj.DataTime,obj.DataTime} ;	
dy={obj.DataWindow(:,1),obj.DataWindow(:,2)} ;

plot_num=numel(dx);
if exist('PlotObj','var') && ~isempty(PlotObj)
	
	for fi = 1:plot_num
		set(PlotObj(fi).line,'XData',dx{fi},'YData',dy{fi});
		set(PlotObj(fi).axis,'XLim',[obj.DataTime(1),obj.DataTime(end)])
	end
else
	cm=colormap('lines');
	for fi = 1:plot_num
		subplot(plot_num,1,fi);
		PlotObj(fi).line=line(dx{fi},dy{fi},'DisplayName',num2str(fi),'LineStyle',':','Marker','+','Color',cm(fi,:));
		PlotObj(fi).axis=gca ;
		set(PlotObj(fi).axis,'XLim',[obj.DataTime(1),obj.DataTime(end)],'XGrid','on','YGrid','on')
	end
end
% legend('1','2','3') % too slow
drawnow ;

end