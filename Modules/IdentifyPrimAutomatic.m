function handles = IdentifyPrimAutomatic(handles)

% Help for the Identify Primary Automatic module:
% Category: Object Processing
%
% SHORT DESCRIPTION:
% Identifies objects given only an image as input.
% *************************************************************************
%
% This module identifies primary objects (e.g. nuclei) in grayscale images
% that show bright objects on a dark background. The module has many
% options which vary in terms of speed and sophistication. The objects that
% are found are displayed with arbitrary colors - the colors do not mean
% anything but simply help you to tell various objects apart. You can
% change the colormap in File > Set Preferences.
%
% Requirements for the images to be fed into this module:
% * If the objects are dark on a light background, they must first be
% inverted using the Invert Intensity module.
% * If you are working with color images, they must first be converted to
% grayscale using the Color To Gray module.
%
% Overview of the strategy ('Settings' below has more details):
%   Properly identifying primary objects (nuclei) that are well-dispersed,
% non-confluent, and bright relative to the background is straightforward
% by applying a simple threshold to the image. This is fast but usually
% fails when nuclei are touching. In CellProfiler, several automatic
% thresholding methods are available, including global and adaptive, using
% Otsu's (Otsu, 1979) and our own version of a Mixture of Gaussians
% algorithm (O. Friman, unpublished). For most biological images, at least
% some nuclei are touching, so CellProfiler contains a novel modular
% three-step strategy based on previously published algorithms (Malpica et
% al., 1997; Meyer and Beucher, 1990; Ortiz de Solorzano et al., 1999;
% Wahlby, 2003; Wahlby et al., 2004). Choosing different options for each
% of these three steps allows CellProfiler to flexibly analyze a variety of
% different cell types. Here are the three steps:
%   In step 1, CellProfiler determines whether an object is an individual
% nucleus or two or more clumped nuclei. This determination can be
% accomplished in two ways, depending on the cell type: When nuclei are
% bright in the middle and dimmer towards the edges (the most common case),
% identifying local maxima in the smoothed intensity image works well
% (Intensity option). When nuclei are quite round, identifying local maxima
% in the distance-transformed thresholded image (where each pixel gets a
% value equal to the distance to the nearest pixel below a certain
% threshold) works well (Shape option). For quick processing where cells
% are well-dispersed, you can choose to make no attempt to separate clumped
% objects.
%   In step 2, the edges of nuclei are identified. For nuclei within the
% image that do not appear to touch, the edges are easily determined using
% thresholding. For nuclei that do appear to touch, there are two options
% for finding the edges of clumped nuclei. Where the dividing lines tend to
% be dimmer than the remainder of the nucleus (the most common case), the
% Intensity option works best (already identified nuclear markers are
% starting points for a watershed algorithm (Vincent and Soille, 1991)
% applied to the original image). When no dim dividing lines exist, the
% Distance option places the dividing line at a point between the two
% nuclei determined by their shape (the distance-transformed thresholded
% image is used for the watershed algorithm). In other words, the dividing
% line is usually placed where indentations occur along the edge of the
% clumped nuclei.
%   In step 3, some identified nuclei are discarded or merged together if
% the user chooses. Incomplete nuclei touching the border of the image can
% be discarded. Objects smaller than a user-specified size range, which are
% likely to be fragments of real nuclei, can be discarded. Alternately, any
% of these small objects that touch a valid nucleus can be merged together
% based on a set of heuristic rules; for example similarity in intensity
% and statistics of the two objects. A separate module,
% FilterByObjectMeasurement, further refines the identified nuclei, if
% desired, by excluding objects that are a particular size, shape,
% intensity, or texture. This refining step could eventually be extended to
% include other quality-control filters, e.g. a second watershed on the
% distance transformed image to break up remaining clusters (Wahlby et al.,
% 2004).
%
% For more details, see the Settings section below and also the notation
% within the code itself (Developer's version).
%
% Malpica, N., de Solorzano, C. O., Vaquero, J. J., Santos, A., Vallcorba,
% I., Garcia-Sagredo, J. M., and del Pozo, F. (1997). Applying watershed
% algorithms to the segmentation of clustered nuclei. Cytometry 28,
% 289-297.
% Meyer, F., and Beucher, S. (1990). Morphological segmentation. J Visual
% Communication and Image Representation 1, 21-46.
% Ortiz de Solorzano, C., Rodriguez, E. G., Jones, A., Pinkel, D., Gray, J.
% W., Sudar, D., and Lockett, S. J. (1999). Segmentation of confocal
% microscope images of cell nuclei in thick tissue sections. Journal of
% Microscopy-Oxford 193, 212-226.
% Wahlby, C. (2003) Algorithms for applied digital image cytometry, Ph.D.,
% Uppsala University, Uppsala.
% Wahlby, C., Sintorn, I. M., Erlandsson, F., Borgefors, G., and Bengtsson,
% E. (2004). Combining intensity, edge and shape information for 2D and 3D
% segmentation of cell nuclei in tissue sections. J Microsc 215, 67-76.
%
% Settings:
%
% Typical diameter of objects, in pixel units (Min,Max):
% This is a very important parameter which tells the module what you are
% looking for. Most options within this module use this estimate of the
% size range of the objects in order to distinguish them from noise in the
% image. For example, for some of the identification methods, the smoothing
% applied to the image is based on the minimum size of the objects. A comma
% should be placed between the minimum and the maximum diameters. The units
% here are pixels so that it is easy to zoom in on objects and determine
% typical diameters. To measure distances easily, use the CellProfiler
% Image Tool, 'ShowOrHidePixelData', in any open window. Once this tool is
% activated, you can draw a line across objects in your image and the
% length of the line will be shown in pixel units. Note that for non-round
% objects, the diameter here is actually the 'equivalent diameter', meaning
% the diameter of a circle with the same area as the object.
%
% Discard objects outside the diameter range:
% You can choose to discard objects outside the specified range of
% diameters. This allows you to exclude small objects (e.g. dust, noise,
% and debris) or large objects (e.g. clumps) if desired. See also the
% FilterByObjectMeasurement module to further discard objects based on some
% other measurement. During processing, the window for this module will
% show that objects outlined in green were acceptable, objects outlined in
% red were discarded based on their size, and objects outlined in yellow
% were discarded because they touch the border.
%
% Try to merge 'too small' objects with nearby larger objects:
% Use caution when choosing 'Yes' for this option! This is an experimental
% functionality that takes objects that were discarded because they were
% smaller than the specified Minimum diameter and tries to merge them with
% other surrounding objects. This is helpful in cases when an object was
% incorrectly split into two objects, one of which is actually just a tiny
% piece of the larger object. However, this could be dangerous if you have
% selected poor settings which produce many tiny objects - the module
% will take a very long time and you will not realize that it is because
% the tiny objects are being merged. It is therefore a good idea to run the
% module first without merging objects to make sure the settings are
% reasonably effective.
%
% Discard objects touching the border of the image:
% You can choose to discard objects that touch the border of the image.
% This is useful in cases when you do not want to make measurements of
% objects that are not fully within the field of view (because, for
% example, the area would not be accurate).
%
% Select automatic thresholding method:
%    The threshold affects the stringency of the lines between the objects
% and the background. You can have the threshold automatically calculated
% using several methods, or you can enter an absolute number between 0 and
% 1 for the threshold (to see the pixel intensities for your images in the
% appropriate range of 0 to 1, use the CellProfiler Image Tool,
% 'ShowOrHidePixelData', in a window showing your image). There are
% advantages either way. An absolute number treats every image identically,
% but is not robust to slight changes in lighting/staining conditions
% between images. An automatically calculated threshold adapts to changes
% in lighting/staining conditions between images and is usually more
% robust/accurate, but it can occasionally produce a poor threshold for
% unusual/artifactual images. It also takes a small amount of time to
% calculate.
%    The threshold which is used for each image is recorded as a
% measurement in the output file, so if you find unusual measurements from
% one of your images, you might check whether the automatically calculated
% threshold was unusually high or low compared to the other images.
%    There are five methods for finding thresholds automatically, Otsu's
% method, the Mixture of Gaussian (MoG) method, the Background method, the
% Robust Background method and the Ridler-Calvard method.
% ** The Otsu method
% uses our version of the Matlab function graythresh (the code is in the
% CellProfiler subfunction CPthreshold). Our modifications include taking
% into account the max and min values in the image and log-transforming the
% image prior to calculating the threshold. Otsu's method is probably best
% if you don't know anything about the image, or if the percent of the
% image covered by objects varies substantially from image to image. If you
% know the object coverage percentage and it does not vary much from image
% to image, the MoG can be better, especially if the coverage percentage is
% not near 50%. Note, however, that the MoG function is experimental and
% has not been thoroughly validated.
% ** The Background method
% is simple and appropriate for images in which most of the image is
% background. It finds the mode of the histogram of the image, which is
% assumed to be the background of the image, and chooses a threshold at
% twice that value (which you can adjust with a Threshold Correction Factor,
% see below).  Note that the mode is protected from a high number of
% saturated pixels by only counting pixels < 0.95. This can be very helpful,
% for example, if your images vary in overall brightness but the objects of
% interest are always twice (or actually, any constant) as bright as the
% background of the image.
% ** The Robust background
% method trims the brightest and dimmest 5% of pixel intensities off first
% in the hopes that the remaining pixels represent a gaussian of intensity
% values that are mostly background pixels. It then calculates the mean and
% standard deviation of the remaining pixels and calculates the threshold
% as the mean + 2 times the standard deviation.
% ** The Ridler-Calvard method
% is simple and its results are often very similar to Otsu's - according to
% Sezgin and Sankur's paper (Journal of Electronic Imaging 2004), Otsu's
% overall quality on testing 40 nondestructive testing images is slightly
% better than Ridler's (Average error - Otsu: 0.318, Ridler: 0.401).
% It chooses an initial threshold, and then iteratively calculates the next
% one by taking the mean of the average intensities of the background and
% foreground pixels determined by the first threshold, repeating this until
% the threshold converges.
% ** The Kapur method
% computes the threshold of an image by
% log-transforming its values, then searching for the threshold that
% maximizes the sum of entropies of the foreground and background
% pixel values, when treated as separate distributions.
%    You can also choose between Global, Adaptive, and Per object
% thresholding:
% Global: one threshold is used for the entire image (fast).
% Adaptive: the threshold varies across the image - a bit slower but
% provides more accurate edge determination which may help to separate
% clumps, especially if you are not using a clump-separation method (see
% below).
% Per object: if you are using this module to find child objects located
% *within* parent objects, the per object method will calculate a distinct
% threshold for each parent object. This is especially helpful, for
% example, when the background brightness varies substantially among the
% parent objects. Important: the per object method requires that you run an
% IdentifyPrim module to identify the parent objects upstream in the
% pipeline. After the parent objects are identified in the pipeline, you
% must then also run a Crop module as follows: the image to be cropped is
% the one
% that you will want to use within this module to identify the children
% objects (e.g., ChildrenStainedImage), and the shape in which to crop
% is the name of the parent objects (e.g., Nuclei). Then, set this
% IdentifyPrimAutomatic module to identify objects within the
% CroppedChildrenStainedImage.
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
% Method to distinguish clumped objects:
% Note: to choose between these methods, you can try test mode (see the
% last setting for this module).
% * Intensity - For objects that tend to have only one peak of brightness
% per object (e.g. objects that are brighter towards their interiors), this
% option counts each intensity peak as a separate object. The objects can
% be any shape, so they need not be round and uniform in size as would be
% required for a distance-based module. The module is more successful when
% the objects have a smooth texture. By default, the image is automatically
% blurred to attempt to achieve appropriate smoothness (see blur option),
% but overriding the default value can improve the outcome on
% lumpy-textured objects. Technical description: Object centers are defined
% as local intensity maxima.
% * Shape - For cases when there are definite indentations separating
% objects. This works best for objects that are round. The intensity
% patterns in the original image are irrelevant - the image is converted to
% black and white (binary) and the shape is what determines whether clumped
% objects will be distinguished. Therefore, the cells need not be brighter
% towards the interior as is required for the Intensity option. The
% de-clumping results of this method are affected by the thresholding
% method you choose. Technical description: The binary thresholded image is
% distance-transformed and object centers are defined as peaks in this
% image.
%
% * Do not use (fastest option) - If objects are far apart and are very well
% separated, it may be unnecessary to attempt to separate clumped objects.
% Using the 'Do not use' option, a simple threshold will be used to identify
% objects. This will override any declumping method chosen in the next
% question.
%
% Method to draw dividing lines between clumped objects:
% * Intensity - works best where the dividing lines between clumped
% objects are dim. Technical description: watershed on the intensity image.
% * Distance - Dividing lines between clumped objects are based on the
% shape of the clump. For example, when a clump contains two objects, the
% dividing line will be placed where indentations occur between the two
% nuclei. The intensity patterns in the original image are irrelevant - the
% cells need not be dimmer along the lines between clumped objects.
% Technical description: watershed on the distance-transformed thresholded
% image.
% * Do not use (fastest option) - If objects are far apart and are very well
% separated, it may be unnecessary to attempt to separate clumped objects.
% Using the 'Do not use' option, the thresholded image will be used to identify
% objects. This will override any declumping method chosen in the above
% question.
%
% Size of smoothing filter, in pixel units:
%    (Only used when distinguishing between clumped objects) This setting,
% along with the suppress local maxima setting, affects whether objects
% close to each other are considered a single object or multiple objects.
% It does not affect the dividing lines between an object and the
% background. If you see too many objects merged that ought to be separate,
% the value should be lower. If you see too many objects split up that
% ought to be merged, the value should be higher.
%    The image is smoothed based on the specified minimum object diameter
% that you have entered, but you may want to override the automatically
% calculated value here. Reducing the texture of objects by increasing the
% smoothing increases the chance that each real, distinct object has only
% one peak of intensity but also increases the chance that two distinct
% objects will be recognized as only one object. Note that increasing the
% size of the smoothing filter increases the processing time exponentially.
%
% Suppress local maxima within this distance (a positive integer, in pixel
% units):
%    (Only used when distinguishing between clumped objects) This setting,
% along with the size of the smoothing filter, affects whether objects
% close to each other are considered a single object or multiple objects.
% It does not affect the dividing lines between an object and the
% background. This setting looks for the maximum intensity in the size
% specified by the user.  The local intensity histogram is smoothed to
% remove the peaks within that distance. So,if you see too many objects
% merged that ought to be separate, the value should be lower. If you see
% too many objects split up that ought to be merged, the value should be higher.
%    Object markers are suppressed based on the specified minimum object
% diameter that you have entered, but you may want to override the
% automatically calculated value here. The maxima suppression distance
% should be set to be roughly equivalent to the minimum radius of a real
% object of interest. Basically, any distinct 'objects' which are found but
% are within two times this distance from each other will be assumed to be
% actually two lumpy parts of the same object, and they will be merged.
%
% Speed up by using lower-resolution image to find local maxima?
% (Only used when distinguishing between clumped objects) If you have
% entered a minimum object diameter of 10 or less, setting this option to
% Yes will have no effect.
%
% Technical notes: The initial step of identifying local maxima is
% performed on the user-controlled heavily smoothed image, the
% foreground/background is done on a hard-coded slightly smoothed image,
% and the dividing lines between clumped objects (watershed) is done on the
% non-smoothed image.
%
% Laplacian of Gaussian method:
% This is a specialized method to find objects and will override the above
% settings in this module. The code was kindly donated by Zach Perlman and
% was used in this published work:
% Multidimensional drug profiling by automated microscopy.
% Science. 2004 Nov 12;306(5699):1194-8.  PMID: 15539606
% Regrettably, we have no further description of its variables.
%
% Special note on saving images: Using the settings in this module, object
% outlines can be passed along to the module OverlayOutlines and then saved
% with the SaveImages module. Objects themselves can be passed along to the
% object processing module ConvertToImage and then saved with the
% SaveImages module. This module produces several additional types of
% objects with names that are automatically passed along with the following
% naming structure: (1) The unedited segmented image, which includes
% objects on the edge of the image and objects that are outside the size
% range, can be saved using the name: UneditedSegmented + whatever you
% called the objects (e.g. UneditedSegmentedNuclei). (2) The segmented
% image which excludes objects smaller than your selected size range can be
% saved using the name: SmallRemovedSegmented + whatever you called the
% objects (e.g. SmallRemovedSegmented Nuclei).
%
% See also IdentifyPrimManual, IdentifySecondary.

%
% Website: http://www.cellprofiler.org
%

%%%%%%%%%%%%%%%%%
%%% VARIABLES %%%
%%%%%%%%%%%%%%%%%
drawnow

[CurrentModule, CurrentModuleNum, ModuleName] = CPwhichmodule(handles);

%%% NOTE: We cannot indent the variables or they will not be read
%%% properly.

%textVAR01 = What did you call the images you want to process?
%infotypeVAR01 = imagegroup
ImageName = char(handles.Settings.VariableValues{CurrentModuleNum,1});
%inputtypeVAR01 = popupmenu

%textVAR02 = What do you want to call the objects identified by this module?
%defaultVAR02 = Nuclei
%infotypeVAR02 = objectgroup indep
ObjectName = char(handles.Settings.VariableValues{CurrentModuleNum,2});

%textVAR03 = Typical diameter of objects, in pixel units (Min,Max):
%defaultVAR03 = 10,40
SizeRange = char(handles.Settings.VariableValues{CurrentModuleNum,3});

%textVAR04 = Discard objects outside the diameter range?
%choiceVAR04 = Yes
%choiceVAR04 = No
ExcludeSize = char(handles.Settings.VariableValues{CurrentModuleNum,4});
%inputtypeVAR04 = popupmenu

%textVAR05 = Try to merge too small objects with nearby larger objects?
%choiceVAR05 = No
%choiceVAR05 = Yes
MergeChoice = char(handles.Settings.VariableValues{CurrentModuleNum,5});
%inputtypeVAR05 = popupmenu

%textVAR06 = Discard objects touching the border of the image?
%choiceVAR06 = Yes
%choiceVAR06 = No
ExcludeBorderObjects = char(handles.Settings.VariableValues{CurrentModuleNum,6});
%inputtypeVAR06 = popupmenu

%textVAR07 = Select an automatic thresholding method or enter an absolute threshold in the range [0,1].  To choose a binary image, select "Other" and type its name.  Choosing 'All' will use the Otsu Global method to calculate a single threshold for the entire image group. The other methods calculate a threshold for each image individually. "Set interactively" will allow you to manually adjust the threshold during the first cycle to determine what will work well.
%choiceVAR07 = Otsu Global
%choiceVAR07 = Otsu Adaptive
%choiceVAR07 = Otsu PerObject
%choiceVAR07 = MoG Global
%choiceVAR07 = MoG Adaptive
%choiceVAR07 = MoG PerObject
%choiceVAR07 = Background Global
%choiceVAR07 = Background Adaptive
%choiceVAR07 = Background PerObject
%choiceVAR07 = RobustBackground Global
%choiceVAR07 = RobustBackground Adaptive
%choiceVAR07 = RobustBackground PerObject
%choiceVAR07 = RidlerCalvard Global
%choiceVAR07 = RidlerCalvard Adaptive
%choiceVAR07 = RidlerCalvard PerObject
%choiceVAR07 = Kapur Global
%choiceVAR07 = Kapur Adaptive
%choiceVAR07 = Kapur PerObject
%choiceVAR07 = All
%choiceVAR07 = Set interactively
Threshold = char(handles.Settings.VariableValues{CurrentModuleNum,7});
%inputtypeVAR07 = popupmenu custom

%textVAR08 = Threshold correction factor
%defaultVAR08 = 1
ThresholdCorrection = str2num(char(handles.Settings.VariableValues{CurrentModuleNum,8})); %#ok Ignore MLint

%textVAR09 = Lower and upper bounds on threshold, in the range [0,1]
%defaultVAR09 = 0,1
ThresholdRange = char(handles.Settings.VariableValues{CurrentModuleNum,9});

%textVAR10 = For MoG thresholding, what is the approximate fraction of image covered by objects?
%choiceVAR10 = 0.01
%choiceVAR10 = 0.1
%choiceVAR10 = 0.2
%choiceVAR10 = 0.3
%choiceVAR10 = 0.4
%choiceVAR10 = 0.5
%choiceVAR10 = 0.6
%choiceVAR10 = 0.7
%choiceVAR10 = 0.8
%choiceVAR10 = 0.9
%choiceVAR10 = 0.99
pObject = char(handles.Settings.VariableValues{CurrentModuleNum,10});
%inputtypeVAR10 = popupmenu custom

%textVAR11 = Method to distinguish clumped objects (see help for details):
%choiceVAR11 = Intensity
%choiceVAR11 = Shape
%choiceVAR11 = Manual
%choiceVAR11 = Manual_for_IdSecondary
%choiceVAR11 = Do not use
OriginalLocalMaximaType = char(handles.Settings.VariableValues{CurrentModuleNum,11});
%inputtypeVAR11 = popupmenu

%textVAR12 =  Method to draw dividing lines between clumped objects (see help for details):
%choiceVAR12 = Intensity
%choiceVAR12 = Distance
%choiceVAR12 = Do not use
OriginalWatershedTransformImageType = char(handles.Settings.VariableValues{CurrentModuleNum,12});
%inputtypeVAR12 = popupmenu

%textVAR13 = Size of smoothing filter, in pixel units (if you are distinguishing between clumped objects). Enter 0 for low resolution images with small objects (~< 5 pixel diameter) to prevent any image smoothing.
%defaultVAR13 = Automatic
SizeOfSmoothingFilter = char(handles.Settings.VariableValues{CurrentModuleNum,13});

%textVAR14 = Suppress local maxima within this distance, (a positive integer, in pixel units) (if you are distinguishing between clumped objects)
%defaultVAR14 = Automatic
MaximaSuppressionSize = char(handles.Settings.VariableValues{CurrentModuleNum,14});

%textVAR15 = Speed up by using lower-resolution image to find local maxima?  (if you are distinguishing between clumped objects)
%choiceVAR15 = Yes
%choiceVAR15 = No
UseLowRes = char(handles.Settings.VariableValues{CurrentModuleNum,15});
%inputtypeVAR15 = popupmenu

%textVAR16 = Enter the following information, separated by commas, if you would like to use the Laplacian of Gaussian method for identifying objects instead of using the above settings: Size of neighborhood(height,width),Sigma,Minimum Area,Size for Wiener Filter(height,width),Threshold
%defaultVAR16 = Do not use
LaplaceValues = char(handles.Settings.VariableValues{CurrentModuleNum,16});

%textVAR17 = What do you want to call the outlines of the identified objects (optional)?
%defaultVAR17 = Do not use
%infotypeVAR17 = outlinegroup indep
SaveOutlines = char(handles.Settings.VariableValues{CurrentModuleNum,17});

%textVAR18 = Do you want to fill holes in identified objects?
%choiceVAR18 = Yes
%choiceVAR18 = No
FillHolesOption = char(handles.Settings.VariableValues{CurrentModuleNum,18});
%inputtypeVAR18 = popupmenu

%textVAR19 = Do you want to run in test mode where each method for distinguishing clumped objects is compared?
%choiceVAR19 = No
%choiceVAR19 = Yes
TestMode = char(handles.Settings.VariableValues{CurrentModuleNum,19});
%inputtypeVAR19 = popupmenu

%%%VariableRevisionNumber = 12

%%% NOTE!  The next time anyone changes the variables for this module, we
%%% would really like to remove the Laplacian option. We are certain that
%%% no one in the world is using it, but we didn't want to just remove it
%%% and change the revision number for no other good reason.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% PRELIMINARY ERROR CHECKING & FILE HANDLING %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
drawnow

%%% Reads (opens) the image you want to analyze and assigns it to a variable,
%%% "OrigImage".
OrigImage = double(CPretrieveimage(handles,ImageName,ModuleName,'MustBeGray','CheckScale'));


%%% Chooses the first word of the method name (removing 'Global' or 'Adaptive').
[ThresholdMethod ThresholdModifier]= strtok(Threshold);
ThresholdModifier = strtrim(ThresholdModifier);
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
%%% I don't think this should be here, Anne 12-4-06
% GetThreshold = 1;

%%% Checks that the Laplace parameters have valid values
if ~strcmp(LaplaceValues,'Do not use')
    index = strfind(LaplaceValues,',');
    if isempty(index) || (length(index) ~= 6)
        error(['Image processing was canceled in the ', ModuleName, ' module because the Laplace Values are invalid.']);
    end
    NeighborhoodSize(1) = str2num(LaplaceValues(1:index(1)-1)); %#ok Ignore MLint
    NeighborhoodSize(2) = str2num(LaplaceValues(index(1)+1:index(2)-1)); %#ok Ignore MLint
    Sigma = str2num(LaplaceValues(index(2)+1:index(3)-1)); %#ok Ignore MLint
    MinArea = str2num(LaplaceValues(index(3)+1:index(4)-1)); %#ok Ignore MLint
    WienerSize(1) = str2num(LaplaceValues(index(4)+1:index(5)-1)); %#ok Ignore MLint
    WienerSize(2) = str2num(LaplaceValues(index(5)+1:index(6)-1)); %#ok Ignore MLint
    LaplaceThreshold = str2num(LaplaceValues(index(6)+1:end)); %#ok Ignore MLint
end

%%% Checks that the Min and Max diameter parameters have valid values
index = strfind(SizeRange,',');
if isempty(index),
    error(['Image processing was canceled in the ', ModuleName, ' module because the Min and Max size entry is invalid.'])
end
MinDiameter = SizeRange(1:index-1);
MaxDiameter = SizeRange(index+1:end);

MinDiameter = str2double(MinDiameter);
if isnan(MinDiameter) | MinDiameter < 0 %#ok Ignore MLint
    error(['Image processing was canceled in the ', ModuleName, ' module because the Min diameter entry is invalid.'])
end
if strcmpi(MaxDiameter,'Inf')
    MaxDiameter = Inf;
else
    MaxDiameter = str2double(MaxDiameter);
    if isnan(MaxDiameter) | MaxDiameter < 0 %#ok Ignore MLint
        error(['Image processing was canceled in the ', ModuleName, ' module because the Max diameter entry is invalid.'])
    end
end
if MinDiameter > MaxDiameter
    error(['Image processing was canceled in the ', ModuleName, ' module because the Min Diameter is larger than the Max Diameter.'])
end

%%% Checks that the Min and Max threshold bounds have valid values
index = strfind(ThresholdRange,',');
if isempty(index)
    error(['Image processing was canceled in the ', ModuleName, ' module because the Min and Max threshold bounds are invalid.'])
end
MinimumThreshold = ThresholdRange(1:index-1);
MaximumThreshold = ThresholdRange(index+1:end);

%%% Check the smoothing filter size parameter
if ~strcmpi(SizeOfSmoothingFilter,'Automatic')
    SizeOfSmoothingFilter = str2double(SizeOfSmoothingFilter);
    if isnan(SizeOfSmoothingFilter) | isempty(SizeOfSmoothingFilter) | SizeOfSmoothingFilter < 0 %#ok Ignore MLint
        %%% I commented out the part where we check that the size of
        %%% smoothing filter is greater than the image, because I think it
        %%% does not yield errors when that is the case, and in some
        %%% dynamic pipelines, the size of the image may be very small in
        %%% some cases and large in others.
        error(['Image processing was canceled in the ', ModuleName, ' module because the specified size of the smoothing filter is not valid or unreasonable.'])
    end
end

%%% Check the maxima suppression size parameter
if ~strcmpi(MaximaSuppressionSize,'Automatic')
    MaximaSuppressionSize = str2double(MaximaSuppressionSize);
    if isnan(MaximaSuppressionSize) | isempty(MaximaSuppressionSize) | MaximaSuppressionSize < 0 %#ok Ignore MLint
        error(['Image processing was canceled in the ', ModuleName, ' module because the specified maxima suppression size is not valid or unreasonable.'])
    end
end

%%%%%%%%%%%%%%%%%%%%%%
%%% IMAGE ANALYSIS %%%
%%%%%%%%%%%%%%%%%%%%%%
drawnow

if GetThreshold
    [handles,OrigThreshold,WeightedVariance,SumOfEntropies] = CPthreshold(handles,Threshold,pObject,MinimumThreshold,MaximumThreshold,ThresholdCorrection,OrigImage,ImageName,ModuleName,ObjectName);
else
    OrigThreshold = 0;
end

%%% Sets up loop for test mode.
if strcmp(TestMode,'Yes')
    LocalMaximaTypeList = {'Intensity' 'Shape'};
    WatershedTransformImageTypeList = {'Intensity' 'Distance' 'Do not use'};
else
    %%% Not looping, but use code for looping below.
    LocalMaximaTypeList = {OriginalLocalMaximaType};
    WatershedTransformImageTypeList = {OriginalWatershedTransformImageType};
end


%%% These loops are necessary for Testing Mode, but otherwise there is only one of each.
for LocalMaximaTypeNumber = 1:length(LocalMaximaTypeList)
    for WatershedTransformImageTypeNumber = 1:length(WatershedTransformImageTypeList)

        LocalMaximaType = LocalMaximaTypeList{LocalMaximaTypeNumber};
        WatershedTransformImageType = WatershedTransformImageTypeList{WatershedTransformImageTypeNumber};
        Threshold = OrigThreshold;

        if strcmp(LaplaceValues,'Do not use')

            %%% Apply a slight smoothing before thresholding to remove
            %%% 1-pixel objects and to smooth the edges of the objects.
            %%% Note that this smoothing is hard-coded, and not controlled
            %%% by the user, but it is omitted if the user selected 0 for
            %%% the size of the smoothing filter.
            if SizeOfSmoothingFilter == 0
                %%% No blurring is done.
                BlurredImage = OrigImage;
            else
                sigma = 1;
                FiltLength = 2*sigma;
                [x,y] = meshgrid(-FiltLength:FiltLength,-FiltLength:FiltLength);   % Filter kernel grid
                f = exp(-(x.^2+y.^2)/(2*sigma^2));f = f/sum(f(:));                 % Gaussian filter kernel
                %                BlurredImage = conv2(OrigImage,f,'same');                             % Blur original image
                %%% This adjustment prevents the outer borders of the image from being
                %%% darker (due to padding with zeros), which causes some objects on the
                %%% edge of the image to not  be identified all the way to the edge of the
                %%% image and therefore not be thrown out properly.
                BlurredImage = conv2(OrigImage,f,'same') ./ conv2(ones(size(OrigImage)),f,'same');
            end
            if GetThreshold
                Objects = BlurredImage > Threshold;                                   % Threshold image
            else
                Objects = BinaryInputImage;
            end
            fieldname = ['CropMask', ImageName];
            if CPisimageinpipeline(handles, fieldname)
                %%% Retrieves previously selected cropping mask from handles
                %%% structure.
                BinaryCropImage = CPretrieveimage(handles,fieldname,ModuleName);
                try Objects = Objects & BinaryCropImage;
                catch
                    error('The image in which you want to identify objects has been cropped, but there was a problem recognizing the cropping pattern.');
                end
            end
            Threshold = mean(Threshold(:));                                       % Use average threshold downstreams
            if strcmp(FillHolesOption,'Yes')
                Objects = imfill(double(Objects),'holes');                            % Fill holes
            end
            drawnow

            %%% STEP 2. If user wants, extract local maxima (of intensity or distance) and apply watershed transform
            %%% to separate neighboring objects.
            if ~strcmp(LocalMaximaType,'Do not use') & ~strcmp(WatershedTransformImageType,'Do not use') %#ok Ignore MLint

                %%% Smooth images for maxima suppression
                if strcmpi(SizeOfSmoothingFilter,'Automatic')
                    SizeOfSmoothingFilter=2.35*MinDiameter/3.5;
                end
                BlurredImage = CPsmooth(OrigImage,'Gaussian Filter',SizeOfSmoothingFilter,0);

                %%% Get local maxima, where the definition of local depends on the
                %%% user-provided object size. This will (usually) be done in a
                %%% lower-resolution image for speed. The ordfilt2() function is
                %%% very slow for large images containing large objects.
                %%% Therefore, image is resized to a size where the smallest
                %%% objects are about 10 pixels wide. Local maxima within a radius
                %%% of 5-6 pixels are then extracted. It might be necessary to
                %%% tune this parameter. The MaximaSuppressionSize must be an
                %%% integer.  The MaximaSuppressionSize should be equal to the
                %%% minimum acceptable radius if the objects are perfectly
                %%% circular with local maxima in the center. In practice, the
                %%% MinDiameter is divided by 1.5 because this allows the local
                %%% maxima to be shifted somewhat from the center of the object.
                if strcmp(UseLowRes,'Yes') && MinDiameter > 10
                    ImageResizeFactor = 10/MinDiameter;
                    if strcmpi(MaximaSuppressionSize,'Automatic')
                        MaximaSuppressionSize = 7;             % ~ 10/1.5
                    else
                        MaximaSuppressionSize = round(MaximaSuppressionSize*ImageResizeFactor);
                    end
                else
                    ImageResizeFactor = 1;
                    if strcmpi(MaximaSuppressionSize,'Automatic')
                        MaximaSuppressionSize = round(MinDiameter/1.5);
                    else
                        MaximaSuppressionSize = round(MaximaSuppressionSize);
                    end
                end
                MaximaMask = getnhood(strel('disk', MaximaSuppressionSize));

                if strcmp(LocalMaximaType,'Intensity')
                    if strcmp(UseLowRes,'Yes')
                        %%% Find local maxima in a lower resolution image
                        ResizedBlurredImage = imresize(BlurredImage,ImageResizeFactor,'bilinear');
                    else
                        ResizedBlurredImage = BlurredImage;
                    end

                    %%% Initialize MaximaImage
                    MaximaImage = ResizedBlurredImage;
                    %%% Save only local maxima
                    MaximaImage(ResizedBlurredImage < ...
                        ordfilt2(ResizedBlurredImage,sum(MaximaMask(:)),MaximaMask)) = 0;

                    if strcmp(UseLowRes,'Yes')
                        %%% Restore image size
                        MaximaImage = imresize(MaximaImage,size(BlurredImage),'bilinear');
                    end

                    if GetThreshold
                        %%% Remove dim maxima
                        %%% TODO: THIS IS THE MEAN THRESHOLD, SHOULDN'T IT
                        %%% BE THE ORIG THRESHOLD?

                        MaximaImage = MaximaImage > Threshold;
                    end
                    %%% Shrink to points (needed because of the resizing)
                    if all(MaximaImage(:))
                        MaximaImage = zeros(size(MaximaImage));
                    else
                        MaximaImage = bwmorph(MaximaImage,'shrink',inf);
                    end
                elseif strcmp(LocalMaximaType,'Shape')
                    %%% Calculate distance transform
                    DistanceTransformedImage = bwdist(~Objects);
                    %%% Add some noise to get distinct maxima
                    %%% First set seed to 0, so that it is reproducible
                    is2008b_or_greater = ~CPverLessThan('matlab','7.7');
                    if is2008b_or_greater,
                        defaultStream = RandStream.getGlobalStream;
                        savedState = defaultStream.State;
                        RandStream.setGlobalStream(RandStream('mt19937ar','seed',0));
                    else
                        rand('seed',0);
                    end
                    DistanceTransformedImage = DistanceTransformedImage + ...
                        0.001*rand(size(DistanceTransformedImage));
                    if is2008b_or_greater, defaultStream.State = savedState; end
                    if strcmp(UseLowRes,'Yes')
                        ResizedDistanceTransformedImage = imresize(DistanceTransformedImage,ImageResizeFactor,'bilinear');
                    else
                        ResizedDistanceTransformedImage = DistanceTransformedImage;
                    end
                    %%% Initialize MaximaImage
                    MaximaImage = ones(size(ResizedDistanceTransformedImage));
                    %%% Set all pixels that are not local maxima to zero
                    MaximaImage(ResizedDistanceTransformedImage < ...
                        ordfilt2(ResizedDistanceTransformedImage,sum(MaximaMask(:)),MaximaMask)) = 0;
                    if strcmp(UseLowRes,'Yes')
                        %%% Restore image size
                        MaximaImage = imresize(MaximaImage,size(Objects),'bilinear');
                    end
                    %%% We are only interested in maxima within thresholded objects
                    MaximaImage(~Objects) = 0;
                    %%% Shrink to points (needed because of the resizing)
                    if all(MaximaImage(:))
                        MaximaImage = zeros(size(MaximaImage));
                    else
                        MaximaImage = bwmorph(MaximaImage,'shrink',inf);
                    end
                elseif strcmp(LocalMaximaType, 'Manual') || strcmp(LocalMaximaType, 'Manual_for_IdSecondary')
                    %%% Do the manual clicking for local maximas
                    IdPrimDistinguishClumpedObjManualFigureNumber = findobj('Tag','IdPrimDistinguishClumpedObjManualFigure');
                    if isempty(IdPrimDistinguishClumpedObjManualFigureNumber) && handles.Current.SetBeingAnalyzed == 1;
                        %%% Creates the window, sets its tag, and puts some
                        %%% text in it. The first lines are meant to find a suitable
                        %%% figure number for the window, so we don't choose a
                        %%% figure number that is being used by another module.
                        IdPrimDistinguishClumpedObjManualFigureNumber = CPfigurehandle(handles);
                        FigureHandle = CPfigure(handles,'',IdPrimDistinguishClumpedObjManualFigureNumber);
                        set(IdPrimDistinguishClumpedObjManualFigureNumber,'Tag','IdPrimDistinguishClumpedObjManualFigure',...
                            'name','IdentifyPrimAutomatic Manually Distinguish Clumped Objects Display, cycle # ');
                    end
                    %%% If the figure window DOES exist now, then calculate and display items
                    %%% in it.
                    if ~isempty(IdPrimDistinguishClumpedObjManualFigureNumber)
                        %%% Makes the window active.
                        FigureHandle = CPfigure(IdPrimDistinguishClumpedObjManualFigureNumber(1));
                        %%% Updates the cycle number on the window.
                        CPupdatefigurecycle(handles.Current.SetBeingAnalyzed,IdPrimDistinguishClumpedObjManualFigureNumber);
                        [hImage,AxisHandle] = CPimagesc(OrigImage,handles,IdPrimDistinguishClumpedObjManualFigureNumber);
                        title(AxisHandle,[{['Cycle #',num2str(handles.Current.SetBeingAnalyzed),...
                            '. Click on approximate cell center points to outline the region of interest.']},...
                            {'The backspace key or right mouse button will erase the last clicked point.'},...
                            {'Use Edit > Colormap to adjust the contrast of the image if needed.'},...
                            {'Press enter when finished.'},...
                            {'Then be patient while waiting for processing to complete.'}],'fontsize',handles.Preferences.FontSize);
                    end
                    [xpts,ypts] = getpoints(AxisHandle);
                    MaximaImage = zeros(size(OrigImage,1), size(OrigImage, 2));
                    point_idx = sub2ind(size(OrigImage), ypts, xpts);
                    MaximaImage(point_idx) = 1;
                end

                %%% Overlay the maxima on either the original image or a distance
                %%% transformed image. The watershed is currently done on
                %%% non-smoothed versions of these image. We may want to try to do
                %%% the watershed in the slightly smoothed image.
                if strcmp(WatershedTransformImageType,'Intensity')
                    %%% Overlays the objects markers (maxima) on the inverted original image so
                    %%% there are black dots on top of each dark object on a white background.
                    Overlaid = imimposemin(1 - OrigImage,MaximaImage);
                elseif strcmp(WatershedTransformImageType,'Distance')
                    %%% Overlays the object markers (maxima) on the inverted DistanceTransformedImage so
                    %%% there are black dots on top of each dark object on a white background.
                    %%% We may have to calculate the distance transform if not already done:
                    if ~exist('DistanceTransformedImage','var')
                        DistanceTransformedImage = bwdist(~Objects);
                    end
                    Overlaid = imimposemin(-DistanceTransformedImage,MaximaImage);
                    % figure, imagesc(Overlaid), title('overlaid');
                    % figure, imagesc(-DistanceTransformedImage), title('-DistanceTransformedImage');
                end

                %%% Calculate the watershed transform and cut objects along the boundaries
                WatershedBoundaries = watershed(Overlaid) > 0;
                Objects = Objects.*WatershedBoundaries;

                %%% Label the objects
                Objects = bwlabel(Objects);

                %%% Remove objects with no marker in them (this happens occasionally)
                %%% This is a very fast way to get pixel indexes for the objects
                tmp = regionprops(Objects,'PixelIdxList');
                for k = 1:length(tmp)
                    %%% If there is no maxima in these pixels, exclude object
                    if sum(MaximaImage(tmp(k).PixelIdxList)) == 0
                        Objects(tmp(k).PixelIdxList) = 0;
                    end
                end
            end
            drawnow

            if strcmp(LocalMaximaType, 'Manual_for_IdSecondary')
               Objects = MaximaImage;
            end

            %%% Label the objects
            Objects = bwlabel(Objects);

            %%% Merge small objects

            if strcmp(MergeChoice,'Yes')
                NumberOfObjectsBeforeMerge = max(Objects(:));
                Objects = MergeObjects(Objects,OrigImage,[MinDiameter MaxDiameter]);
                NumberOfObjectsAfterMerge = max(Objects(:));
                NumberOfMergedObjects = NumberOfObjectsBeforeMerge-NumberOfObjectsAfterMerge;
            end

            %%% Will be stored to the handles structure
            UneditedLabelMatrixImage = Objects;

            %%% Get diameters of objects and calculate the interval
            %%% that contains 90% of the objects
            tmp = regionprops(Objects,'EquivDiameter');
            Diameters = [0;cat(1,tmp.EquivDiameter)];
            SortedDiameters = sort(Diameters);
            NbrInTails = max(round(0.05*length(Diameters)),1);
            Lower90Limit = SortedDiameters(NbrInTails);
            Upper90Limit = SortedDiameters(end-NbrInTails+1);

            %%% Locate objects with diameter outside the specified range
            tmp = Objects;
            if strcmp(ExcludeSize,'Yes')
                %%% Create image with object intensity equal to the diameter
                DiameterMap = Diameters(Objects+1);
                %%% Remove objects that are too small
                Objects(DiameterMap < MinDiameter) = 0;
                %%% Will be stored to the handles structure
                SmallRemovedLabelMatrixImage = Objects;
                %%% Remove objects that are too big
                Objects(DiameterMap > MaxDiameter) = 0;
            else
                %%% Will be stored to the handles structure even if it's unedited.
                SmallRemovedLabelMatrixImage = Objects;
            end
            %%% Store objects that fall outside diameter range for display
            DiameterExcludedObjects = tmp - Objects;

            %%% Remove objects along the border of the image (depends on user input)
            tmp = Objects;
            if strcmp(ExcludeBorderObjects,'Yes')
                PrevObjects = Objects;
                Objects = CPclearborder(Objects);

                %%% CODE TO REMOVE BORDERS FROM ELLIPSE CROPPED OBJECTS
                if sum(PrevObjects(:)) == sum(Objects(:))
                    try %#ok Ignore MLint
                        CropMask = CPretrieveimage(handles,['CropMask',ImageName],ModuleName);
                        CropBorders = bwperim(CropMask);
                        BorderTable = sortrows(unique([CropBorders(:) Objects(:)],'rows'),1);
                        for z = 1:size(BorderTable,1)
                            if BorderTable(z,1) ~= 0 && BorderTable(z,2) ~= 0
                                Objects(Objects == BorderTable(z,2)) = 0;
                            end
                        end
                    end
                end
            end
            %%% Store objects that touch the border for display
            BorderObjects = tmp - Objects;

            %%% Relabel the objects
            [Objects,NumOfObjects] = bwlabel(Objects > 0);
            FinalLabelMatrixImage = Objects;
        else
            %%% Creates the Laplacian of a Gaussian filter.
            rgLoG=fspecial('log',NeighborhoodSize,Sigma);
            %%% Filters the image.
            imLoGout=imfilter(double(OrigImage),rgLoG);
            %%% Removes noise using the wiener filter.
            imLoGoutW=wiener2(imLoGout,WienerSize);

            rgNegCurve = imLoGoutW < LaplaceThreshold;
            class(rgNegCurve)
            min(min(rgNegCurve))
            max(max(rgNegCurve))

            %set outsides
            rgNegCurve([1 end],1:end)=1;
            rgNegCurve(1:end,[1 end])=1;

            %Throw out noise, label regions
            rgArOpen=bwareaopen(rgNegCurve,MinArea,4);
            rgLabelled=uint16(bwlabel(rgArOpen,4));
            % rgArOpen=bwareaopen(rgNegCurve,MinArea,8); %use 8-connectivity like rest of CP
            % rgLabelled=uint16(bwlabel(rgArOpen,8));
            if max(rgLabelled(:))==1
                error(['Image processing was canceled in the ', ModuleName, ' module because no DAPI regions were generated.']);
            end

            %Get rid of region around outsides (upper-left region gets value 1)
            rgLabelled(rgLabelled==1)=0;
            rgLabelled(rgLabelled==0)=1;
            rgLabelled=uint16(double(rgLabelled)-1);
            %disp(['Generated labelled, size-excluded regions. Time: ' num2str(toc)])

            %(Smart)closing
            % rgDilated=RgSmartDilate(rgLabelled,50); %%% IMPORTANT VARIABLE
            rgDilated=CPrgsmartdilate(rgLabelled,2); %%% IMPORTANT VARIABLE

            % InvertedBinaryImage = RgSmartDilate(rgNegCurve,1);
            InvertedBinaryImage = rgDilated;

            %%% Creates label matrix image.

            PrelimLabelMatrixImage1 = bwlabel(imfill(InvertedBinaryImage,'holes'));
            UneditedLabelMatrixImage = PrelimLabelMatrixImage1;
            %%% Finds objects larger and smaller than the user-specified size.
            %%% Finds the locations and labels for the pixels that are part of an object.
            AreaLocations = find(PrelimLabelMatrixImage1);
            AreaLabels = PrelimLabelMatrixImage1(AreaLocations);
            drawnow
            %%% Creates a sparse matrix with column as label and row as location,
            %%% with a 1 at (A,B) if location A has label B.  Summing the columns
            %%% gives the count of area pixels with a given label.  E.g. Areas(L) is the
            %%% number of pixels with label L.
            Areas = full(sum(sparse(AreaLocations, AreaLabels, 1)));
            Map = [0,Areas];
            AreasImage = Map(PrelimLabelMatrixImage1 + 1);
            %%% The small objects are overwritten with zeros.
            PrelimLabelMatrixImage2 = PrelimLabelMatrixImage1;
            PrelimLabelMatrixImage2(AreasImage < MinDiameter) = 0;
            SmallRemovedLabelMatrixImage = PrelimLabelMatrixImage2;
            drawnow
            %%% Relabels so that labels are consecutive. This is important for
            %%% downstream modules (IdentifySec).
            PrelimLabelMatrixImage2 = bwlabel(im2bw(PrelimLabelMatrixImage2,.5));
            %%% The large objects are overwritten with zeros.
            PrelimLabelMatrixImage3 = PrelimLabelMatrixImage2;
            if MaxDiameter ~= 99999
                PrelimLabelMatrixImage3(AreasImage > MaxDiameter) = 0;
                DiameterExcludedObjects = PrelimLabelMatrixImage3;
                BorderObjects = PrelimLabelMatrixImage3;
            end
            %%% Removes objects that are touching the edge of the image, since they
            %%% won't be measured properly.
            if strncmpi(ExcludeBorderObjects,'Y',1) == 1
                Objects = CPclearborder(PrelimLabelMatrixImage3,8);
            else Objects = PrelimLabelMatrixImage3;
            end
            %%% The PrelimLabelMatrixImage4 is converted to binary.
            FinalBinaryPre = im2bw(Objects,.5);
            drawnow
            %%% Holes in the FinalBinaryPre image are filled in.
            FinalBinary = imfill(FinalBinaryPre, 'holes');
            %%% The image is converted to label matrix format. Even if the above step
            %%% is excluded (filling holes), it is still necessary to do this in order
            %%% to "compact" the label matrix: this way, each number corresponds to an
            %%% object, with no numbers skipped.
            [FinalLabelMatrixImage,NumOfObjects] = bwlabel(FinalBinary);
        end

        %%%%%%%%%%%%%%%%%%%%%%%
        %%% DISPLAY RESULTS %%%
        %%%%%%%%%%%%%%%%%%%%%%%
        drawnow

        if strcmp(OriginalLocalMaximaType,'Do not use') || (strcmp(OriginalLocalMaximaType,LocalMaximaType) && strcmp(OriginalWatershedTransformImageType,WatershedTransformImageType))

            if strcmp(LaplaceValues,'Do not use')
                %%% Indicate objects in original image and color excluded objects in red
                tmp = OrigImage - min(OrigImage(:));
                if any(tmp(:))
                    tmp = tmp/max(tmp(:));
                end
                OutlinedObjectsR = tmp;
                OutlinedObjectsG = tmp;
                OutlinedObjectsB = tmp;
                PerimObjects = bwperim(Objects > 0);
                PerimDiameter = bwperim(DiameterExcludedObjects > 0);
                PerimBorder = bwperim(BorderObjects > 0);
                OutlinedObjectsR(PerimObjects) = 0; OutlinedObjectsG(PerimObjects) = 1; OutlinedObjectsB(PerimObjects) = 0;
                OutlinedObjectsR(PerimDiameter) = 1; OutlinedObjectsG(PerimDiameter)   = 0; OutlinedObjectsB(PerimDiameter)   = 0;
                OutlinedObjectsR(PerimBorder) = 1; OutlinedObjectsG(PerimBorder) = 1; OutlinedObjectsB(PerimBorder) = 0;

                FinalOutline = false(size(OrigImage,1),size(OrigImage,2));
                FinalOutline(PerimObjects) = 1;
                FinalOutline(PerimDiameter) = 0;
                FinalOutline(PerimBorder) = 0;

                ThisModuleFigureNumber = handles.Current.(['FigureNumberForModule',CurrentModule]);
                if any(findobj == ThisModuleFigureNumber)
                    % Remove uicontrols from last cycle
                    delete(findobj(ThisModuleFigureNumber,'tag','TextUIControl'));

                    %%% Activates the appropriate figure window.
                    CPfigure(handles,'Image',ThisModuleFigureNumber);
                    if handles.Current.SetBeingAnalyzed == handles.Current.StartingImageSet
                        CPresizefigure(OrigImage,'TwoByTwo',ThisModuleFigureNumber)
                    end
                    hAx=subplot(2,2,1,'Parent',ThisModuleFigureNumber);
                    CPimagesc(OrigImage,handles,hAx);
                    title(hAx,['Input Image, cycle # ',num2str(handles.Current.SetBeingAnalyzed)]);
                    hx = subplot(2,2,2,'Parent',ThisModuleFigureNumber);
                    im = CPlabel2rgb(handles,Objects);
                    CPimagesc(im,handles,hx);
                    title(hx,['Identified ',ObjectName]);
                    hy = subplot(2,2,3,'Parent',ThisModuleFigureNumber);
                    OutlinedObjects = cat(3,OutlinedObjectsR,OutlinedObjectsG,OutlinedObjectsB);
                    CPimagesc(OutlinedObjects,handles,hy);
                    title(hy,['Outlined ', ObjectName]);

                    %%% Report numbers
                    posx = get(hx,'Position');
                    posy = get(hy,'Position');
                    bgcolor = get(ThisModuleFigureNumber,'Color');
                    n = 1;
                    uicontrol(ThisModuleFigureNumber,'Style','Text','Units','Normalized','Position',[posx(1)-0.05 posy(2)+posy(4)-0.04*n posx(3)+0.1 0.04],'tag','TextUIControl',...
                        'BackgroundColor',bgcolor,'HorizontalAlignment','Left','String',sprintf('Method:  %s',[ThresholdMethod ThresholdModifier]),'FontSize',handles.Preferences.FontSize);
                    n = n+1;
                    uicontrol(ThisModuleFigureNumber,'Style','Text','Units','Normalized','Position',[posx(1)-0.05 posy(2)+posy(4)-0.04*n posx(3)+0.1 0.04],'tag','TextUIControl',...
                        'BackgroundColor',bgcolor,'HorizontalAlignment','Left','String',sprintf('Threshold:  %0.3f',Threshold),'FontSize',handles.Preferences.FontSize);
                    if strcmpi(ThresholdMethod,'MoG')
                        n = n+1;
                        uicontrol(ThisModuleFigureNumber,'Style','Text','Units','Normalized','Position',[posx(1)-0.05 posy(2)+posy(4)-0.04*n posx(3)+0.1 0.04],'tag','TextUIControl',...
                            'BackgroundColor',bgcolor,'HorizontalAlignment','Left','String',sprintf('Approx fraction covered by objects:  %0.2f',str2double(pObject)),'FontSize',handles.Preferences.FontSize);
                    end
                    n = n+2;
                    uicontrol(ThisModuleFigureNumber,'Style','Text','Units','Normalized','Position',[posx(1)-0.05 posy(2)+posy(4)-0.04*n posx(3)+0.1 0.04],'tag','TextUIControl',...
                        'BackgroundColor',bgcolor,'HorizontalAlignment','Left','String',sprintf('Number of identified objects: %d',NumOfObjects),'FontSize',handles.Preferences.FontSize);
                    n = n+1;
                    uicontrol(ThisModuleFigureNumber,'Style','Text','Units','Normalized','Position',[posx(1)-0.05 posy(2)+posy(4)-0.04*n posx(3)+0.1 0.04],'tag','TextUIControl',...
                        'BackgroundColor',bgcolor,'HorizontalAlignment','Left','String',sprintf('90%% of objects within diameter range [%0.1f, %0.1f] pixels',...
                        Lower90Limit,Upper90Limit),'FontSize',handles.Preferences.FontSize);
                    ObjectCoverage = 100*sum(sum(Objects > 0))/numel(Objects);
                    n = n+1;
                    uicontrol(ThisModuleFigureNumber,'Style','Text','Units','Normalized','Position',[posx(1)-0.05 posy(2)+posy(4)-0.04*n posx(3)+0.1 0.04],'tag','TextUIControl',...
                        'BackgroundColor',bgcolor,'HorizontalAlignment','Left','String',sprintf('%0.1f%% of image consists of objects',ObjectCoverage),'FontSize',handles.Preferences.FontSize);
                    if ~strcmp(LocalMaximaType,'Do not use') & ~strcmp(WatershedTransformImageType,'Do not use') %#ok Ignore MLint
                        n = n+2;
                        uicontrol(ThisModuleFigureNumber,'Style','Text','Units','Normalized','Position',[posx(1)-0.05 posy(2)+posy(4)-0.04*n posx(3)+0.1 0.04],'tag','TextUIControl',...
                            'BackgroundColor',bgcolor,'HorizontalAlignment','Left','String',sprintf('Smoothing filter size:  %0.1f',SizeOfSmoothingFilter),'FontSize',handles.Preferences.FontSize);
                        n = n+1;
                        uicontrol(ThisModuleFigureNumber,'Style','Text','Units','Normalized','Position',[posx(1)-0.05 posy(2)+posy(4)-0.04*n posx(3)+0.1 0.04],'tag','TextUIControl',...
                            'BackgroundColor',bgcolor,'HorizontalAlignment','Left','String',sprintf('Maxima suppression size:  %d',round(MaximaSuppressionSize/ImageResizeFactor)),'FontSize',handles.Preferences.FontSize);
                    end
                    if strcmp(MergeChoice,'Yes')
                        n = n+1;
                        uicontrol(ThisModuleFigureNumber,'Style','Text','Units','Normalized','Position',[posx(1)-0.05 posy(2)+posy(4)-0.04*n posx(3)+0.1 0.04],'tag','TextUIControl',...
                            'BackgroundColor',bgcolor,'HorizontalAlignment','Left','String',sprintf('Number of Merged Objects:  %d',NumberOfMergedObjects),'FontSize',handles.Preferences.FontSize);
                    end
                end
            else
                ThisModuleFigureNumber = handles.Current.(['FigureNumberForModule',CurrentModule]);
                if any(findobj == ThisModuleFigureNumber) | ~strcmpi(SaveOutlines,'Do not use') %#ok Ignore MLint
                    %%% Calculates the ColoredLabelMatrixImage for displaying in the figure
                    %%% window in subplot(2,2,2).
                    ColoredLabelMatrixImage = CPlabel2rgb(handles,FinalLabelMatrixImage);
                    %%% Calculates the object outlines, which are overlaid on the original
                    %%% image and displayed in figure subplot (2,2,4).
                    %%% Creates the structuring element that will be used for dilation.
                    StructuringElement = strel('square',3);
                    %%% Converts the FinalLabelMatrixImage to binary.
                    FinalBinaryImage = im2bw(FinalLabelMatrixImage,.5);
                    %%% Dilates the FinalBinaryImage by one pixel (8 neighborhood).
                    DilatedBinaryImage = imdilate(FinalBinaryImage, StructuringElement);
                    %%% Subtracts the FinalBinaryImage from the DilatedBinaryImage,
                    %%% which leaves the PrimaryObjectOutlines.
                    PrimaryObjectOutlines = DilatedBinaryImage - FinalBinaryImage;
                    %%% Overlays the object outlines on the original image.
                    ObjectOutlinesOnOrigImage = OrigImage;
                    %%% Determines the grayscale intensity to use for the cell outlines.
                    LineIntensity = max(OrigImage(:));
                    ObjectOutlinesOnOrigImage(PrimaryObjectOutlines == 1) = LineIntensity;

                    CPfigure(handles,'Image',ThisModuleFigureNumber);
                    if handles.Current.SetBeingAnalyzed == handles.Current.StartingImageSet
                        CPresizefigure(OrigImage,'TwoByTwo',ThisModuleFigureNumber);
                    end
                    %%% A subplot of the figure window is set to display the original image.
                    hAx=subplot(2,2,1,'Parent',ThisModuleFigureNumber);
                    CPimagesc(OrigImage,handles,hAx);
                    title(hAx,['Input Image, cycle # ',num2str(handles.Current.SetBeingAnalyzed)]);
                    %%% A subplot of the figure window is set to display the colored label
                    %%% matrix image.
                    hAx = subplot(2,2,2,'Parent',ThisModuleFigureNumber);
                    CPimagesc(ColoredLabelMatrixImage,handles,hAx);
                    title(hAx,['Identified ',ObjectName]);
                    %%% A subplot of the figure window is set to display the Overlaid image,
                    %%% where the maxima are imposed on the inverted original image
                    % subplot(2,2,3); CPimagesc(Overlaid);  title([ObjectName, ' markers']);
                    %%% A subplot of the figure window is set to display the inverted original
                    %%% image with watershed lines drawn to divide up clusters of objects.
                    hAx=subplot(2,2,4,'Parent',ThisModuleFigureNumber);
                    CPimagesc(ObjectOutlinesOnOrigImage,handles,hAx);
                    title(hAx,[ObjectName, ' Outlines on Input Image']);
                end
            end

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%% SAVE DATA TO HANDLES STRUCTURE %%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            drawnow

            %%% Saves the segmented image, not edited for objects along the edges or
            %%% for size, to the handles structure.
            fieldname = ['UneditedSegmented',ObjectName];
            handles = CPaddimages(handles,fieldname,UneditedLabelMatrixImage);

            %%% Saves the segmented image, only edited for small objects, to the
            %%% handles structure.
            fieldname = ['SmallRemovedSegmented',ObjectName];
            handles = CPaddimages(handles,fieldname,SmallRemovedLabelMatrixImage);

            %%% Saves the final segmented label matrix image to the handles structure.
            fieldname = ['Segmented',ObjectName];
            handles = CPaddimages(handles,fieldname,FinalLabelMatrixImage);

            %%% Saves images to the handles structure so they can be saved to the hard
            %%% drive, if the user requested.
            if ~strcmpi(SaveOutlines,'Do not use')
                try
                    handles = CPaddimages(handles,SaveOutlines,FinalOutline);
                catch
                    error(['The object outlines were not calculated by the ', ModuleName, ' module, so these images were not saved to the handles structure. The Save Images module will therefore not function on these images. This is just for your information - image processing is still in progress, but the Save Images module will fail if you attempted to save these images.'])
                end
            end

            if strcmp(MergeChoice,'Yes')
                % Save the NumberOfMergedObjects to the handles structure.
                handles = CPaddmeasurements ...
                    (handles, 'Image', ...
                    ['NumberOfMergedObjects_', ObjectName], ...
                    NumberOfMergedObjects);
            end

            % Save the Threshold value to the handles structure
            handles = CPaddmeasurements(handles, 'Image', ...
                ['Threshold_FinalThreshold_', ObjectName], ...
                Threshold);

            if strcmp(ThresholdModifier,'PerObject')
                %%% If per-object, add the threshold as an object measurement
                [UniqueLabels,LabelIndices]=unique(Objects);
                if UniqueLabels == 0
                    % if there aren't any primary objects, OrigThreshold will
                    % be set to 1 with len 1; this arbitrarily lets us save the
                    % value, despite the fact that we didnt find any
                    % 'per-objects' either.
                    ThresholdsPerObjects = OrigThreshold(1);
                else
                    ThresholdsPerObjectsIncludingZero = OrigThreshold(LabelIndices);
                    ThresholdsPerObjects = ThresholdsPerObjectsIncludingZero(2:end);
                end
                handles = CPaddmeasurements(handles, ...
                    ObjectName,'Threshold_PerObject',ThresholdsPerObjects);
            end

            %%% Also add the thresholding quality metrics to the measurements
            if exist('WeightedVariance', 'var')
                handles = CPaddmeasurements(handles, 'Image', ...
                    ['Threshold_WeightedVariance_', ObjectName], ...
                    WeightedVariance);
                handles = CPaddmeasurements(handles, 'Image', ...
                    ['Threshold_SumOfEntropies_', ObjectName], ...
                    SumOfEntropies);
            end

            handles = CPsaveObjectCount(handles, ObjectName, FinalLabelMatrixImage);
            handles = CPsaveObjectLocations(handles, ObjectName, FinalLabelMatrixImage);
        end

        if strcmp(TestMode,'Yes')
            if ~(LocalMaximaTypeNumber == 2 && WatershedTransformImageTypeNumber == 3)
                drawnow;
                %%% If the test mode window does not exist, it is created, but only
                %%% if it's at the starting image set (if the user closed the window
                %%% intentionally, we don't want to pop open a new one).
                IdPrimTestModeSegmentedFigureNumber = findobj('Tag','IdPrimTestModeSegmentedFigure');
                if isempty(IdPrimTestModeSegmentedFigureNumber) && handles.Current.SetBeingAnalyzed == handles.Current.StartingImageSet;
                    %%% Creates the window, sets its tag, and puts some
                    %%% text in it. The first lines are meant to find a suitable
                    %%% figure number for the window, so we don't choose a
                    %%% figure number that is being used by another module.
                    IdPrimTestModeSegmentedFigureNumber = CPfigurehandle(handles);
                    CPfigure(handles,'Image',IdPrimTestModeSegmentedFigureNumber);
                    set(IdPrimTestModeSegmentedFigureNumber,'Tag','IdPrimTestModeSegmentedFigure',...
                        'name','IdentifyPrimAutomatic Test Objects Display, cycle # ');
                    uicontrol(IdPrimTestModeSegmentedFigureNumber,'style','text','units','normalized','string','Identified objects are shown here. Note: Choosing "Do not use" for either option will result in the same image, therefore only the Intensity and "Do not use" option has been shown.','position',[.65 .1 .3 .4],'BackgroundColor',CPBackgroundColor())
                end
                %%% If the figure window DOES exist now, then calculate and display items
                %%% in it.
                if ~isempty(IdPrimTestModeSegmentedFigureNumber)
                    %%% Makes the window active.
                    CPfigure(IdPrimTestModeSegmentedFigureNumber(1));
                    %%% Updates the cycle number on the window.
                    CPupdatefigurecycle(handles.Current.SetBeingAnalyzed,IdPrimTestModeSegmentedFigureNumber);

                    hAx = subplot(2,3,WatershedTransformImageTypeNumber+3*(LocalMaximaTypeNumber-1));
                    im = CPlabel2rgb(handles,Objects);
                    CPimagesc(im,handles,hAx);
                    title(hAx,sprintf('%s and %s',LocalMaximaTypeList{LocalMaximaTypeNumber},WatershedTransformImageTypeList{WatershedTransformImageTypeNumber}));
                end

                %%% Repeat what we've done for the segmented test mode window, now
                %%% for the outlined test mode window.
                IdPrimTestModeOutlinedFigureNumber = findobj('Tag','IdPrimTestModeOutlinedFigure');
                if isempty(IdPrimTestModeOutlinedFigureNumber) && handles.Current.SetBeingAnalyzed == handles.Current.StartingImageSet;
                    IdPrimTestModeOutlinedFigureNumber = CPfigurehandle(handles);
                    CPfigure(handles,'Image',IdPrimTestModeOutlinedFigureNumber);
                    set(IdPrimTestModeOutlinedFigureNumber,'Tag','IdPrimTestModeOutlinedFigure',...
                        'name','IdentifyPrimAutomatic Test Outlines Display, cycle # ');
                    uicontrol(IdPrimTestModeOutlinedFigureNumber,'style','text','units','normalized','string','Outlined objects are shown here. Note: Choosing "Do not use" for either option will result in the same image, therefore only the Intensity and "Do not use" option has been shown.','position',[.65 .1 .3 .4],'BackgroundColor',CPBackgroundColor());
                end

                if ~isempty(IdPrimTestModeOutlinedFigureNumber)
                    CPfigure(IdPrimTestModeOutlinedFigureNumber(1));
                    CPupdatefigurecycle(handles.Current.SetBeingAnalyzed,IdPrimTestModeOutlinedFigureNumber);

                    tmp = OrigImage - min(OrigImage(:));
                    tmp = tmp/max(tmp(:));
                    OutlinedObjectsR = tmp;
                    OutlinedObjectsG = tmp;
                    OutlinedObjectsB = tmp;
                    PerimObjects = bwperim(Objects > 0);
                    PerimDiameter = bwperim(DiameterExcludedObjects > 0);
                    PerimBorder = bwperim(BorderObjects > 0);
                    OutlinedObjectsR(PerimObjects) = 0; OutlinedObjectsG(PerimObjects) = 1; OutlinedObjectsB(PerimObjects) = 0;
                    OutlinedObjectsR(PerimDiameter) = 1; OutlinedObjectsG(PerimDiameter)   = 0; OutlinedObjectsB(PerimDiameter)   = 0;
                    OutlinedObjectsR(PerimBorder) = 1; OutlinedObjectsG(PerimBorder) = 1; OutlinedObjectsB(PerimBorder) = 0;

                    hAx = subplot(2,3,WatershedTransformImageTypeNumber+3*(LocalMaximaTypeNumber-1));
                    OutlinedObjects = cat(3,OutlinedObjectsR,OutlinedObjectsG,OutlinedObjectsB);
                    CPimagesc(OutlinedObjects,handles,hAx);
                    title(hAx,sprintf('%s and %s',LocalMaximaTypeList{LocalMaximaTypeNumber},WatershedTransformImageTypeList{WatershedTransformImageTypeNumber}));
                end
            end
        end
    end
end

%%%%%%%%%%%%%%%%%%%%
%%% SUBFUNCTIONS %%%
%%%%%%%%%%%%%%%%%%%%

function Objects = MergeObjects(Objects,OrigImage,Diameters)

%%% Find the object that we should try to merge with other objects. The object
%%% numbers of these objects are stored in the variable 'MergeIndex'. The objects
%%% that we will try to merge are either the ones that fall below the specified
%%% MinDiameter threshold, or relatively small objects that are above the MaxEccentricity
%%% threshold. These latter objects are likely to be cells where two maxima have been
%%% found and the watershed transform has divided cells into two parts.
MinDiameter = Diameters(1);
MaxDiameter = Diameters(2);
MaxEccentricity = 0.75;      % Empirically determined value
warning('off', 'MATLAB:divideByZero'); %%% Matlab failing atan vs atan2 in regionprops line 672.
props = regionprops(Objects,'EquivDiameter','PixelIdxList','Eccentricity');   % Get diameters of the objects
warning('on', 'MATLAB:divideByZero');
EquivDiameters = cat(1,props.EquivDiameter);
Eccentricities = cat(1,props.Eccentricity);
IndexEccentricity = intersect(find(Eccentricities > MaxEccentricity),find(EquivDiameters < (MinDiameter + (MaxDiameter - MinDiameter)/4)));
IndexDiameter = find(EquivDiameters < MinDiameter);
MergeIndex = unique([IndexDiameter;IndexEccentricity]);

% Try to merge until there are no objects left in the 'MergeIndex' list.
[sr,sc] = size(OrigImage);
while ~isempty(MergeIndex)

    % Get next object to merge
    CurrentObjectNbr = MergeIndex(1);

    %%% Identify neighbors and put their label numbers in a list 'NeighborsNbr'
    %%% Cut a patch so we don't have to work with the entire image
    [r,c] = ind2sub([sr sc],props(CurrentObjectNbr).PixelIdxList);
    rmax = min(sr,max(r) + 3);
    rmin = max(1,min(r) - 3);
    cmax = min(sc,max(c) + 3);
    cmin = max(1,min(c) - 3);
    ObjectsPatch = Objects(rmin:rmax,cmin:cmax);
    BinaryPatch = double(ObjectsPatch == CurrentObjectNbr);
    GrownBinaryPatch = conv2(BinaryPatch,double(getnhood(strel('disk',2))),'same') > 0;
    Neighbors = ObjectsPatch .*GrownBinaryPatch;
    NeighborsNbr = setdiff(unique(Neighbors(:)),[0 CurrentObjectNbr]);


    %%% For each neighbor, calculate a set of criteria based on which we decide if to merge.
    %%% Currently, two criteria are used. The first is a Likelihood ratio that indicates whether
    %%% the interface pixels between the object to merge and its neighbor belong to a background
    %%% class or to an object class. The background class and object class are modeled as Gaussian
    %%% distributions with mean and variance estimated from the image. The Likelihood ratio determines
    %%% to which of the distributions the interface voxels most likely belong to. The second criterion
    %%% is the eccentrity of the object resulting from a merge. The more circular, i.e., the lower the
    %%% eccentricity, the better.
    LikelihoodRatio    = zeros(length(NeighborsNbr),1);
    MergedEccentricity = zeros(length(NeighborsNbr),1);
    for j = 1:length(NeighborsNbr)

        %%% Get Neigbor number
        CurrentNeighborNbr = NeighborsNbr(j);

        %%% Cut patch which contains both original object and the current neighbor
        [r,c] = ind2sub([sr sc],[props(CurrentObjectNbr).PixelIdxList;props(CurrentNeighborNbr).PixelIdxList]);
        rmax = min(sr,max(r) + 3);
        rmin = max(1,min(r) - 3);
        cmax = min(sc,max(c) + 3);
        cmin = max(1,min(c) - 3);
        ObjectsPatch = Objects(rmin:rmax,cmin:cmax);
        OrigImagePatch = OrigImage(rmin:rmax,cmin:cmax);

        %%% Identify object interiors, background and interface voxels
        BinaryNeighborPatch      = double(ObjectsPatch == CurrentNeighborNbr);
        BinaryObjectPatch        = double(ObjectsPatch == CurrentObjectNbr);
        GrownBinaryNeighborPatch = conv2(BinaryNeighborPatch,ones(3),'same') > 0;
        GrownBinaryObjectPatch   = conv2(BinaryObjectPatch,ones(3),'same') > 0;
        Interface                = GrownBinaryNeighborPatch.*GrownBinaryObjectPatch;
        Background               = ((GrownBinaryNeighborPatch + GrownBinaryObjectPatch) > 0) - BinaryNeighborPatch - BinaryObjectPatch - Interface;
        WithinObjectIndex        = find(BinaryNeighborPatch + BinaryObjectPatch);
        InterfaceIndex           = find(Interface);
        BackgroundIndex          = find(Background);

        %%% Calculate likelihood of the interface belonging to the background or to an object.
        WithinObjectClassMean   = mean(OrigImagePatch(WithinObjectIndex));
        WithinObjectClassStd    = std(OrigImagePatch(WithinObjectIndex)) + sqrt(eps);
        BackgroundClassMean     = mean(OrigImagePatch(BackgroundIndex));
        BackgroundClassStd      = std(OrigImagePatch(BackgroundIndex)) + sqrt(eps);
        InterfaceMean           = mean(OrigImagePatch(InterfaceIndex)); %#ok Ignore MLint
        LogLikelihoodObject     = -log(WithinObjectClassStd^2) - (InterfaceMean - WithinObjectClassMean)^2/(2*WithinObjectClassStd^2);
        LogLikelihoodBackground = -log(BackgroundClassStd^2) - (InterfaceMean - BackgroundClassMean)^2/(2*BackgroundClassStd^2);
        LikelihoodRatio(j)      =  LogLikelihoodObject - LogLikelihoodBackground;

        %%% Calculate the eccentrity of the object obtained if we merge the current object
        %%% with the current neighbor.
        MergedObject =  double((BinaryNeighborPatch + BinaryObjectPatch + Interface) > 0);
        tmp = regionprops(MergedObject,'Eccentricity');
        MergedEccentricity(j) = tmp(1).Eccentricity;

        %%% Get indexes for the interface pixels in original image.
        %%% These indexes are required if we need to merge the object with
        %%% the current neighbor.
        tmp = zeros(size(OrigImage));
        tmp(rmin:rmax,cmin:cmax) = Interface;
        tmp = regionprops(double(tmp),'PixelIdxList');
        OrigInterfaceIndex{j} = cat(1,tmp.PixelIdxList); %#ok Ignore MLint
    end

    %%% Let each feature rank which neighbor to merge with. Then calculate
    %%% a score for each neighbor. If the neighbors is ranked 1st, it will get
    %%% 1 point; 2nd, it will get 2 points; and so on. The lower score the better.
    [ignore,LikelihoodRank]   = sort(LikelihoodRatio,'descend'); %#ok Ignore MLint % The higher the LikelihoodRatio the better
    [ignore,EccentricityRank] = sort(MergedEccentricity,'ascend'); %#ok Ignore MLint % The lower the eccentricity the better
    NeighborScore = zeros(length(NeighborsNbr),1);
    for j = 1:length(NeighborsNbr)
        NeighborScore(j) = find(LikelihoodRank == j) +  find(EccentricityRank == j);
    end

    %%% Go through the neighbors, starting with the highest ranked, and merge
    %%% with the first neighbor for which certain basic criteria are fulfilled.
    %%% If no neighbor fulfil the basic criteria, there will be no merge.
    [ignore,TotalRank] = sort(NeighborScore); %#ok Ignore MLint
    for j = 1:length(NeighborsNbr)
        CurrentNeighborNbr = NeighborsNbr(TotalRank(j));

        %%% To merge, the interface between objects must be more likely to belong to the object class
        %%% than the background class. The eccentricity of the merged object must also be lower than
        %%% for the original object.
        if LikelihoodRatio(TotalRank(j)) > 0 && MergedEccentricity(TotalRank(j)) < Eccentricities(CurrentObjectNbr)

            %%% OK, let's merge!
            %%% Assign the neighbor number to the current object
            Objects(props(CurrentObjectNbr).PixelIdxList) = CurrentNeighborNbr;

            %%% Assign the neighbor number to the interface pixels between the current object and the neigbor
            Objects(OrigInterfaceIndex{TotalRank(j)}) = CurrentNeighborNbr;

            %%% Add the pixel indexes to the neigbor index list
            props(CurrentNeighborNbr).PixelIdxList = cat(1,...
                props(CurrentNeighborNbr).PixelIdxList,...
                props(CurrentObjectNbr).PixelIdxList,...
                OrigInterfaceIndex{TotalRank(j)});

            %%% Remove the neighbor from the list of objects to be merged (if it's there).
            MergeIndex = setdiff(MergeIndex,CurrentNeighborNbr);
        end
    end

    %%% OK, we are done with the current object, let's go to the next
    MergeIndex = MergeIndex(2:end);
end

%%% Finally, relabel the objects
Objects = bwlabel(Objects > 0);


%%%%%%%%%%%%%%%%%%%
%%% SUBFUNCTION %%%
%%%%%%%%%%%%%%%%%%%

function [xpts,ypts] = getpoints(AxisHandle)

Position = get(AxisHandle,'Position');
FigureHandle = (get(AxisHandle, 'Parent'));
PointHandles = [];
xpts = [];
ypts = [];
NbrOfPoints = 0;
done = 0;
%%% Turns off the CPimagetool function because it interferes with getting
%%% points.
ImageHandle = get(AxisHandle,'children');
set(ImageHandle,'ButtonDownFcn','');

hold on
while ~done;

    UserInput = waitforbuttonpress;                            % Wait for user input
    SelectionType = get(FigureHandle,'SelectionType');         % Get information about the last button press
    CharacterType = get(FigureHandle,'CurrentCharacter');      % Get information about the character entered

    % Left mouse button was pressed, add a point
    if UserInput == 0 && strcmp(SelectionType,'normal')

        % Get the new point and store it
        CurrentPoint  = get(AxisHandle, 'CurrentPoint');
        xpts = [xpts CurrentPoint(2,1)];
        ypts = [ypts CurrentPoint(2,2)];
        NbrOfPoints = NbrOfPoints + 1;

        % Plot the new point
        h = plot(CurrentPoint(2,1),CurrentPoint(2,2),'r.');
        set(AxisHandle,'Position',Position)                   % For some reason, Matlab moves the Title text when the first point is plotted, which in turn resizes the image slightly. This line restores the original size of the image
        PointHandles = [PointHandles h];

        % If there are any points, and the right mousebutton or the backspace key was pressed, remove a points
    elseif NbrOfPoints > 0 && ((UserInput == 0 && strcmp(SelectionType,'alt')) || (UserInput == 1 && CharacterType == char(8)))   % The ASCII code for backspace is 8

        NbrOfPoints = NbrOfPoints - 1;
        xpts = xpts(1:end-1);
        ypts = ypts(1:end-1);
        delete(PointHandles(end));
        PointHandles = PointHandles(1:end-1);

        % Enter key was pressed, manual outlining done, and the number of points are at least 3
    elseif NbrOfPoints >= 3 && UserInput == 1 && CharacterType == char(13)

        % Indicate that we are done
        done = 1;
%{
        % Close the curve by making the first and last points the same
        xpts = [xpts xpts(1)];
        ypts = [ypts ypts(1)];
%}
        % Remove plotted points
        if ~isempty(PointHandles)
            delete(PointHandles)
        end

    end
    %{
    % Remove old spline and draw new
    if exist('SplineCurve','var')
        delete(SplineCurve)                                % Delete the graphics object
        clear SplineCurve                                  % Clear the variable
    end
    if NbrOfPoints > 1
        q = 0:length(xpts)-1;
        qq = 0:0.1:length(xpts)-1;                          % Increase the number of points 10 times using spline interpolation
        xpts_spline = spline(q,xpts,qq);
        ypts_spline = spline(q,ypts,qq);
        SplineCurve = plot(xpts_spline,ypts_spline,'r');
        drawnow
    else
        xpts_spline = xpts;
        ypts_spline = ypts;
    end
    %}
end
xpts = round(xpts);
ypts = round(ypts);
hold off
set(ImageHandle,'ButtonDownFcn','CPimagetool');