function fixcoast (id1,fixids, flag)
% FIXCOAST
%
% Give the id of the polygon to be fixed.  A file polygon.id.new
% will be create with the new, modified polygon,  Optionally,
% give a second id (or array with ids); those polygon are just
% plotted for reference (to see how clsoe your first polygon goes).
%
% The following click-types are supported:
%   d = Delete nearest point (or Left mouse click)
%   f = Enter point number and paint that point red to identify it
%   i = Insert new point between 2 nearest (or Right mouse click)
%   m = move point (next click where it goes)
%   n = Report point number and its coordinates
%   z = allow zoom level to be changed
%   r = reverse direction of the polygon
%   q = ends the editing and saves file
%   a = aborts without saving the edited file
%
% Paul Wessel, June 2013

% Remember that all polygons are closed so x(n) == x(1)

if (nargin == 3)
    offset = flag*360;
else
    offset = 0;
end
% Read in one (or two) polygons
file1 = ['polygon.' num2str(id1)];
load (file1)
x1 = polygon(:,1) - offset;
y1 = polygon(:,2);

% Plot in figure 1 polygon 1 as green line with blue circles at points
figure(1)
clf
pl = plot (x1, y1, 'g-');
hold on
grid on
offset = 0;
pp = plot (x1, y1, '.');
pf = plot (x1(1), y1(1), 'r*', 'MarkerSize', 10);
if (nargin > 1)
% Plot polygon 2 as black line with black circles at points
    n_ids = length (fixids);
    for i=1:n_ids
        file2 = ['polygon.' num2str(fixids(i))];
        load (file2)
        x2 = polygon(:,1);
        y2 = polygon(:,2);
    	plot (x2, y2, 'k-');
        plot (x2, y2, 'k.', 'MarkerSize', 3);
    end
end
%elseif (nargin == 3)
% Plot crossings as red circles at points
%     n_ids = length (fixids);
%     for i=1:n_ids
%         file2 = ['cross.' num2str(fixids(i))];
%         load (file2)
%         x2 = cross(:,1);
%         y2 = cross(:,2);
%     	plot (x2, y2, 'ro');
%         plot (x2, y2, 'ro');
%     end
%end
title ('Zoom in if you need to - then hit return to continue')
pause
title ('Click to start editing - hit q to quit')
ok=1;
fmt = '%.6f';
while (ok == 1)   % Until we press q
    title ('Point and type a to abort, d to delete, m to select for move, i to insert, n for pt #, z for zoom, f to enter point # and paint it red, r to reverse pol direction, q to quit')
    [x0, y0, key] = ginput(1);
    n = length(x1);
    numbers = 1:n;
    n1=n-1;
    k = find_near (x1(1:n1), y1(1:n1), x0, y0);
    if (key == 'd' || key == 1)   % DELETE POINT
        use = find (numbers ~= k(1));
        x1 = x1(use);
        y1 = y1(use);
        if (k(1) == 1) % First point, must replace the duplicate first-last pair
            x1(n-1) = x1(1);
            y1(n-1) = y1(1);
        elseif (k(1) == n) % Last point, must replace the duplicate last-first pair
            x1(1) = x1(n-1);
            y1(1) = y1(n-1);
        end
    elseif (key == 'm')   % MOVE POINT
        title ('Click where you want to move the point')
        [x0, y0, key] = ginput(1);
        x1(k(1)) = x0;
        y1(k(1)) = y0;
        if (k(1) == 1)  % Also move duplicate last point
            x1(n) = x0;
            y1(n) = y0;
        end
    elseif (key == 'f')   % Locate given POINT # and paint it read; remove red if ID < 1
        title ('Enter point number and hit return')
        k = input ('Enter desired point number: ');
        if (k > length(x1))
            disp ('Beyond end of array')
        elseif (k > 0)
            set (pf, 'XData', x1(k), 'YData', y1(k));
        else
           set (pf, 'XData', x1(1), 'YData', y1(1));
        end
    elseif (key == 'n')   % FIND POINT #
        title ('Click on point to determine point number and location')
        [x0, y0, key] = ginput(1);
        k = find_near (x1(1:n1), y1(1:n1), x0, y0);
        k = k(1);
        disp (['Point number ' int2str(k) ' at lon = ' num2str(x1(k),fmt) ' lat = ' num2str(y1(k),fmt) ]);
    elseif (key == 'i' || key == 3)   % INSERT POINT
        if (abs(k(1)-k(2)) == 1)    % Consecutive neighbors
            x1 = [ x1(1:min(k)); x0; x1(max(k):n) ];
            y1 = [ y1(1:min(k)); y0; y1(max(k):n) ];
        elseif (abs(k(1)-k(2)) == (n-2))    % Cut across beginning/end
            x1 = [ x1(1:n1); x0; x1(1) ];
            y1 = [ y1(1:n1); y0; y1(1) ];
        end
    elseif (key == 'z') % Zoom
        title ('Zoom in if you need to - then hit return to continue')
        pause
    elseif (key == 'r') % Reverse direction
        x1 = flipud (x1);
        y1 = flipud (y1);
        title ('Polygon was reversed - hit return to continue')
        pause
    elseif (key == 'q') % QUIT
        ok = 0;
    elseif (key == 'a') % Abort, no write
        ok = 2;
   end
    set (pl, 'XData', x1, 'YData', y1);
    set (pp, 'XData', x1, 'YData', y1);
    title ('Click to start editing - hit any key to quit')
    drawnow
end
if ok == 0
    x1 = x1 + offset;
    % Save modified polygon to new file
    file = ['polygon.' num2str(id1) '.new'];
    fp = fopen (file, 'wt');
    A = [ x1'; y1'];
    fprintf (fp, '%.6f\t%.6f\n', A);
    fclose (fp);
    title (['Done.  Revised file saved to ' file])
else
        title ('Skipped this polygon')
end


function pair = find_near (x, y, x0, y0)
% Return the id's of the two nearest consecutive points
% Quick flat-earth distances used
r = abs ((x - x0).*cosd(0.5*(y+y0)) + sqrt(-1).*(y - y0));
[rsort, i] = sort (r);
pair(1) = i(1);
n = length(x);
if (i(1) == 1)  % First point
    left = n-1;
    right = 2;
elseif (i(1) == n)  % Last point
    left = n-1;
    right = 2;
else
    left = i(1) - 1;
    right = i(1) + 1;
end
if (r(left) < r(right))
    pair(2) = left;
else
    pair(2) = right;
end


