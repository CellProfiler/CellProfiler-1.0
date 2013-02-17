function [SmoothedImage RealFilterLength SizeOfSmoothingFilterUsed] = CPsmooth(OrigImage,SmoothingMethod,SizeOfSmoothingFilter,WidthFlg,varargin)

% This subfunction is used for several modules, including SMOOTH, AVERAGE,
% CORRECTILLUMINATION_APPLY, CORRECTILLUMINATION_CALCULATE,
% IDENTIFYPRIMAUTOMATIC
%
% The function takes an optional mask parameter which causes the algorithms
% to ignore points outside of the mask.
%
% SizeOfSmoothingFilter = Diameter of the Filter Window (Box).
%                       ~ roughly equal to object diameter
%
% CellProfiler is distributed under the GNU General Public License.
% See the accompanying file LICENSE for details.
%
% Developed by the Whitehead Institute for Biomedical Research.
% Copyright 2003,2004,2005.
%
% Developed by the Broad Institute of MIT and Harvard
%
% Please see the AUTHORS file for credits.
%
% Website: http://www.cellprofiler.org
%
% $Revision$

%%% If SizeOfSmoothingFilter(S) >= LARGESIZE_OF_SMOOTHINGFILTER (L),
%%% then rescale the original image by L/S, and rescale S to L.
%%% It is a predefined effective maximum filter size (diameter).
LARGESIZE_OF_SMOOTHINGFILTER = 50;

SmoothedImage = OrigImage;
RealFilterLength = 0;
SizeOfSmoothingFilterUsed =0;

if nargin > 4
    HasMask = 1;
    MaskImage = varargin{1};
else
    HasMask = 0;
end

%%% For now, nothing fancy is done to calculate the size automatically. We
%%% just choose 1/40 the size of the image, with a min of 1 and max of 30.
if strcmpi(SizeOfSmoothingFilter,'A')
    if size(OrigImage,3) > 1
        error('CPSmooth only works on grayscale images.')
    end
    SizeOfSmoothingFilter = min(30,max(1,ceil(mean(size(OrigImage))/40))); % Get size of filter
    WidthFlg = 0;
end

%%% If we are NOT using the polynomial method and the user set the Size of
%%% Smoothing Filter to be 0, no smoothing will be done.
if all(SizeOfSmoothingFilter == 0) && ~strncmp(SmoothingMethod,'P',1)
    %%% No blurring is done.
    return;
end

%%% If the incoming image is binary (logical), we convert it to grayscale.
if islogical(OrigImage)
    OrigImage = im2double(OrigImage);
    %OrigImage = im2single(OrigImage);
end

%%% For faster smoothing with a large filter size:
%%% If the SizeOfSmoothingFilter is greather than
%%% LARGESIZE_OF_SMOOTHINGFILTER, then we resize the original image
%%% Tip: Smoothing with filter size LARGESIZE_OF_SMOOTHINGFILTER is the slowest.
if (max(SizeOfSmoothingFilter) >= LARGESIZE_OF_SMOOTHINGFILTER) && HasMask == 0
    ResizingFactor = LARGESIZE_OF_SMOOTHINGFILTER./SizeOfSmoothingFilter;
    original_row = size(OrigImage,1);
    original_col = size(OrigImage,2);
    OrigImage = imresize(OrigImage, ResizingFactor);
    SizeOfSmoothingFilter = SizeOfSmoothingFilter.*ResizingFactor;
    Resized = 1;
else
    Resized = 0;
end

