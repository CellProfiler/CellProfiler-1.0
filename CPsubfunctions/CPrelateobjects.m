function [handles,ChildCounts,ParentList] = CPrelateobjects(handles,ChildName,ParentName,ChildLabelMatrix,ParentLabelMatrix,ModuleName)
% function [handles,ChildCounts,ParentList] = CPrelateobjects(handles,ChildName,ParentName,ChildLabelMatrix,ParentLabelMatrix,ModuleName)
%
% This function does the heavy lifting of relating child objects to
% parents.  It returns the number of children for each parent in
% ChildCounts and the map from children to parent in ParentList.
%
% It also updates the handles.Measurements with these values (.Parent
% for children, .Children (just a count) for parents).

%
% Website: http://www.cellprofiler.org
%

%%% First, we need to make sure the two matrices are the same size.
if size(ChildLabelMatrix) ~= size(ParentLabelMatrix),
    %%% For the cases where the ChildLabelMatrix was produced from a
    %%% cropped version of the ParentLabelMatrix, the sizes of the
    %%% matrices will not be equal. So, we try cropping the
    %%% ParentLabelMatrix to see if the matrices are then the proper
    %%% size.

    %%% Removes Rows and Columns that are completely blank.
    ColumnTotals = sum(ParentLabelMatrix,1);
    RowTotals = sum(ParentLabelMatrix,2)';

    % Is this necessary? - Ray 2007-08-09
    warningstate = warning('off', 'all');
    ColumnsToDelete = ~logical(ColumnTotals);
    RowsToDelete = ~logical(RowTotals);
    warning(warningstate)

    CroppedParentLabelMatrix = ParentLabelMatrix;
    CroppedParentLabelMatrix(:,ColumnsToDelete,:) = [];
    CroppedParentLabelMatrix(RowsToDelete,:,:) = [];
    %%% In case the entire image has been cropped away, we store a single
    %%% zero pixel for the variable.
    if isempty(CroppedParentLabelMatrix)
        CroppedParentLabelMatrix = 0;
    end
    %%% And we check if sizes are the same, now.
    if size(ChildLabelMatrix) ~= size(CroppedParentLabelMatrix),
        error(['Image processing was canceled in the ',ModuleName, ' module because the parent and children objects you are trying to relate come from images that are not the same size.']);
    else
        % They match, so replace the parent matrix with its cropped version.
        ParentLabelMatrix = CroppedParentLabelMatrix;
    end
end

%%% Get the number of children and parents in the label matrices.
NumberOfParents = max(ParentLabelMatrix(:));
NumberOfSubobjects = max(ChildLabelMatrix(:));

%%% We want to choose a child's parent based on the most overlapping
%%% parent.  We first find all pixels that are in both a child and a
%%% parent, as we wish to ignore pixels that are background in either
%%% labelmatrix.
BothForegroundMask = (ChildLabelMatrix > 0) & (ParentLabelMatrix > 0);

%%% Use the Matlab full(sparse()) trick to create a 2D histogram of
%%% child/parent overlap counts.
ParentChildLabelHistogram = full(sparse(ParentLabelMatrix(BothForegroundMask), ChildLabelMatrix(BothForegroundMask), 1, NumberOfParents, NumberOfSubobjects));

%%% Make sure there are overlapping parents and children
if any(ParentChildLabelHistogram(:)),
    %%% For each child, we must choose a single parent.  We will choose
    %%% this by maximum overlap, which in this case is maximum value in
    %%% the child's column in the histogram.  sort() will give us the
    %%% necessary parent (row) index as its second return argument.
    [OverlapCounts, ParentIndexes] = sort(ParentChildLabelHistogram,1);

    % Get the parent list.
    ParentList = ParentIndexes(end, :);

    % handle the case of a zero overlap -> no parent
    ParentList(OverlapCounts(end, :) == 0) = 0;

    % transpose to a column vector
    ParentList = ParentList';

    %%% Now we need the number of children for each parent.  We can get
    %%% this as a histogram, again.  Must only use children that actually
    %%% have a parent.
    ChildCounts = full(sparse(ParentList(ParentList > 0), 1, 1, NumberOfParents, 1));
else
    %%% No overlapping parents or children.
    ChildCounts = zeros(NumberOfParents, 1);
    ParentList = zeros(NumberOfSubobjects, 1);
end

%%% Add the new measurements to the handles
handles = CPaddmeasurements(handles, ChildName, ['Parent_', ParentName], ...
			    ParentList);
handles = CPaddmeasurements(handles, ParentName, ...
			    ['Children_', ChildName, '_Count'], ...
			    ChildCounts);
