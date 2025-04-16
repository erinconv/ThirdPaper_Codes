function fixed_struct = fix_struct(carreux_struct)
    % FIX_STRUCT Restructures the input structure into an array of structs.
    %
    %   fixed_struct = FIX_STRUCT(carreux_struct) takes an input structure
    %   'carreux_struct' and converts it into an array of structs, where each
    %   field corresponds to a table in the input structure. Specifically, it
    %   handles the "idCPsAmont" table differently by converting its rows into
    %   lists.
    %
    % Inputs:
    %   carreux_struct - A structure containing multiple tables (fields).
    %
    % Outputs:
    %   fixed_struct - An array of structures with the same fields as the input,
    %                  but with rows converted to lists for "idCPsAmont".
    
    % Get the field names (table names) from the input structure
    table_names = fieldnames(carreux_struct);
    
    % Determine the number of rows in the first table
    [~, n] = size(carreux_struct.(table_names{1}));
    
    % Initialize a zero struct array for the output
    for i = 1:size(table_names, 1)
        % Check if the current table is "idCPsAmont"
        if strcmp(table_names{i}, "idCPsAmont")
            % Loop through each row of the "idCPsAmont" table
            for j = 1:n
                % Get the array's column as a list
                list_array = carreux_struct.(table_names{i})(j, :);
                % Assign the list to the corresponding field in the output struct
                fixed_struct(j).(table_names{i}) = list_array;
            end
        else
            % Loop through each row of other tables
            for j = 1:n
                % Assign the value to the corresponding field in the output struct
                fixed_struct(j).(table_names{i}) = carreux_struct.(table_names{i})(j);
            end
        end
    end
    % End of function
end 