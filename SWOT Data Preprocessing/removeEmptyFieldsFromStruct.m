function dataStruct = removeEmptyFieldsFromStruct(dataStruct)

fn = fieldnames(dataStruct);

for i = 1:numel(fn)
    sub = dataStruct.(fn{i});        % the 1x1 struct with 17 fields
    subfn = fieldnames(sub);         % the 17 fields inside

    % Get all values of the subfields
    vals = struct2cell(sub);

    % Check if ALL subfield values are empty
    if all(cellfun(@isempty, vals))
        dataStruct = rmfield(dataStruct, fn{i});
    end
end

end

