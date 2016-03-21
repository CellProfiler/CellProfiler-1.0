function handles = SpeedUpCellProfiler(handles)

% Help for the Speed Up CellProfiler module:
% Category: Other
%
% SHORT DESCRIPTION:
% Speeds up CellProfiler processing and conserves memory.
% *************************************************************************
%
% Speeds up CellProfiler processing and conserves memory by reducing the
% frequency of saving partial output files and/or clearing the memory.
%
% Settings:
%
% * Output files should be saved every Nth cycle?
% To save the output file after every cycle, as usual, leave this set to 1.
% Entering a larger integer allows faster image processing by refraining
% from saving the output file after every cycle is processed. Instead, the
% output file is saved after every Nth cycle (and always after the first
% and last cycles). For large output files, this can result in substantial
% time savings. The only disadvantage is that if processing is canceled
% prematurely, the output file will contain only data up to the last cycle
% that was a multiple of N, even if several cycles have been processed
% since then. Another hint: be sure you are not in Diagnostic mode (see
% File > Set Preferences) to avoid saving very large output files with
% intermediate images, because this slows down CellProfiler as well.
%
% * Do you want to clear the memory?
% If yes, everything in temporary memory will be removed except for the
% images you specify. Therefore, only the images you specify will be
% accessible to modules downstream in the pipeline. This module can
% therefore be used to clear space in the memory.
% Note: currently, this option will remove everything in the memory, which
% may not be compatible with some modules, which often store non-image
% information in memory to be re-used during every cycle.

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


% MBray 2009_03_27: Comments on variables for pyCP upgrade
%
% Recommended variable order (setting, followed by current variable in MATLAB CP)
% (1) Output files are normally saved every cycle, which can be
%   time-consuming. Here you can choose to only save output files every Nth
%   cycle. What value of N do want to use? Note: The output file is always saved after the first
%   or last cycle is processed, regardless of N. (SaveWhen) Options in the
%   dropdown menu should be 1, 2, 5, 10, other (so they can type in an
%   integer), first and last cycle only.
% (2) Do you want to clear images from memory during this module?
%       options: (2a) Yes, clear all images except for those that I specify
%                (2b) Yes, clear only the particular images I specify
%                (2c) No, do not clear any images from memory
%       If yes for 2a: Which image(s) do you want to remain in memory for use by downstream modules?
%       If yes for 2b: What image(s) do you want to remove from memory?
%
% (i) A button should be added that lets the user add/subtract images for
%   (2a and b)
% (ii) A user may want to remove a large set of images and leave only a
% few, or remove only a few images and leave a large set. Options (2a and
% b) give the user flexibility to choose.

%%%%%%%%%%%%%%%%%
%%% VARIABLES %%%
%%%%%%%%%%%%%%%%%
drawnow

[CurrentModule, CurrentModuleNum, ModuleName] = CPwhichmodule(handles);

%textVAR01 = Output files will be saved every Nth cycle (1,2,3,...). Note: the output file is always saved after the first or last cycle is complete, no matter what is entered here.
%defaultVAR01 = 1
SaveWhen = char(handles.Settings.VariableValues{CurrentModuleNum,1});

%textVAR02 = Do you want to clear the memory during this module? Note: this may not be compatible with some downstream modules.
%choiceVAR02 = Yes
%choiceVAR02 = No
ClearMemory = char(handles.Settings.VariableValues{CurrentModuleNum,2});
%inputtypeVAR02 = popupmenu

%textVAR03 = If yes, which images would you like to remain in memory?
%choiceVAR03 = Do not use
%infotypeVAR03 = imagegroup
ImageNameList{1} = char(handles.Settings.VariableValues{CurrentModuleNum,3});
%inputtypeVAR03 = popupmenu

%textVAR04 =
%choiceVAR04 = Do not use
%infotypeVAR04 = imagegroup
ImageNameList{2} = char(handles.Settings.VariableValues{CurrentModuleNum,4});
%inputtypeVAR04 = popupmenu

%textVAR05 =
%choiceVAR05 = Do not use
%infotypeVAR05 = imagegroup
ImageNameList{3} = char(handles.Settings.VariableValues{CurrentModuleNum,5});
%inputtypeVAR05 = popupmenu

%textVAR06 =
%choiceVAR06 = Do not use
%infotypeVAR06 = imagegroup
ImageNameList{4} = char(handles.Settings.VariableValues{CurrentModuleNum,6});
%inputtypeVAR06 = popupmenu

