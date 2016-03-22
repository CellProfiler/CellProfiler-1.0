function CPupdatefigurecycle(SetBeingAnalyzed,FigureNumber)
% CPupdatefigurecycle Assigns proper cycle # to figure title

%
% Website: http://www.cellprofiler.org
%

OldText = get(FigureNumber,'name');
NumberSignIndex = find(OldText=='#');
if isempty(NumberSignIndex)
   error(['CPupdatefigurecycle could not locate a number sign (#) in the name field of Figure #' num2str(FigureNumber)])
end
OldTextUpToNumberSign = OldText(1:NumberSignIndex(1));
NewNum = SetBeingAnalyzed;
set(FigureNumber,'name',[OldTextUpToNumberSign,num2str(NewNum)]);