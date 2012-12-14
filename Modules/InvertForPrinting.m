function handles = InvertForPrinting(handles)

% Help for the Invert For Displaymodule:
% Category: Image Processing
%
% SHORT DESCRIPTION:
% Inverts Fluorescent-looking images into Brightfield-looking images.
% *************************************************************************
%
% This module works on color images.  It turns a single or
% multi-channel immunofluorescent-stained image into an image that
% resembles a brightfield image stained with similarly-colored stains,
% which generally print better.

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

%%%%%%%%%%%%%%%%%
%%% VARIABLES %%%
%%%%%%%%%%%%%%%%%

% Settings for PyCP
% I don't see anything wrong with the settings.. the only thing I can think
% of is perhaps this could be combined with another module? It seems very
% specific.
%
% Anne 4-9-09: The rewording should match other modules "What did you call
% the red channel?" (and 'None' should be the default). But I agree that this
% module could be merged into GrayToColor, by having a special option for
% this InvertForPrinting option, and then context-dependent variables from
% there.
%
% We should also provide this functionality to be performed on a color
% image directly (whereas here you do the transformation on three
% grayscales to produce three other grayscales). I'm not sure where that
% could go because we don't have any modules for doing a color
% transformation on a color image. Perhaps a new module "TransformColor"
% which could also do things like convert CMYK to RGB?  I'm not sure that
% makes sense - just throwing out ideas. But anyway, if this functionality
% was in a module that allowed an input RGB image and produced the color
% inverted-for-printing image, then we wouldn't even need the ability to
% run this on grayscale images separately.
%
% I think the help is completely wrong because it says it works on color
% images but it seems to take 3 grayscales as input.

drawnow

[CurrentModule, CurrentModuleNum, ModuleName] = CPwhichmodule(handles);

%textVAR01 = What is the name of the Fluorescent Red channel (or "None")
%infotypeVAR01 = imagegroup
RedImageName = char(handles.Settings.VariableValues{CurrentModuleNum,1});
%inputtypeVAR01 = popupmenu custom

%textVAR02 = What is the name of the Fluorescent Green channel (or "None")
%infotypeVAR02 = imagegroup
GreenImageName = char(handles.Settings.VariableValues{CurrentModuleNum,2});
%inputtypeVAR02 = popupmenu custom

%textVAR03 = What is the name of the Fluorescent Blue channel (or "None")
%infotypeVAR03 = imagegroup
BlueImageName = char(handles.Settings.VariableValues{CurrentModuleNum,3});
%inputtypeVAR03 = popupmenu custom

%textVAR04 = What do you want to call the inverted Red image?
%defaultVAR04 = InvertedDisplayRed
%infotypeVAR04 = imagegroup indep
InvertedRedImageName = char(handles.Settings.VariableValues{CurrentModuleNum,4});

%textVAR05 = What do you want to call the inverted Green image?
%defaultVAR05 = InvertedDisplayGreen
%infotypeVAR05 = imagegroup indep
InvertedGreenImageName = char(handles.Settings.VariableValues{CurrentModuleNum,5});

%textVAR06 = What do you want to call the inverted Blue image?
%defaultVAR06 = InvertedDisplayBlue
%infotypeVAR06 = imagegroup indep
InvertedBlueImageName = char(handles.Settings.VariableValues{CurrentModuleNum,6});

%%%VariableRevisionNumber = 1

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% PRELIMINARY CALCULATIONS & FILE HANDLING %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
drawnow

%%% Check that we have at least one image
if strcmp(RedImageName, 'None') & strcmp(GreenImageName, 'None') &  strcmp(BlueImageName, 'None'),
    error(['Image processing was canceled in the ', ModuleName, ' module because at least one input image name must not be "None".']);
end

%%% Reads (opens) the image you want to analyze and assigns it to a
%%% variable.
if strcmp(RedImageName, 'None') == 0,
    OrigRedImage = CPretrieveimage(handles,RedImageName,ModuleName,'MustBeGray','CheckScale');
else
    OrigRedImage = 0
end
if strcmp(GreenImageName, 'None') == 0,
    OrigGreenImage = CPretrieveimage(handles,GreenImageName,ModuleName,'MustBeGray','CheckScale');
else
    OrigGreenImage = 0
end
if strcmp(BlueImageName, 'None') == 0,
    OrigBlueImage = CPretrieveimage(handles,BlueImageName,ModuleName,'MustBeGray','CheckScale');
else
    OrigBlueImage = 0
end

%%%%%%%%%%%%%%%%%%%%%%
%%% IMAGE ANALYSIS %%%
%%%%%%%%%%%%%%%%%%%%%%
drawnow

%%% Inverts the image.
InvertedRed =   (1 - OrigGreenImage) .* (1 - OrigBlueImage);
InvertedGreen = (1 - OrigRedImage)   .* (1 - OrigBlueImage);
InvertedBlue =  (1 - OrigRedImage)   .* (1 - OrigGreenImage);

%%%%%%%%%%%%%%%%%%%%%%%
%%% DISPLAY RESULTS %%%
%%%%%%%%%%%%%%%%%%%%%%%
drawnow

ThisModuleFigureNumber = handles.Current.(['FigureNumberForModule',CurrentModule]);
if any(findobj == ThisModuleFigureNumber)

    StackedInput = zeros(max(size(OrigRedImage), max(size(OrigGreenImage), size(OrigBlueImage))));
    StackedInput(:,:,1) = OrigRedImage;
    StackedInput(:,:,2) = OrigGreenImage;
    StackedInput(:,:,3) = OrigBlueImage;

    %%% Activates the appropriate figure window.
    CPfigure(handles,'Image',ThisModuleFigureNumber);
    if handles.Current.SetBeingAnalyzed == handles.Current.StartingImageSet
        CPresizefigure(StackedInput(:,:,1),'TwoByOne',ThisModuleFigureNumber)
    end
    %%% A subplot of the figure window is set to display the original image.
    hAx=subplot(2,1,1,'Parent',ThisModuleFigureNumber);

    CPimagesc(StackedInput,handles,hAx);
    title(hAx,['Input Image, cycle # ',num2str(handles.Current.SetBeingAnalyzed)]);
    %%% A subplot of the figure window is set to display the Inverted
    %%% Image.
    hAx=subplot(2,1,2,'Parent',ThisModuleFigureNumber);

    InvertedStackedImage = StackedInput;
    InvertedStackedImage(:,:,1) = InvertedRed;
    InvertedStackedImage(:,:,2) = InvertedGreen;
    InvertedStackedImage(:,:,3) = InvertedBlue;
    CPimagesc(InvertedStackedImage,handles,hAx);
    title(hAx,'Inverted Image');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% SAVE DATA TO HANDLES STRUCTURE %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
drawnow

%%% Saves the Inverted image to the
%%% handles structure so it can be used by subsequent modules.
handles = CPaddimages(handles,InvertedRedImageName, InvertedRed,...
                            InvertedGreenImageName, InvertedGreen,...
                            InvertedBlueImageName, InvertedBlue);