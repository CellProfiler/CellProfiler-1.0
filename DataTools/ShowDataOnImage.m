function orig_handles = ShowDataOnImage(handles)

% Help for the Show Data on Image tool:
% Category: Data Tools
%
% SHORT DESCRIPTION:
% Produces an image with measured data on top of identified objects.
% *************************************************************************
% Note: this tool is beta-version and has not been thoroughly checked.
%
% This tool allows you to extract measurements from an output file and
% overlay any measurements that you have made on any image, very much like
% the DisplayDataOnImage module. For example, you could look at the DNA
% content (e.g. IntegratedIntensityOrigBlue) of each cell on an image of
% nuclei. Or, you could look at cell area on an image of nuclei.
%
% First, you are asked to select the measurement you want to be displayed
% on the image. Next, if your output file has measurements from many
% cycles, you are asked to select which sample/cycle number to view. Then,
% you are asked to select an image to display the measurements over. You
% can choose from among the list of images saved in the output file you
% chose (which are generally the original images loaded by a LoadImages or
% LoadSingleImage module), or you can browse for an image manually (e.g. a
% cropped image that was created during the pipeline and saved on the disk
% by a SaveImages module). You must try to select the image from which the
% measurements were taken because the tool will try to display each
% measurement over the corresponding object, so if the image is not the
% right one, the data will make no sense. Once all these settings are
% chosen, extraction ensues and eventually the image will be shown with the
% measurements on top.
%
% You can then use the InteractiveZoom under the CellProfiler Image Tools
% menu to zoom in on this image. If the text is overlapping and not easily
% visible, you can change the number of decimal places shown with the
% 'Significant digits' button, or you can change the font size with the
% 'Text Properties' button. You can also change the font style, color, and 
% other properties with this button. If you want to go back to the original
% label settings, click the 'Restore labels' button. Alternatively, you can
% hide and show the labels by clicking the 'Hide labels' and 'Show labels'
% buttons, respectively.
%
% The resulting figure can be saved in MATLAB format (.fig) or exported in
% a traditional image file format.
%
% See also DisplayDataOnImage.

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


%%% This tool shouldn't change anything in the handles.
orig_handles = handles;

%%% Asks the user to choose the file from which to extract measurements.
[RawFileName, RawPathname] = CPuigetfile('*.mat', 'Select the raw measurements file',handles.Current.DefaultOutputDirectory);
if RawFileName == 0,return,end

load(fullfile(RawPathname,RawFileName));

% Try to convert features
handles = CP_convert_old_measurements(handles);

%%% Call the function CPgetfeature(), which opens a series of list dialogs and
%%% lets the user choose a feature. The feature can be identified via 'ObjectTypename',
%%% 'FeatureType' and 'FeatureNo'.
try
    [ObjectTypename,FeatureType] = CPgetfeature(handles,1, true);
catch
    ErrorMessage = lasterr;
    CPerrordlg(['An error occurred in the ShowDataOnImage Data Tool. ' ErrorMessage(30:end)]);
    return
end
if isempty(ObjectTypename),return,end

%%% Prompts the user to choose a sample number to be displayed.
Answer = inputdlg({'Which sample/cycle number do you want to display?'},'Choose sample number',1,{'1'});
if isempty(Answer)
    return
end
SampleNumber = str2double(Answer{1});
if strcmp(FeatureType, 'Object Number'),
    if SampleNumber > length(handles.Measurements.Image.(CPjoinstrings('Count', ObjectTypename))),
        CPerrordlg(['Error: the sample number you entered, ' num2str(SampleNumber) ', exceeds the number of samples in the output file.']);
        return
    end
else
    if SampleNumber > length(handles.Measurements.(ObjectTypename).(FeatureType))
       CPerrordlg(['Error: the sample number you entered, ' num2str(SampleNumber) ', exceeds the number of samples in the output file.']);
        return
    end 
end

%%% Looks up the corresponding image file name
PipelineFields = fieldnames(handles.Pipeline);
idx = strmatch('FileList',PipelineFields);
PotentialImageNames = {}; for i = 1:length(idx), PotentialImageNames = cat(1,PotentialImageNames,handles.Pipeline.(PipelineFields{idx(i)}){SampleNumber}); end

