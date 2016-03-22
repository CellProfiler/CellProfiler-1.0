function handles = IdentifySecondary(handles)

% Help for the Identify Secondary module:
% Category: Object Processing
%
% SHORT DESCRIPTION:
% Identifies objects (e.g. cell edges) using "seed" objects identified by
% an Identify Primary module (e.g. nuclei).
% *************************************************************************
%
% This module identifies secondary objects (e.g. cell edges) based on two
% inputs: (1) a previous module's identification of primary objects (e.g.
% nuclei) and (2) an image stained for the secondary objects (not required
% for the Distance - N option). Each primary object is assumed to be completely
% within a secondary object (e.g. nuclei are completely within cells
% stained for actin).
%
% It accomplishes two tasks:
% (a) finding the dividing lines between secondary objects which touch each
% other. Three methods are available: Propagation, Watershed (an older
% version of Propagation), and Distance.
% (b) finding the dividing lines between the secondary objects and the
% background of the image. This is done by thresholding the image stained
% for secondary objects, except when using Distance - N.
%
% Settings:
%
% Methods to identify secondary objects:
% * Propagation - For task (a), this method will find dividing lines
% between clumped objects where the image stained for secondary objects
% shows a change in staining (i.e. either a dimmer or a brighter line).
% Smoother lines work better, but unlike the watershed method, small gaps
% are tolerated. This method is considered an improvement on the
% traditional watershed method. The dividing lines between objects are
% determined by a combination of the distance to the nearest primary object
% and intensity gradients. This algorithm uses local image similarity to
% guide the location of boundaries between cells. Boundaries are
% preferentially placed where the image's local appearance changes
% perpendicularly to the boundary. Reference: TR Jones, AE Carpenter, P
% Golland (2005) Voronoi-Based Segmentation of Cells on Image Manifolds,
% ICCV Workshop on Computer Vision for Biomedical Image Applications, pp.
% 535-543. For task (b), thresholding is used.
%
% * Watershed - For task (a), this method will find dividing lines between
% objects by looking for dim lines between objects. For task (b),
% thresholding is used. Reference: Vincent, Luc, and Pierre Soille,
% "Watersheds in Digital Spaces: An Efficient Algorithm Based on Immersion
% Simulations," IEEE Transactions of Pattern Analysis and Machine
% Intelligence, Vol. 13, No. 6, June 1991, pp. 583-598.
%
% * Distance - This method is bit unusual because the edges of the primary
% objects are expanded a specified distance to create the secondary
% objects. For example, if nuclei are labeled but there is no stain to help
% locate cell edges, the nuclei can simply be expanded in order to estimate
% the cell's location. This is often called the 'doughnut' or 'annulus' or
% 'ring' approach for identifying the cytoplasmic compartment. Using the
% Distance - N method, the image of the secondary staining is not used at
% all, and these expanded objects are the final secondary objects. Using
% the Distance - B method, thresholding is used to eliminate background
% regions from the secondary objects. This allows the extent of the
% secondary objects to be limited to a certain distance away from the edge
% of the primary objects.
%
% Select automatic thresholding method or enter an absolute threshold:
%    The threshold affects the stringency of the lines between the objects
% and the background. See the help for the IdentifyPrimAutomatic module for
% a complete description of the options. Per object methods may be used for
% cases where the secondary object is completely contained within a
% second primary object, perhaps making a per-object threshold preferable
% for determining the secondary object boudanries.
%
% Threshold correction factor:
% When the threshold is calculated automatically, it may consistently be
% too stringent or too lenient. You may need to enter an adjustment factor
% which you empirically determine is suitable for your images. The number 1
% means no adjustment, 0 to 1 makes the threshold more lenient and greater
% than 1 (e.g. 1.3) makes the threshold more stringent. For example, the
% Otsu automatic thresholding inherently assumes that 50% of the image is
% covered by objects. If a larger percentage of the image is covered, the
% Otsu method will give a slightly biased threshold that may have to be
% corrected using a threshold correction factor.
%
% Lower and upper bounds on threshold:
% Can be used as a safety precaution when the threshold is calculated
% automatically. For example, if there are no objects in the field of view,
% the automatic threshold will be unreasonably low. In such cases, the
% lower bound you enter here will override the automatic threshold.
%
% Approximate percentage of image covered by objects:
% An estimate of how much of the image is covered with objects. This
% information is currently only used in the MoG (Mixture of Gaussian)
% thresholding but may be used for other thresholding methods in the future
% (see below).
%
% Regularization factor (for propagation method only):
% This method takes two factors into account when deciding where to draw
% the dividing line between two touching secondary objects: the distance to
% the nearest primary object, and the intensity of the secondary object
% image. The regularization factor controls the balance between these two
% considerations: A value of zero means that the distance to the nearest
% primary object is ignored and the decision is made entirely on the
% intensity gradient between the two competing primary objects. Larger
% values weight the distance between the two values more and more heavily.
% The regularization factor can be infinitely large, but around 10 or so,
% the intensity image is almost completely ignored and the dividing line
% will simply be halfway between the two competing primary objects.
%
% Note: Primary identify modules produce two (hidden) output images that
% are used by this module. The Segmented image contains the final, edited
% primary objects (i.e. objects at the border and those that are too small
% or large have been excluded). The SmallRemovedSegmented image is the
% same except that the objects at the border and the large objects have
% been included. These extra objects are used to perform the identification
% of secondary object outlines, since they are probably real objects (even
% if we don't want to measure them). Small objects are not used at this
% stage because they are more likely to be artifactual, and so they
% therefore should not "claim" any secondary object pixels.
%
% TECHNICAL DESCRIPTION OF THE PROPAGATION OPTION:
% Propagate labels from LABELS_IN to LABELS_OUT, steered by IMAGE and
% limited to MASK. MASK should be a logical array. LAMBDA is a
% regularization parameter, larger being closer to Euclidean distance in
% the image plane, and zero being entirely controlled by IMAGE. Propagation
% of labels is by shortest path to a nonzero label in LABELS_IN. Distance
% is the sum of absolute differences in the image in a 3x3 neighborhood,
% combined with LAMBDA via sqrt(differences^2 + LAMBDA^2). Note that there
% is no separation between adjacent areas with different labels (as there
% would be using, e.g., watershed). Such boundaries must be added in a
% postprocess. IdentifySecPropagateSubfunction is the subfunction
% implemented in C and MEX to perform the propagate algorithm.
%
% IdentifySecPropagateSubfunction.cpp is the source code, in C++
% IdentifySecPropagateSubfunction.dll is compiled for windows
% IdentifySecPropagateSubfunction.mexmac is compiled for macintosh
% IdentifySecPropagateSubfunction.mexglx is compiled for linux
% IdentifySecPropagateSubfunction.mexa64 is compiled for 64-bit linux
%
% To compile IdentifySecPropagateSubfunction for different operating
% systems, you will need to log on to that operating system and at the
% command line of MATLAB enter:
% mex IdentifySecPropagateSubfunction
%
% See also Identify primary modules.

%
% Website: http://www.cellprofiler.org
%

%%%%%%%%%%%%%%%%%
%%% VARIABLES %%%
%%%%%%%%%%%%%%%%%

[CurrentModule, CurrentModuleNum, ModuleName] = CPwhichmodule(handles);

%%% Sets up loop for test mode.
if strcmp(char(handles.Settings.VariableValues{CurrentModuleNum,12}),'Yes')
    IdentChoiceList = {'Distance - N' 'Distance - B' 'Watershed' 'Propagation'};
else
    IdentChoiceList = {char(handles.Settings.VariableValues{CurrentModuleNum,3})};
end

%textVAR01 = What did you call the primary objects you want to create secondary objects around?
%infotypeVAR01 = objectgroup
PrimaryObjectName = char(handles.Settings.VariableValues{CurrentModuleNum,1});
%inputtypeVAR01 = popupmenu

%textVAR02 = What do you want to call the objects identified by this module?
%defaultVAR02 = Cells
%infotypeVAR02 = objectgroup indep
SecondaryObjectName = char(handles.Settings.VariableValues{CurrentModuleNum,2});

%textVAR03 = Select the method to identify the secondary objects (Distance - B uses background; Distance - N does not):
%choiceVAR03 = Propagation
%choiceVAR03 = Watershed
%choiceVAR03 = Distance - N
%choiceVAR03 = Distance - B
%inputtypeVAR03 = popupmenu
OriginalIdentChoice = char(handles.Settings.VariableValues{CurrentModuleNum,3});

%textVAR04 = What did you call the images to be used to find the edges of the secondary objects? For DISTANCE - N, this will not affect object identification, only the final display.
%infotypeVAR04 = imagegroup
ImageName = char(handles.Settings.VariableValues{CurrentModuleNum,4});
%inputtypeVAR04 = popupmenu

%textVAR05 = Select an automatic thresholding method or enter an absolute threshold in the range [0,1]. To choose a binary image, select "Other" and type its name.  Choosing 'All' will use the Otsu Global method to calculate a single threshold for the entire image group. The other methods calculate a threshold for each image individually. Set interactively will allow you to manually adjust the threshold during the first cycle to determine what will work well.
%choiceVAR05 = Otsu Global
%choiceVAR05 = Otsu Adaptive
%choiceVAR05 = Otsu PerObject
%choiceVAR05 = MoG Global
%choiceVAR05 = MoG Adaptive
%choiceVAR05 = MoG PerObject
%choiceVAR05 = Background Global
%choiceVAR05 = Background Adaptive
%choiceVAR05 = Background PerObject
%choiceVAR05 = RobustBackground Global
%choiceVAR05 = RobustBackground Adaptive
%choiceVAR05 = RobustBackground PerObject
%choiceVAR05 = RidlerCalvard Global
%choiceVAR05 = RidlerCalvard Adaptive
%choiceVAR05 = RidlerCalvard PerObject
%choiceVAR05 = Kapur Global
%choiceVAR05 = Kapur Adaptive
%choiceVAR05 = Kapur PerObject
%choiceVAR05 = All
%choiceVAR05 = Set interactively
Threshold = char(handles.Settings.VariableValues{CurrentModuleNum,5});
%inputtypeVAR05 = popupmenu custom

%textVAR06 = Threshold correction factor
%defaultVAR06 = 1
ThresholdCorrection = str2double(char(handles.Settings.VariableValues{CurrentModuleNum,6}));

%textVAR07 = Lower and upper bounds on threshold, in the range [0,1]
%defaultVAR07 = 0,1
ThresholdRange = char(handles.Settings.VariableValues{CurrentModuleNum,7});

%textVAR08 = For MoG thresholding, what is the approximate fraction of image covered by objects?
%choiceVAR08 = 0.01
%choiceVAR08 = 0.1
%choiceVAR08 = 0.2
%choiceVAR08 = 0.3
%choiceVAR08 = 0.4
%choiceVAR08 = 0.5
%choiceVAR08 = 0.6
%choiceVAR08 = 0.7
%choiceVAR08 = 0.8
%choiceVAR08 = 0.9
%choiceVAR08 = 0.99
pObject = char(handles.Settings.VariableValues{CurrentModuleNum,8});
%inputtypeVAR08 = popupmenu custom

%textVAR09 = For DISTANCE, enter the number of pixels by which to expand the primary objects [Positive integer]
%defaultVAR09 = 10
DistanceToDilate = str2double(char(handles.Settings.VariableValues{CurrentModuleNum,9}));

%textVAR10 = For PROPAGATION, enter the regularization factor (0 to infinity). Larger=distance,0=intensity
%defaultVAR10 = 0.05
RegularizationFactor = str2double(char(handles.Settings.VariableValues{CurrentModuleNum,10}));

%textVAR11 = What do you want to call the outlines of the identified objects (optional)?
%defaultVAR11 = Do not use
%infotypeVAR11 = outlinegroup indep
SaveOutlines = char(handles.Settings.VariableValues{CurrentModuleNum,11});

%textVAR12 = Do you want to run in test mode where each method for identifying secondary objects is compared?
%choiceVAR12 = No
%choiceVAR12 = Yes
TestMode = char(handles.Settings.VariableValues{CurrentModuleNum,12});
%inputtypeVAR12 = popupmenu

%%%VariableRevisionNumber = 3

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% PRELIMINARY CALCULATIONS & FILE HANDLING %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Reads (opens) the image you want to analyze and assigns it to a
%%% variable.
OrigImage = CPretrieveimage(handles,ImageName,ModuleName,'MustBeGray','CheckScale');
OrigImage = double(OrigImage);

%%% Retrieves the preliminary label matrix image that contains the primary
%%% segmented objects which have only been edited to discard objects
%%% that are smaller than a certain size.  This image
%%% will be used as markers to segment the secondary objects with this
%%% module.  Checks first to see whether the appropriate image exists.
PrelimPrimaryLabelMatrixImage = CPretrieveimage(handles,['SmallRemovedSegmented', PrimaryObjectName],ModuleName,'DontCheckColor','DontCheckScale',size(OrigImage));

%%% Retrieves the label matrix image that contains the edited primary
%%% segmented objects which will be used to weed out which objects are
%%% real - not on the edges and not below or above the specified size
%%% limits. Checks first to see whether the appropriate image exists.
EditedPrimaryLabelMatrixImage = CPretrieveimage(handles,['Segmented', PrimaryObjectName],ModuleName,'DontCheckColor','DontCheckScale',size(OrigImage));

%%% Converts the EditedPrimaryBinaryImage to binary.
EditedPrimaryBinaryImage = im2bw(EditedPrimaryLabelMatrixImage,.5);

%%% Chooses the first word of the method name (removing 'Global' or 'Adaptive').
ThresholdMethod = strtok(Threshold);
%%% Checks if a custom entry was selected for Threshold, which means we are using an incoming binary image rather than calculating a threshold.
if isempty(strmatch(ThresholdMethod,{'Otsu','MoG','Background','RobustBackground','RidlerCalvard','Kapur','All','Set'},'exact'))
    if isnan(str2double(Threshold))
        GetThreshold = 0;
        BinaryInputImage = CPretrieveimage(handles,Threshold,ModuleName,'MustBeGray','CheckScale');
    else
        GetThreshold = 1;
    end
else
    GetThreshold = 1;
end

%%% Checks that the Min and Max threshold bounds have valid values
index = strfind(ThresholdRange,',');
if isempty(index)
    error(['Image processing was canceled in the ', ModuleName, ' module because the Min and Max threshold bounds are invalid.'])
end

MinimumThreshold = ThresholdRange(1:index-1);
MaximumThreshold = ThresholdRange(index+1:end);

%%%%%%%%%%%%%%%%%%%%%%
%%% IMAGE ANALYSIS %%%
%%%%%%%%%%%%%%%%%%%%%%

%%% STEP 1: Marks at least some of the background by applying a
%%% weak threshold to the original image of the secondary objects.
if GetThreshold
    if (length(IdentChoiceList) == 1) && strcmp(IdentChoiceList{1}, 'Distance -N'),
        Threshold = 0;
    else
        [handles,Threshold,WeightedVariance,SumOfEntropies] = CPthreshold(handles,Threshold,pObject,MinimumThreshold,MaximumThreshold,ThresholdCorrection,OrigImage,ImageName,ModuleName,SecondaryObjectName);
    end
else Threshold = 0; % should never be used
end
%%% ANNE REPLACED THIS LINE 11-06-05.
%%% Thresholds the original image.
% ThresholdedOrigImage = im2bw(OrigImage, Threshold);

%%% Thresholds the original image.
if GetThreshold
    ThresholdedOrigImage = OrigImage > Threshold;
else
    ThresholdedOrigImage = logical(BinaryInputImage);
end
Threshold = mean(Threshold(:));       % Use average threshold downstreams


for IdentChoiceNumber = 1:length(IdentChoiceList)

    IdentChoice = IdentChoiceList{IdentChoiceNumber};

    if strncmp(IdentChoice,'Distance',8)
        if strcmp(IdentChoice(12),'N')
            %%% Dilate primary objects, and find nearest pixel in original label.
            [dist, Labels] = bwdist(full(PrelimPrimaryLabelMatrixImage>0));
            DilatedPrelimSecObjectBinaryImage = dist < DistanceToDilate;

            %%% Remaps labels in Labels to labels in PrelimPrimaryLabelMatrixImage.

            if max(Labels(:)) == 0,
                Labels = ones(size(Labels));
            end
            ExpandedRelabeledDilatedPrelimSecObjectImage = PrelimPrimaryLabelMatrixImage(Labels);
            %%% Removes the background pixels (those not labeled as foreground in the
            %%% DilatedPrelimSecObjectBinaryImage). This is necessary because the
            %%% nearest neighbor function assigns *every* pixel to a nucleus, not just
            %%% the pixels that are part of a secondary object.
            RelabeledDilatedPrelimSecObjectImage = zeros(size(ExpandedRelabeledDilatedPrelimSecObjectImage));
            RelabeledDilatedPrelimSecObjectImage(DilatedPrelimSecObjectBinaryImage) = ExpandedRelabeledDilatedPrelimSecObjectImage(DilatedPrelimSecObjectBinaryImage);
        elseif strcmp(IdentChoice(12),'B')
            [labels_out,d]=IdentifySecPropagateSubfunction(PrelimPrimaryLabelMatrixImage,OrigImage,ThresholdedOrigImage,1.0);
            labels_out(d>DistanceToDilate) = 0;
            labels_out((PrelimPrimaryLabelMatrixImage > 0)) = PrelimPrimaryLabelMatrixImage((PrelimPrimaryLabelMatrixImage > 0));
            RelabeledDilatedPrelimSecObjectImage = labels_out;
        end

        %%% Removes objects that are not in the edited EditedPrimaryLabelMatrixImage.
        Map = sparse(1:numel(PrelimPrimaryLabelMatrixImage), PrelimPrimaryLabelMatrixImage(:)+1, EditedPrimaryLabelMatrixImage(:));
        LookUpColumn = full(max(Map,[], 1));
        LookUpColumn(1)=0;
        FinalLabelMatrixImage = LookUpColumn(RelabeledDilatedPrelimSecObjectImage+1);

    elseif strcmp(IdentChoice,'Propagation')
        %%% STEP 2: Starting from the identified primary objects, the secondary
        %%% objects are identified using the propagate function, written by Thouis
        %%% R. Jones. Calls the function
        %%% "IdentifySecPropagateSubfunction.mexmac" (or whichever version is
        %%% appropriate for the computer platform being used), which consists of C
        %%% code that has been compiled to run quickly within Matlab.

        % 2007-Jul-16 Kyungnam: If you want to get additional outputs, then
        % add more output arguments as follows:
        %%% [PropagatedImage, dist, diff_count, pop_count] = IdentifySecPropagateSubfunction(PrelimPrimaryLabelMatrixImage,OrigImage,ThresholdedOrigImage,RegularizationFactor);
        PropagatedImage = IdentifySecPropagateSubfunction(PrelimPrimaryLabelMatrixImage,OrigImage,ThresholdedOrigImage,RegularizationFactor);

        %%% STEP 3: We used the PrelimPrimaryLabelMatrixImage as the
        %%% source for primary objects, but that label-matrix is built
        %%% before small/large objects and objects touching the
        %%% boundary are removed.  We need to filter the label matrix
        %%% from propagate to make the labels match, and remove any
        %%% secondary objects that correspnd to size- or
        %%% boundary-filtered primaries.
        %%%
        %%% Map preliminary labels to edited labels based on maximum
        %%% overlap from prelim to edited.  We can probably assume
        %%% that no borders are adjusted during editing (i.e., any
        %%% changes from Prelim to Edited only involves removing
        %%% entire objects), but this is safer.
        %%%
        %%% (add one so that zeros are remapped correctly.)
        PrelimToEditedHist = sparse(EditedPrimaryLabelMatrixImage(:) + 1, PrelimPrimaryLabelMatrixImage(:) + 1, 1);
        [ignore, PrelimToEditedRemap] = sort(PrelimToEditedHist, 1);
        PrelimToEditedRemap = PrelimToEditedRemap(end, :) - 1;
        %%% make sure zeros map to zeros (note the off-by-one for the
        %%% index because Matlab doesn't do 0-indexing).
        PrelimToEditedRemap(1) = 0;
        EditedLabelMatrixImage = PrelimToEditedRemap(PropagatedImage + 1);

        %%% STEP 4:
        %%%
        %%% Fill holes (any contiguous, all-0 regions that are
        %%% surrounded by a single value).
        FinalLabelMatrixImage = CPfill_holes(EditedLabelMatrixImage);

    elseif strcmp(IdentChoice,'Watershed')
        %%% In order to use the watershed transform to find dividing lines between
        %%% the secondary objects, it is necessary to identify the foreground
        %%% objects and to identify a portion of the background.  The foreground
        %%% objects are retrieved as the binary image of primary objects from the
        %%% previously run image analysis module.   This forces the secondary
        %%% object's outline to extend at least as far as the edge of the primary
        %%% objects.

        %%% Inverts the image.
        InvertedThresholdedOrigImage = imcomplement(ThresholdedOrigImage);

        %%% NOTE: There are two other ways to mark the background prior to
        %%% watershedding; I think the method used above is best, but I have
        %%% included the ideas for two alternate methods.
        %%% METHOD (2): Threshold the original image (or a smoothed image)
        %%% so that background pixels are black.  This is overly strong, so instead
        %%% of weakly thresholding the image as is done in METHOD (1),  you can then "thin"
        %%% the background pixels by computing the SKIZ
        %%% (skeleton of influence zones), which is done by watershedding the
        %%% distance transform of the thresholded image.  These watershed lines are
        %%% then superimposed on the marked image that will be watershedded to
        %%% segment the objects.  I think this would not produce results different
        %%% from METHOD 1 (the one used above), since METHOD 1 overlays the
        %%% outlines of the primary objects anyway.
        %%% This method is based on the Mathworks Image Processing Toolbox demo
        %%% "Marker-Controlled Watershed Segmentation".  I found it online; I don't
        %%% think it is in the Matlab Demos that are found through help.  It uses
        %%% an image of a box of oranges.
        %%%
        %%% METHOD (3):  (I think this method does not work well for clustered
        %%% objects.)  The distance transformed image containing the marked objects
        %%% is watershedded, which produces lines midway between the marked
        %%% objects.  These lines are superimposed on the marked image that will be
        %%% watershedded to segment the objects. But if marked objects are
        %%% clustered and not a uniform distance from each other, this will produce
        %%% background lines on top of actual objects.
        %%% This method is based on Gonzalez, et al. Digital Image Processing using
        %%% Matlab, page 422-425.

        %%% STEP 2: Identify the outlines of each primary object, so that each
        %%% primary object can be definitely separated from the background.  This
        %%% solves the problem of some primary objects running
        %%% right up against the background pixels and therefore getting skipped.
        %%% Note: it is less accurate and less fast to use edge detection (sobel)
        %%% to identify the edges of the primary objects.
        %%% Converts the PrelimPrimaryLabelMatrixImage to binary.
        PrelimPrimaryBinaryImage = im2bw(PrelimPrimaryLabelMatrixImage,.5);
        %%% Creates the structuring element that will be used for dilation.
        StructuringElement = strel('square',3);
        %%% Dilates the Primary Binary Image by one pixel (8 neighborhood).
        DilatedPrimaryBinaryImage = imdilate(PrelimPrimaryBinaryImage, StructuringElement);
        %%% Subtracts the PrelimPrimaryBinaryImage from the DilatedPrimaryBinaryImage,
        %%% which leaves the PrimaryObjectOutlines.
        PrimaryObjectOutlines = DilatedPrimaryBinaryImage - PrelimPrimaryBinaryImage;

        %%% STEP 3: Produce the marker image which will be used for the first
        %%% watershed.
        %%% Combines the foreground markers and the background markers.
        BinaryMarkerImagePre = PrelimPrimaryBinaryImage | InvertedThresholdedOrigImage;
        %%% Overlays the PrimaryObjectOutlines to maintain distinctions between each
        %%% primary object and the background.
        BinaryMarkerImage = BinaryMarkerImagePre;
        BinaryMarkerImage(PrimaryObjectOutlines == 1) = 0;

        %%% STEP 4: Calculate the Sobel image, which reflects gradients, which will
        %%% be used for the watershedding function.
        %%% Calculates the 2 sobel filters.  The sobel filter is directional, so it
        %%% is used in both the horizontal & vertical directions and then the
        %%% results are combined.
        filter1 = fspecial('sobel');
        filter2 = filter1';
        %%% Applies each of the sobel filters to the original image.
        I1 = imfilter(OrigImage, filter1);
        I2 = imfilter(OrigImage, filter2);
        %%% Adds the two images.
        %%% The Sobel operator results in negative values, so the absolute values
        %%% are calculated to prevent errors in future steps.
        AbsSobeledImage = abs(I1) + abs(I2);

        %%% STEP 5: Perform the first watershed.

        %%% Overlays the foreground and background markers onto the
        %%% absolute value of the Sobel Image, so there are black nuclei on top of
        %%% each dark object, with black background.
        Overlaid = imimposemin(AbsSobeledImage, BinaryMarkerImage);
        %%% Perform the watershed on the marked absolute-value Sobel Image.
        BlackWatershedLinesPre = watershed(Overlaid);
        %%% Bug workaround (see step 9).
        BlackWatershedLinesPre2 = im2bw(BlackWatershedLinesPre,.5);
        BlackWatershedLines = bwlabel(BlackWatershedLinesPre2);

        %%% STEP 6: Identify and extract the secondary objects, using the watershed
        %%% lines.
        %%% The BlackWatershedLines image is a label matrix where the watershed
        %%% lines = 0 and each distinct object is assigned a number starting at 1.
        %%% This image is converted to a binary image where all the objects = 1.
        SecondaryObjects1 = im2bw(BlackWatershedLines,.5);
        %%% Identifies objects in the binary image using bwlabel.
        %%% Note: Matlab suggests that in some circumstances bwlabeln is faster
        %%% than bwlabel, even for 2D images.  I found that in this case it is
        %%% about 10 times slower.
        LabelMatrixImage1 = bwlabel(SecondaryObjects1,4);

        %%% STEP 7: Discarding background "objects".  The first watershed function
        %%% simply divides up the image into regions.  Most of these regions
        %%% correspond to actual objects, but there are big blocks of background
        %%% that are recognized as objects. These can be distinguished from actual
        %%% objects because they do not overlap a primary object.

        %%% The following changes all the labels in LabelMatrixImage1 to match the
        %%% centers they enclose (from PrelimPrimaryBinaryImage), and marks as background
        %%% any labeled regions that don't overlap a center. This function assumes
        %%% that every center is entirely contained in one labeled area.  The
        %%% results if otherwise may not be well-defined. The non-background labels
        %%% will be renumbered according to the center they enclose.

        %%% Finds the locations and labels for different regions.
        area_locations = find(LabelMatrixImage1);
        area_labels = LabelMatrixImage1(area_locations);
        %%% Creates a sparse matrix with column as label and row as location,
        %%% with the value of the center at (I,J) if location I has label J.
        %%% Taking the maximum of this matrix gives the largest valued center
        %%% overlapping a particular label.  Tacking on a zero and pushing
        %%% labels through the resulting map removes any background regions.
        map = [0 full(max(sparse(area_locations, area_labels, PrelimPrimaryBinaryImage(area_locations))))];
        ActualObjectsBinaryImage = map(LabelMatrixImage1 + 1);

        %%% STEP 8: Produce the marker image which will be used for the second
        %%% watershed.
        %%% The module has now produced a binary image of actual secondary
        %%% objects.  The gradient (Sobel) image was used for watershedding, which
        %%% produces very nice divisions between objects that are clumped, but it
        %%% is too stringent at the edges of objects that are isolated, and at the
        %%% edges of clumps of objects. Therefore, the stringently identified
        %%% secondary objects are used as markers for a second round of
        %%% watershedding, this time based on the original (intensity) image rather
        %%% than the gradient image.

        %%% Creates the structuring element that will be used for dilation.
        StructuringElement = strel('square',3);
        %%% Dilates the Primary Binary Image by one pixel (8 neighborhood).
        DilatedActualObjectsBinaryImage = imdilate(ActualObjectsBinaryImage, StructuringElement);
        %%% Subtracts the PrelimPrimaryBinaryImage from the DilatedPrimaryBinaryImage,
        %%% which leaves the PrimaryObjectOutlines.
        ActualObjectOutlines = DilatedActualObjectsBinaryImage - ActualObjectsBinaryImage;
        %%% Produces the marker image which will be used for the watershed. The
        %%% foreground markers are taken from the ActualObjectsBinaryImage; the
        %%% background markers are taken from the same image as used in the first
        %%% round of watershedding: InvertedThresholdedOrigImage.
        BinaryMarkerImagePre2 = ActualObjectsBinaryImage | InvertedThresholdedOrigImage;
        %%% Overlays the ActualObjectOutlines to maintain distinctions between each
        %%% secondary object and the background.
        BinaryMarkerImage2 = BinaryMarkerImagePre2;
        BinaryMarkerImage2(ActualObjectOutlines == 1) = 0;

        %%% STEP 9: Perform the second watershed.
        %%% As described above, the second watershed is performed on the original
        %%% intensity image rather than on a gradient (Sobel) image.
        %%% Inverts the original image.
        InvertedOrigImage = imcomplement(OrigImage);
        %%% Overlays the foreground and background markers onto the
        %%% InvertedOrigImage, so there are black secondary object markers on top
        %%% of each dark secondary object, with black background.
        MarkedInvertedOrigImage = imimposemin(InvertedOrigImage, BinaryMarkerImage2);
        %%% Performs the watershed on the MarkedInvertedOrigImage.
        SecondWatershedPre = watershed(MarkedInvertedOrigImage);
        %%% BUG WORKAROUND:
        %%% There is a bug in the watershed function of Matlab that often results in
        %%% the label matrix result having two objects labeled with the same label.
        %%% I am not sure whether it is a bug in how the watershed image is
        %%% produced (it seems so: the resulting objects often are nowhere near the
        %%% regional minima) or whether it is simply a problem in the final label
        %%% matrix calculation. Matlab has been informed of this issue and has
        %%% confirmed that it is a bug (February 2004). I think that it is a
        %%% reasonable fix to convert the result of the watershed to binary and
        %%% remake the label matrix so that each label is used only once. In later
        %%% steps, inappropriate regions are weeded out anyway.
        SecondWatershedPre2 = im2bw(SecondWatershedPre,.5);
        SecondWatershed = bwlabel(SecondWatershedPre2);

        %%% STEP 10: As in step 7, remove objects that are actually background
        %%% objects.  See step 7 for description. This time, the edited primary object image is
        %%% used rather than the preliminary one, so that objects whose nuclei are
        %%% on the edge of the image and who are larger or smaller than the
        %%% specified size are discarded.

        %%% Finds the locations and labels for different regions.
        area_locations2 = find(SecondWatershed);
        area_labels2 = SecondWatershed(area_locations2);
        %%% Creates a sparse matrix with column as label and row as location,
        %%% with the value of the center at (I,J) if location I has label J.
        %%% Taking the maximum of this matrix gives the largest valued center
        %%% overlapping a particular label.  Tacking on a zero and pushing
        %%% labels through the resulting map removes any background regions.
        map2 = [0 full(max(sparse(area_locations2, area_labels2, EditedPrimaryBinaryImage(area_locations2))))];
        FinalBinaryImagePre = map2(SecondWatershed + 1);
        %%% Fills holes in the FinalBinaryPre image.
        FinalBinaryImage = imfill(FinalBinaryImagePre, 'holes');
        %%% Converts the image to label matrix format. Even if the above step
        %%% is excluded (filling holes), it is still necessary to do this in order
        %%% to "compact" the label matrix: this way, each number corresponds to an
        %%% object, with no numbers skipped.
        ActualObjectsLabelMatrixImage3 = bwlabel(FinalBinaryImage);
        %%% The final objects are relabeled so that their numbers
        %%% correspond to the numbers used for nuclei.
        %%% For each object, one label and one label location is acquired and
        %%% stored.
        [LabelsUsed,LabelLocations] = unique(EditedPrimaryLabelMatrixImage);
        %%% The +1 increment accounts for the fact that there are zeros in the
        %%% image, while the LabelsUsed starts at 1.
        LabelsUsed(ActualObjectsLabelMatrixImage3(LabelLocations(2:end))+1) = EditedPrimaryLabelMatrixImage(LabelLocations(2:end));
        FinalLabelMatrixImagePre = LabelsUsed(ActualObjectsLabelMatrixImage3+1);
        %%% The following is a workaround for what seems to be a bug in the
        %%% watershed function: very very rarely two nuclei end up sharing one
        %%% "cell" object, so that one of the nuclei ends up without a
        %%% corresponding cell.  I am trying to determine why this happens exactly.
        %%% When the cell is measured, the area (and other
        %%% measurements) are recorded as [], which causes problems when dependent
        %%% measurements (e.g. perimeter/area) are attempted.  It results in divide
        %%% by zero errors and the mean area = NaN and so on.  So, the Primary
        %%% label matrix image (where it is nonzero) is written onto the Final cell
        %%% label matrix image pre so that every primary object has at least some
        %%% pixels of secondary object.
        FinalLabelMatrixImage = FinalLabelMatrixImagePre;
        FinalLabelMatrixImage(EditedPrimaryLabelMatrixImage ~= 0) = EditedPrimaryLabelMatrixImage(EditedPrimaryLabelMatrixImage ~= 0);
    end

    %%% Calculates OutlinesOnOrigImage for displaying in the figure
    %%% window in subplot(2,2,3).
    %%% Note: these outlines are not perfectly accurate; for some reason it
    %%% produces more objects than in the original image.  But it is OK for
    %%% display purposes.
    %%% Maximum filters the image with a 3x3 neighborhood.
    MaxFilteredImage = ordfilt2(FinalLabelMatrixImage,9,ones(3,3),'symmetric');
    %%% Determines the outlines.
    IntensityOutlines = FinalLabelMatrixImage - MaxFilteredImage;
    %%% Converts to logical.
    warning off MATLAB:conversionToLogical
    LogicalOutlines = logical(IntensityOutlines);
    warning on MATLAB:conversionToLogical
    %%% Determines the grayscale intensity to use for the cell outlines.
    LineIntensity = max(OrigImage(:));
    %%% Overlays the outlines on the original image.
    ObjectOutlinesOnOrigImage = OrigImage;
    ObjectOutlinesOnOrigImage(LogicalOutlines) = LineIntensity;
    %%% Calculates BothOutlinesOnOrigImage for displaying in the figure
    %%% window in subplot(2,2,4).
    %%% Creates the structuring element that will be used for dilation.
    StructuringElement = strel('square',3);
    %%% Dilates the Primary Binary Image by one pixel (8 neighborhood).
    DilatedPrimaryBinaryImage = imdilate(EditedPrimaryBinaryImage, StructuringElement);
    %%% Subtracts the PrelimPrimaryBinaryImage from the DilatedPrimaryBinaryImage,
    %%% which leaves the PrimaryObjectOutlines.
    PrimaryObjectOutlines = DilatedPrimaryBinaryImage - EditedPrimaryBinaryImage;
    BothOutlinesOnOrigImage = ObjectOutlinesOnOrigImage;
    BothOutlinesOnOrigImage(PrimaryObjectOutlines == 1) = LineIntensity;

    if strcmp(TestMode,'Yes')
        %%% If the test mode window does not exist, it is created, but only
        %%% if it's at the starting image set (if the user closed the window
        %%% intentionally, we don't want to pop open a new one).
        SecondaryTestFigureNumber = findobj('Tag','IdSecondaryTestModeFigure');
        if isempty(SecondaryTestFigureNumber) && handles.Current.SetBeingAnalyzed == handles.Current.StartingImageSet;
            %%% Creates the window, sets its tag, and puts some
            %%% text in it. The first lines are meant to find a suitable
            %%% figure number for the window, so we don't choose a
            %%% figure number that is being used by another module.
            SecondaryTestFigureNumber = CPfigurehandle(handles);
            CPfigure(handles,'Image',SecondaryTestFigureNumber);
            set(SecondaryTestFigureNumber,'Tag','IdSecondaryTestModeFigure',...
                'name','IdentifySecondary Test Display, cycle # ');
            CPresizefigure(ObjectOutlinesOnOrigImage,'TwoByTwo',SecondaryTestFigureNumber);
        end
        %%% If the figure window DOES exist now, then calculate and display items
        %%% in it.
        if ~isempty(SecondaryTestFigureNumber)
            %%% Makes the figure window active.
            CPfigure(handles,'Image',SecondaryTestFigureNumber);
            %%% Updates the cycle number on the window.
            CPupdatefigurecycle(handles.Current.SetBeingAnalyzed,SecondaryTestFigureNumber);

            hAx = subplot(2,2,IdentChoiceNumber,'Parent',SecondaryTestFigureNumber);
            CPimagesc(ObjectOutlinesOnOrigImage,handles,hAx);
            title(IdentChoiceList(IdentChoiceNumber),'Parent',hAx);
        end
    end

    if strcmp(OriginalIdentChoice,IdentChoice)
        if ~isfield(handles.Measurements,SecondaryObjectName)
            handles.Measurements.(SecondaryObjectName) = {};
        end

        if ~isfield(handles.Measurements,PrimaryObjectName)
            handles.Measurements.(PrimaryObjectName) = {};
        end

        handles = CPrelateobjects(handles,SecondaryObjectName,PrimaryObjectName,FinalLabelMatrixImage,EditedPrimaryLabelMatrixImage,ModuleName);

        %%%%%%%%%%%%%%%%%%%%%%%
        %%% DISPLAY RESULTS %%%
        %%%%%%%%%%%%%%%%%%%%%%%

        ThisModuleFigureNumber = handles.Current.(['FigureNumberForModule',CurrentModule]);
        if any(findobj == ThisModuleFigureNumber)
            %%% Activates the appropriate figure window.
            CPfigure(handles,'Image',ThisModuleFigureNumber);

            %%% Text display of Threshold
            ObjectCoverage = 100*sum(sum(FinalLabelMatrixImage > 0))/numel(FinalLabelMatrixImage);
            uicontrol(ThisModuleFigureNumber,'Style','Text','Units','Normalized','Position',[0.05 0.01 .8 0.04],...
                'BackgroundColor',CPBackgroundColor(),'HorizontalAlignment','Left','String',sprintf('Threshold:  %0.3f               %0.1f%% of image consists of objects',Threshold,ObjectCoverage),'FontSize',handles.Preferences.FontSize);

            %%% Calculates the ColoredLabelMatrixImage for display
            ColoredLabelMatrixImage = CPlabel2rgb(handles,FinalLabelMatrixImage);

            %%%% Display secondary outlines as default
            CPimagesc(ObjectOutlinesOnOrigImage, handles,ThisModuleFigureNumber);
            title(['Outlined ',SecondaryObjectName])

            %%% Construct struct which holds images and figure titles
            if isempty(findobj(ThisModuleFigureNumber,'tag','PopupImage')),
                ud(1).img = ObjectOutlinesOnOrigImage;
                ud(2).img = BothOutlinesOnOrigImage;
                ud(3).img = ColoredLabelMatrixImage;
                ud(4).img = OrigImage;
                ud(1).title = [SecondaryObjectName, ' Outlines on Input Image, cycle # ',num2str(handles.Current.SetBeingAnalyzed)];
                ud(2).title = ['Outlines of ', PrimaryObjectName, ' and ', SecondaryObjectName, ' on Input Image, cycle # ',num2str(handles.Current.SetBeingAnalyzed)];
                ud(3).title = ['Outlined ',SecondaryObjectName ' with random colors, cycle # ',num2str(handles.Current.SetBeingAnalyzed)];
                ud(4).title = ['Input Image, cycle # ',num2str(handles.Current.SetBeingAnalyzed)];

                %%% uicontrol for displaying other images
                uicontrol(ThisModuleFigureNumber, 'Style', 'popup',...
                    'String', 'Outlines: Secondary|Outlines: Primary and Secondary|Colored Label|Input Image',...
                    'UserData',ud,...
                    'units','normalized',...
                    'position',[.01 .95 .25 .04],...
                    'backgroundcolor',CPBackgroundColor(),...
                    'tag','PopupImage',...
                    'Callback', @CP_ImagePopupmenu_Callback);
            end
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% SAVE DATA TO HANDLES STRUCTURE %%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %%% Saves the final, segmented label matrix image of secondary objects to
        %%% the handles structure so it can be used by subsequent modules.
        fieldname = ['Segmented',SecondaryObjectName];
        handles = CPaddimages(handles,fieldname,FinalLabelMatrixImage);

        if strcmp(IdentChoice,'Propagation')
            % Save the Threshold value to the handles structure.
            handles = CPaddmeasurements(handles, 'Image', ...
                ['Threshold_FinalThreshold_', SecondaryObjectName], Threshold);

            %%% Also add the thresholding quality metrics to the measurements
            if exist('WeightedVariance', 'var')
            handles = CPaddmeasurements(handles, 'Image', ...
                ['Threshold_WeightedVariance_', SecondaryObjectName], ...
                WeightedVariance);
            handles = CPaddmeasurements(handles, 'Image', ...
                ['Threshold_SumOfEntropies_', SecondaryObjectName],...
                SumOfEntropies);
            end
        end

        handles = CPsaveObjectCount(handles, SecondaryObjectName, ...
            FinalLabelMatrixImage);
        handles = CPsaveObjectLocations(handles, SecondaryObjectName, ...
            FinalLabelMatrixImage);

        %%% Saves images to the handles structure so they can be saved to the hard
        %%% drive, if the user requested.
        try
            if ~strcmpi(SaveOutlines,'Do not use')
                handles = CPaddimages(handles,SaveOutlines,LogicalOutlines);
            end
        catch
            error(['The object outlines were not calculated by the ', ModuleName, ' module, so these images were not saved to the handles structure. The Save Images module will therefore not function on these images. This is just for your information - image processing is still in progress, but the Save Images module will fail if you attempted to save these images.'])
        end
    end
end