switch lower(SmoothingMethod)
    case {'fit polynomial','p'}
        %%% The following is used to fit a low-dimensional polynomial to
        %%% the original image. The SizeOfSmoothingFilter is not relevant
        %%% for this method.
        [x,y] = meshgrid(1:size(OrigImage,2), 1:size(OrigImage,1));
        x2 = x.*x;
        y2 = y.*y;
        xy = x.*y;
        o = ones(size(OrigImage));
        drawnow
        if HasMask
            Ind = find((OrigImage & MaskImage) > 0);
        else
            Ind = find(OrigImage > 0);
        end
        Coeffs = [x2(Ind) y2(Ind) xy(Ind) x(Ind) y(Ind) o(Ind)] \ double(OrigImage(Ind));
        drawnow
        SmoothedImage = reshape([x2(:) y2(:) xy(:) x(:) y(:) o(:)] * Coeffs, size(OrigImage));
    %%% Note: we decided that sum of squares and square of sums are rarely
    %%% used for anything (they were historically used for an undergrad
    %%% project implementing a published method for worm-finding) so most
    %%% modules don't directly allow choosing these methods.
    case {'sum of squares','s'}
        %%% The following is used for the Sum of squares method.
        FiltLength = SizeOfSmoothingFilter;
        PaddedImage = padarray(OrigImage,[FiltLength FiltLength],'replicate');
        %%% Could be good to use a disk structuring element of
        %%% floor(FiltLength/2) radius instead of a square window, or allow
        %%% user to choose.
        SmoothedImage = conv2(PaddedImage.^2,ones(FiltLength,FiltLength),'same');
        SmoothedImage = SmoothedImage(FiltLength+1:end-FiltLength,FiltLength+1:end-FiltLength);
        RealFilterLength=2*FiltLength;
        SizeOfSmoothingFilterUsed = SizeOfSmoothingFilter;
    case {'square of sum','q'}
        %%% The following is used for the Square of sum method.
        FiltLength = SizeOfSmoothingFilter;
        PaddedImage = padarray(OrigImage,[FiltLength FiltLength],'replicate');
        %%% Could be good to use a disk structuring element of
        %%% floor(FiltLength/2) radius instead of a square window, or allow
        %%% user to choose.
        SumImage = conv2(PaddedImage,ones(FiltLength,FiltLength),'same');
        SmoothedImage = SumImage.^2;
        SmoothedImage = SmoothedImage(FiltLength+1:end-FiltLength,FiltLength+1:end-FiltLength);
        RealFilterLength=2*FiltLength;
        SizeOfSmoothingFilterUsed = SizeOfSmoothingFilter;
    case 'median filter'
        %%% The following is used for the Median Filtering smoothing method
        %%% medfilt2 on double images is too slow. Let's covert it to uint16 which is much faster!
        %%% Let's get pixel values stretched from [min,max] to [0,1] for the best precision/accuracy
        maxval = max(OrigImage(:));
        minval = min(OrigImage(:));
        if HasMask
            %%% If we alternate large and small values for the points
            %%% in the masked image, then the median will not be these points.
            SavedImage = im2double(OrigImage);
            pts = find(~MaskImage);
            OrigImage(pts(mod(pts,2)>0))= minval;
            OrigImage(pts(mod(pts,2)>0))= maxval;
        end
        range = maxval - minval;
        RESCALE_FLAG = maxval ~= minval;
        if (RESCALE_FLAG) % stretch the range to [0,1] for best precision
            OrigImage = (OrigImage-minval)./range;
        end
        SmoothedImage = medfilt2(im2uint16(OrigImage),[SizeOfSmoothingFilter SizeOfSmoothingFilter],'symmetric');
        SmoothedImage = im2double(SmoothedImage);
        SizeOfSmoothingFilterUsed = SizeOfSmoothingFilter;
        if HasMask
            SmoothedImage(~MaskImage)=SavedImage(~MaskImage);
        end
        if (RESCALE_FLAG) % return to the original range of OrigImage;
            SmoothedImage = SmoothedImage.*double(range) + double(minval);
        end
    case {'median filtering','m'}
        %%% We leave this SmoothingMethod to be compatible with previous
        %%% pipelines that used 'median filtering'
        CPwarndlg('The smoothing method ''Median Filtering'' is not valid any more. Please replace it with ''Gaussian Filtering'' if you still want to make your pipeline working as it was. Or use ''Median Filter'' which was re-implemented.');
    case 'gaussian filter'
        %%% The following is used for the Gaussian lowpas filtering method.
        if WidthFlg
            %%% Empirically done (from IdentifyPrimAutomatic)
            sigma = SizeOfSmoothingFilter/3.5;
        else
            sigma = SizeOfSmoothingFilter/2.35; % Convert between Full Width at Half Maximum (FWHM) to sigma
        end
        h = fspecial('gaussian', [round(SizeOfSmoothingFilter) round(SizeOfSmoothingFilter)], sigma);
        if HasMask
            OrigImage(~MaskImage) = 0;
        end
        SmoothedImage = imfilter(OrigImage, h, 'replicate');
        SizeOfSmoothingFilterUsed = SizeOfSmoothingFilter;
        %%% If the image was masked, the filter will darken the areas near
        %%% the masked part. We can figure out the fraction darkened by
        %%% filtering the mask - then, at each point, we get the fraction
        %%% of the convolution that's not mask. Divide by this to just
        %%% get the masked convolution.
        if HasMask
            SmoothedMask = imfilter(im2double(MaskImage), h, 'replicate');
            SmoothedImage(MaskImage~=0) = SmoothedImage(MaskImage~=0) ./ SmoothedMask(MaskImage~=0);
            SmoothedImage(~MaskImage) = 0;
        end
