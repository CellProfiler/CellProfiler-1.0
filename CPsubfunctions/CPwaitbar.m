function fout = CPwaitbar(varargin)

% This CP function is present only so we can easily replace the
% waitbar if necessary, and also to change colors and fonts to match
% CP's preferences.  See documentation for waitbar for usage.

% $Revision$

is2008b_or_greater = ~CPverLessThan('matlab','7.7');
if is2008b_or_greater && nargin > 2 && ~(ischar(varargin{2}) || iscellstr(varargin{2})),  % Updating previously created waitbar
    fin = varargin{2};
    userData = get(fin,'userdata');
    set(fin,'userdata',userData.FractionInput);
end
fout = waitbar(varargin{:});
userData.Application = 'CellProfiler';
userData.ImageFlag = 0;
if is2008b_or_greater, userData.FractionInput = get(fout,'userdata'); end
set(fout, 'Color', [0.7 0.7 0.9], 'UserData',userData);
    
ax = get(fout, 'Children');
ttl = get(ax, 'Title');
% set(ttl,'Interpreter','none') 
try 
    handles = guidata(gcbo);
    axFontSize = handles.Preferences.FontSize;
    set(ax, 'FontSize', axFontSize);
    set(ttl, 'FontSize', axFontSize);
catch
    set(ax, 'FontSize', 12);
    set(ttl, 'FontSize', 12);
end

p = findobj(fout,'Type','patch');
l = findobj(fout,'Type','line');
set(p, 'FaceColor', [0.3 0.3 0.5]);
set(l, 'Color', [0.3 0.3 0.5]);

return;
