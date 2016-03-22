% CPSAVEOBJECTCOUNT Save the count of segmented objects.
%   The function returns a new version of the handles structure, in which
%   the number of segmented objects has been saved.
%
%   Example:
%      handles = CPsaveObjectCount(handles, 'Cells', labelMatrix)
%      creates handles.Measurements.Cells{i}.Count_Cells.
function handles = CPsaveObjectCount(handles, objectName, labels)
%
%
% Website: http://www.cellprofiler.org
%
handles = CPaddmeasurements(handles, 'Image', ...
                            CPjoinstrings('Count', objectName), ...
                            max(labels(:)));
