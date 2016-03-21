function m = CPnanmean(x)
%CPNANMEAN Mean value, ignoring NaNs.
%   M = CPNANMEAN(X) returns the sample mean of X, treating NaNs as
%   missing values.  For vector input, M is the mean value of the non-NaN
%   elements in X.  For matrix input, M is a row vector containing the
%   mean value of non-NaN elements in each column.
%
%   This function will need rewriting if it needs to take means
%   along any dimension other than the first.  Also, it only accepts
%   vectors and 2D matrices at this time.

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



assert(length(size(x)) <= 2, 'CPnanmean can only operate on vectors and 2D matrices.');

if isempty(x(:))
    m = NaN;
elseif ~any(isnan(x(:)))
    m = mean(x);
elseif all(isnan(x(:)))
    m = NaN;
else
    % If it's a row vector, just return the mean of that vector
    if size(x, 1) == 1
        m = mean(x(~isnan(x)));
    else
        % 2D matrix

        % preallocate
        m = zeros(1, size(x, 2));

        % work by columns
        for i = 1:size(x, 2)
            col = x(:, i);
            m(i) = mean(col(~isnan(col)));
        end
    end
end
