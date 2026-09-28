function [zcIdx, signChange] = zeroCrossingIndices(signal)
    signChange = diff(sign(signal));
    zcIdx = find(signChange ~= 0);
end
