function ExportDatabase(handles)

% Help for the Export Database tool:
% Category: Data Tools
%
% SHORT DESCRIPTION:
% Exports data in database readable format, including an importing file
% with column names.
% *************************************************************************
%
% NOTE:
% This tool is not functional right now - use the ExportToDatabase module
% within your pipeline instead. Sorry for the inconvenience!!
%
% This data tool exports measurements to a SQL compatible format. It creates
% MySQL or Oracle scripts and associated data files which will create a
% database and import the data into it. You can also run the ExportToDatabase
% module in your pipeline so this step happens automatically during
% processing; its function is the same.
%
% See the help for the ExportToDatabase module for information on the
% settings for this data tool and how to use it.
%
% Current known limitations and things to consider:
%
% - No check is performed that the selected files are compatible, i.e.
%   were produced with the same pipeline of modules.
%
% - The tool only works with standard CellProfiler output files, not
%   batch output files. Use the ConvertBatchFiles data tool to convert if
%   necessary.
%
% - Image sets are numbered according to the order they are written by
%   this tool. This numbering may not be consistent with the order they
%   were processed, e.g. on the cluster. This can be fixed by adding an
%   extra feature field in handles.Measurements.Image

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

% This function is not called from ExportToDatabase ModuleCall but from the Data tool menu
ModuleCall = 0;

%%% Let the user select one output file to indicate the directory and how the
%%% filename is constructed
[ExampleFile, DataPath] = CPuigetfile('*.mat', 'Select one CellProfiler output file',handles.Current.DefaultOutputDirectory);
if ~DataPath;return;end
%CurrentDataPath = handles.Current.DefaultOutputDirectory %current dir

%%% Get all files with .mat extension in the chosen directory.
%%% If the selected file name contains an 'OUT', it is assumed
%%% that all interesting files contain an 'OUT'.
AllFiles = dir(DataPath);                                                        % Get all file names in the chosen directory
AllFiles = {AllFiles.name};
Files = AllFiles(~cellfun('isempty',strfind(AllFiles,'.mat')));                  % Keep files that has and .mat extension
if strfind(ExampleFile,'OUT')
    Files = Files(~cellfun('isempty',strfind(Files,'OUT')));                     % Keep files with an 'OUT' in the name
end

%%% Let the user select the files to be exported
[selection,ok] = listdlg('liststring',Files,'name','Export SQL',...
    'PromptString','Select files to export. Use Ctrl+Click or Shift+Click.','listsize',[300 500]);
if ~ok,return,end
CellProfilerDataFileNames = Files(selection);

%%% Ask for database name and name of SQL script, should probably use some
%%% sort of drop down menue for type of database
answer = inputdlg({'Name of Database to use:','SQL script name:','Type of Database to use (Oracle or MySQL)','Table Prefix','Calculate per-image means? (Y/N)','Calculate per-image standard deviations? (Y/N)','Calculate per-image medians? (Y/N)','Create a Per_Well table? (Y/N)','Which token uniquely specifies your Plate  (Type ''Do not use'' if you only have one plate)?','Which token uniquely specifies your Well?'},...
    'Export SQL',1,...
    {'Default','SQL_','MySQL','Do not use','Y','Y','Y','N','Plate','Well'});
if isempty(answer),return;end
DatabaseName = answer{1};
SQLScriptFileName = answer{2};%fullfile(DataPath,answer{2});
DatabaseType = answer(3);
TablePrefix = char(answer(4));
StatisticsCalculated = {'Mean','Standard deviation','Median'};
StatisticsCalculated = StatisticsCalculated([strncmpi(char(answer{5}),'y',1),strncmpi(char(answer{6}),'y',1),strncmpi(char(answer{7}),'y',1)]);
if isempty(DatabaseName) || isempty(SQLScriptFileName)
    error('A database name and an SQL script name must be specified!');
    return;
end

if strcmp(answer{8},'Yes'),
    WritePerWell = 'Yes';
else WritePerWell = 'No';
end
PlateMeasurement = answer{9};
WellMeasurement = answer{10};

%check whether have write permission in current dir
SQLScriptFid = fopen(SQLScriptFileName, 'wt');
if SQLScriptFid == -1, error(['Could not open ' SQLScriptFileName ' for writing.']); end

%display waiting bar
waitbarhandle = waitbar(0,'Exporting SQL files');
drawnow

for FileNo = 1:length(CellProfilerDataFileNames)

    % If called as a Data tool, load handles structure from file
    if ~ModuleCall,load(fullfile(DataPath,CellProfilerDataFileNames{FileNo}));end

    % Get the object types, e.g. 'Image', 'Cells', 'Nuclei',...
    try
        ObjectTypes = fieldnames(handles.Measurements);
    catch
        CPerrordlg('The output file does not contain a field called Measurements');
        return;
    end

     % Get the output file's prefix as .sql file's fileprefix, so if mutliple
    % files are selected the sql files will be named differently, even the
    % output files are exactly the same except the file names
    filename = CellProfilerDataFileNames{FileNo};
    index = strfind(filename,'.');
    if ~isempty(index)
        filename = filename(1:index-1);%,everything before . will be kept
    end

    % Select objects for export
    [selection,ok] = listdlg('liststring',ObjectTypes,'name','Objects to export',...
    'PromptString',['Select objects to export from ',filename,'. Use Ctrl+Click or Shift+Click.'],'listsize',[300 500]);
    if ~ok,return,end
    ObjectTypes = ObjectTypes(selection);

    for ObjectTypeNo = 1:length(ObjectTypes)    % Loop over the objects
        % Get the object type in a variable for convenience
        ObjectType = ObjectTypes{ObjectTypeNo};

        % Update waitbar
        done = (FileNo - 1)*length(ObjectTypes) + ObjectTypeNo;
        total = length(CellProfilerDataFileNames)*length(ObjectTypes);
        waitbar(done/total,waitbarhandle);drawnow

    end %endloop over objtype
    %figure out the first and last set
    if isfield(handles.Measurements, 'BatchInfo'),
        FirstSet = handles.Measurements.BatchInfo.Start;
        LastSet = handles.Measurements.BatchInfo.End;
    else
        FirstSet = 1;
        fields = fieldnames(handles.Measurements.Image);
        filefields = fields(strncmp(fields,'FileName',8));
        LastSet = length(handles.Measurements.Image.(filefields{1}));
    end

    % for calling from data tool, no tableprefix is asked from user, leave
    % it as blank

   CPconvertsql(handles, DataPath, SQLScriptFileName, DatabaseName,TablePrefix,FirstSet, LastSet, DatabaseType, StatisticsCalculated, ObjectTypes, WritePerWell, PlateMeasurement, WellMeasurement);

end % End loop over data files

%%% Done, let the user know if this function was called as a data tool and restore the handles structure
close(waitbarhandle);
if ~ModuleCall
    CPmsgbox('Exporting is completed.')
end
fclose(SQLScriptFid);