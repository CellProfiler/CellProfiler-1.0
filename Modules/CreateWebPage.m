function handles = CreateWebPage(handles)

% Help for the Create Web Page module:
% Category: Other
%
% SHORT DESCRIPTION:
% Creates the html for a webpage to display images (or their thumbnails, if
% desired), including a link to a zipped file with all of the included
% images.
% *************************************************************************
%
% This module will create an html file that will display the specified
% images and also produce a zip-file of these images with a link. The
% thumbnail images must be in the same directory as the original images.
%
% Settings:
% * Thumbnails: By default, the full-size images will be displayed on the
% webpage itself. If you have made thumbnails (small versions of the
% images), you can have these displayed on the webpage, and the full-size
% images will be displayed when the user clicks on the thumbnails.
%
% * Create webpage (HTML file) before or after processing all images?
% If the full-size images and thumbnails (optional) already exist on the
% hard drive and you are loading them with the Load Images module, you can
% answer "Before" to this question. If, however, you are producing either
% of these images during the pipeline and you therefore need to complete
% all of the cycles before generating the webpage, choose "After".
%
% * What do you want to call the resulting webpage file (include .htm or
% .html as the extension)?
% This file will be created in your default output directory. It can then
% be copied to your web server. The primary difference between .htm and
% .html is simply that .html can't be represented in a DOS/16 bit operating
% system which uses the 8.3 file naming convention. Most servers (but not
% all) that can handle 4 character file extensions can be set up to treat
% .htm and .html files in exactly the same way, just as they can be set up 
% to treat .jpg and .jpeg files the same way.
% 
% * Will you have the webpage HTML file in the same folder or one level 
% above the images?
% If the images are going to be in a subfolder, then the HTML file will be
% one level above the images. If the HTML file and the images will all be
% in the same folder, answer "Same as the images".
%
% * Table border: If desired, there will be lines around each image,
% creating a table. The thickness and color of these lines can be specified.
%
% * Spacing between images: If this is set to greater than zero, there will
% be an additional frame, the same color as the table border, around each
% image. The spacing is the space between the frames that surrounds each
% image.
%
% * Image border width: This is the distance between each image and its
% frame. If the spacing between images is zero, you will not see the frame
% itself, but the image border width will still affect the spacing between
% images.

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

