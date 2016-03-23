function Directories = CPgetdirectorytree(RootDirectory)
% Return a cell array of all directories under the root.
% RootDirectory is a single string.

%
% Website: http://www.cellprofiler.org
%

Listing = sort(CPgetdirectories(RootDirectory));
% Delete any hidden directories (and "." and "..")
Listing(strncmp(Listing,'.',1)) = [];
Directories = [{RootDirectory}];
for i=1:length(Listing)
    SubDirectory = fullfile(RootDirectory,Listing{i});
    SubListing = CPgetdirectorytree(SubDirectory);
    Directories = [Directories;SubListing];
end