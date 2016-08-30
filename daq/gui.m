% Need "GUI Layout Toolbox" developed by Ben Tordoff and David Sampson .

clear all ;
close all;
fig = figure('Renderer','OpenGL','MenuBar', 'none','ToolBar', 'none');

ui.grdBase = uiextras.Grid('Parent',fig,'Spacing', 3);
ui.panOptA=uiextras.TabPanel( 'Parent',ui.grdBase);
	ui.grdOptA1=uiextras.Grid('Parent',ui.panOptA,'Spacing', 3,'ColumnSizes', [-1 -1], 'RowSizes',[30,30]);
		txto1=uicontrol( 'Parent', ui.grdOptA1, 'Style','text', 'String' ,'var1' );
		txto1=uicontrol( 'Parent',ui.grdOptA1, 'Style','text','String' ,'var2' );
		edito1=uicontrol( 'Parent', ui.grdOptA1, 'Style','edit','String' ,'edit1' );
		edito1=uicontrol( 'Parent', ui.grdOptA1, 'Style','edit','String' ,'edit2');
		%set( ui.grdOptA1,'ColumnSizes', [-1 -1], 'RowSizes',[30,30]);
	%uicontrol( 'Parent', ui.panOptA, 'Background', 'r' );
	%uicontrol( 'Parent', ui.panOptA, 'Background', 'b' );
ui.btnStart = uicontrol( 'Style','togglebutton','String', 'Start', 'Parent', ui.grdBase ); % start/stop button
PlotArea=uiextras.GridFlex('Parent',ui.grdBase,'Spacing', 5);
	uicontrol( 'Parent', PlotArea, 'Background', 'r' );
	uicontrol( 'Parent', PlotArea, 'Background', 'g' );
	uicontrol( 'Parent', PlotArea, 'Background', 'b' );
	uicontrol( 'Parent', PlotArea, 'Background', 'k' );
	txt1=uicontrol( 'Parent', PlotArea, 'Style','text', 'Background', 'y' );
	txt2=uicontrol( 'Parent', PlotArea, 'Style','text', 'Background', 'c' );
	
	set(PlotArea,'ColumnSizes', [-1 -1 150], 'RowSizes',[-1,-1]);

OptArea_2=uiextras.HBox('Parent',ui.grdBase );
	uicontrol( 'Parent', OptArea_2, 'Background', 'r' );
	uicontrol( 'Parent', OptArea_2, 'Background', 'b' );
set(ui.grdBase,'ColumnSizes', [150 -1], 'RowSizes',[-1,40]); % set size when finish put item.

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
