function handles = SplitOrSpliceMovie(handles)

% Help for the Split Or Splice Movie module:
% Category: File Processing
%
% SHORT DESCRIPTION:
% Creates one large movie from several small movies, or creates several
% small movies from one large movie.
% *************************************************************************
%
% This module is only compatible with AVI format movies.
%
% Settings:
%
% Where are the existing avi-formatted movies?
% Typing a period (.) will use the default image folder. Relative folder
% locations will work also (e.g.   ../SIBLINGFOLDER)
%
% Where do you want to put the resulting files?
% Typing a period (.) will use the default output folder. Relative folder
% locations will work also (e.g.   ../SIBLINGFOLDER)
%
% For SPLICE, what is the common text in your movie file names?
% The files to be spliced should all be located within a single folder. You
% can choose a subset of movies in the folder to splice by specifying
% common text in their names. To splice all movies in the folder, you can
% just enter the file extension (e.g. '.avi').
%
% For SPLIT, you can split only one movie at a time, and the full file name
% should be entered here.
%
% For SPLIT, how many frames per movie do you want?
% The way CellProfiler reads movie files is that it reads each movie frame
% by frame. It will open the first frame and run through the pipeline then
% open the next and do the same. This is done until there are no more
% frames. Indicating the number of frames can be seen as also indicating
% the number cycles that a pipeline will be run.
%
% Note: This module is run by itself in a pipeline; there is no need to use
% a LoadImages or SaveImages module.

%
% Website: http://www.cellprofiler.org
%

%%%%%%%%%%%%%%%%%
%%% VARIABLES %%%
%%%%%%%%%%%%%%%%%
drawnow

[CurrentModule, CurrentModuleNum, ModuleName] = CPwhichmodule(handles);

%textVAR01 = Do you want to split (create multiple smaller movies from one large movie) or splice (create one large movie from multiple smaller movies)?
%choiceVAR01 = Split
%choiceVAR01 = Splice
%inputtypeVAR01 = popupmenu
SplitOrSplice = char(handles.Settings.VariableValues{CurrentModuleNum,1});

%pathnametextVAR02 = Where are the existing avi-formatted movie files?
ExistingPath = char(handles.Settings.VariableValues{CurrentModuleNum,2});

%pathnametextVAR03 = Where do you want to put the resulting file(s)?
FinalPath = char(handles.Settings.VariableValues{CurrentModuleNum,3});

%textVAR04 = For SPLICE, what is the common text in your movie files? For SPLIT, what is the entire name, including extension, of the movie file to be split?
%defaultVAR04 = GFPstain.avi
TargetMovieFileName = char(handles.Settings.VariableValues{CurrentModuleNum,4});

%textVAR05 = For SPLIT, how many frames per movie do you want?
%defaultVAR05 = 100
FramesPerSplitMovie = str2double(char(handles.Settings.VariableValues{CurrentModuleNum,5}));

%textVAR06 = For SPLICE, what do you want to call the final movie?
%defaultVAR06 = GFPstainSPLICED.avi
FinalSpliceName = char(handles.Settings.VariableValues{CurrentModuleNum,6});

%textVAR07 = Note: This module is run by itself in a pipeline; there is no need to use a Load Images or Save Images module.

%%%VariableRevisionNumber = 2

%%%%%%%%%%%%%%%%%%%%%%%
%%% FILE PROCESSING %%%
%%%%%%%%%%%%%%%%%%%%%%%
drawnow

%%% The figure window display is unnecessary for this module, so it is
%%% closed during the starting image cycle.
CPclosefigure(handles,CurrentModule)

%%% Get the pathname and check that it exists
if strncmp(ExistingPath,'.',1)
    if length(ExistingPath) == 1
        ExistingPath = handles.Current.DefaultImageDirectory;
    else
        ExistingPath = fullfile(handles.Current.DefaultImageDirectory,ExistingPath(2:end));
    end
end

%%% Get the pathname and check that it exists
if strncmp(FinalPath,'.',1)
    if length(FinalPath) == 1
        FinalPath = handles.Current.DefaultOutputDirectory;
    else
        FinalPath = fullfile(handles.Current.DefaultOutputDirectory,FinalPath(2:end));
    end
end

if handles.Current.SetBeingAnalyzed == handles.Current.StartingImageSet
    if strcmp(SplitOrSplice,'Split')
        AviMovieInfo = aviinfo(fullfile(ExistingPath,TargetMovieFileName));

        NumSplitMovies = ceil(AviMovieInfo.NumFrames/FramesPerSplitMovie);

        LastFrameRead = 0;
        for i = 1:NumSplitMovies
            [Pathname,FilenameWithoutExtension,Extension] = fileparts(fullfile(ExistingPath,TargetMovieFileName)); %#ok Ignore MLint
            NewFileAndPathName = fullfile(FinalPath, [FilenameWithoutExtension, '_', num2str(i),Extension]);
            LastFrameToReadForThisFile = min(i*FramesPerSplitMovie,AviMovieInfo.NumFrames);
            LoadedRawImages = aviread(fullfile(ExistingPath,TargetMovieFileName),LastFrameRead+1:LastFrameToReadForThisFile);
            try movie2avi(LoadedRawImages,NewFileAndPathName)
            catch
                error(['Image processing was canceled in the ', ModuleName, ' module because a problem was encountered during save of ',NewFileAndPathName,'.'])
                return;
            end
            LastFrameRead = i*FramesPerSplitMovie;
        end
    else
        [handles,FileNames] = CPretrievemediafilenames(handles, ExistingPath,TargetMovieFileName,'N','E','Movie');
        %%% Checks whether any files are left.
        if isempty(Filenames)
            error(['Image processing was canceled in the ', ModuleName, ' module because there are no image files with the text "', TargetMovieFileName, '" in the chosen directory (or subdirectories, if you requested them to be analyzed as well).'])
        end

        NewFileAndPathName = fullfile(FinalPath,FinalSpliceName);
        NewAviMovie = avifile(NewFileAndPathName);
        NumMovies = length(Filenames);

        for i = 1:NumMovies
            LoadedRawImages = aviread(fullfile(ExistingPath,char(Filenames(i))));
            try NewAviMovie = addframe(NewAviMovie,LoadedRawImages);
            catch
                error(['Image processing was canceled in the ', ModuleName, ' module because a problem was encountered during save of ',NewFileAndPathName,'.'])
                return;
            end
        end
        close(NewAviMovie);
    end
end