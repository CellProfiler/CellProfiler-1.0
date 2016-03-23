function ispresent = CPisimageinpipeline(handles, fieldname)
% Check if images exist in handles.Pipeline structure.

%
% Website: http://www.cellprofiler.org
%

if ~isfield(handles.Pipeline,'ImageGroupFields')
    ispresent = isfield(handles.Pipeline,fieldname);
else
    ispresent = isfield(handles.Pipeline.GroupFileList{handles.Pipeline.CurrentImageGroupID},fieldname);
end
