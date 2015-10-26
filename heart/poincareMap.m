function varargout = poincareMap(data,varargin)
% Plot 3D poincare Map in new figure and return figure handle when
% exist out variable .

switch nargin
	case 2
		addTitle = true ;
end

data = reshape(data, [],1);

fig=figure;
hold on;
%	2D use this :
% 	x=pks(1:end-1);
% 	y=pks(2:end);
% 	u=[diff(x);0];
% 	v=[diff(y);0];
% 	quiver(x,y,u,v,'k');
x=data(1:end-2);
y=data(2:end-1);
z=data(3:end);
u=[diff(x);0];
v=[diff(y);0];
w=[diff(z);0];
quiver3(x,y,z,u,v,w,'k');
plot3(x,y,z,'b:',x,y,z,'r*');

if exist('addTitle', 'var') && addTitle
	title(varargin{1},'Interpreter', 'none');
else
	title('Poincare Map','Interpreter', 'none');
end
xlabel('peak(n) mmHg');
ylabel('peak(n+1) mmHg');
zlabel('peak(n+2)');
hold off;

set (gcf,'PaperUnits','point','PaperPosition',[0 0 400 400])  %should use pixels

%print(gcf,'-dpng',fullfile(path,[f_name,'.png']))

if nargout
	varargout{1} = fig ;
end