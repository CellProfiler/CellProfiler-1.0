function [Basic] = CPobjintensity(OrigImage, LabelMatrixImage)


    %%% Get pixel indexes (fastest way), and count objects
    [sr sc] = size(LabelMatrixImage);
    props = regionprops(LabelMatrixImage,'PixelIdxList','Area');
    ObjectCount = length(props);

    %%% Label-aware boundary finding (even when two objects are adjacent)
    LabelBoundaryImage = CPlabelperim(LabelMatrixImage);

    if ObjectCount > 0
        Basic = cell(ObjectCount,14);

        for Object = 1:ObjectCount
            %%% It's possible for objects not to have any pixels,
            %%% particularly tertiary objects (such as cytoplasm from
            %%% cells the exact same size as their nucleus).
            if isempty(props(Object).PixelIdxList),
                [Basic{Object,:}] = deal(0);
                continue;
            end

            %%% Measure basic set of Intensity features
            Basic{Object,1} = sum(OrigImage(props(Object).PixelIdxList));
            Basic{Object,2} = mean(OrigImage(props(Object).PixelIdxList));
            Basic{Object,3} = std(OrigImage(props(Object).PixelIdxList));
            Basic{Object,4} = min(OrigImage(props(Object).PixelIdxList));
            Basic{Object,5} = max(OrigImage(props(Object).PixelIdxList));

            %%% Kyungnam, 2007-Aug-06: optimized code
            %%% Cut patch so that we don't have to deal with entire image
            [r,c] = ind2sub([sr sc],props(Object).PixelIdxList);
            rmax = min(sr,max(r));
            rmin = max(1,min(r));
            cmax = min(sc,max(c));
            cmin = max(1,min(c));
            BWim = LabelMatrixImage(rmin:rmax,cmin:cmax) == Object;
            Greyim = OrigImage(rmin:rmax,cmin:cmax);
            Boundaryim = LabelBoundaryImage(rmin:rmax,cmin:cmax) == Object;
            perim = Greyim(Boundaryim(:));
            Basic{Object,6}  = sum(perim);
            Basic{Object,7}  = mean(perim);
            Basic{Object,8}  = std(perim);
            Basic{Object,9}  = min(perim);
            Basic{Object,10} = max(perim);

            %%% Kyungnam, 2007-Aug-06: the original old code left commented below
            %%%                        'bwperim' is slow!
            %             %%% Get perimeter in order to calculate edge features
            %             perim = bwperim(BWim);
            %             perim = Greyim(find(perim)); %#ok Ignore MLint
            %             Basic(Object,6)  = sum(perim);
            %             Basic(Object,7)  = mean(perim);
            %             Basic(Object,8)  = std(perim);
            %             Basic(Object,9)  = min(perim);
            %             Basic(Object,10) = max(perim);

        end
        %%% Calculate the Mass displacment (taking the pixelsize into account), which is the distance between
        %%% the center of gravity in the gray level image and the binary
        %%% image.
        mask = (LabelMatrixImage > 0);
        masked_labels = LabelMatrixImage(mask);
        masked_intensity = double(OrigImage(mask));
        [x,y] = meshgrid(1:size(LabelMatrixImage,1),1:size(LabelMatrixImage,2));
        masked_x = x(mask);
        masked_y = y(mask);
        CM_x = full(sparse(masked_labels, 1, masked_x) ./ sparse(masked_labels, 1, 1));
        CM_y = full(sparse(masked_labels, 1, masked_y) ./ sparse(masked_labels, 1, 1));

        denom = sparse(masked_labels, 1, masked_intensity);
        if denom ~= 0
            intensity_CM_x = full(sparse(masked_labels, 1, masked_x .*masked_intensity) ./ denom);
            intensity_CM_y = full(sparse(masked_labels, 1, masked_y .*masked_intensity) ./ denom);
        else
            intensity_CM_x = zeros(size(CM_x));
            intensity_CM_y = zeros(size(CM_y));
        end

        %PixelSize = str2double(handles.Settings.PixelSize);
        PixelSize = 1;
        diff_x = CM_x - intensity_CM_x;
        diff_y = CM_y - intensity_CM_y;
        Basic(:,11) = arrayfun(@(x) {x}, sqrt(diff_x.^2+diff_y.^2).*PixelSize);

        %
        % A trick for median, lower & upper quartile:
        %   Add the object # to an intensity scaled between .1 and .9
        %   Sort the resulting array.
        %   Restore the pixels to scaled intensities w/o object #
        %   Do the cumulative sum of the areas of each object
        %   Subtract 1/4, 1/2 and 3/4 of the area and use that to
        %   index into the sorted array to get the values.
        %
        SortedObjectPixels=OrigImage(LabelMatrixImage>0);
        Min = min(SortedObjectPixels);
        Max = max(SortedObjectPixels);
        Scale = (Max-Min) / .8;
        SortedObjectPixels = ((SortedObjectPixels - Min) / (Scale+eps))+.1;
        SortedObjectPixels = SortedObjectPixels + LabelMatrixImage(LabelMatrixImage>0);
        SortedObjectPixels = sort(SortedObjectPixels);
        SortedObjectPixels = SortedObjectPixels - floor(SortedObjectPixels);
        SortedObjectPixels = (SortedObjectPixels - .1) * Scale + Min;
        Address = cumsum([props.Area]);
        idx = max(1,floor(Address-[props.Area]*3/4));
        Basic(:,12) = arrayfun(@(x) {x}, SortedObjectPixels(idx));
        idx = max(1,floor(Address-[props.Area]/2));
        Basic(:,13) = arrayfun(@(x) {x}, SortedObjectPixels(idx));
        idx = max(1,floor(Address-[props.Area]/4));
        Basic(:,14) = arrayfun(@(x) {x}, SortedObjectPixels(idx));
    else
        % Fill in with empty sets
        Basic = cell(1,14);
    end
end

