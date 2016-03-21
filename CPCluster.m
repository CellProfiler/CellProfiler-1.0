function CPCluster(batchfile,StartingSet,EndingSet,OutputFolder,BatchFilePrefix,WriteMatFiles,KeepAlive)

%%% Must list all CellProfiler modules here
% DO NOT CHANGE THE LINE BELOW
%%% BuildCellProfiler: INSERT FUNCTIONS HERE

tic

% Mario Emmenlauer, 2011.08.19
% This code is copied from CellProfiler.m. It enables CPCluster
% to run from Matlab shell in interactive mode (non-deployed needs
% the paths to be added).
% Begin initialization code - DO NOT EDIT
if ~isdeployed
    try
        subdirs = strread(genpath(fileparts(which('CPCluster'))), '%s','delimiter',pathsep);
        subdirs = subdirs(cellfun('isempty', strfind(subdirs, '.svn')));
        addpath(subdirs{:});
    catch
    end
end

try
    state = warning('off', 'all'); % necessary to get around pipelines that complain about missing functions.
    load(batchfile);
    warning(state);
catch
    reportBatchError(['Batch Error: Loading batch file (' batchfile ')']);
end

try
    % r2008b saves the preferences as it exits and complains
    % so we put the preferences somewhere random
    prefdir = OutputFolder;
catch
    warning('Failed to set the preferences directory')
end

% Arguments come in as strings, convert to integer
StartingSet = str2num(StartingSet);
EndingSet = str2num(EndingSet);

% The following is neccessary for image grouping to work. It assumes that
% the batch size = 1 (so StartingSet = EndingSet) and the images in a group
% are in a contiguous order
if isfield(handles.Pipeline,'ImageGroupFields')
    [OriginalStartingSet,OriginalEndingSet] = deal(StartingSet,EndingSet);
    CurrentImageGroupID = StartingSet;
    ImageIndicesInGroup = handles.Pipeline.GroupFileListIDs == CurrentImageGroupID;
    StartingSet = find(ImageIndicesInGroup,1,'first');
    EndingSet = find(ImageIndicesInGroup,1,'last');
    handles.Current.NumberOfImageSets = handles.Pipeline.GroupFileList{handles.Current.SetBeingAnalyzed}.NumberOfImageSets;
end

% The following is necessary for some modules (e.g., ExportToDatabase) to work correctly.
handles.Current.BatchInfo.Start = StartingSet;
handles.Current.BatchInfo.End = EndingSet;

for BatchSetBeingAnalyzed = StartingSet:EndingSet
    t_set_start = toc;
    disp(sprintf('Analyzing set %d.', BatchSetBeingAnalyzed));
    handles.Current.SetBeingAnalyzed = BatchSetBeingAnalyzed;

    if (BatchSetBeingAnalyzed == StartingSet)
        disp('Pipeline:')
        for SlotNumber = 1:handles.Current.NumberOfModules
            ModuleNumberAsString = sprintf('%02d', SlotNumber);
            ModuleName = char(handles.Settings.ModuleNames(SlotNumber));
            disp(sprintf('     module %d - %s', SlotNumber, ModuleName));
        end
    end


    for SlotNumber = 1:handles.Current.NumberOfModules
        % Signal that we're alive
        system(KeepAlive);

        t_start = toc;
        ModuleNumberAsString = sprintf('%02d', SlotNumber);
        ModuleName = char(handles.Settings.ModuleNames(SlotNumber));
        disp(sprintf('  executing module %d - %s', SlotNumber, ModuleName));
        handles.Current.CurrentModuleNumber = ModuleNumberAsString;
        try
            handles = feval(ModuleName,handles);
        catch
            reportBatchError(['Batch Error: ' ModuleName]);
        end
        t_end = toc;
        disp(sprintf('    %f seconds', t_end - t_start));
     end
     disp(sprintf('  %f seconds for image set %d.', toc - t_set_start, BatchSetBeingAnalyzed));
end

t_tot = toc;
disp(sprintf('All sets analyzed in %f seconds (%f per image set)', t_tot, t_tot / (EndingSet - StartingSet + 1)));

% If image grouping: Change the starting/ending set indices back so the output files are
% written with the right numbers, and the Python scripts will recognize
% that the batch is done
if isfield(handles.Pipeline,'ImageGroupFields')
    [StartingSet,EndingSet] = deal(OriginalStartingSet,OriginalEndingSet);
end

if strcmp(WriteMatFiles, 'yes')
    handles.Pipeline = [];
    OutputFileName = sprintf('%s/%s%d_to_%d_OUT.mat',OutputFolder,BatchFilePrefix,StartingSet,EndingSet);
    save(OutputFileName,'handles');
end

OutputFileName = sprintf('%s/%s%d_to_%d_DONE.mat',OutputFolder,BatchFilePrefix,StartingSet,EndingSet);
save(OutputFileName,'BatchSetBeingAnalyzed');
disp(sprintf('Created %s',OutputFileName));
fprintf('Module CPCluster finished successfully\n')
end

function reportBatchError(errorstring)
errorinfo = lasterror;
if isfield(errorinfo, 'stack')
    try
        stackinfo = errorinfo.stack(1,1);
        ExtraInfo = [' (file: ', stackinfo.file, ' function: ', stackinfo.name, ' line: ', num2str(stackinfo.line), ')'];
    catch
        %%% The line stackinfo = errorinfo.stack(1,1); will fail if the
        %%% errorinfo.stack is empty, which sometimes happens during
        %%% debugging, I think. So we catch it here.
        ExtraInfo = '';
    end
end
disp([errorstring ': ' lasterr]);
disp(ExtraInfo);
error('Error in execution');
end
