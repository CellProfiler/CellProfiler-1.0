function handles = MeasureObjectNeighbors(handles,varargin)

% Help for the Measure Object Neighbors module:
% Category: Measurement
%
% SHORT DESCRIPTION:
% Calculates how many neighbors each object has.
% *************************************************************************
%
% Given an image with objects identified (e.g. nuclei or cells), this
% module determines how many neighbors each object has. The user selects
% the distance within which objects should be considered neighbors. The
% module can measure the number of neighbors each object has if every
% object were expanded up until the point where it hits another object; to
% use this option, enter 0 (the number zero) for the pixel distance. If you
% want your objects to be touching before you count neighbors (for
% instance, in an image of tissue), use the ExpandOrShrink module to expand
% your objects beforehand.
%
% Features measured:      Feature Number:
% NumberOfNeighbors         |    1
% PercentTouching           |    2
% FirstClosestObjectNumber  |    3
% FirstClosestXVector       |    4
% FirstClosestYVector       |    5
% SecondClosestObjectNumber |    6
% SecondClosestXVector      |    7
% SecondClosestYVector      |    8
% AngleBetweenNeighbors     |    9
%
% How it works: Retrieves objects in label matrix format. The objects
% are expanded by the number of pixels the user specifies, and then
% the module counts up how many other objects the object is
% overlapping.  PercentTouching, if computed, is defined as the number
% of boundary pixels on an object not obscured when other objects are
% dilated by the Neighbor distance limit (or 2 pixels if this distance
% is set to 0 for the maximum expansion option detailed above).
%
% Interpreting the module output:
% In the color image output of the module, there is a color spectrum used
% to determine which objects have neighbors, and how many. According to the
% indices on the spectrum, the background is -1, objects with no neighbors
% are 0, and objects with neighbors are greater than 0, with the increasing
% index corresponding to more neighbors.
%
% Note that the identity of neighbors for each object is saved in the
% output file but that the structure of that data makes it incompatible
% with CellProfiler's export functions. To access this data, you will have
% to use MATLAB.
%
% Saving the objects:
% * You can save the objects colored by number of neighbors to the handles
% structure to be used in other modules. Here, the scalar value 1 is added
% to every pixel so that the background is zero and the objects range from
% 1 up to the highest number of neighbors, plus one. This makes the objects
% compatible with the Convert To Image module.
%
% Saving the image:
% * You can save the grayscale image of objects to the handles structure so
% it can be saved to the hard drive. Here, the background is -1, and the
% objects range from 0 (if it has no neighbors) up to the highest number of
% neighbors. The -1 value makes it incompatible with the Convert To Image
% module which expects a label matrix starting at zero.
%

%
% Website: http://www.cellprofiler.org
%

% MBray 2009_03_20: Comments on variables for pyCP upgrade
%
% Recommended variable order (setting, followed by current variable in MATLAB CP)
% (1) What did you call the objects whose neighbors you want to measure? (ObjectName)
%   [If convenient, have + buttons so the user can add more than one object
%   type. But then you have to synch up the output image question below to each
%   image, so perhaps this is a pain]
%
% (2) Within what distance (in pixels) are objects to be considered
%   neighbors?
%    [Note: the user should enter an integer here, but with two special
%    cases available (perhaps via a dropdown menu?): (a) Only count as
%    neighbors if objects are directly touching. (b) Expand all objects
%    until they touch others, then count neighbors as those directly
%    touching. (NeighborDistance)]
%
% (3) Downstream in the pipeline, do you want to use the image colored
% according to the number of neighbors ? (Yes/no)
%    If yes, "What do you want to call the image colored according to the
%    number of neighbors?"
%
% (4) Downstream in the pipeline, do you want to use the image colored
% according to the percentage of each object's border that touches
% neighbors? (Yes/no)
%    If yes, "What do you want to call the image colored according to the
%    percentage touching?"
%
% Note: In order to avoid the issue of making sure the output image is
% suitable for SaveImages/ConvertToImage, there should be a tag which
% identifies it as a label matrix vs. grayscale, so that other modules can
% handle it properly.
%
% Also, a general display module that we don't have right now stems from
% (3) and (4): can our ShowDataOnImage module (which currently shows
% numerical data superimposed on an image) also have the option to colorize
% objects based on a particular measurement?

