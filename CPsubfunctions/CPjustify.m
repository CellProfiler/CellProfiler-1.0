function out = CPjustify(im)
    if min(im(:)) == max(im(:))
        out = zeros(size(im));
    else
        out = im - min(im(:));
        out = out / max(out(:));
    end