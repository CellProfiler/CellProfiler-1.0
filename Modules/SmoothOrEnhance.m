function handles = SmoothOrEnhance(handles)

% Help for the SmoothOrEnhance module:
% Category: Image Processing
%
% SHORT DESCRIPTION:
% Smooths (blurs) or enhances (sharpens) images.
% *************************************************************************
%
% Settings:
%
% Smoothing Method:
% Note that smoothing is a time-consuming process, and fitting a polynomial
% is fastest but does not allow a very tight fit as compared to the slower
% median filtering method. Artifacts with widths over ~50 take substantial
% amounts of time to process.
%
% BRIGHT SPECKLE DETECTION: 'Enhance BrightRoundSpeckles' performs
% morphological tophat filtering, which has the effect of enhancing round
% objects with size equal to, or slightly smaller than, the ObjectWidth setting.
%   'Remove BrightRoundSpeckles' is a filtering method to remove bright, round
% speckles, equivalent to a morphological open operation (an erosion followed by a dilation).
% When followed by a Subtract module which subtracts the smoothed image from the original,
% bright round-shaped speckles will be enhanced. This is effectively the
% same as 'Enhance BrightRoundSpeckles', or tophat filtering.  We used
% MATLAB's built-in imtophat and imopen function to perform these
% operations; more information can be found by accessing MATLAB's help at
% http://www.mathworks.com.
%   Then, you could use the ApplyThreshold module to make a binary
% speckles/non-speckles image. Furthermore, the IdentifyPrimAutomatic can
% be used on the thresholded image to label each speckle for your analysis.
%
% ENHANCE NEURITES: This method maximizes the contrast of objects slightly
% less than the width of the Object Width setting, while leaving other
% structures intact.  For example, this is useful for enhancing thin
% neurite processes while leaving cell bodies morphologically intact.
% The algorithm applied is Orig+tophat(Orig)-bottomhat(Orig), from
% Zhang et al., 2007, J. Neuroscience Methods.
%
% ENHANCE DARK HOLES: This method fills in dark holes surrounded by a
% bright ring. The result is an image in which the holes appear as bright
% spots. A range of filter sizes can be provided to capture variations in
% ring diameter.
%
% SMOOTH KEEPING EDGES: 'Smooth Keeping Edges' smooths the images while
% preserving the edges. It uses the Bilateral Filter, as implemented by
% Jiawen Chen.
%
% Special note on saving images: If you want to save the smoothed image to
% your computer to use it for later sessions in CellProfiler, you should
% save the smoothed image in '.mat' format to prevent degradation of the
% data.
%
% Technical note on the median filtering method: the artifact width is
% divided by two to obtain the radius of a disk-shaped structuring element
% which is used for filtering. No longer done this way.
%
% See also CorrectIllumination_Apply, CorrectIllumination_Calculate.

% CellProfiler is distributed under the GNU General Public License.
% See the accompanying file LICENSE for details.
%
% Developed by the Whitehead Institute for Biomedical Research.
% Copyright 2003,2004,2005.
%
% Please see the AUTHORS file for credits.
%
% Website: http://www.cellprofiler.org
%
% $Revision$

% Variable Settings for PyCP
%
% SEE ALSO: notes in the FindEdges module.
%
% Var 3: should re-word to be "What type of filtering would you like to
% perform?" It's understandable to use the word "filtering" rather than "smoothing or
% enhancing", right? I think it's still ok to leave the name of the module
% as SmoothOrEnhance though. We should change the input/output image
% questions to say "filter" rather than "smooth" also.
%
% Vars 4 & 5: I've always thought it's odd how we let them specify an
% object size but then also let them specify a filter, which overrides
% it.  This variable should be context dependent, so if the user selects
% fit polynomial, it should not appear.  I think maybe it is best to just
% combine these with a statement like, "Please enter an object size.  This
% will be used as the filter size." and leave automatic as an option, or
% some similar wording so it's clear at least whats going on.

% I'm confused about variable 6; Why would you need to do that if the
% illum. cxn modules have smoothing in them?  I can't think of any other
% case where you would have an image resulting from processing multiple
% cycles other than an average or projected image; and the illum cxn module
% allows you to smooth an averaged image.  So I guess this allows for the
% case of (1)Making a max. projection (2)Filtering or smoothing that
% resulting image in some way.  seems like there should be a better way...?
% Or CellProfiler should be smarter in knowing when an image has finished
% processing...
% Note from Anne: I agree it's confusing. It's handy if you
% want to try multiple smoothing settings in an illumination correction
% pipeline (so you would put several Smooth modules in and save the result
% of each one so that you can compare them later).
% But perhaps this question needs to stay as
% is?  I'm not sure whether the new image grouping situation will solve
% this issue. With variable 6, this module is essentially trying to let you do a
% complicated pipeline where some modules of the pipeline are executed once per
% cycle and others are executed once for the whole run. This functionality
% might be replaced by the new image grouping... or it might break it!  I'm
% not really sure.

