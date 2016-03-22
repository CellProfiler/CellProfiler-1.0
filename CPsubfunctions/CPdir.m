%CPdir List directory.
%   D = CPdir('directory_name') returns the results in an M-by 1
%   structure with the fields:
%       name    -- filename
%       isdir    -- 1 if name is a directory and 0 if not
%
%   This is a subset of the functionality of Matlab's DIR, but
%   should be much faster, as it does not stat the files.

%
% Website: http://www.cellprofiler.org
%

% The following code is there just as a backup, in case the Mex is
% missing.

function result = CPdir(directory)
if nargin == 0
    result = dir();
else
    result = dir(directory);
end
result = rmfield(result, 'date');
result = rmfield(result, 'bytes');
result = rmfield(result, 'datenum');