%%% Error detection.
if isempty(PotentialImageNames)
    PromptMessage = 'CellProfiler was not able to look up the image file names used to create these measurements to help you choose the correct image on which to display the results. You may continue, but you are on your own to choose the correct image file.';
    %%% Prompts the user with the image file name.
    h = CPmsgbox(PromptMessage);
    %%% Opens a user interface window which retrieves a file name and path
    %%% name for the image to be displayed.
    [FileName,Pathname] = CPuigetfile('*.*', 'Select the image to view', handles.Current.DefaultImageDirectory);
    %%% If the user presses "Cancel", the FileName will = 0 and nothing will happen.
    if FileName == 0,return,end
    try delete(h), end
    ImageFileName = {FileName};
else
    PotentialImageNames{end+1} = 'Choose Image Manually';
    %%% Allows the user to select a filename from the list.
    [Selection, ok] = listdlg('ListString',PotentialImageNames, 'ListSize', [300 300],...
        'Name','Choose the image whose filename you want to display',...
        'PromptString','Choose the image whose filename you want to display','CancelString','Cancel',...
        'SelectionMode','single');
    if ok == 0
        return
    end
    if Selection == length(PotentialImageNames)
        PromptMessage = 'You have chosen to choose the image to display manually.';
        %%% Prompts the user with the image file name.
        h = CPmsgbox(PromptMessage);
        uiwait(h);

        %%% Opens a user interface window which retrieves a file name and path
        %%% name for the image to be displayed.
        [FileName,Pathname] = CPuigetfile('*.*', 'Select the image to view', handles.Current.DefaultImageDirectory);
        %%% If the user presses "Cancel", the FileName will = 0 and nothing will happen.
        if FileName == 0,return,end
        try delete(h), end
        ImageFileName = {FileName};
    else
        ImageFileName = handles.Pipeline.(PipelineFields{idx(Selection)}){SampleNumber};
        PromptMessage = ['Browse to find the image called ', ImageFileName,'.'];
        prefix = 'FileList';
        Pathname = handles.Pipeline.(['Pathname',PipelineFields{idx(Selection)}(strfind(PipelineFields{idx(Selection)},prefix)+length(prefix):end)]);
        FileName = char(ImageFileName);
        if  ~exist(fullfile(Pathname,FileName),'file') %path and file does not exist there.
            %%% Prompts the user with the image file name.
            h = CPmsgbox(PromptMessage);

            %%% Opens a user interface window which retrieves a file name and path
            %%% name for the image to be displayed.
            [FileName,Pathname] = CPuigetfile('*.*', 'Select the image to view', handles.Current.DefaultImageDirectory);
            %%% If the user presses "Cancel", the FileName will = 0 and nothing will happen.
            if FileName == 0,return,end
            try delete(h), end
        end
    end
end

%%% Opens and displays the image.
try
    ImageToDisplay = CPimread(fullfile(Pathname,FileName));
catch
    CPerrordlg(['Error opening image ', FileName, ' in folder ', Pathname])
    return
end

%%% Extracts the measurement values.
if strcmp(FeatureType, 'Object Number'),
    tmp = (1:handles.Measurements.Image.(CPjoinstrings('Count', ObjectTypename)){SampleNumber})';
else
    tmp = handles.Measurements.(ObjectTypename).(FeatureType){SampleNumber};
end
if isempty(tmp)
    CPerrordlg('Error: there are no object measurements in your file for that image.');
    return
end

TextFlag = 0;
if iscell(tmp)    
    if strcmp(FeatureType, 'Tracking')
        StringListOfMeasurements = tmp;
    else
        StringListOfMeasurements = handles.Measurements.(ObjectTypename).(FeatureType){SampleNumber};
    end    
    ListOfMeasurements = StringListOfMeasurements;
    TextFlag = 1;
else
    ListOfMeasurements = tmp;
    StringListOfMeasurements = cellstr(num2str(ListOfMeasurements));
end

%%% Extracts the XY locations. This is temporarily hard-coded
Xlocations = handles.Measurements.(ObjectTypename).Location_Center_X{SampleNumber};
Ylocations = handles.Measurements.(ObjectTypename).Location_Center_Y{SampleNumber};

%%% Create window
FigureHandle = CPfigure(handles,'image');
CPimagesc(ImageToDisplay,handles);

title([ObjectTypename,', ',FeatureType,' on ',ImageFileName])

%%% Overlays the values in the proper location in the image.
TextHandles = text(Xlocations , Ylocations , StringListOfMeasurements,...
    'HorizontalAlignment','center', 'color', [1 0 0],'fontsize',handles.Preferences.FontSize);

%%% Create structure and save it to the UserData property of the window
Info = get(FigureHandle,'UserData');
Info.ListOfMeasurements = ListOfMeasurements;
Info.TextHandles = TextHandles;
set(FigureHandle,'UserData',Info);