% Vars 7&8: should be context-dependent and only show up if you pick Smooth
% keeping edges.
% For Var7, I've never understood what 'preserved objects' are.
% For Var8, I dont like the idea of 0.0 being equivalent to 'calculate from
% the image'.  This could be asked in a better way like, 'What is the
% intensity step that indicates an edge, in intensity units?' (we can just
% divide this number to get the intensity-based radius) and have 'Calculate
% from Image' be an option.

% Anne 4-9-09: The help for this module is quite out of date!


%%%%%%%%%%%%%%%%%
%%% VARIABLES %%%
%%%%%%%%%%%%%%%%%
drawnow

[CurrentModule, CurrentModuleNum, ModuleName] = CPwhichmodule(handles);

%textVAR01 = What did you call the image to be smoothed?
%infotypeVAR01 = imagegroup
OrigImageName = char(handles.Settings.VariableValues{CurrentModuleNum,1});
%inputtypeVAR01 = popupmenu

%textVAR02 = What do you want to call the smoothed image?
%defaultVAR02 = CorrBlue
%infotypeVAR02 = imagegroup indep
SmoothedImageName = char(handles.Settings.VariableValues{CurrentModuleNum,2});

%textVAR03 = Enter the smoothing method you would like to use.
%choiceVAR03 = Fit Polynomial
%choiceVAR03 = Median Filter
%choiceVAR03 = Gaussian Filter
%choiceVAR03 = Remove BrightRoundSpeckles
%choiceVAR03 = Enhance BrightRoundSpeckles (Tophat Filter)
%choiceVAR03 = Smooth Keeping Edges
%choiceVAR03 = Enhance Neurites (I+Tophat-Bothat)
%choiceVAR03 = Enhance Dark Holes
SmoothingMethod = char(handles.Settings.VariableValues{CurrentModuleNum,3});
%inputtypeVAR03 = popupmenu

%textVAR04 = If you choose any setting besides 'Fit Polynomial' as your smoothing method, please specify the approximate width of the objects in your image (in pixels). This will be used to calculate an adequate filter size. If you don't know the width of your objects, you can use the ShowOrHidePixelData image tool to find out or leave the word 'Automatic'. For 'Enhance Dark Holes', a range of values may be used, separated by a hyphen.
%defaultVAR04 = Automatic
ObjectWidth = handles.Settings.VariableValues{CurrentModuleNum,4};

%textVAR05 = If you want to use your own filter size (in pixels), please specify it here. Otherwise, leave "Do not use". If you entered a width for the previous variable, this will override it.
%defaultVAR05 = Do not use
SizeOfSmoothingFilter = char(handles.Settings.VariableValues{CurrentModuleNum,5});

%textVAR06 = Are you using this module to smooth an image that results from processing multiple cycles?  (If so, this module will wait until it sees a flag that the other module has completed its calculations before smoothing is performed).
%choiceVAR06 = No
%choiceVAR06 = Yes
WaitForFlag = char(handles.Settings.VariableValues{CurrentModuleNum,6});
WaitForFlag = WaitForFlag(1);
%inputtypeVAR06 = popupmenu

%textVAR07 = If you choose 'Smooth Keeping Edges', what spatial filter radius should be used, in pixels? (The approximate size of preserved objects is good)?
%defaultVAR07 = 16.0
SpatialRadius = str2double(char(handles.Settings.VariableValues{CurrentModuleNum,7}));

%textVAR08 = If you choose 'Smooth Keeping Edges', what intensity-based radius should be used, in intensity units? (Half the intensity step that indicates an edge is good.  Set to 0.0 to calculate from the image.)?
%defaultVAR08 = 0.1
IntensityRadius = str2double(char(handles.Settings.VariableValues{CurrentModuleNum,8}));

%%%VariableRevisionNumber = 5

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% PRELIMINARY CALCULATIONS & FILE HANDLING %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
drawnow