% MBray 2009_04_17: Comments on variables for pyCP upgrade
% (1) What did you call the full-size images that you want to include on the
% webpage? (OrigImage)
% (2) What did you call the thumbnail images you want to use to link to the 
% full-size images? Select "Do not use" to ignore. (ThumbImage)
% (3) Do you want to create the webpage (HTML file) before or after
% processing all images? (CreateBA)
% (4) What do you want to call the resulting webpage file? The '.html' 
%   file extension will be added automatically. (FileName)
% (5) Will you have the webpage HTML file in the same folder or one level
% above the images? (DirectoryOption)
% (6) What is the webpage title, which will be displayed at the top of the 
%   browser window? (PageTitle)
% (7) What do you want the webpage background color to be? For custom 
% colors, provide the html color code (e.g. #00FF00). (BGColor)
% (8) How many columns of images do you want? (ThumbCols)
% (9) What is the table border width, in pixels? (TableBorderWidth)
% (10) What is the table border color? For custom colors, provide the html 
%   color code (e.g. #00FF00) (TableBorderColor)
% (11) What is the spacing between images, in pixels? (ThumbSpacing)
% (12) What is the image border width, in pixels? (ThumbBorderWidth)
% (13) Do you want to open a new browser window when clicking on a 
%   thumbnail? (CreateNewWindow)
% (14) If you want the webpage to have a link to a zipped file which 
%   contains all of the full-size images, what is the filename. The '.zip' 
%   file extension will be added automatically. (ZipFileName)
%
% Setting (4): The .htm vs. .html distinction is probably no longer
% neccesary. Metadata tokens should be permitted here as well.

%%%%%%%%%%%%%%%%%
%%% VARIABLES %%%
%%%%%%%%%%%%%%%%%
drawnow

[CurrentModule, CurrentModuleNum, ModuleName] = CPwhichmodule(handles);

%textVAR01 = What did you call the full-size images you want to include on the webpage?
%infotypeVAR01 = imagegroup
OrigImage = char(handles.Settings.VariableValues{CurrentModuleNum,1});
%inputtypeVAR01 = popupmenu

%textVAR02 = What did you call the thumbnail images you want to use to link to the full-size images (optional)?
%choiceVAR02 = Do not use
%infotypeVAR02 = imagegroup
ThumbImage = char(handles.Settings.VariableValues{CurrentModuleNum,2});
%inputtypeVAR02 = popupmenu

%textVAR03 = Do you want to create the webpage (HTML file) before or after processing all images?
%choiceVAR03 = Before
%choiceVAR03 = After
CreateBA = char(handles.Settings.VariableValues{CurrentModuleNum,3});
%inputtypeVAR03 = popupmenu

%textVAR04 = What do you want to call the resulting webpage file (include .htm or .html as the extension)?
FileName = char(handles.Settings.VariableValues{CurrentModuleNum,4});
%defaultVAR04 = images1.html

%textVAR05 = Will you have the webpage HTML file in the same folder or one level above the images?
%choiceVAR05 = One level over the images
%choiceVAR05 = Same as the images
DirectoryOption = char(handles.Settings.VariableValues{CurrentModuleNum,5});
%inputtypeVAR05 = popupmenu

%textVAR06 = Webpage title, which will be displayed at the top of the browser window
PageTitle = char(handles.Settings.VariableValues{CurrentModuleNum,6});
%defaultVAR06 = CellProfiler Images

%textVAR07 = Webpage background color. For custom colors, provide the html color code (e.g. #00FF00)
%choiceVAR07 = Black
%choiceVAR07 = White
%choiceVAR07 = Aqua
%choiceVAR07 = Blue
%choiceVAR07 = Fuchsia
%choiceVAR07 = Green
%choiceVAR07 = Gray
%choiceVAR07 = Lime
%choiceVAR07 = Maroon
%choiceVAR07 = Navy
%choiceVAR07 = Olive
%choiceVAR07 = Purple
%choiceVAR07 = Red
%choiceVAR07 = Silver
%choiceVAR07 = Teal
%choiceVAR07 = Yellow
BGColor = char(handles.Settings.VariableValues{CurrentModuleNum,7});
%inputtypeVAR07 = popupmenu custom

%textVAR08 = Number of columns of images
%choiceVAR08 = 1
%choiceVAR08 = 2
%choiceVAR08 = 3
%choiceVAR08 = 4
%choiceVAR08 = 5
ThumbCols = str2double(char(handles.Settings.VariableValues{CurrentModuleNum,8}));
%inputtypeVAR08 = popupmenu custom

%textVAR09 = Table border width (pixels)
%choiceVAR09 = 0
%choiceVAR09 = 1
%choiceVAR09 = 2
TableBorderWidth = char(handles.Settings.VariableValues{CurrentModuleNum,9});
%inputtypeVAR09 = popupmenu custom

%textVAR10 = Table border color. For custom colors, provide the html color code (e.g. #00FF00)
%choiceVAR10 = Black
%choiceVAR10 = White
%choiceVAR10 = Aqua
%choiceVAR10 = Blue
%choiceVAR10 = Fuchsia
%choiceVAR10 = Green
%choiceVAR10 = Gray
%choiceVAR10 = Lime
%choiceVAR10 = Maroon
%choiceVAR10 = Navy
%choiceVAR10 = Olive
%choiceVAR10 = Purple
%choiceVAR10 = Red
%choiceVAR10 = Silver
%choiceVAR10 = Teal
%choiceVAR10 = Yellow
TableBorderColor = char(handles.Settings.VariableValues{CurrentModuleNum,10});
%inputtypeVAR10 = popupmenu custom

%textVAR11 = Spacing between images (pixels)
%choiceVAR11 = 0
%choiceVAR11 = 1
%choiceVAR11 = 2
ThumbSpacing = char(handles.Settings.VariableValues{CurrentModuleNum,11});
%inputtypeVAR11 = popupmenu custom

%textVAR12 = Image border width (pixels)
%choiceVAR12 = 0
%choiceVAR12 = 1
%choiceVAR12 = 2
ThumbBorderWidth = char(handles.Settings.VariableValues{CurrentModuleNum,12});
%inputtypeVAR12 = popupmenu custom

%textVAR13 = Open a new browser window when clicking on a thumbnail?
%choiceVAR13 = Once only
%choiceVAR13 = For each image
%choiceVAR13 = No
CreateNewWindow = char(handles.Settings.VariableValues{CurrentModuleNum,13});
%inputtypeVAR13 = popupmenu

%textVAR14 = If you want the webpage to have a link to a zipped file which contains all of the full-size images, specify a filename. The '.zip' file extension will be added automatically.
%choiceVAR14 = Do not use
ZipFileName = char(handles.Settings.VariableValues{CurrentModuleNum,14});
%inputtypeVAR14 = popupmenu custom

%%%VariableRevisionNumber = 1

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% PRELIMINARY CALCULATIONS %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
drawnow

%%% Determines which cycle is being analyzed.
SetBeingAnalyzed = handles.Current.SetBeingAnalyzed;
NumberOfImageSets = handles.Current.NumberOfImageSets;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% FIRST CYCLE FILE HANDLING %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
drawnow

if ((SetBeingAnalyzed == 1) && strcmp(CreateBA,'Before')) || ((SetBeingAnalyzed == NumberOfImageSets) && strcmp(CreateBA,'After'))
    NumOrigImage = numel(handles.Pipeline.(['FileList' OrigImage]));
    if ~strcmp(ThumbImage,'Do not use')
        if ~isfield(handles.Pipeline,['FileList' ThumbImage]);
            error(['Image processing was canceled in the ', ModuleName, ' module because the thumbnail images were not available on the hard drive. You must use load thumbnail images that already exist on the hard drive, or you must use a Save Images module prior to this module and choose the update file names option.']);
        end
        NumThumbImage = numel(handles.Pipeline.(['FileList' ThumbImage]));
        if NumOrigImage ~= NumThumbImage
            error(['Image processing was canceled in the ', ModuleName, ' module because the number of original images and thumbnail images do not match']);
        end
        ThumbImageFileNames = handles.Pipeline.(['FileList' ThumbImage]);
        ThumbImagePathName = handles.Pipeline.(['Pathname' ThumbImage]);
    end

    try
        OrigImageFileNames = handles.Pipeline.(['FileList' OrigImage]);
        OrigImagePathName = handles.Pipeline.(['Pathname' OrigImage]);
        ZipImagePathName = OrigImagePathName;
    catch
        error(['Image processing was canceled in the ', ModuleName, ' module because there was an error finding your images. You must specify images directly loaded by the Load Images module.']);
    end

    CurrentImage = 1;

    if strcmp(DirectoryOption,'One level over the images')
        LastDirPos = max(findstr('\',OrigImagePathName))+1;
        if isempty(LastDirPos)
            LastDirPos = max(findstr('/',OrigImagePathName))+1;
        end

        HTMLSavePath = OrigImagePathName(1:LastDirPos-2);
        OrigImagePathName = OrigImagePathName(LastDirPos:end);
        if ~strcmp(ThumbImage,'Do not use')
            try
                ThumbImagePathName = ThumbImagePathName(LastDirPos:end);
            catch
                error(['Image processing was canceled in the ', ModuleName, ' module because the folder ', ThumbImagePathName,' could not be found in the module ',ModuleName,'.']);
            end
        end
    else
        HTMLSavePath = OrigImagePathName;
        OrigImagePathName = '';
        ThumbImagePathName = '';
    end

    WindowName = '_CPNewWindow';

    ZipList = {[]};

    Lines = '<HTML>';
    Lines = strvcat(Lines,['<HEAD><TITLE>',PageTitle,'</TITLE></HEAD>']);
    Lines = strvcat(Lines,['<BODY BGCOLOR=',AddQ(BGColor),'>']);
    Lines = strvcat(Lines,['<CENTER><TABLE BORDER=',TableBorderWidth, ' BORDERCOLOR=', AddQ(TableBorderColor), ' CELLPADDING=0',' CELLSPACING=',ThumbSpacing,'>']);
    %%% Creates the html to create a link to download the images as a
    %%% zipped archive.
    TitleText = 'Click an image to see a higher-resolution version.  ';
    Lines = strvcat(Lines,TitleText);
    if ~strcmp(ZipFileName,'Do not use')
        Lines = strvcat(Lines,['<CENTER><A HREF = ',AddQ([ZipFileName,'.zip']),'>Download all high-resolution images as a zipped file</A></CENTER>']);
    end
    while CurrentImage <= NumOrigImage
        Lines = strvcat(Lines,'<TR>');
        for i=1:ThumbCols

            Lines = strvcat(Lines,'<TD>');

            if ~strcmp(ThumbImage,'Do not use')
                if strcmp(CreateNewWindow,'Once only')
                    Lines = strvcat(Lines,['<A HREF=',AddQ(fullfile(OrigImagePathName,OrigImageFileNames{CurrentImage})),' TARGET=',AddQ(WindowName),'>']);
                elseif strcmp(CreateNewWindow,'For each image')
                    Lines = strvcat(Lines,['<A HREF=',AddQ(fullfile(OrigImagePathName,OrigImageFileNames{CurrentImage})),' TARGET=',AddQ([WindowName,num2str(CurrentImage)]),'>']);
                else
                    Lines = strvcat(Lines,['<A HREF=',AddQ(fullfile(OrigImagePathName,OrigImageFileNames{CurrentImage})),'>']);
                end
                Lines = strvcat(Lines,['<IMG SRC=',AddQ(fullfile(ThumbImagePathName,ThumbImageFileNames{CurrentImage})),' BORDER=',ThumbBorderWidth,'>']);
                Lines = strvcat(Lines,'</A>');
            else
                Lines = strvcat(Lines,['<IMG SRC=',AddQ(fullfile(OrigImagePathName,OrigImageFileNames{CurrentImage})),' BORDER=',ThumbBorderWidth,'>']);
            end

            Lines = strvcat(Lines,'</TD>');
            if ~strcmp(ZipFileName,'Do not use')
                ZipList(CurrentImage) = {fullfile(ZipImagePathName,OrigImageFileNames{CurrentImage})};
            end

            CurrentImage = CurrentImage + 1;
            if CurrentImage > NumOrigImage
                break;
            end

        end
        Lines = strvcat(Lines,'</TR>');
    end
    %%% Creates the zip file of all the high resolution images.
    if ~strcmp(ZipFileName,'Do not use')
        zip(fullfile(HTMLSavePath,ZipFileName),ZipList);
    end

    Lines = strvcat(Lines,'</TABLE></CENTER>');

    Lines = strvcat(Lines,'</BODY>');
    Lines = strvcat(Lines,'</HTML>');
    HTMLFullfile = fullfile(HTMLSavePath,FileName);
    dlmwrite(HTMLFullfile,Lines,'delimiter','');
    CPmsgbox(['Your webpage has been saved as ', HTMLFullfile, '.']);
    if SetBeingAnalyzed == 1
        %%% This is the first cycle, so this is the first time seeing this
        %%% module.  It should cause a cancel so no further processing is done
        %%% on this machine.
        set(handles.timertexthandle,'string','Cancel');
    end
end

%%%%%%%%%%%%%%%%%%%%%%%
%%% DISPLAY RESULTS %%%
%%%%%%%%%%%%%%%%%%%%%%%
drawnow

%%% The figure window display is unnecessary for this module, so it is
%%% closed during the starting image cycle.
CPclosefigure(handles,CurrentModule)

function AfterQuotation = AddQ(BeforeQuotation)
AfterQuotation = ['"',BeforeQuotation,'"'];