%%%%%%%%%%%%%%%%%
%%% VARIABLES %%%
%%%%%%%%%%%%%%%%%

drawnow

[CurrentModule, CurrentModuleNum, ModuleName] = CPwhichmodule(handles);

%textVAR01 = What did you call the objects whose neighbors you want to measure?
%infotypeVAR01 = objectgroup
ObjectName = char(handles.Settings.VariableValues{CurrentModuleNum,1});
%inputtypeVAR01 = popupmenu

%textVAR02 = Objects are considered neighbors if they are within this distance, in pixels. If you want your objects to be touching before you count neighbors (for instance, in an image of tissue), use the ExpandOrShrink module to expand your objects:
%defaultVAR02 = 0
NeighborDistance = str2double(handles.Settings.VariableValues{CurrentModuleNum,2});

%textVAR03 = What do you want to call the objects colored by number of neighbors, which are compatible for converting to a color image using the Convert To Image and Save Images modules?
%defaultVAR03 = Do not use
%infotypeVAR03 = objectgroup indep
ColoredNeighborsName = char(handles.Settings.VariableValues{CurrentModuleNum,3});

%textVAR04 = What do you want to call the image of the objects with grayscale values corresponding to the number of neighbors, which is compatible for saving in .mat format using the Save Images module for further analysis in Matlab?
%defaultVAR04 = Do not use
%infotypeVAR04 = imagegroup indep
GrayscaleNeighborsName = char(handles.Settings.VariableValues{CurrentModuleNum,4});

%textVAR05 = This text is left for consistency with prior versions. Any saved settings shown to the right are not used.

%%%%%%%%%%%%%%%%
%%% FEATURES %%%
%%%%%%%%%%%%%%%%

if nargin > 1
    switch varargin{1}
%feature:categories
        case 'categories'
            if nargin == 1 || strcmp(varargin{2},ObjectName)
                result = { 'Neighbors' };
            else
                result = {};
            end
%feature:measurements
        case 'measurements'
            result = {};
            if nargin >= 3 &&...
                strcmp(varargin{3},'Neighbors') &&...
                strcmp(varargin{2},ObjectName)
                result = {...
                    'NumberOfNeighbors','PercentTouching','FirstClosestObjectNumber',...
                    'FirstClosestXVector','FirstClosestYVector','SecondClosestObjectNumber',...
                    'SecondClosestXVector','SecondClosestYVector','AngleBetweenNeighbors' };
            end
        otherwise
            error(['Unhandled category: ',varargin{1}]);
    end
    handles=result;
    return;
end

%%%VariableRevisionNumber = 5

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% PRELIMINARY CALCULATIONS & FILE HANDLING %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
drawnow

%%% Reads (opens) the image you want to analyze and assigns it to a variable,
%%% "OrigImage".
IncomingLabelMatrixImage = CPretrieveimage(handles,['Segmented', ObjectName],ModuleName,'MustBeGray','DontCheckScale');

%%%%%%%%%%%%%%%%%%%%%%
%%% IMAGE ANALYSIS %%%
%%%%%%%%%%%%%%%%%%%%%%
drawnow

%%% Determines the neighbors for each object.
[sr,sc] = size(IncomingLabelMatrixImage);
ImageOfNeighbors = -ones(sr,sc);
ImageOfPercentTouching = -ones(sr,sc);
NumberOfObjects = max(IncomingLabelMatrixImage(:));