%%% The following checks to see whether it is appropriate to calculate the
%%% smooth image at this time or not.  If not, the return function abandons
%%% the remainder of the code, which will otherwise calculate the smooth
%%% image, save it to the handles, and display the results.
if strncmpi(WaitForFlag,'Y',1) == 1
    fieldname = [OrigImageName,'ReadyFlag'];
    ReadyFlag = CPretrieveimages(handles,fieldname,ModuleName);
    if ~ReadyFlag
        %%% If the projection image is not ready, the module aborts until
        %%% the next cycle.
        ThisModuleFigureNumber = handles.Current.(['FigureNumberForModule',CurrentModule]);
        if any(findobj == ThisModuleFigureNumber)
            CPfigure(handles,'Image',ThisModuleFigureNumber);
            title('Results will be shown after the last image cycle only if this window is left open.')
        end
        return;
    elseif ReadyFlag
        %%% If the smoothed image has already been calculated, the module
        %%% aborts until the next cycle. Otherwise we continue in this
        %%% module and calculate the smoothed image.
        if CPisimageinpipeline(handles, SmoothedImageName)
            return;
        end
        %%% If we make it to this point, it is OK to proceed to calculating the smooth
        %%% image, etc.
    else error(['Image processing was canceled in the ', ModuleName, ' module because there is a programming error of some kind. The module was expecting to find the text Ready or NotReady in the field called ', fieldname, ' but that text was not matched for some reason.'])
    end
end

%%% If we make it to this point, it is OK to proceed to calculating the smooth
%%% image, etc.

%%% Some variable checking:

if ~strcmp(SizeOfSmoothingFilter,'Do not use')
    SizeOfSmoothingFilter = str2double(SizeOfSmoothingFilter);
    if isnan(SizeOfSmoothingFilter) || (SizeOfSmoothingFilter < 1)
        if isempty(findobj('Tag',['Msgbox_' ModuleName ', ModuleNumber ' num2str(CurrentModuleNum) ': Smoothing size invalid']))
            CPwarndlg(['The size of the smoothing filter you specified  in the ', ModuleName, ' module is invalid, it is being reset to Automatic.'],[ModuleName ', ModuleNumber ' num2str(CurrentModuleNum) ': Smoothing size invalid'],'replace');
        end
        SizeOfSmoothingFilter = 'A';
        WidthFlg = 0;
    else
        SizeOfSmoothingFilter = floor(SizeOfSmoothingFilter);
        WidthFlg = 0;
    end
else
    if ~isempty(regexp(ObjectWidth,'\d+','once'))
        ObjectWidth = str2double(regexp(ObjectWidth,'\d+','match'));
        if length(ObjectWidth) == 1  % Single number,
            if isnan(ObjectWidth) || ObjectWidth < 0
                if isempty(findobj('Tag',['Msgbox_' ModuleName ', ModuleNumber ' num2str(CurrentModuleNum) ': Object width invalid']))
                    CPwarndlg(['The object width you specified  in the ', ModuleName, ' module is invalid, it is being reset to Automatic.'],[ModuleName ', ModuleNumber ' num2str(CurrentModuleNum) ': Object width invalid'],'replace');
                end
                SizeOfSmoothingFilter = 'A';
                WidthFlg = 0;
            else
                SizeOfSmoothingFilter = 2*floor(ObjectWidth/2);
                WidthFlg = 1;
            end
        else % Range of numbers
            if isempty(strfind(SmoothingMethod,'Dark Holes'))
                CPwarndlg(['The object width you specified  in the ', ModuleName, ' module is not appropriate for Enhance Dark Holes, it is being reset to Automatic.'],[ModuleName ', ModuleNumber ' num2str(CurrentModuleNum) ': Object width invalid'],'replace');
                SizeOfSmoothingFilter = 'A';
                WidthFlg = 0;
            else
                SizeOfSmoothingFilter = 2*floor(ObjectWidth/2);
                WidthFlg = 1;
            end
        end
    else
        SizeOfSmoothingFilter = 'A';
        WidthFlg = 0;
    end
end

%%% Reads (opens) the image you want to analyze and assigns it to a
%%% variable.
try
    OrigImage = CPretrieveimage(handles,OrigImageName,ModuleName,'MustBeGray','CheckScale');
catch
    ErrorMessage = lasterr;
    error(['Image processing was canceled in the ' ModuleName ' module because: ' ErrorMessage(33:end)]);
end

%%%%%%%%%%%%%%%%%%%%%%
%%% IMAGE ANALYSIS %%%
%%%%%%%%%%%%%%%%%%%%%%
drawnow

