clear all ;
close all;


f = figure('Renderer','OpenGL','MenuBar', 'none','ToolBar', 'none');

layout0 = uiextras.Grid('Parent',f,'Spacing', 3);
OptArea_1=uiextras.TabPanel( 'Parent',layout0);
	layout_opta1=uiextras.Grid('Parent',OptArea_1,'Spacing', 3,'ColumnSizes', [-1 -1], 'RowSizes',[30,30]);
		txto1=uicontrol( 'Parent', layout_opta1, 'Style','text', 'String' ,'var1' );
		txto1=uicontrol( 'Parent',layout_opta1, 'Style','text','String' ,'var2' );
		edito1=uicontrol( 'Parent', layout_opta1, 'Style','edit','String' ,'edit1' );
		edito1=uicontrol( 'Parent', layout_opta1, 'Style','edit','String' ,'edit2');
		%set( layout_opta1,'ColumnSizes', [-1 -1], 'RowSizes',[30,30]);
	%uicontrol( 'Parent', OptArea_1, 'Background', 'r' );
	uicontrol( 'Parent', OptArea_1, 'Background', 'b' );
uicontrol( 'Style','togglebutton','String', 'Start', 'Parent', layout0 ); % start/stop button
PlotArea=uiextras.GridFlex('Parent',layout0,'Spacing', 5);
	uicontrol( 'Parent', PlotArea, 'Background', 'r' );
	uicontrol( 'Parent', PlotArea, 'Background', 'g' );
	uicontrol( 'Parent', PlotArea, 'Background', 'b' );
	uicontrol( 'Parent', PlotArea, 'Background', 'k' );
	txt1=uicontrol( 'Parent', PlotArea, 'Style','text', 'Background', 'y' );
	txt2=uicontrol( 'Parent', PlotArea, 'Style','text', 'Background', 'c' );
	
	set(PlotArea,'ColumnSizes', [-1 -1 150], 'RowSizes',[-1,-1]);

OptArea_2=uiextras.HBox('Parent',layout0 );
	uicontrol( 'Parent', OptArea_2, 'Background', 'r' );
	uicontrol( 'Parent', OptArea_2, 'Background', 'b' );
set(layout0,'ColumnSizes', [150 -1], 'RowSizes',[-1,40]); % set size when finish put item.

set(txt1,'string',sprintf(' 5 min IBI = %1.2f\n 10 min IBI = %1.2e',1,2),'HorizontalAlignment','left')
t=[0:0.01:2*pi*3];
x=sin(t);
y=cos(t);
%ax1=axes('Parent',layout );
%plot(t,x);
% 
% ax2=axes('Parent',layout );
% plot(t,y);
% 
% ax3=axes('Parent',layout );
% plot(t,x+3*y);
% layout.Sizes=[-2,-1,-1]
