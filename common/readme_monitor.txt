It's for real time monitor program.

Suppose you have 1~3 data set :
x,y,y2

each data set can be vector(1D array) or vector in cell.

So, first creat monitor object.
> mon = monitor (x,y)
You will get a figure of xy plot.
if you want update data.just
> mon.plot(x,y)

What different of plot in matlab ?
This program will fit xtick to xdata, and fast update.


=== argument detail ===
= Parent Handle =
You can specify where to put plot.If did not specify , it will make new figure.
It's good for complex GUI.
> FigHandle = figure()
> mon = monitor (FigHandle , x,y)

= The Data Set =
Program allow max 3 data set , x,y,y2 (y2 not finish).
If you only input 1 , it will be y , x will be number of y.
If you input 2 , it will be x,y . eg.
> t=[0:0.01:2*pi];
> d=sin(t);
> mon1 = monitor (d);	% x of plot will be [1:629]
> mon2 = monitor (t,d);	% x of plot will be t

As above, each data set can be vector(1D array) or vector in cell.
If you want plot multi-line in same time, you should put in cell.
> t=[0:0.01:2*pi];
> y1=sin(t); y2=cos(t); y3=sin(t).*cos(t);
> mon1 = monitor (t , {y1,y2,y3}  );
> mon2 = monitor (  {y1,y2,y3}  );

In mon1, t is vector but it will share to each y. It's for real "time" , so each y should be same size. It will not check in program.
In mon2, program will make 3 x (in cell) for each y.

And,it will dynamic change when you use .plot .

=== Todo ===
I will add below function later .
change title,x/ylabel
can fix y range
finish y2 part.
