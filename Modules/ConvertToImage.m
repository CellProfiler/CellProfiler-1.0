function handles = ConvertToImage(handles)

% Help for the Convert To Image module:
% Category: Object Processing
%
% SHORT DESCRIPTION:
% Converts objects you have identified into an image so that it can be
% saved with the Save Images module.
% *************************************************************************
%
% This module allows you to take previously identified objects and convert
% them into an image, which can then be saved with the SaveImages modules.
%
% Settings:
%
% Binary (black & white), grayscale, or color: Choose how you would like
% the objects to appear. Color allows you to choose a colormap which will
% produce jumbled colors for your objects. Grayscale will give each object
% a graylevel pixel intensity value corresponding to its number (also
% called label), so it usually results in objects on the left side of the
% image being very dark, and progressing towards white on the right side of
% the image. You can choose "Color" with a "Gray" colormap to produce
% jumbled gray objects.
%
% Colormap:
% Affect how the objects are colored. You can look up your default colormap
% under File > Set Preferences. Look in matlab help online (try Google) to
% see what the available colormaps look like. See also Help > HelpColormaps
% in the main CellProfiler window.

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

% Variable settings for PyCp
% Var4 should be context-dependent and only appear if the user selects
% 'color' as their option.
% 
% Anne 4-9-09: We should consider why this module exists at all... the user
% can't be expected to understand the difference between a label matrix and
% a regular image, so this module has always been a bit confusing. Perhaps
% we should work to identify those points where
% the difference matters and coach the user better. For example, if you
% want SaveImages to save objects as a TIF formatted image, it will break
% if you just feed it objects. Perhaps SaveImages should allow objects as
% input and have these options here to let you convert them to the colors
% you want?  It's also worth considering that
% IdentifyPrim allows you to save outlines within the identify module itself. It
% seems that we should be consistent and also allow saving a
% colored/gray/binary output of the objects within Identify modules, or perhaps even better,
% extract BOTH functionalities (outlines and colored objects) into a
% separate module? I'm really not sure what to do. Keep in mind that
% whatever we decide will affect the OverlayOutlines module.

%%%%%%%%%%%%%%%%%
%%% VARIABLES %%%
%%%%%%%%%%%%%%%%%



drawnow

[CurrentModule, CurrentModuleNum, ModuleName] = CPwhichmodule(handles);

%textVAR01 = What did you call the objects you want to convert to an image?
%infotypeVAR01 = objectgroup
%inputtypeVAR01 = popupmenu
ObjectName = char(handles.Settings.VariableValues{CurrentModuleNum,1});

%textVAR02 = What do you want to call the resulting image?
%defaultVAR02 = CellImage
%infotypeVAR02 = imagegroup indep
ImageName = char(handles.Settings.VariableValues{CurrentModuleNum,2});

%textVAR03 = What colors should the resulting image use?
%choiceVAR03 = Color
%choiceVAR03 = Binary (black & white)
%choiceVAR03 = Grayscale
%choiceVAR03 = uint16
%inputtypeVAR03 = popupmenu
ImageMode = char(handles.Settings.VariableValues{CurrentModuleNum,3});

%textVAR04 = For COLOR, what do you want the colormap to be?
%choiceVAR04 = Default
%choiceVAR04 = autumn
%choiceVAR04 = bone
%choiceVAR04 = colorcube
%choiceVAR04 = cool
%choiceVAR04 = copper
%choiceVAR04 = flag
%choiceVAR04 = gray
%choiceVAR04 = hot
%choiceVAR04 = hsv
%choiceVAR04 = jet
%choiceVAR04 = lines
%choiceVAR04 = pink
%choiceVAR04 = prism
%choiceVAR04 = spring
%choiceVAR04 = summer
%choiceVAR04 = white
%choiceVAR04 = winter
%inputtypeVAR04 = popupmenu
ColorMap = char(handles.Settings.VariableValues{CurrentModuleNum,4});

%%%VariableRevisionNumber = 1

%%%%%%%%%%%%%%%%%%%%%%
%%% IMAGE ANALYSIS %%%
%%%%%%%%%%%%%%%%%%%%%%
drawnow

%LabelMatrixImage = handles.Pipeline.(['Segmented' ObjectName]);
LabelMatrixImage = CPretrieveimage(handles,['Segmented',ObjectName],ModuleName);

if strcmp(ImageMode,'Binary (black & white)')
    Image = logical(LabelMatrixImage ~= 0);
elseif strcmp(ImageMode,'Grayscale')
    warning off Matlab:DivideByZero
    Image = double(LabelMatrixImage / max(max(LabelMatrixImage)));
	warning on Matlab:DivideByZero
elseif strcmp(ImageMode,'Color')
    if strcmpi(ColorMap,'Default')
        Image = CPlabel2rgb(handles,LabelMatrixImage);
    else
        try
            cmap = eval([ColorMap '(max(max(2,LabelMatrixImage(:))))']);
        catch
            error(['Image processing was canceled in the ', ModuleName, ' module because the ColorMap, ' ColorMap ', that you entered, is not valid.']);
        end
        Image = label2rgb(LabelMatrixImage,cmap,'k');
    end
elseif strcmp(ImageMode,'uint16')
    Image = uint16(LabelMatrixImage);
end

%%%%%%%%%%%%%%%%%%%%%%%
%%% DISPLAY RESULTS %%%
%%%%%%%%%%%%%%%%%%%%%%%
drawnow

ThisModuleFigureNumber = handles.Current.(['FigureNumberForModule',CurrentModule]);
if any(findobj == ThisModuleFigureNumber)
    ColoredLabelMatrixImage = CPlabel2rgb(handles,LabelMatrixImage);

    CPfigure(handles,'Image',ThisModuleFigureNumber);
    if handles.Current.SetBeingAnalyzed == handles.Current.StartingImageSet
        CPresizefigure(LabelMatrixImage,'TwoByOne',ThisModuleFigureNumber)
    end
    hAx=subplot(2,1,1,'Parent',ThisModuleFigureNumber);
    CPimagesc(ColoredLabelMatrixImage,handles,hAx);
    title(hAx,['Original Identified ', ObjectName]);
    hAx=subplot(2,1,2,'Parent',ThisModuleFigureNumber);
    CPimagesc(Image,handles,hAx);
    title(hAx,ImageName);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% SAVE DATA TO HANDLES STRUCTURE %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
drawnow;
handles = CPaddimages(handles,ImageName,Image);