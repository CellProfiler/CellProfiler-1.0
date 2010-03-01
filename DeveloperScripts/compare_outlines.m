function compare_outlines

% This script was used to compare outlines for Meghan Shan's project before and after some CP edits.
% We wanted to be sure that the segmentation hadn't changed. (2009-07 DLogan)

% FOLDER1 = '/Volumes/imaging_analysis/2007_11_07_Hepatoxicity_SPARC/4_28_09_InformerIII/test/BR00011210/HepOutlines';
% FOLDER2 = '/Volumes/imaging_analysis/2007_11_07_Hepatoxicity_SPARC/4_28_09_InformerIII/test/BR00011210/HepOutlinesCopiedFromOrigRun';

FOLDER1 = '/Volumes/imaging_analysis/2007_11_07_Hepatoxicity_SPARC/2009_3_20_ValidationScreen/BR00008677/HepOutlines';
FOLDER2 = '/Volumes/imaging_analysis/2007_11_07_Hepatoxicity_SPARC/RadialTest_7_15_09/BR00008677/HepOutlines';


try
    h = waitbar(0,'Please wait...');
    filelist1 = dir(FOLDER1);
    filelist2 = dir(FOLDER2);

    assert(length(filelist1) == length(filelist2))


    for i = 1:length(filelist1)
        file1 = filelist1(i).name;
        file2 = filelist2(i).name;

        if ~isempty(regexp(file1,'.*.png','once'))
            IM1 = imread(fullfile(FOLDER1,file1));
            IM2 = imread(fullfile(FOLDER2,file2));
        else continue
        end

        if ~all(IM1(:) == IM2(:))
            disp(['File ' file1 ' does not equal ' file2])
        else
            disp(['File ' file1 ' equals ' file2])
        end
        waitbar(i/length(filelist1))
    end
catch
    disp('errored somewhere!!')
end
close(h)
disp('done')