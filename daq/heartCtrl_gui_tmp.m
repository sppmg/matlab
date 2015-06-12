function heartCtrl_gui_tmp()
global ui
% for test gui
defFontSize=20 ;
ui.GenTime.fig = figure('MenuBar', 'none','ToolBar', 'none','Visible','off');
ui.GenTime.layBase = uiextras.Grid('Parent',ui.GenTime.fig,'Spacing', 3);
ui.GenTime.txt= [ uicontrol( 'Parent', ui.GenTime.layBase, 'Style','text','FontSize',defFontSize, 'String' ,'pre pacing t0' ) , ...
	uicontrol( 'Parent', ui.GenTime.layBase, 'Style','text','FontSize',defFontSize, 'String' ,'pre pacing count' ) , ...
	uicontrol( 'Parent', ui.GenTime.layBase, 'Style','text','FontSize',defFontSize, 'String' ,'adapt pacing count' ) , ...
	uicontrol( 'Parent', ui.GenTime.layBase, 'Style','text','FontSize',defFontSize, 'String' ,'t0' ) , ...
	uicontrol( 'Parent', ui.GenTime.layBase, 'Style','text','FontSize',defFontSize, 'String' ,'dt' ) , ...
	uicontrol( 'Parent', ui.GenTime.layBase, 'Style','text','FontSize',defFontSize, 'String' ,'count' ) ] ;
ui.GenTime.edit= [ uicontrol( 'Parent', ui.GenTime.layBase, 'Style','edit','FontSize',defFontSize, 'String' ,0.5 ) , ...
	uicontrol( 'Parent', ui.GenTime.layBase, 'Style','edit','FontSize',defFontSize, 'String' ,8 ) , ...
	uicontrol( 'Parent', ui.GenTime.layBase, 'Style','edit','FontSize',defFontSize, 'String' ,16 ) , ...
	uicontrol( 'Parent', ui.GenTime.layBase, 'Style','edit','FontSize',defFontSize, 'String' ,0.3 ) , ...
	uicontrol( 'Parent', ui.GenTime.layBase, 'Style','edit','FontSize',defFontSize, 'String' ,'0.1 , 0.2' ) , ...
	uicontrol( 'Parent', ui.GenTime.layBase, 'Style','edit','FontSize',defFontSize, 'String' ,8) ] ;
uiextras.Empty( 'Parent', ui.GenTime.layBase);
uiextras.Empty( 'Parent', ui.GenTime.layBase);
uiextras.Empty( 'Parent', ui.GenTime.layBase);
uiextras.Empty( 'Parent', ui.GenTime.layBase);
uiextras.Empty( 'Parent', ui.GenTime.layBase);
ui.GenTime.ok=uicontrol( 'Parent', ui.GenTime.layBase,'Style', 'pushbutton','FontSize',defFontSize, 'String', 'OK', 'Callback',{@genTime,ui});
set(ui.GenTime.layBase, 'ColumnSizes', [-1 -1 100])