%%% A button is created in the display window which
%%% allows altering the properties of the text.
StdUnit = 'point';
StdColor = get(0,'DefaultUIcontrolBackgroundColor');
PointsPerPixel = 72/get(0,'ScreenPixelsPerInch');

uicontrol('Parent',FigureHandle, ...
    'Unit',StdUnit, ...
    'BackgroundColor',StdColor, ...
    'CallBack',@DisplayButtonCallback1, ...
    'Position',PointsPerPixel*[2 2 90 22], ...
    'Units','Normalized',...
    'String','Text Properties', ...
    'Style','pushbutton', ...
    'FontSize',handles.Preferences.FontSize);

if ~TextFlag
    uicontrol('Parent',FigureHandle, ...
        'Unit',StdUnit, ...
        'BackgroundColor',StdColor, ...
        'CallBack',@DisplayButtonCallback2, ...
        'Position',PointsPerPixel*[100 2 135 22], ...
        'Units','Normalized',...
        'String','Significant digits', ...
        'Style','pushbutton', ...
        'FontSize',handles.Preferences.FontSize);

    uicontrol('Parent',FigureHandle, ...
        'Unit',StdUnit, ...
        'BackgroundColor',StdColor, ...
        'CallBack',@DisplayButtonCallback3, ...
        'Position',PointsPerPixel*[240 2 135 22], ...
        'Units','Normalized',...
        'String','Restore labels', ...
        'Style','pushbutton', ...
        'FontSize',handles.Preferences.FontSize);
end

uicontrol('Parent',FigureHandle, ...
    'Unit',StdUnit, ...
    'BackgroundColor',StdColor, ...
    'CallBack',@DisplayButtonCallback4, ...
    'Position',PointsPerPixel*[380 2 85 22], ...
    'Units','Normalized',...
    'String','Hide labels', ...
    'Style','togglebutton', ...
    'FontSize',handles.Preferences.FontSize);

%%%%%%%%%%%%%%%%%%%%
%%% SUBFUNCTIONS %%%
%%%%%%%%%%%%%%%%%%%%
%%
%%% SUBFUNCTION - DisplayButtonCallback1
function DisplayButtonCallback1(hObject,eventdata)

VersionCheck = version;

if strcmp(computer,'MAC') && str2num(VersionCheck(1:3)) < 7.1 %#ok Ignore MLint
    CPmsgbox('A bug in MATLAB is preventing this function from working on the Mac platform. Service Request #1-RR6M1');
    drawnow;
else
    info = get(gcbf,'Userdata');
    CurrentTextHandles = info.TextHandles; 
    try
        propedit(CurrentTextHandles); 
    catch
        CPmsgbox('A bug in MATLAB is preventing this function from working. Service Request #1-RR6M1');
    end
    drawnow;
end

%%
%%% SUBFUNCTION - DisplayButtonCallback2
function DisplayButtonCallback2(hObject,eventdata)

NumberOfDecimals = inputdlg('Enter the number of decimal places to display','Enter the number of decimal places',1,{'0'});
info = get(gcbf,'Userdata');
CurrentTextHandles = info.TextHandles;
NumberValues = info.ListOfMeasurements; 
if(isempty(NumberOfDecimals)) 
    return; 
end
Command = ['%.',num2str(NumberOfDecimals{1}),'f']; 
NewNumberValues = num2str(NumberValues,Command); 
CellNumberValues = cellstr(NewNumberValues); 
PropName(1) = {'string'}; 
set(CurrentTextHandles,PropName, CellNumberValues); 
drawnow;

%%
%%% SUBFUNCTION - DisplayButtonCallback3
function DisplayButtonCallback3(hObject,eventdata)

info = get(gcbf,'Userdata');
CurrentTextHandles = info.TextHandles; 
ListOfMeasurements = info.ListOfMeasurements; 
StringListOfMeasurements = cellstr(num2str(ListOfMeasurements)); 
PropName(1) = {'string'}; 
set(CurrentTextHandles,PropName, StringListOfMeasurements);
drawnow;
    
%%
%%% SUBFUNCTION - DisplayButtonCallback5
function DisplayButtonCallback4(hObject,eventdata)

info = get(gcbf,'Userdata');
CurrentTextHandles = info.TextHandles; 
if get(hObject,'value'),
    set(CurrentTextHandles, 'visible', 'off'); 
    set(hObject,'string','Show labels');
else
    set(CurrentTextHandles, 'visible', 'on'); 
    set(hObject,'string','Hide labels');
end
drawnow;