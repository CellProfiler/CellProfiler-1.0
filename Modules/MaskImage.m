function handles = MaskImage(handles)

% Help for the Mask Image module:
% Category: Image Processing
%
% SHORT DESCRIPTION:
% Masks image and saves it for future use.
% *************************************************************************
%
% This module masks an image and saves it in the handles structure for
% future use. The masked image is based on the original image and the
% object selected.
%
% Note that the image saved for further processing downstream is grayscale.
% If a binary mask is desired in subsequent modules, you might be able to
% access ['CropMask',MaskedImageName] (e.g. 'CropMaskMaskBlue'), or simply
% use the ApplyThreshold module instead of MaskImage.

% See also IdentifyPrimAutomatic, IdentifyPrimManual.

%
% Website: http://www.cellprofiler.org
%

%%%%%%%%%%%%%%%%%
%%% VARIABLES %%%
%%%%%%%%%%%%%%%%%
drawnow

[CurrentModule, CurrentModuleNum, ModuleName] = CPwhichmodule(handles);

%textVAR01 = From which object would you like to make a mask?
%choiceVAR01 = Image
%infotypeVAR01 = objectgroup
%inputtypeVAR01 = popupmenu
ObjectName = char(handles.Settings.VariableValues{CurrentModuleNum,1});

%textVAR02 = Which image do you want to mask?
%infotypeVAR02 = imagegroup
%inputtypeVAR02 = popupmenu
ImageName = char(handles.Settings.VariableValues{CurrentModuleNum,2});

%textVAR03 = What do you want to call the masked image?
%defaultVAR03 = MaskBlue
%infotypeVAR03 = imagegroup indep
MaskedImageName = char(handles.Settings.VariableValues{CurrentModuleNum,3});

%textVAR04 = Do you want to invert the object mask?
%choiceVAR04 = No
%choiceVAR04 = Yes
InvertMask = char(handles.Settings.VariableValues{CurrentModuleNum,4});
%inputtypeVAR04 = popupmenu

%%%VariableRevisionNumber = 3

%%%%%%%%%%%%%%%%
%%% ANALYSIS %%%
%%%%%%%%%%%%%%%%

OrigImage = CPretrieveimage(handles,ImageName,ModuleName,'MustBeGray','CheckScale');
ObjectLabelMatrix = CPretrieveimage(handles,['Segmented',ObjectName],ModuleName);
CropMask = ObjectLabelMatrix>0;

if strcmp(InvertMask,'Yes')
    CropMask = ~CropMask;
end

% Respect previous MaskImage modules
fieldname = ['CropMask', ImageName];
if CPisimageinpipeline(handles, fieldname)
    %%% Retrieves previously selected cropping mask from handles
    %%% structure.
    BinaryCropImage = CPretrieveimage(handles,fieldname,ModuleName);
    try
        CropMask = CropMask & BinaryCropImage;
    catch
        error('The image in which you want to identify objects has been cropped, but there was a problem recognizing the cropping pattern.');
    end
end

MaskedImage = OrigImage;
MaskedImage(~CropMask) = 0;

%%%%%%%%%%%%%%%%%%%%%%%
%%% DISPLAY RESULTS %%%
%%%%%%%%%%%%%%%%%%%%%%%
drawnow

ThisModuleFigureNumber = handles.Current.(['FigureNumberForModule',CurrentModule]);
%%% Check whether that figure is open. This checks all the figure handles
%%% for one whose handle is equal to the figure number for this module.
if any(findobj == ThisModuleFigureNumber)
    %%% Activates the appropriate figure window.
    CPfigure(handles,'Image',ThisModuleFigureNumber);
    if handles.Current.SetBeingAnalyzed == handles.Current.StartingImageSet
        CPresizefigure(OrigImage,'TwoByOne',ThisModuleFigureNumber)
    end

    %%% A subplot of the Original image.
    hAx=subplot(2,1,1,'Parent',ThisModuleFigureNumber);
    CPimagesc(OrigImage,handles,hAx);
    title(hAx,['Input Image, cycle # ',num2str(handles.Current.SetBeingAnalyzed)]);

    %%% A subplot of the Masked image.
    hAx=subplot(2,1,2,'Parent',ThisModuleFigureNumber);
    CPimagesc(MaskedImage,handles,hAx);
    title(hAx,[MaskedImageName ' from ' ObjectName]);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% SAVE DATA TO HANDLES STRUCTURE %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
drawnow

handles = CPaddimages(handles,  MaskedImageName,MaskedImage,...
                                ['CropMask',MaskedImageName],CropMask);
