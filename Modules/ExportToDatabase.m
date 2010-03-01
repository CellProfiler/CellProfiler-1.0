function handles = ExportToDatabase(handles)

% Help for the Export To Database module:
% Category: File Processing
%
% SHORT DESCRIPTION:
% Exports data in database readable format, including an importing file
% with column names and a CellProfiler Analyst properties file, if desired.
% *************************************************************************
%
% This module exports measurements to a SQL compatible format. It creates
% MySQL or Oracle scripts and associated data files which will create a
% database and import the data into it and gives you the option of creating
% a properties file for use with CellProfiler Analyst. 
% 
% This module must be run at the end of a pipeline, or second to last if 
% you are using the CreateBatchFiles module. If you forget this module, you
% can also run the ExportDatabase data tool after processing is complete; 
% its functionality is the same.
%
% The database is set up with two primary tables. These tables are the
% Per_Image table and the Per_Object table (which may have a prefix if you
% specify). The Per_Image table consists of all the Image measurements and
% the Mean and Standard Deviation of the object measurements. There is one
% Per_Image row for every image. The Per_Object table contains all the
% measurements for individual objects. There is one row of object
% measurements per object identified. The two tables are connected with the
% primary key column ImageNumber. The Per_Object table has another primary
% key called ObjectNumber, which is unique per image.
%
% The Oracle database has an extra table called Column_Names. This table is
% necessary because Oracle has the unfortunate limitation of not being able
% to handle column names longer than 32 characters. Since we must
% distinguish many different objects and measurements, our column names are
% very long. This required us to create a separate table which contains a
% short name and corresponding long name. The short name is simply "col"
% with an attached number, such as "col1" "col2" "col3" etc. The short name
% has a corresponding long name such as "Nuclei_AreaShape_Area". Each of
% the Per_Image and Per_Object columnnames are loaded as their "short name"
% but the long name can be determined from the Column_Names table.
%
% Settings:
%
% Database Type: 
% You can choose to export MySQL or Oracle database scripts. The exported
% data is the same for each type, but the setup files for MySQL and Oracle
% are different.
%
% Database Name: 
%   In MySQL, you can enter the name of a database to create or the name of
% an existing database. When using the script, if the database already
% exists, the database creation step will be skipped so the existing
% database will not be overwritten but new tables will be added. Do be
% careful, however, in choosing the Table Prefix. If you use an existing
% table name, you might unintentionally overwrite the data in that table.
%   In Oracle, when you log in you must choose a database to work with, so
% there is no need to specify the database name in this module. This also
% means it is impossible to create/destroy a database with these
% CellProfiler scripts.
%
% Table Prefix: 
% Here you can choose what to append to the table names Per_Image and
% Per_Object. If you choose "Do not use", no prefix will be appended. If you choose
% a prefix, the tables will become PREFIX_Per_Image and PREFIX_Per_Object
% in the database. If you are using the same database for all of your
% experiments, the table prefix is necessary and will be the only way to
% distinguish different experiments. If you are creating a new database for
% every experiment, then it may be easier to keep the generic Per_Image and
% Per_Object table names. Be careful when choosing the table prefix, since
% you may unintentionally overwrite existing tables.
%
%
% Do you want to create a Per_Well table?:
% To create a Per_Well table, you need to have a FileNameMetadata module in
% your pipeline which extracts the Plate (if applicable) and Well metadata
% from the filename and/or pathname.  You then need to specify here in
% ExportToDatabase what these tokens were called (though they are by
% default Plate & Well, which corresponds to
% the default in FilenNameMetadata).  If instead you had labeled your
% 'plate' as <Barcode> in FileNameMetadata, here you would select 'Other'
% and specify Barcode in response to 'Which token
% uniquely specifies your Plate?'
%
% SQL File Prefix: All the CSV files will start with this prefix.
%
% Create a CellProfiler Analyst properties file: Generate a template
% properties for using your new database in CellProfiler Analyst (a data
% exploration tool which can also be downloaded from
% http://www.cellprofiler.org/)
% 
% If creating a properties file for use with CellProfiler Analyst (CPA): 
% The module will attempt to fill in as many as the entries as possible 
% based on the current handles structure. However, entries such as the 
% server name, username and password are omitted. Hence, opening the 
% properties file in CPA will produce an error since it won't be able to
% connect to the server. However, you can still edit the file in CPA and
% then fill in the required information.
%
% ********************* How To Import MySQL *******************************
% Step 1: Log onto the server where the database will be located.
%
% Step 2: From within a terminal logged into that server, navigate to folder 
% where the CSV output files and the SETUP script is located.
%
% Step 3: Type the following within the terminal to log into MySQL on the 
% server where the database will be located:
%    mysql -uUsername -pPassword -hHost
%
% Step 4: Type the following within the terminal to run SETUP script: 
%      \. DefaultDB_SETUP.SQL
%
% The SETUP file will do everything necessary to load the database.
%
% ********************* How To Import Oracle ******************************
% Step 1: Using a terminal, navigate to folder where the CSV output files
% and the SETUP script is located.
%
% Step 2: Log into SQLPlus: "sqlplus USERNAME/PASSWORD@DATABASESCRIPT"
% You may need to ask your IT department the name of DATABASESCRIPT.
%
% Step 3: Run SETUP script: "@DefaultDB_SETUP.SQL"
%
% Step 4: Exit SQLPlus: "exit"
%
% Step 5: Load data files (for columnames, images, and objects):
%
% sqlldr USERNAME/PASSWORD@DATABASESCRIPT control=DefaultDB_LOADCOLUMNS.CTL
% sqlldr USERNAME/PASSWORD@DATABASESCRIPT control=DefaultDB_LOADIMAGE.CTL
% sqlldr USERNAME/PASSWORD@DATABASESCRIPT control=DefaultDB_LOADOBJECT.CTL
%
% Step 6: Log into SQLPlus: "sqlplus USERNAME/PASSWORD@DATABASESCRIPT"
%
% Step 7: Run FINISH script: "@DefaultDB_FINISH.SQL"
%
% Technical note: This module calls the CPconvertsql function to do the
% actual exporting, which is same function as called by the ExportDatabase
% data tool.
%
% See also: CreateBatchFiles, ExportDatabase data tool.

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
% (1a) What type of database do you want to use? (DatabaseType)
% (1b) (Shown if "MySQL" is selected above) What is the name of the database to use?
% (2) What prefix do you want to name the per-image and per-object tables 
% in the database? Type "Do not use" to ignore. Metadata token may also be 
% used. An underscore will be added to the end of the prefix automatically.
% (3) What prefix should be used to name the SQL files? (FilePrefix)
% (4) What directory do you want the SQL files to be saved? Type period
% (.) to use the default output folder. (DataPath)
% (5) Which per-image statistics do you want to calculate?  Select "Do not
% use" to omit. (StatisticsCalculated)
% (6) Which objects do you want to export? (ObjectsToBeExported)
% (7) Do you want to create a CellProfiler Analyst properties file?
% (WriteProperties)
%
% (i) Setting (2): The user should be able to use metadata tokens as well
% (ii) Seting (4): Metadata tokens should be permitted here in order to 
% create  subdirectories. Subdirecrtories should be created automatically 
% if needed.
% (iii) Setting (5): The selections should be Mean, Median and Standard deviation.
% It should start with one popup, with a button to add/subtract more
% statistics popups, with a max of three (for all the stats)
% (iv) Setting (6): A button should be added that lets the user add/subtract 
% objects

%%%%%%%%%%%%%%%%%
%%% VARIABLES %%%
%%%%%%%%%%%%%%%%%
drawnow

[CurrentModule, CurrentModuleNum, ModuleName] = CPwhichmodule(handles);

%textVAR01 = What type of database do you want to use?
%choiceVAR01 = MySQL
%choiceVAR01 = Oracle
DatabaseType = char(handles.Settings.VariableValues{CurrentModuleNum,1});
%inputtypeVAR01 = popupmenu

%textVAR02 = For MySQL only, what is the name of the database to use?
%defaultVAR02 = DefaultDB
DatabaseName = char(handles.Settings.VariableValues{CurrentModuleNum,2});

assert(~any(isspace(DatabaseName)),['Image processing was canceled in the ', ModuleName, ...
    ' module because you have entered one or more spaces in the text box for the database name.'])
assert(~any(strfind(DatabaseName,'-')),['Image processing was canceled in the ', ModuleName, ...
    ' module because you have entered one or more dashes in the text box for the database name.'])

        
%textVAR03 = What prefix should be used to name the tables in the database (should be unique per experiment, or leave "Do not use" to have generic Per_Image and Per_Object tables)?  An underscore will be added to the end of the prefix automatically. If a FileNameMetadata module was used, a regular expression may be inserted here.
%defaultVAR03 = Do not use
TablePrefix = char(handles.Settings.VariableValues{CurrentModuleNum,3});

% Substitute filename metadata tokens into TablePrefix (if found) and
% checks if the prefix is valid
TablePrefix = CPreplacemetadata(handles,TablePrefix);

if ~strcmp(TablePrefix,'Do not use')
    % Try to ensure prefix validity by removing whitespaces and hyphens
    if any(TablePrefix == ' ' | TablePrefix == '-')
        TablePrefix = strrep(TablePrefix,' ','');
        TablePrefix = strrep(TablePrefix,'-','_');
        CPwarndlg('Your table prefix has spaces and/or hyphens, which are not SQL-compatible. Spaces will be removed and hyphens converted to underscores. Check your database script to see if this change is acceptable',[mfilename,': Invalid characters in Table Prefix'],'replace');
    end
    
    CPvalidfieldname(TablePrefix)
end

%textVAR04 = What prefix should be used to name the SQL files?
%defaultVAR04 = SQL_
FilePrefix = char(handles.Settings.VariableValues{CurrentModuleNum,4});
% Substitute filename metadata tokens into FilePrefix (if found)
FilePrefix = CPreplacemetadata(handles,FilePrefix);

%pathnametextVAR05 = Enter the directory where the SQL files are to be saved.  Type period (.) to use the default output folder.
%defaultVAR05 = .
DataPath = char(handles.Settings.VariableValues{CurrentModuleNum,5});

%textVAR06 = Which per-image statistics do you want to be calculate?  Select "Do not use" to omit.
%choiceVAR06 = Mean
%choiceVAR06 = Standard deviation
%choiceVAR06 = Median
%choiceVAR06 = Do not use
%defaultVAR06 = Mean
StatisticsCalculated{1} = char(handles.Settings.VariableValues{CurrentModuleNum,6});
%inputtypeVAR06 = popupmenu

%textVAR07 = 
%choiceVAR07 = Standard deviation
%choiceVAR07 = Mean
%choiceVAR07 = Median
%choiceVAR07 = Do not use
%defaultVAR07 = Standard deviation
StatisticsCalculated{2} = char(handles.Settings.VariableValues{CurrentModuleNum,7});
%inputtypeVAR07 = popupmenu

%textVAR08 = 
%choiceVAR08 = Do not use
%choiceVAR08 = Standard deviation
%choiceVAR08 = Mean
%choiceVAR08 = Median
%defaultVAR08 = Do not use
StatisticsCalculated{3} = char(handles.Settings.VariableValues{CurrentModuleNum,8});
%inputtypeVAR08 = popupmenu

%textVAR09 = Which objects do you want to export? Use "All objects" in this first box to export all objects (including 'Image'), or select the objects you want to export in this and the following boxes. Use "Do not use" to ignore. 
%infotypeVAR09 = objectgroup
%choiceVAR09 = All objects
%choiceVAR09 = Image
%choiceVAR09 = Do not use
ObjectsToBeExported{1} = char(handles.Settings.VariableValues{CurrentModuleNum,9});
%inputtypeVAR09 = popupmenu

%textVAR10 =
%infotypeVAR10 = objectgroup
%choiceVAR10 = Do not use
%choiceVAR10 = Image
ObjectsToBeExported{2} = char(handles.Settings.VariableValues{CurrentModuleNum,10});
%inputtypeVAR10 = popupmenu

%textVAR11 =
%infotypeVAR11 = objectgroup
%choiceVAR11 = Do not use
%choiceVAR11 = Image
ObjectsToBeExported{3} = char(handles.Settings.VariableValues{CurrentModuleNum,11});
%inputtypeVAR11 = popupmenu

%textVAR12 =
%infotypeVAR12 = objectgroup
%choiceVAR12 = Do not use
%choiceVAR12 = Image
ObjectsToBeExported{4} = char(handles.Settings.VariableValues{CurrentModuleNum,12});
%inputtypeVAR12 = popupmenu

%textVAR13 =
%infotypeVAR13 = objectgroup
%choiceVAR13 = Do not use
%choiceVAR13 = Image
ObjectsToBeExported{5} = char(handles.Settings.VariableValues{CurrentModuleNum,13});
%inputtypeVAR13 = popupmenu

%textVAR14 =
%infotypeVAR14 = objectgroup
%choiceVAR14 = Do not use
%choiceVAR14 = Image
ObjectsToBeExported{6} = char(handles.Settings.VariableValues{CurrentModuleNum,14});
%inputtypeVAR14 = popupmenu

%textVAR15 =
%infotypeVAR15 = objectgroup
%choiceVAR15 = Do not use
%choiceVAR15 = Image
ObjectsToBeExported{7} = char(handles.Settings.VariableValues{CurrentModuleNum,15});
%inputtypeVAR15 = popupmenu

%textVAR16 = Do you want to create a Per_Well table? (NOTE: You must use a FileNameMetaData module to create a Per_Well table; See Help for details.)
%choiceVAR16 = No
%choiceVAR16 = Yes
WritePerWell = char(handles.Settings.VariableValues{CurrentModuleNum,16});
%inputtypeVAR16 = popupmenu

%textVAR17 = Which token uniquely specifies your Plate? (Select 'Do not use' if you only have one plate)
%choiceVAR17 = Plate
%choiceVAR17 = Do not use
PlateMeasurement = char(handles.Settings.VariableValues{CurrentModuleNum,17});
%inputtypeVAR17 = popupmenu custom

%textVAR18 = Which token uniquely specifies your Well? 
%choiceVAR18 = Well
%choiceVAR18 = Do not use
WellMeasurement = char(handles.Settings.VariableValues{CurrentModuleNum,18});
%inputtypeVAR18 = popupmenu custom

%textVAR19 = Do you want to create a CellProfiler Analyst properties file?
%choiceVAR19 = Yes - Both V1.0 and V2.0 format
%choiceVAR19 = Yes - V1.0 format
%choiceVAR19 = Yes - V2.0 format
%choiceVAR19 = No
WriteProperties = char(handles.Settings.VariableValues{CurrentModuleNum,19});
%inputtypeVAR19 = popupmenu

%%%VariableRevisionNumber = 10

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% PRELIMINARY CALCULATIONS & FILE HANDLING %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
drawnow

if handles.Current.NumberOfModules == 1
    error(['Image processing was canceled in the ', ModuleName, ' module because there are no other modules in the pipeline. Probably you should use the ExportDatabase data tool.']);
elseif handles.Current.NumberOfModules == 2
    if ~isempty((strmatch('CreateBatchFiles',handles.Settings.ModuleNames)))
        error(['Image processing was canceled in the ', ModuleName, ' module because there are no modules in the pipeline other than the CreateBatchFiles module. Probably you should use the ExportDatabase data tool.']);
    end
end

if CurrentModuleNum ~= handles.Current.NumberOfModules
    if isempty((strmatch('CreateBatchFiles',handles.Settings.ModuleNames))) || handles.Current.NumberOfModules ~= CurrentModuleNum+1
        error([ModuleName, ' must be the last module in the pipeline, or second to last if the CreateBatchFiles module is in the pipeline.']);
    end
end

if strncmp(DataPath, '.',1)
    if length(DataPath) == 1
        DataPath = handles.Current.DefaultOutputDirectory;
    else
        DataPath = fullfile(handles.Current.DefaultOutputDirectory,DataPath(2:end));
    end
end

StatisticsCalculated(strcmp(StatisticsCalculated,'Do not use')) = [];
ObjectsToBeExported(strcmp(ObjectsToBeExported,'Do not use')) = [];

ObjectsToBeExported = unique(ObjectsToBeExported);
StatisticsCalculated = unique(StatisticsCalculated);

% Two possibilities: we're at the end of the pipeline in an
% interactive session, or we're in the middle of batch processing.

if isfield(handles.Current, 'BatchInfo'),
    FirstSet = handles.Current.BatchInfo.Start;
    LastSet = handles.Current.BatchInfo.End;
else
    FirstSet = 1;
    LastSet = handles.Current.NumberOfImageSets;
end

if strcmp(WritePerWell,'Yes') && ~strcmp(PlateMeasurement,'Do not use'),
    if ~isfield(handles.Measurements.Image,['Metadata_',(PlateMeasurement)]);
        error(['Image processing was canceled in the ',ModuleName, ' module because you requested to create a Per Well table,but the plate name you specified was invalid. You must use a FileNameMetadata module to create this measurement.']);
    end
    if ~isfield(handles.Measurements.Image,['Metadata_',(WellMeasurement)]);
        error(['Image processing was canceled in the ',ModuleName, ' module because you requested to create a Per Well table,but the well name you specified was invalid. You must use a FileNameMetadata module to create this measurement.']);
    end
elseif strcmp(WritePerWell,'Yes') && strcmp(PlateMeasurement,'Do not use')
    if ~isfield(handles.Measurements.Image,['Metadata_',(WellMeasurement)]);
        error(['Image processing was canceled in the ',ModuleName, ' module because you requested to create a Per Well table,but the well name you specified was invalid. You must use a FileNameMetadata module to create this measurement.']);
    end
end
DoWriteSQL = (handles.Current.SetBeingAnalyzed == LastSet);
DoWriteCPAPropertiesFile = strcmpi(WriteProperties(1),'y') & (handles.Current.SetBeingAnalyzed == 1);

% Initial checking of variables, if we're writing anything
if DoWriteSQL || DoWriteCPAPropertiesFile

    if isempty(DataPath)
        error(['Image processing was canceled in the ', ModuleName, ' module because no folder was specified.']);
    elseif ~exist(DataPath,'dir')
        error(['Image processing was canceled in the ', ModuleName, ' module because the specified folder could not be found.']);
    end
    if isempty(DatabaseName)
        error(['Image processing was canceled in the ', ModuleName, ' module because no database was specified.']);
    end
end

if DoWriteSQL,
    CPconvertsql(handles,DataPath,FilePrefix,DatabaseName,TablePrefix,FirstSet,LastSet,DatabaseType,StatisticsCalculated,ObjectsToBeExported,WritePerWell,PlateMeasurement,WellMeasurement);
end

if DoWriteCPAPropertiesFile,
    re = regexp(WriteProperties,'V(?<number>[0-9]+\.[0-9]+)','names');
    for verIdx = 1:length(re)
        version = str2double(re(verIdx).number);
        CPcreateCPAPropertiesFile(handles, DataPath, DatabaseName, TablePrefix, DatabaseType, version);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%
%%% DISPLAY RESULTS %%%
%%%%%%%%%%%%%%%%%%%%%%%
drawnow

%%% The figure window display is unnecessary for this module, so it is
%%% closed during the starting image cycle.
CPclosefigure(handles,CurrentModule)