%%% Smooths the OrigImage according to the user's specifications.
try
    if strcmp(SmoothingMethod,'Smooth Keeping Edges')
        if (IntensityRadius == 0.0),
            % use MAD of gradients to estimate scale, use half that estimate
            % XXX - adjust such that it returns 1.0 for worm images.
            IntensityRadius = ImageMAD(OrigImage) / 2.0;
        end

        SmoothedImage = bilateralFilter(OrigImage, OrigImage, SpatialRadius, IntensityRadius,...
            SpatialRadius / 2.0, IntensityRadius / 2.0);
    else
        [SmoothedImage ignore SizeOfSmoothingFilterUsed] = CPsmooth(OrigImage,SmoothingMethod,SizeOfSmoothingFilter,WidthFlg);
    end
catch
    ErrorMessage = lasterr;
    error(['Image processing was canceled in the ' ModuleName ' module because: ' ErrorMessage(26:end)]);
end

%%%%%%%%%%%%%%%%%%%%%%%
%%% DISPLAY RESULTS %%%
%%%%%%%%%%%%%%%%%%%%%%%
drawnow

ThisModuleFigureNumber = handles.Current.(['FigureNumberForModule',CurrentModule]);
if any(findobj == ThisModuleFigureNumber)
    %%% Activates the appropriate figure window.
    CPfigure(handles,'Image',ThisModuleFigureNumber);
    if handles.Current.SetBeingAnalyzed == handles.Current.StartingImageSet
        CPresizefigure(OrigImage,'TwoByOne',ThisModuleFigureNumber)
    end
    %%% A subplot of the figure window is set to display the original
    %%% image and the smoothed image.
    hAx=subplot(2,1,1,'Parent',ThisModuleFigureNumber);
    CPimagesc(OrigImage,handles,hAx);
    title(hAx,['Input Image, cycle # ',num2str(handles.Current.SetBeingAnalyzed)]);
    hAx=subplot(2,1,2,'Parent',ThisModuleFigureNumber);
    CPimagesc(SmoothedImage,handles,hAx);
    title(hAx,'Smoothed Image');
    if ~ strcmp(SmoothingMethod,'Smooth Keeping Edges')
        text(0.05, -0.15, ...
            ['Size of Smoothing Filter: ' num2str(SizeOfSmoothingFilterUsed)],...
            'Units','Normalized',...
            'fontsize',handles.Preferences.FontSize,...
            'Parent',hAx);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% SAVE DATA TO HANDLES STRUCTURE %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
drawnow

%%% Saves the processed image to the handles structure so it can be used by
%%% subsequent modules.
handles = CPaddimages(handles,SmoothedImageName,SmoothedImage);

function MAD = ImageMAD(Image)
    GradientImage = Image(:,1:end-1)-Image(:,2:end);
    MAD = median(abs(GradientImage(:) - median(GradientImage(:))));


% Code below is (C) Jiawen Chen, MIT CSAIL, and distributed under the
% MIT License.
%
% output = bilateralFilter( data, edge, sigmaSpatial, sigmaRange, ...
%                          samplingSpatial, samplingRange )
%
% Bilateral and Cross-Bilateral Filter
%
% Bilaterally filters the image 'data' using the edges in the image 'edge'.
% If 'data' == 'edge', then it the normal bilateral filter.
% Else, then it is the "cross" or "joint" bilateral filter.
%
% Note that for the cross bilateral filter, data does not need to be
% defined everywhere.  Undefined values can be set to 'NaN'.  However, edge
% *does* need to be defined everywhere.
%
% data and edge should be of the same size and greyscale.
% (i.e. they should be ( height x width x 1 matrices ))
%
% data is the only required argument
%
% By default:
% edge = data
% sigmaSpatial = samplingSpatial = min( width, height ) / 16;
% sigmaRange = samplingRange = ( max( edge( : ) ) - min( edge( : ) ) ) / 10
%
%
function output = bilateralFilter( data, edge, sigmaSpatial, sigmaRange, samplingSpatial, samplingRange )

if ~exist( 'edge', 'var' ),
    edge = data;
end

inputHeight = size( data, 1 );
inputWidth = size( data, 2 );

if ~exist( 'sigmaSpatial', 'var' ),
    sigmaSpatial = min( inputWidth, inputHeight ) / 16;
end

edgeMin = min( edge( : ) );
edgeMax = max( edge( : ) );
edgeDelta = edgeMax - edgeMin;

if ~exist( 'sigmaRange', 'var' ),
    sigmaRange = 0.1 * edgeDelta;
end

