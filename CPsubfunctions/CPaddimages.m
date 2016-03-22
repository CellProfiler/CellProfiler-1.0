function handles = CPaddimages(handles, varargin)
% Add images to the handles.Pipeline structure.
% Location will be "handles.Pipeline.ImageName".

%
% Website: http://www.cellprofiler.org
%

% Parse out varargin. The added data can be numeric, logical or a structure
% (e.g, movie)
if mod(length(varargin),2) ~= 0 || ...
   ~all(cellfun(@ischar,varargin(1:2:end)) & ...
   (cellfun(@isnumeric,varargin(2:2:end)) | cellfun(@islogical,varargin(2:2:end)) | cellfun(@isstruct,varargin(2:2:end))))
    error('The argument list must be of the form: ''ImageName1'', ImageData1, etc');
else
    ImageName = varargin(1:2:end);
    ImageData = varargin(2:2:end);
end

CPvalidfieldname(ImageName);

% Checks have passed, add the data
if ~isfield(handles.Pipeline,'ImageGroupFields')
    % If no image groups, add to the handles.Pipeline structure
    for i = 1:length(ImageName)
        % Here it would be possible to convert images to single
        % precision to reduce RAM storage space:
        %if isa(ImageData{i},'double')
        %    handles.Pipeline.(ImageName{i}) = single(ImageData{i});
        %else
            handles.Pipeline.(ImageName{i}) = ImageData{i};
        %end
    end
else
    % If no image groups, add to the appropriate
    % handles.Pipeline.GroupFileList structure
    for i = 1:length(ImageName)
        % Here it would be possible to convert images to single
        % precision to reduce RAM storage space:
        %if isa(ImageData{i},'double')
        %    handles.Pipeline.GroupFileList{handles.Pipeline.CurrentImageGroupID}.(ImageName{i}) = single(ImageData{i});
        %else
            handles.Pipeline.GroupFileList{handles.Pipeline.CurrentImageGroupID}.(ImageName{i}) = ImageData{i};
        %end
    end
end