if NumberOfObjects > 0
    NumberOfNeighbors = zeros(NumberOfObjects,1);
    IdentityOfNeighbors = cell(max(NumberOfObjects),1);
    props = regionprops(IncomingLabelMatrixImage,'PixelIdxList');

    % Find structuring element to use for neighbor & perimeter identification.
    switch NeighborDistance,
        case {0, 2},
            se = strel('square', 5);
            d = 2;
        case 1,
            se = strel('square', 3);
            d = 1;
        otherwise,
            se = strel('disk', NeighborDistance);
            d = NeighborDistance;
    end

    % If NeighborDistance is 0, we need to dilate all the labels
    if (NeighborDistance == 0),
        [D, L] = bwdist(IncomingLabelMatrixImage > 0);
        DilatedLabels = IncomingLabelMatrixImage(L);
    end


    if max(IncomingLabelMatrixImage(:)) > 0
        XLocations=handles.Measurements.(ObjectName).Location_Center_X{handles.Current.SetBeingAnalyzed};
        YLocations=handles.Measurements.(ObjectName).Location_Center_Y{handles.Current.SetBeingAnalyzed};
        %%% Compute all pairs distance matrix
        XYLocations = [XLocations, YLocations];
        a = reshape(XYLocations,1,NumberOfObjects,2);
        b = reshape(XYLocations,NumberOfObjects,1,2);
        AllPairsDistance = sqrt(sum((a(ones(NumberOfObjects,1),:,:) - b(:,ones(NumberOfObjects,1),:)).^2,3));
    end

    % Initialize measurements
    [FirstObjectNumber,FirstXVector,FirstYVector,SecondObjectNumber,PercentTouching,...
        SecondXVector,SecondYVector,AngleBetweenTwoClosestNeighbors] = deal(zeros(1,NumberOfObjects));

    for k = 1:NumberOfObjects
        % Cut patch around cell
        [r,c] = ind2sub([sr sc],props(k).PixelIdxList);
        rmax = min(sr,max(r) + (d+1));
        rmin = max(1,min(r) - (d+1));
        cmax = min(sc,max(c) + (d+1));
        cmin = max(1,min(c) - (d+1));
        patch = IncomingLabelMatrixImage(rmin:rmax,cmin:cmax);
        % Extend cell to find neighbors
        if (NeighborDistance > 0),
            extended = imdilate(patch==k,se,'same');
            overlap = patch(extended);
            IdentityOfNeighbors{k} = setdiff(unique(overlap(:)),[0,k]);
            NumberOfNeighbors(k) = length(IdentityOfNeighbors{k});
            ImageOfNeighbors(sub2ind([sr sc],r,c)) = NumberOfNeighbors(k);
        else
            %%% Use the dilated image to find neighbors (don't bother using patches)
            extended = imdilate(DilatedLabels == k, strel('square', 3));
            overlap = DilatedLabels(extended);
            IdentityOfNeighbors{k} = setdiff(unique(overlap(:)),[0,k]);
            NumberOfNeighbors(k) = length(IdentityOfNeighbors{k});
            ImageOfNeighbors(sub2ind([sr sc],r,c)) = NumberOfNeighbors(k);
        end


        %%% PERCENT TOUCHING %%%
        % Find boundary pixel of current cell
        BoundaryPixels = bwperim(patch == k, 8);
        % Remove the current cell, and dilate the other objects
        OtherCellsMask = imdilate((patch > 0) & (patch ~= k), se, 'same');
        PercentTouching(k) = sum(OtherCellsMask(BoundaryPixels)) / sum(BoundaryPixels(:))*100;
        ImageOfPercentTouching(sub2ind([sr sc],r,c)) = PercentTouching(k);
        if NumberOfObjects >= 3
            %%% CLOSEST NEIGHBORS %%%
            DistancesFromCurrent = AllPairsDistance(k, :);
            [Dists, Indices] = sort(DistancesFromCurrent);
            FirstObjectNumber(k) = Indices(2);
            FirstXVector(k) = XLocations(FirstObjectNumber(k)) - XLocations(k);
            FirstYVector(k) = YLocations(FirstObjectNumber(k)) - YLocations(k);
            SecondObjectNumber(k) = Indices(3);
            SecondXVector(k) = XLocations(SecondObjectNumber(k)) - XLocations(k);
            SecondYVector(k) = YLocations(SecondObjectNumber(k)) - YLocations(k);
            Vec1 = [FirstXVector(k) FirstYVector(k)];
            Vec2 = [SecondXVector(k) SecondYVector(k)];
            AngleBetweenTwoClosestNeighbors(k) = real(acosd(dot(Vec1, Vec2) / (norm(Vec1) * norm(Vec2))));
        elseif NumberOfObjects == 2,
            %%% CLOSEST NEIGHBORS %%%
            if k == 1,
                FirstObjectNumber(k) = 2;
            else
                FirstObjectNumber(k) = 1;
            end
            FirstXVector(k) = XLocations(FirstObjectNumber(k)) - XLocations(k);
            FirstYVector(k) = YLocations(FirstObjectNumber(k)) - YLocations(k);
            SecondObjectNumber(k) = 0;
            SecondXVector(k) = 0;
            SecondYVector(k) = 0;
            AngleBetweenTwoClosestNeighbors(k) = 0;
        end
    end
else
    DilatedLabels = zeros(size(IncomingLabelMatrixImage));
    NumberOfNeighbors = [];
    PercentTouching = [];
    FirstObjectNumber = [];
    FirstXVector = [];
    FirstYVector = [];
    SecondObjectNumber = [];
    SecondXVector = [];
    SecondYVector = [];
    AngleBetweenTwoClosestNeighbors = [];
    IdentityOfNeighbors = cell(0,1);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% MAKE MEASUREMENTS & SAVE TO HANDLES STRUCTURE %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
drawnow

handles = CPaddmeasurements(handles, ObjectName, ...
    ['Neighbors_NumberOfNeighbors_' num2str(NeighborDistance)], NumberOfNeighbors);

%%% Saves neighbor measurements to handles structure.
handles = CPaddmeasurements(handles, ObjectName, ...
            ['Neighbors_PercentTouching_' num2str(NeighborDistance)], PercentTouching');
handles = CPaddmeasurements(handles, ObjectName, ...
            ['Neighbors_FirstClosestObjectNumber_' num2str(NeighborDistance)], ...
            FirstObjectNumber');
handles = CPaddmeasurements(handles, ObjectName, ...
            ['Neighbors_FirstClosestXVector_' num2str(NeighborDistance)], ...
            FirstXVector');
handles = CPaddmeasurements(handles, ObjectName, ...
            ['Neighbors_FirstClosestYVector_' num2str(NeighborDistance)], ...
            FirstYVector');
handles = CPaddmeasurements(handles, ObjectName, ...
            ['Neighbors_SecondClosestObjectNumber_' num2str(NeighborDistance)], ...
            SecondObjectNumber');
handles = CPaddmeasurements(handles, ObjectName, ...
            ['Neighbors_SecondClosestXVector_' num2str(NeighborDistance)], ...
            SecondXVector');
handles = CPaddmeasurements(handles, ObjectName, ...
            ['Neighbors_SecondClosestYVector_' num2str(NeighborDistance)], ...
            SecondYVector');
handles = CPaddmeasurements(handles, ObjectName, ...
            ['Neighbors_AngleBetweenNeighbors_' num2str(NeighborDistance)], ...
            AngleBetweenTwoClosestNeighbors');


% This field is different from the usual measurements.  It is one of
% the very few places in the CP codebase where we don't use
% CPaddmeasurements.  There is special code in CPconvertsql that
% recognizes Neighbors as a special field of Measurements and refrains
% from exporting it.
%
% Example: To extract the number of neighbor for objects called Cells, use code like this:
%   handles.Measurements.Neighbors.IdentityOfNeighborsCells{1}{3}
% where 1 is the image number and 3 is the object number. This
% yields a list of the objects who are neighbors with Cell object 3.
handles.Measurements.Neighbors.IdentityOfNeighbors(handles.Current.SetBeingAnalyzed) = {IdentityOfNeighbors};

%%%

%%%%%%%%%%%%%%%%%%%%%%%
%%% DISPLAY RESULTS %%%
%%%%%%%%%%%%%%%%%%%%%%%
drawnow

ThisModuleFigureNumber = handles.Current.(['FigureNumberForModule',CurrentModule]);
if any(findobj == ThisModuleFigureNumber)
    %%% Calculates the ColoredIncomingObjectsImage for displaying in the figure
    %%% window and saving to the handles structure.
    ColoredIncomingObjectsImage = CPlabel2rgb(handles,IncomingLabelMatrixImage);

    %%% Activates the appropriate figure window.
    CPfigure(handles,'Image',ThisModuleFigureNumber);
    if handles.Current.SetBeingAnalyzed == handles.Current.StartingImageSet
        CPresizefigure(IncomingLabelMatrixImage,'TwoByTwo',ThisModuleFigureNumber)
    end
    hAx=subplot(2,2,1,'Parent',ThisModuleFigureNumber);
    CPimagesc(ColoredIncomingObjectsImage,handles,hAx);
    axis(hAx,'image');
    title(hAx,ObjectName);

    hAx=subplot(2,2,2,'Parent',ThisModuleFigureNumber);
    CPimagesc(ImageOfNeighbors,handles,hAx);
    axis(hAx,'image');
    colormap(hAx,handles.Preferences.LabelColorMap);
    cbar_handle = colorbar('EastOutside','peer',hAx);

    % Ensure that colorbar minimum is >=0, if possible
    ylim = get(cbar_handle,'YLim');
    clim = [max([ylim(1) 0]) ylim(2)];
    if diff(clim) <= 0, clim = ylim; end
    set(cbar_handle,'YLim',clim)

    title(hAx,[ObjectName,' colored by number of neighbors']);

    if (NeighborDistance == 0),
        hAx = subplot(2,2,3,'Parent',ThisModuleFigureNumber);
        CPimagesc(CPlabel2rgb(handles, DilatedLabels), handles,hAx);
        axis(hAx,'image');
        title(hAx,['Fully expanded ' ObjectName]);
    end

    hAx = subplot(2,2,4,'Parent',ThisModuleFigureNumber);
	CPimagesc(ImageOfPercentTouching,handles,hAx);
	axis(hAx,'image');
	colormap(hAx,handles.Preferences.LabelColorMap)
	cbar_handle = colorbar('EastOutside','peer',hAx);

	% Ensure that colorbar minimum is >=0, if possible
    ylim = get(cbar_handle,'YLim');
    clim = [max([ylim(1) 0]) ylim(2)];
    if diff(clim) <= 0, clim = ylim; end
    set(cbar_handle,'YLim',clim)

    title(hAx,[ObjectName,' colored by percent touching'])

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% SAVE IMAGES TO HANDLES STRUCTURE %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
drawnow

%%% Saves the grayscale image of objects to the handles structure so
%%% they can be saved to the hard drive, if the user requests. Here, the
%%% background is -1, and the objects range from 0 (if it has no neighbors)
%%% up to the highest number of neighbors. The -1 value makes it
%%% incompatible with the Convert To Image module which expects a label
%%% matrix starting at zero.
if ~strcmpi(GrayscaleNeighborsName,'Do not use')
    handles = CPaddimages(handles,GrayscaleNeighborsName,ImageOfNeighbors);
end

%%% Saves the objects colored by number of neighbors to the handles
%%% structure to be used in other modules.
%%% Here, the scalar value 1 is added to every pixel so that the background
%%% is zero and the objects are from 1 up to the highest number of
%%% neighbors, plus one. This makes the objects compatible with the Convert
%%% To Image module.
if ~strcmpi(ColoredNeighborsName,'Do not use')
    handles = CPaddimages(handles,['Segmented',ColoredNeighborsName],ImageOfNeighbors+1);
end