function AddData(handles)

% Help for the Add Data tool:
% Category: Data Tools
%
% SHORT DESCRIPTION:
% Allows adding information for each image cycle to an output file.
% *************************************************************************
% Note: this tool is beta-version and has not been thoroughly checked.
%
% Use this tool if you would like to add text information about each image
% (e.g. Gene names or sample numbers) to the output file alongside the
% measurements that have been made. Then, the text information will be
% exported with the measurements when you use the ExportData data tool,
% helping you to keep track of your samples. You can also run the LoadText
% module in your pipeline so this step happens automatically during
% processing; its function is the same. Once the data is added to the
% output file, you can view the text file within the output file by using
% the ViewData data tool and selecting "Image". To delete the text file
% from the output file, use the ClearData data tool.
%
% Note that the number of text entries that you load with this module must
% be identical to the number of cycles you are processing in order for
% exporting to work properly.
%
% The information to be added must be in a separate text file with the
% following syntax:
%
% DESCRIPTION <description>
% <Text info for image cycle #1>
% <Text info for image cycle #2>
% <Text info for image cycle #3>
%              .
%              .
%
% <description> is a description of the text information stored in the
% file. It can contain spaces or unusual characters.
%
% For example:
%
% DESCRIPTION Gene names
% Gene X
% Gene Y
% Gene Z
%
% While not thoroughly tested, most likely you can load numerical data too.
%
% See also the LoadText module, ViewData and ClearData data tools.

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

%%% Select file with text information to be added
[filename, pathname] = CPuigetfile('*.*', 'Choose the file containing the data',handles.Current.DefaultOutputDirectory);
if filename == 0 %User canceled
    return;
end

%%% Get the pathname and let user select the files he wants
[Pathname, SelectedFiles] = CPselectoutputfiles(handles);

%%% Check if cancel button pressed
if ~iscellstr(SelectedFiles)
    return;
end

FieldName = inputdlg('What name would you like to give this data (what heading)?');

%%% Loop over the selected files and add the selected feature
%%% An cell array is used to indicated any errors in the processing
errors = cell(length(SelectedFiles),1);
for FileNbr = 1:length(SelectedFiles)

    %%% Load the specified CellProfiler output file
    try
        temp_handles = load(fullfile(Pathname, SelectedFiles{FileNbr}));
    catch
        errors{FileNbr} = [SelectedFiles{FileNbr},' is not a CellProfiler or MATLAB file (it does not have the extension .mat)'];
        continue
    end

    %%% Quick check if it seems to be a CellProfiler file or not
    if ~isfield(temp_handles, 'handles')
        errors{FileNbr} = [SelectedFiles{FileNbr},' is not a CellProfiler output file'];
        continue
    end

    handles = temp_handles.handles;

    %% Save temp values that LoadText needs
    tempVarValues=handles.Settings.VariableValues;
    tempCurrentField = handles.Current;
    %% Change handles that LoadText requires
    handles.Settings.VariableValues{1,1}=filename;
    handles.Settings.VariableValues{1,2}=FieldName;
    handles.Settings.VariableValues{1,3}=pathname;
    handles.Current.CurrentModuleNumber='01';
    handles.Current.SetBeingAnalyzed=1;
    %% Load Text
    handles = LoadText(handles);
    %% Return previous values
    handles.Settings.VariableValues=tempVarValues;
    handles.Current=tempCurrentField;

    %%% Save the updated CellProfiler output file
    try
        save(fullfile(Pathname, SelectedFiles{FileNbr}),'handles')
    catch
        errors{FileNbr} = ['Could not save updated ',SelectedFiles{FileNbr},' file.'];
        continue
    end
end

%%% Finished, display success or warning windows if we failed for some data set
error_index = find(~cellfun('isempty',errors));
if isempty(error_index)
    CPmsgbox('Data successfully added.')
else
    %%% Show a warning dialog box for each error
    for k = 1:length(error_index)
        CPwarndlg(errors{error_index(k)},'Add Data failure')
    end
end
