function categories=CPgetpriorcategories(handles, CurrentModuleNum, ObjectOrImageName)

% Get the measurement categories created by modules prior to
% CurrentModuleNum, returning them as cells.
%
% Note: The initial release of this returns all possible categories.
%
%
% Website: http://www.cellprofiler.org
%
categories=[];
for i = 1:(CurrentModuleNum-1)
    SupportsCategories=false;
    for feature=handles.Settings.ModuleSupportedFeatures{i}
        if strcmp(feature,'categories')
            SupportsCategories=true;
        end
    end
    if SupportsCategories
        handles.Current.CurrentModuleNumber=num2str(i);
        categories=unique([categories,...
            feval(handles.Settings.ModuleNames{i},handles,...
                  'categories', ObjectOrImageName)]);
    end
end
if isempty(categories)
    %%% If no categories apparently available, revert to old behavior
    categories = { ...
        'AreaOccupied','AreaShape','Children','Parent','Correlation',...
        'Intensity','Neighbors','Ratio','Texture','RadialDistribution',...
        'Granularity','Location','ImageQuality','Distance','NormDistance',...
        'TrackObjects', 'Math', 'Count'};
end
categories=sort(categories);
