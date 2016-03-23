function [im, handles]=CPlabel2rgb(handles, image)

%
% Website: http://www.cellprofiler.org
%

%%% Note that the label2rgb function doesn't work when there are no objects
%%% in the label matrix image, so there is an "if".
if sum(sum(image)) >= 1
    cmap = eval([handles.Preferences.LabelColorMap '(max(2,max(image(:))))']);
    im = label2rgb(image, cmap, 'k', 'shuffle');
else
    im=image;
end