%       [Kyungnam Jul-30-2007: The following old code that was replaced with the above code has been left for reference]
%         FiltLength = min(30,max(1,ceil(2*sigma))); % Determine filter size, min 3 pixel, max 61
%         [x,y] = meshgrid(-FiltLength:FiltLength,-FiltLength:FiltLength);      % Filter kernel grid
%         f = exp(-(x.^2+y.^2)/(2*sigma^2));f = f/sum(f(:));                    % Gaussian filter kernel
%         %%% The original image is blurred. Prior to this blurring, the
%         %%% image is padded with values at the edges so that the values
%         %%% around the edge of the image are not artificially low.  After
%         %%% blurring, these extra padded rows and columns are removed.
%         SmoothedImage = conv2(padarray(OrigImage, [FiltLength,FiltLength], 'replicate'),f,'same');
%         SmoothedImage = SmoothedImage(FiltLength+1:end-FiltLength,FiltLength+1:end-FiltLength);
%         % I think this is wrong, but we should ask Ray.
%         % RealFilterLength = 2*FiltLength+1;
%         RealFilterLength = FiltLength;
    %%% Note: many modules currently aren't allowing this method to be
    %%% chosen. We should change that!
    case {'smooth to average','a'}
        %%% The following is used for the Smooth to average method.
        %%% Creates an image where every pixel has the value of the mean of the original
        %%% image.
        if HasMask
            SmoothedImage = mean(OrigImage(MaskImage~=0)) * ones(size(OrigImage));
        else
            SmoothedImage = mean(OrigImage(:))*ones(size(OrigImage));
        end
%       [Kyungnam Jul-30-2007: If you want to use the traditional averaging filter, use the following]
%        h = fspecial('average', [SizeOfSmoothingFilter SizeOfSmoothingFilter]);
%        SmoothedImage = imfilter(OrigImage, h, 'replicate');
    case 'remove brightroundspeckles'
        %%% It does a grayscale open morphological operation. Effectively,
        %%% it removes speckles of SizeOfSmoothingFilter brighter than its
        %%% surroundings. If combined with the 'Subtract' module, it
        %%% behaves like a tophat filter
        SPECKLE_RADIUS = round(SizeOfSmoothingFilter/2);
        disk_radius = round(SPECKLE_RADIUS);
        SE = strel('disk', disk_radius);
        SmoothedImage = imopen(OrigImage, SE);
        SizeOfSmoothingFilterUsed = SizeOfSmoothingFilter;
    case 'enhance brightroundspeckles (tophat filter)'
        SPECKLE_RADIUS = round(SizeOfSmoothingFilter/2);
        disk_radius = round(SPECKLE_RADIUS);
        SE = strel('disk', disk_radius);
        SmoothedImage = imtophat(OrigImage,SE);
        SizeOfSmoothingFilterUsed = SizeOfSmoothingFilter;
    case 'enhance neurites (i+tophat-bothat)'
        SPECKLE_RADIUS = round(SizeOfSmoothingFilter/2);
        disk_radius = round(SPECKLE_RADIUS);
        SE = strel('disk', disk_radius);
        SmoothedImage = imsubtract(imadd(OrigImage,imtophat(OrigImage,SE)), imbothat(OrigImage,SE));
        SmoothedImage(SmoothedImage > 1) = 1;
        SmoothedImage(SmoothedImage < 0) = 0;
        SizeOfSmoothingFilterUsed = SizeOfSmoothingFilter;
    case 'enhance dark holes (fill-i)'
        %SmoothedImage = imfill(OrigImage) - OrigImage;
        SPECKLE_RADIUS = round(SizeOfSmoothingFilter/2);
        disk_radius = round(SPECKLE_RADIUS);
        SE = strel('disk', 1);
        invertedOrigImage = imcomplement(OrigImage);
        [ErodedImage,PreviousReconstructedImage] = deal(invertedOrigImage);
        SmoothedImage = zeros(size(OrigImage));
        for i = 2 : max(disk_radius)
            ErodedImage = imerode(ErodedImage,SE);
            ReconstructedImage = imreconstruct(ErodedImage,invertedOrigImage,4);
            output_image = PreviousReconstructedImage - ReconstructedImage;
            if ismember(i,disk_radius(1):disk_radius(end))
                SmoothedImage = SmoothedImage + output_image;
            end
            PreviousReconstructedImage = ReconstructedImage;
        end
        SmoothedImage(SmoothedImage > 1) = 1;
        SmoothedImage(SmoothedImage < 0) = 0;
        SizeOfSmoothingFilterUsed = SizeOfSmoothingFilter;
    otherwise
        if ~strcmp(SmoothingMethod,'N');
            error('The smoothing method you specified is not valid. This error should not have occurred. Check the code in the module or tool you are using or let the CellProfiler team know.');
        end
end

%%% Resize back to original if resized earlier due to the large filter size
if Resized
    SmoothedImage = imresize(SmoothedImage, [original_row original_col]);
    RealFilterLength = RealFilterLength * ResizingFactor;
end