%textVAR07 =
%choiceVAR07 = Do not use
%infotypeVAR07 = imagegroup
ImageNameList{5} = char(handles.Settings.VariableValues{CurrentModuleNum,7});
%inputtypeVAR07 = popupmenu

%textVAR08 =
%choiceVAR08 = Do not use
%infotypeVAR08 = imagegroup
ImageNameList{6} = char(handles.Settings.VariableValues{CurrentModuleNum,8});
%inputtypeVAR08 = popupmenu

%textVAR09 =
%choiceVAR09 = Do not use
%infotypeVAR09 = imagegroup
ImageNameList{7} = char(handles.Settings.VariableValues{CurrentModuleNum,9});
%inputtypeVAR09 = popupmenu

%textVAR10 =
%choiceVAR10 = Do not use
%infotypeVAR10 = imagegroup
ImageNameList{8} = char(handles.Settings.VariableValues{CurrentModuleNum,10});
%inputtypeVAR10 = popupmenu

%textVAR11 =
%choiceVAR11 = Do not use
%infotypeVAR11 = imagegroup
ImageNameList{9} = char(handles.Settings.VariableValues{CurrentModuleNum,11});
%inputtypeVAR11 = popupmenu

%textVAR12 =
%choiceVAR12 = Do not use
%infotypeVAR12 = imagegroup
ImageNameList{10} = char(handles.Settings.VariableValues{CurrentModuleNum,12});
%inputtypeVAR12 = popupmenu

%textVAR13 =
%choiceVAR13 = Do not use
%infotypeVAR13 = imagegroup
ImageNameList{11} = char(handles.Settings.VariableValues{CurrentModuleNum,13});
%inputtypeVAR13 = popupmenu

%textVAR14 =
%choiceVAR14 = Do not use
%infotypeVAR14 = imagegroup
ImageNameList{12} = char(handles.Settings.VariableValues{CurrentModuleNum,14});
%inputtypeVAR14 = popupmenu

%%%VariableRevisionNumber = 5

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% PRELIMINARY CALCULATIONS & FILE HANDLING %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ImageNameList(strcmp(ImageNameList,'Do not use')) = [];

if strcmpi(ClearMemory,'Yes')
    ListOfFields = fieldnames(handles.Pipeline);
    for i = 1:length(ListOfFields)
        if all(size(handles.Pipeline.(ListOfFields{i})) ~= 1) && ...    % As long as the image is not a scalar...
                ~any(strcmp(ImageNameList,ListOfFields{i})) && ...      % ...is in the list of image fields...
                ~iscell(handles.Pipeline.(ListOfFields{i}))             % ...and is not a cell (e.g., FileList)
            handles.Pipeline = rmfield(handles.Pipeline,ListOfFields(i));
        end
    end
    isImageGroups = isfield(handles.Pipeline,'ImageGroupFields');
    if isImageGroups
        idx = handles.Pipeline.CurrentImageGroupID;
        ListOfFields = fieldnames(handles.Pipeline.GroupFileList{idx});
        for i = 1:length(ListOfFields)
            if all(size(handles.Pipeline.GroupFileList{idx}.(ListOfFields{i})) ~= 1) && ...    % As long as the image is not a scalar...
                    ~any(strcmp(ImageNameList,ListOfFields{i})) && ...                       % ...is in the list of image fields...
                    ~iscell(handles.Pipeline.GroupFileList{idx}.(ListOfFields{i}))                             % ...and is not a cell (e.g., FileList)
                handles.Pipeline.GroupFileList{idx} = rmfield(handles.Pipeline.GroupFileList{idx},ListOfFields(i));
            end
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% SAVE DATA TO HANDLES STRUCTURE %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
drawnow

if handles.Current.SetBeingAnalyzed == handles.Current.StartingImageSet
    try SaveWhen = str2double(SaveWhen);
    catch
        error(['Image processing was canceled in the ', ModuleName, ' module because the number of cycles must be entered as a number.'])
    end
    handles.Current.SaveOutputHowOften = SaveWhen;
end

%%%%%%%%%%%%%%%%%%%%%%%
%%% DISPLAY RESULTS %%%
%%%%%%%%%%%%%%%%%%%%%%%
drawnow

%%% The figure window display is unnecessary for this module, so it is
%%% closed during the starting image cycle.
CPclosefigure(handles,CurrentModule)