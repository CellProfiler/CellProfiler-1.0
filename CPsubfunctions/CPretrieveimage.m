function Image = CPretrieveimage(handles,ImageName,ModuleName,ColorFlag,ScaleFlag,SizeFlag)

%
% Website: http://www.cellprofiler.org
%

%%% Fills in missing arguments, if necessary.
if nargin == 5
%%% CPretrieveimage(handles,ImageName,ModuleName,ColorFlag,ScaleFlag)
    SizeFlag = 0;
elseif nargin == 3
%%% CPretrieveimage(handles,ImageName,ModuleName)
    ColorFlag = 0;
    ScaleFlag = 0;
    SizeFlag = 0;
end

if ischar(ColorFlag)
    if strcmpi(ColorFlag, 'MustBeBinary')
        ColorFlag = 4;
    elseif strcmpi(ColorFlag,'MustBeColor')
        ColorFlag = 3;
    elseif strcmpi(ColorFlag,'MustBeGray')
        ColorFlag = 2;
    elseif strcmpi(ColorFlag,'DontCheckColor')
        ColorFlag = 0;
    else
        error('The value you have chosen for the colorflag is invalid.');
    end
end

if ischar(ScaleFlag)
    if strcmpi(ScaleFlag,'CheckScale')
        ScaleFlag = 1;
    elseif strcmpi(ScaleFlag,'DontCheckScale')
        ScaleFlag = 0;
    else
        error('The value you have chosen for the scaleflag is invalid.');
    end
end

%%% Checks whether the image to be analyzed exists in the handles
%%% structure.
if ~CPisimageinpipeline(handles, ImageName) %~isfield(handles.Pipeline, ImageName)
    %%% If the image is not there, an error message is produced.  The error
    %%% is not displayed: The error function halts the current function and
    %%% returns control to the calling function (the analyze all images
    %%% button callback.)  That callback recognizes that an error was
    %%% produced because of its try/catch loop and breaks out of the image
    %%% analysis loop without attempting further modules.
    error(['Image processing was canceled in the ', ModuleName, ' module because CellProfiler could not find the input image. CellProfiler expected to find an image named "', ImageName, '", but that image has not been created by the pipeline. Please adjust your pipeline to produce the image "', ImageName, '" prior to this ', ModuleName, ' module.'])
end
%%% Reads the image.
if ~isfield(handles.Pipeline,'ImageGroupFields')
    % If no image groups, retrieve from the handles.Pipeline structure
    Image = handles.Pipeline.(ImageName);
else
    % If no image groups, retrieve from the appropriate
    % handles.Pipeline.GroupFileList structure
    Image = handles.Pipeline.GroupFileList{handles.Pipeline.CurrentImageGroupID}.(ImageName);
end


% Here it would be possible to convert images from single
% back to double precision (reduce RAM storage space):
%if isa(Image,'single')
%    Image = double(Image);
%end


if ScaleFlag == 1
    if (min(Image(:)) < 0 || max(Image(:)) > 1)
        CPwarndlg(['The image loaded in the ', ModuleName, ' module is outside the 0-1 range, and you may be losing data.'],'Outside 0-1 Range','replace');
    end
end

if ColorFlag == 2
    if ndims(Image) ~= 2
        error(['Image processing was canceled in the ', ModuleName, ' module because it requires an input image that is two-dimensional (i.e. X vs Y), but the image loaded does not fit this requirement. This may be because the image is a color image.']);
    end
elseif ColorFlag == 3
    if ndims(Image) ~= 3
        error(['Image processing was canceled in the ', ModuleName, ' module because it requires an input image that is color, but the image loaded does not fit this requirement. This may be because the image is grayscale.']);
    end
elseif ColorFlag ==4
      fieldname = ['Pathname', ImageName];
      % Preferentially load from file unless the image was generated
      if isfield(handles.Pipeline,fieldname)
          Pathname = handles.Pipeline.(fieldname);

          % Retrieves the list of filenames where the images are stored from the
          % handles structure.
          fieldname = ['FileList', ImageName];
          FileList = handles.Pipeline.(fieldname);
          idx = handles.Current.SetBeingAnalyzed;
          try
              Image = imread(fullfile(Pathname,char(FileList(idx))));
          end
      end
    if islogical(Image)==0
           error(['Image processing was canceled in the ', ModuleName, ' module because it requires an input image that is binary, but the image loaded does not fit this requirement. This may be because the image is grayscale.']);

    end
end


if SizeFlag ~= 0
    %%% The try is necessary because if either image does not have the
    %%% proper number of dimensions, things will fail otherwise. If one of
    %%% the images (the SizeFlag or the Image itself) is 3-D (color), then
    %%% only the X Y dimensions are checked for size.
    try if any(SizeFlag(1:2) ~= size(Image(:,:,1)))
            error(['Image processing was canceled in the ', ModuleName, ' module. The incoming images are not all of equal size.']);
        end
    catch
        error(['Image processing was canceled in the ', ModuleName, ' module. The incoming images are not all of equal size.']);
    end
end
