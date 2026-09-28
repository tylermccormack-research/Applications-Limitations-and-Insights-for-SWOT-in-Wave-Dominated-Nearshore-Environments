function s = removeBlankFields(s)
% removeBlankFields Remove fields from a struct if they are blank or empty
%
%   s = removeBlankFields(s)
%
% Works for scalar structs. Removes fields that are:
%   - Empty arrays []
%   - Empty strings ''
%   - Empty cell arrays {}
%   - All-NaN arrays

    fn = fieldnames(s);
    for i = 1:numel(fn)
        val = s.(fn{i});
        if isempty(val) || ...
           (ischar(val) && all(isspace(val))) || ...
           (iscell(val) && isempty([val{:}])) || ...
           (isnumeric(val) && all(isnan(val(:))))
            s = rmfield(s, fn{i});
        end
    end
end
