function matchLogical = matchStructDates_short(structA, structB)
% matchStructDates Compare two data structures by dates in their field names
%
% matchLogical = matchStructDates(structA, structB)
%
% INPUTS:
%   structA - first data structure with fields formatted as:
%             'L2_LR_SSH_Expert001_354_20230802'
%   structB - second data structure with same format
%
% OUTPUT:
%   matchLogical - logical vector with length equal to the structure
%                  containing fewer fields. TRUE where a date match exists,
%                  FALSE otherwise.

    % --- Get field names
    fieldsA = fieldnames(structA);
    fieldsB = fieldnames(structB);

    % --- Determine which structure has fewer fields
    if numel(fieldsA) <= numel(fieldsB)
        primaryFields = fieldsA;
        secondaryFields = fieldsB;
    else
        primaryFields = fieldsB;
        secondaryFields = fieldsA;
    end

    % --- Extract dates from field names
    primaryDates = extractDateFromFields(primaryFields);
    secondaryDates = extractDateFromFields(secondaryFields);

    % --- Preallocate logical array (shorter length)
    matchLogical = false(numel(primaryFields), 1);

    % --- Compare dates
    for i = 1:numel(primaryDates)
        matchLogical(i) = any(strcmp(primaryDates{i}, secondaryDates));
    end
end

% Helper function to extract date (last 8 digits) from each field name
function dates = extractDateFromFields(fieldList)
    dates = cell(size(fieldList));
    for i = 1:numel(fieldList)
        % Match last 8 digits at end of string
        tokens = regexp(fieldList{i}, '(\d{8})$', 'tokens');
        if ~isempty(tokens)
            dates{i} = tokens{1}{1};
        else
            dates{i} = '';
        end
    end
end
