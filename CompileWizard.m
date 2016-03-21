function CompileWizard
% CompileWizard
% This function, when run in the default CellProfiler path, will produce a
% file with help information stored in variables to be used in the compiled
% version of CellProfiler.  It should be called from BuildCellProfiler.m,
% which manages file handling and the Matlab path.
% $Revision$



% 2007-07-30 Ray: Someday, the code below should be rewritten.  In the
% meantime, I want this function to automatically do all the work
% necessary for building the updated CellProfiler.m.  So, for now, I'm
% going to change what 'fid' is multiple time to create some temporary
% files, then use those to rewrite CellProfiler.m
% changes are marked by "%%% AUTOMATIC EDITING CHANGES"


addpath Modules CPsubfunctions DataTools ImageTools Help

%% Current SVN version number
%% Note that the working directory must be the CP root, since
%% BuildCellProfiler, which calls this function, requires it
svngit_ver_char = CPversionnumber(pwd);

%%% AUTOMATIC EDITING CHANGES
% First, the help text.
assert(~ exist('CompileWizardText_help.m','file'), 'CompileWizardText_help.m should not exist.');
fid = fopen('CompileWizardText_help.m','wt');

%% Piggyback the SVN version number code onto CompileWizardText_help
fprintf(fid,['handles.Current.svn_version_number = ''' svngit_ver_char ''';\n']);

ImageToolfilelist = dir('ImageTools/*.m');
fprintf(fid,'%%%%%% IMAGE TOOL HELP\n');
fprintf(fid,'ToolHelpInfo = ''Help information for individual image tools:'';\n\n');
for i=1:length(ImageToolfilelist)
    ToolName = ImageToolfilelist(i).name;
    fprintf(fid,[ToolName(1:end-2),'Help = sprintf([...\n']);
    body = char(strread(help(ImageToolfilelist(i).name),'%s','delimiter','','whitespace',''));
    for j = 1:size(body,1)
        fixedtext = fixthistext(body(j,:));
        newtext = ['''',fixedtext,'\\n''...\n'];
        fprintf(fid,newtext);
    end
    fprintf(fid,']);\n\n');
    fprintf(fid,['ToolHelp{',num2str(i),'} = [ToolHelpInfo, ''-----------'' 10 ',[ToolName(1:end-2),'Help'],'];\n\n']);
    if exist('ToolList','var')
        ToolList = [ToolList, ' ''',ToolName(1:end-2),''''];
    else
        ToolList = ['''',ToolName(1:end-2),''''];
    end
    if exist('ToolListNoQuotes','var')
        ToolListNoQuotes = [ToolListNoQuotes,' ',ToolName(1:end-2)];
    else
        ToolListNoQuotes = ToolName(1:end-2);
    end
end
fprintf(fid,['handles.Current.ImageToolsFilenames = {''Image tools'' ',ToolList,'};\n']);
fprintf(fid,'handles.Current.ImageToolHelp = ToolHelp;\n\n');

clear ToolList

DataToolfilelist = dir('DataTools/*.m');
fprintf(fid,'%%%%%% DATA TOOL HELP\n');
fprintf(fid,'ToolHelpInfo = ''Help information for individual data tools:'';\n\n');
for i=1:length(DataToolfilelist)
    ToolName = DataToolfilelist(i).name;
    fprintf(fid,[ToolName(1:end-2),'Help = sprintf([...\n']);
    body = char(strread(help(DataToolfilelist(i).name),'%s','delimiter','','whitespace',''));
    for j = 1:size(body,1)
        fixedtext = fixthistext(body(j,:));
        newtext = ['''',fixedtext,'\\n''...\n'];
        fprintf(fid,newtext);
    end
    fprintf(fid,']);\n\n');
    fprintf(fid,['ToolHelp{',num2str(i),'} = [ToolHelpInfo, ''-----------'' 10 ',[ToolName(1:end-2),'Help'],'];\n\n']);
    if exist('ToolList','var')
        ToolList = [ToolList, ' ''',ToolName(1:end-2),''''];
    else
        ToolList = ['''',ToolName(1:end-2),''''];
    end
    if exist('ToolListNoQuotes','var')
        ToolListNoQuotes = [ToolListNoQuotes,' ',ToolName(1:end-2)];
    else
        ToolListNoQuotes = ToolName(1:end-2);
    end
end
fprintf(fid,['handles.Current.DataToolsFilenames = {''Data tools'' ',ToolList,'};\n']);
fprintf(fid,'handles.Current.DataToolHelp = ToolHelp;\n\n');

clear ToolList

Modulesfilelist = dir('Modules/*.m');
fprintf(fid,'%%%%%% MODULES HELP\n');
for i=1:length(Modulesfilelist)
    ToolName = Modulesfilelist(i).name;
    fprintf(fid,[ToolName(1:end-2),'Help = sprintf([...\n']);
    body = char(strread(help(Modulesfilelist(i).name),'%s','delimiter','','whitespace',''));
    for j = 1:size(body,1)
        fixedtext = fixthistext(body(j,:));
        newtext = ['''',fixedtext,'\\n''...\n'];
        fprintf(fid,newtext);
    end
    fprintf(fid,']);\n\n');
    fprintf(fid,['ToolHelp{',num2str(i),'} = ',ToolName(1:end-2),'Help;\n\n']);
    if exist('ToolList','var')
        ToolList = [ToolList, ' ''',ToolName(1:end-2),''''];
    else
        ToolList = ['''',ToolName(1:end-2),''''];
    end
    if exist('ToolListNoQuotes','var')
        ToolListNoQuotes = [ToolListNoQuotes,' ',ToolName(1:end-2)];
    else
        ToolListNoQuotes = ToolName(1:end-2);
    end
end
fprintf(fid,['handles.Current.ModulesFilenames = {''Modules'' ',ToolList,'};\n']);
fprintf(fid,'handles.Current.ModulesHelp = ToolHelp;\n\n');

clear ToolList

Helpfilelist = dir('Help/*.m');
fprintf(fid,'%%%%%% HELP\n');
ToolCount=1;
GSToolCount=1;
for i=1:length(Helpfilelist)
    ToolName = Helpfilelist(i).name;
    if strncmp(ToolName,'GS',2)
        fprintf(fid,['GSToolHelp{',num2str(GSToolCount),'} = sprintf([...\n']);
        GSToolCount=GSToolCount+1;
        body = char(strread(help(Helpfilelist(i).name),'%s','delimiter','','whitespace',''));
        for j = 1:size(body,1)
            fixedtext = strrep(body(j,:),'''','''''');
            fixedtext = strrep(fixedtext,'\','\\\\');
            fixedtext = strrep(fixedtext,'%','%%%%');
            newtext = ['''',fixedtext,'\\n''...\n'];
            fprintf(fid,newtext);
        end
        fprintf(fid,']);\n\n');
        if exist('GSToolList','var')
            GSToolList = [GSToolList, ' ''',ToolName(1:end-2),''''];
        else
            GSToolList = ['''',ToolName(1:end-2),''''];
        end
    else
        fprintf(fid,['ToolHelp{',num2str(ToolCount),'} = sprintf([...\n']);
        ToolCount=ToolCount+1;
        body = char(strread(help(Helpfilelist(i).name),'%s','delimiter','','whitespace',''));
        for j = 1:size(body,1)
            fixedtext = strrep(body(j,:),'''','''''');
            fixedtext = strrep(fixedtext,'\','\\\\');
            fixedtext = strrep(fixedtext,'%','%%%%');
            newtext = ['''',fixedtext,'\\n''...\n'];
            fprintf(fid,newtext);
        end
        fprintf(fid,']);\n\n');
        if exist('ToolList','var')
            ToolList = [ToolList, ' ''',ToolName(1:end-2),''''];
        else
            ToolList = ['''',ToolName(1:end-2),''''];
        end
    end
end
fprintf(fid,['handles.Current.HelpFilenames = {''Help'' ',ToolList,'};\n']);
fprintf(fid,'handles.Current.Help = ToolHelp;\n\n');

fprintf(fid,['handles.Current.GSFilenames = {''Help'' ',GSToolList,'};\n']);
fprintf(fid,'handles.Current.GS = GSToolHelp;\n\n');

clear ToolList



%%% AUTOMATIC EDITING CHANGES
fclose(fid);

%%% AUTOMATIC EDITING CHANGES
% Next, the listbox code.
assert(~ exist('CompileWizardText_listbox.m','file'), 'CompileWizardText_listbox.m should not exist.');
fid = fopen('CompileWizardText_listbox.m','wt');

Modulefilelist = dir('Modules/*.m');
fprintf(fid,'%%%%%% load_listbox code (replace function in CellProfiler.m)\n\n');
FileProcessingFiles ={};
PreProcessingFiles={};
ObjectProcessingFiles={};
MeasurementFiles={};
OtherFiles={};
for i=1:length(Modulefilelist)
    name=Modulefilelist(i).name;
    name=name(1:end-2);
    if file_in_category(Modulefilelist(i).name, 'File Processing')
        FileProcessingFiles(length(FileProcessingFiles)+1)=cellstr(name);
    elseif file_in_category(Modulefilelist(i).name, 'Image Processing')
        PreProcessingFiles(length(PreProcessingFiles)+1)=cellstr(name);
    elseif file_in_category(Modulefilelist(i).name, 'Object Processing')
        ObjectProcessingFiles(length(ObjectProcessingFiles)+1)=cellstr(name);
    elseif file_in_category(Modulefilelist(i).name, 'Measurement')
        MeasurementFiles(length(MeasurementFiles)+1)=cellstr(name);
    else
        OtherFiles(length(OtherFiles)+1)=cellstr(name);
    end

    %%% CODE TO WRITE TEXT FILES OF MODULES
    fid2=fopen(fullfile(pwd,'Modules',Modulefilelist(i).name));
    fid3=fopen(fullfile(pwd,'Modules',[name,'.txt']),'wt');
    while 1;
        output = fgetl(fid2); if ~ischar(output); break; end;
        if strncmp(output,'%defaultVAR',11)
            fprintf(fid3,[fixthistext2(output),'\n']);
        elseif strncmp(output,'%choiceVAR',10)
            fprintf(fid3,[fixthistext2(output),'\n']);
        elseif strncmp(output,'%textVAR',8)
            fprintf(fid3,[fixthistext2(output),'\n']);
        elseif strncmp(output,'%pathnametextVAR',16)
            fprintf(fid3,[fixthistext2(output),'\n']);
        elseif strncmp(output,'%filenametextVAR',16)
            fprintf(fid3,[fixthistext2(output),'\n']);
        elseif strncmp(output,'%infotypeVAR',12)
            fprintf(fid3,[fixthistext2(output),'\n']);
        elseif strncmp(output,'%inputtypeVAR',13)
            fprintf(fid3,[fixthistext2(output),'\n']);
        elseif strncmp(output,'%%%VariableRevisionNumber',25)
            fprintf(fid3,[fixthistext2(output),'\n']);
        end
    end
    fclose(fid2);
    fclose(fid3);
    %%% END CODE TO WRITE TEXT FILES OF MODULES
end
fprintf(fid,'CategoryList = {''File Processing'' ''Image Processing'' ''Object Processing'' ''Measurement'' ''Other''};\n');

fprintf(fid,'FileProcessingFiles = {');
for i=1:length(FileProcessingFiles)
    fprintf(fid,['''',FileProcessingFiles{i},''' ']);
end
fprintf(fid,'};\n');

fprintf(fid,'PreProcessingFiles = {');
for i=1:length(PreProcessingFiles)
    fprintf(fid,['''',PreProcessingFiles{i},''' ']);
end
fprintf(fid,'};\n');

fprintf(fid,'ObjectProcessingFiles = {');
for i=1:length(ObjectProcessingFiles)
    fprintf(fid,['''',ObjectProcessingFiles{i},''' ']);
end
fprintf(fid,'};\n');

fprintf(fid,'MeasurementFiles = {');
for i=1:length(MeasurementFiles)
    fprintf(fid,['''',MeasurementFiles{i},''' ']);
end
fprintf(fid,'};\n');

fprintf(fid,'OtherFiles = {');
for i=1:length(OtherFiles)
    fprintf(fid,['''',OtherFiles{i},''' ']);
end
fprintf(fid,'};\n');

fprintf(fid,'set(AddModuleWindowHandles.ModuleCategoryListBox,''String'',CategoryList,''Value'',[])\n');
fprintf(fid,'set(AddModuleWindowHandles.ModulesListBox,''String'',FileProcessingFiles,''Value'',[])\n');
fprintf(fid,'AddModuleWindowHandles.ModuleStrings{1} = FileProcessingFiles;\n');
fprintf(fid,'AddModuleWindowHandles.ModuleStrings{2} = PreProcessingFiles;\n');
fprintf(fid,'AddModuleWindowHandles.ModuleStrings{3} = ObjectProcessingFiles;\n');
fprintf(fid,'AddModuleWindowHandles.ModuleStrings{4} = MeasurementFiles;\n');
fprintf(fid,'AddModuleWindowHandles.ModuleStrings{5} = OtherFiles;\n');
fprintf(fid,'guidata(AddModuleWindowHandles.AddModuleWindow,AddModuleWindowHandles);\n\n');

%%% AUTOMATIC EDITING CHANGES
fclose(fid);

CPsubfunctionfilelist = dir('CPsubfunctions/*.m');
for i=1:length(CPsubfunctionfilelist)
    ToolName = CPsubfunctionfilelist(i).name;
    if exist('ToolListNoQuotes','var')
        ToolListNoQuotes = [ToolListNoQuotes,' ',ToolName(1:end-2)];
    else
        ToolListNoQuotes = ToolName(1:end-2);
    end
end


%%% AUTOMATIC EDITING CHANGES
% Finally, the "%%#function" code.
assert(~ exist('CompileWizardText_function.m','file'), 'CompileWizardText_function.m should not exist.');
fid = fopen('CompileWizardText_function.m','wt');

fprintf(fid,'%%%%%% FUNCTIONS TO ADD (place before first line of code in CellProfiler.m)\n');
fprintf(fid,['%%#function ',ToolListNoQuotes, '\n']);

fclose(fid);



%%% AUTOMATIC EDITING CHANGES
%%% Now we do the automatic edits and remove the temporary files.

% read the current CellProfiler.m into memory
fid = fopen('CellProfiler.m', 'r');
CPcode = fread(fid, inf, '*char')';
fclose(fid);

% read the modules line into memory
fid = fopen('CompileWizardText_function.m', 'r');
Functioncode = fread(fid, inf, '*char')';
fclose(fid);

% read the help text into memory
fid = fopen('CompileWizardText_help.m', 'r');
Helpcode = fread(fid, inf, '*char')';
fclose(fid);

% read the load_listbox into memory
fid = fopen('CompileWizardText_listbox.m', 'r');
Listboxcode = fread(fid, inf, '*char')';
fclose(fid);

%%% Now do the search and replaces
function_idx = strfind(CPcode, '%%% Compiler: INSERT FUNCTIONS HERE');
assert(length(function_idx) == 1, 'Could not find place to put %%#functions line.');
CPcode = [CPcode(1:function_idx-1) Functioncode CPcode(function_idx:end)];

help_startidx = strfind(CPcode, '%%% Compiler: BEGIN HELP');
help_endidx = strfind(CPcode, '%%% Compiler: END HELP');
assert(length(help_startidx) == 1, 'Could not find start of Help section.');
assert(length(help_endidx) == 1, 'Could not find end of Help section.');
CPcode = [CPcode(1:help_startidx-1) Helpcode CPcode(help_endidx:end)];

listbox_startidx = strfind(CPcode, '%%% Compiler: BEGIN load_listbox');
listbox_endidx = strfind(CPcode, '%%% Compiler: END load_listbox');
assert(length(listbox_startidx) == 1, 'Could not find start of load_listbox function.');
assert(length(listbox_endidx) == 1, 'Could not find end of load_listbox function.');
CPcode = [CPcode(1:listbox_startidx-1) Listboxcode CPcode(listbox_endidx:end)];

% write out the result
fid = fopen('CompileWizard_CellProfiler.m', 'w');
fprintf(fid, '%s', CPcode);
fclose(fid);

% remove the temporary files
delete('CompileWizardText_function.m');
delete('CompileWizardText_help.m');
delete('CompileWizardText_listbox.m');



%%%%%%%%%%%%%%%%%%%%
%%% SUBFUNCTIONS %%%
%%%%%%%%%%%%%%%%%%%%

function fixedtext = fixthistext(text)

fixedtext = strrep(text,'''','''''''''');
fixedtext = strrep(fixedtext,'\','\\\\');
fixedtext = strrep(fixedtext,'%','%%%%');

function c = file_in_category(filename, category)
h = help(filename);
c = strfind(h, ['Category: ' category]);

function fixedtext = fixthistext2(text)

fixedtext = strrep(text,'''','''''');
fixedtext = strrep(fixedtext,'\','\\');
fixedtext = strrep(fixedtext,'%','%%');