if ~exist( 'samplingSpatial', 'var' ),
    samplingSpatial = sigmaSpatial;
end

if ~exist( 'samplingRange', 'var' ),
    samplingRange = sigmaRange;
end

if size( data ) ~= size( edge ),
    error( 'data and edge must be of the same size' );
end

% parameters
derivedSigmaSpatial = sigmaSpatial / samplingSpatial;
derivedSigmaRange = sigmaRange / samplingRange;

paddingXY = floor( 2 * derivedSigmaSpatial ) + 1;
paddingZ = floor( 2 * derivedSigmaRange ) + 1;

% allocate 3D grid
downsampledWidth = floor( ( inputWidth - 1 ) / samplingSpatial ) + 1 + 2 * paddingXY;
downsampledHeight = floor( ( inputHeight - 1 ) / samplingSpatial ) + 1 + 2 * paddingXY;
downsampledDepth = floor( edgeDelta / samplingRange ) + 1 + 2 * paddingZ;

gridData = zeros( downsampledHeight, downsampledWidth, downsampledDepth );
gridWeights = zeros( downsampledHeight, downsampledWidth, downsampledDepth );

% compute downsampled indices
[ jj, ii ] = meshgrid( 0 : inputWidth - 1, 0 : inputHeight - 1 );

% ii =
% 0 0 0 0 0
% 1 1 1 1 1
% 2 2 2 2 2

% jj =
% 0 1 2 3 4
% 0 1 2 3 4
% 0 1 2 3 4

% so when iterating over ii( k ), jj( k )
% get: ( 0, 0 ), ( 1, 0 ), ( 2, 0 ), ... (down columns first)

di = round( ii / samplingSpatial ) + paddingXY + 1;
dj = round( jj / samplingSpatial ) + paddingXY + 1;
dz = round( ( edge - edgeMin ) / samplingRange ) + paddingZ + 1;

% perform scatter (there's probably a faster way than this)
% normally would do downsampledWeights( di, dj, dk ) = 1, but we have to
% perform a summation to do box downsampling

for k = 1 : numel( dz ),

    dataZ = data( k ); % traverses the image column wise, same as di( k )
    if ~isnan( dataZ  ),

        dik = di( k );
        djk = dj( k );
        dzk = dz( k );

        gridData( dik, djk, dzk ) = gridData( dik, djk, dzk ) + dataZ;
        gridWeights( dik, djk, dzk ) = gridWeights( dik, djk, dzk ) + 1;

    end
end

% make gaussian kernel
kernelWidth = 2 * derivedSigmaSpatial + 1;
kernelHeight = kernelWidth;
kernelDepth = 2 * derivedSigmaRange + 1;

halfKernelWidth = floor( kernelWidth / 2 );
halfKernelHeight = floor( kernelHeight / 2 );
halfKernelDepth = floor( kernelDepth / 2 );

[gridX, gridY, gridZ] = meshgrid( 0 : kernelWidth - 1, 0 : kernelHeight - 1, 0 : kernelDepth - 1 );
gridX = gridX - halfKernelWidth;
gridY = gridY - halfKernelHeight;
gridZ = gridZ - halfKernelDepth;
gridRSquared = ( gridX .* gridX + gridY .* gridY ) / ( derivedSigmaSpatial * derivedSigmaSpatial ) + ( gridZ .* gridZ ) / ( derivedSigmaRange * derivedSigmaRange );
kernel = exp( -0.5 * gridRSquared );

% convolve
blurredGridData = convn( gridData, kernel, 'same' );
blurredGridWeights = convn( gridWeights, kernel, 'same' );

% divide
blurredGridWeights( blurredGridWeights == 0 ) = -2; % avoid divide by 0, won't read there anyway
normalizedBlurredGrid = blurredGridData ./ blurredGridWeights;
normalizedBlurredGrid( blurredGridWeights < -1 ) = 0; % put 0s where it's undefined
blurredGridWeights( blurredGridWeights < -1 ) = 0; % put zeros back

% upsample
[ jj, ii ] = meshgrid( 0 : inputWidth - 1, 0 : inputHeight - 1 ); % meshgrid does x, then y, so output arguments need to be reversed
% no rounding
di = ( ii / samplingSpatial ) + paddingXY + 1;
dj = ( jj / samplingSpatial ) + paddingXY + 1;
dz = ( edge - edgeMin ) / samplingRange + paddingZ + 1;

% interpn takes rows, then cols, etc
% i.e. size(v,1), then size(v,2), ...
output = interpn( normalizedBlurredGrid, di, dj, dz );
