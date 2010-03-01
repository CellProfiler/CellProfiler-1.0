function [Pathname SelectedFiles] = CPselectoutputfiles(handles)

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

%%% Ask the user to choose the directory from which to extract measurements.
if exist(handles.Current.DefaultOutputDirectory, 'dir')
    Pathname = CPuigetdir(handles.Current.DefaultOutputDirectory,'Choose the folder that contains the output file(s) to use');
else
    Pathname = CPuigetdir(pwd,'Choose the folder that contains the output file(s) to use');
end

if Pathname ~= 0
    %%% Get all files with .mat extension in the chosen directory that contains a 'OUT' in the filename
    AllFiles = dir(Pathname);                                                        % Get all file names in the chosen directory
    AllFiles = {AllFiles.name};                                                      % Cell array with file names
    SelectedFiles = AllFiles(~cellfun('isempty',strfind(AllFiles,'.mat')));          % Keep files that has a .mat extension
    SelectedFiles = SelectedFiles(~cellfun('isempty',strfind(SelectedFiles,'OUT'))); % Keep files with an 'OUT' in the name

    if isempty(SelectedFiles)
        error('There are no valid CellProfiler OUT(put) files in this directory.')
    end
    %%% Let the user select the files
    [selection,ok] = listdlg('liststring',SelectedFiles,'name','Select output files',...
        'PromptString','Choose CellProfiler output files to use. Use Ctrl+Click or Shift+Click to choose multiple files.','listsize',[300 500]);
    if ~ok
        SelectedFiles = 0;
    else
        SelectedFiles = SelectedFiles(selection);
    end
else
    SelectedFiles = 0;
end