ui.ctrlPad.fig = figure('Renderer','OpenGL','MenuBar', 'none','ToolBar', 'none');
ui.ctrlPad.layBase = uiextras.VBox('Parent',ui.ctrlPad.fig,'Spacing', 3);
	ui.ctrlPad.layPreSet = uiextras.HBox('Parent',ui.ctrlPad.layBase,'Spacing', 3);
		ui.ctrlPad.timingTable = uitable('Parent',ui.ctrlPad.layPreSet, 'Data',magic(2),'ColumnEditable',true , 'ColumnWidth', 'auto', 'ColumnName', {'t0', 'dt', 'count'} );
		ui.ctrlPad.layPreBtn = uiextras.VBox('Parent',ui.ctrlPad.layPreSet,'Spacing', 3);
			ui.ctrlPad.perBtnSmart = uicontrol( 'Parent', ui.ctrlPad.layPreBtn,'Style', 'pushbutton','FontSize',defFontSize, 'String', 'Smart Set', 'Callback',{@openGentimeFig,ui});
			ui.ctrlPad.perBtnStart = uicontrol( 'Parent', ui.ctrlPad.layPreBtn,'Style', 'togglebutton','FontSize',defFontSize , 'String', 'Start');
			uiextras.Empty( 'Parent',ui.ctrlPad.layPreBtn);
			ui.ctrlPad.perBtnDec = uicontrol( 'Parent', ui.ctrlPad.layPreBtn,'Style', 'pushbutton','FontSize',defFontSize , 'String', '-', 'Callback',{@timingDec,ui} );
			ui.ctrlPad.perBtnInc = uicontrol( 'Parent', ui.ctrlPad.layPreBtn,'Style', 'pushbutton','FontSize',defFontSize , 'String', '+', 'Callback',{@timingInc,ui});
		set(ui.ctrlPad.layPreSet, 'Sizes', [-1, 200]);
	ui.ctrlPad.layRTSet = uiextras.HBox('Parent',ui.ctrlPad.layBase,'Spacing', 3);
		uicontrol( 'Parent',ui.ctrlPad.layRTSet, 'Style','text','FontSize',defFontSize, 'String', 't0 (s)');
		ui.ctrlPad.RTSetT0 = uicontrol( 'Parent',ui.ctrlPad.layRTSet, 'Style','edit','FontSize', defFontSize, 'String', 0.3);
		uicontrol( 'Parent',ui.ctrlPad.layRTSet, 'Style','text','FontSize',defFontSize, 'String', 'dt (ms)');
		ui.ctrlPad.RTSetDt = uicontrol( 'Parent',ui.ctrlPad.layRTSet, 'Style','edit','FontSize',defFontSize, 'String', 3);
		ui.ctrlPad.RTSetBtn = uicontrol( 'Parent', ui.ctrlPad.layRTSet,'Style', 'pushbutton','FontSize',defFontSize, 'String', 'Send');
	ui.ctrlPad.layTimingState = uiextras.HBox('Parent',ui.ctrlPad.layBase,'Spacing', 3);
		ui.ctrlPad.TimingStateTxt = uicontrol( 'Parent', ui.ctrlPad.layTimingState, 'Style','text','FontSize',defFontSize, 'String' ,'dt=0' ) ;
	set(ui.ctrlPad.layBase, 'Sizes', [-1, 30 , 30]);
end	
%Callback
function openGentimeFig(~,~,ui)
	global ui;
	set(ui.GenTime.fig, 'Visible','on')
end

function genTime(~,~,ui)
	global ui;
	tmpDt=str2num(get(ui.GenTime.edit(5),'String'));
	t0 = [linspace( str2num(get(ui.GenTime.edit(1),'String')) , ...
			str2num(get(ui.GenTime.edit(4),'String')) , ...
			str2num(get(ui.GenTime.edit(2),'String'))  ) , ...
		str2num(get(ui.GenTime.edit(4),'String')) , ...
		ones(1,length(tmpDt)) * str2num(get(ui.GenTime.edit(4),'String')) , ...
		str2num(get(ui.GenTime.edit(4),'String')) ] ;
  	dt= [ zeros(1, str2num(get(ui.GenTime.edit(2),'String')) ) , ...
  		0 , ...
  		tmpDt , ...
  		0 ] ;
	count = [ ones(1, str2num(get(ui.GenTime.edit(2),'String'))) , ...
		str2num(get(ui.GenTime.edit(3),'String')) , ...
		ones(1,length(tmpDt)+1) * str2num(get(ui.GenTime.edit(6),'String')) ] ;

	set(ui.GenTime.fig, 'Visible','off')
	set(ui.ctrlPad.timingTable,'Data',[t0',dt',count']);

end
function timingInc(~,~,ui)
	set(ui.ctrlPad.timingTable,'Data',[get(ui.ctrlPad.timingTable,'Data'); nan(1,3)]);
end
function timingDec(~,~,ui)
	tmp=get(ui.ctrlPad.timingTable,'Data');
	set(ui.ctrlPad.timingTable,'Data',tmp(1:end-1,:));
end