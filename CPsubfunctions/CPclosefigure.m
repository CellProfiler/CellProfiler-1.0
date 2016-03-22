function CPclosefigure(handles,CurrentModule)
%
% This function closes a window for the current set being analyzed.

%
% Website: http://www.cellprofiler.org
%

%%% The figure window display is unnecessary for the calling module, so it is
%%% closed during the starting image cycle.
if handles.Current.SetBeingAnalyzed == handles.Current.StartingImageSet
    ThisModuleFigureNumber = handles.Current.(['FigureNumberForModule',CurrentModule]);
    if any(findobj == ThisModuleFigureNumber)
        close(ThisModuleFigureNumber)
    end
end