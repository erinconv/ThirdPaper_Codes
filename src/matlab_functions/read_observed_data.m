function result_table = read_observed_data(file_path)
    % read_observed_data - Reads observed data from a CSV file and returns a complete data table.
    %
    % Syntax: result_table = read_observed_data(file_path)
    %
    % Inputs:
    %    file_path - A string representing the path to the CSV file containing the data.
    %
    % Outputs:
    %    result_table - A table containing two columns: 'Date' and 'Value'.
    %                   'Date' includes all dates in the range, and 'Value' includes
    %                   corresponding values, with NaN for missing dates.
    %
    % The expected file format is:
    %    Date, Value
    %    1979-01-01, 100
    %    1979-01-02, 101
    %    ...

    % Read the observed data from the file
    Tab = readtable(file_path);
    
    % Check if column names are correct
    if ~ismember('Date', Tab.Properties.VariableNames) || ~ismember('Value', Tab.Properties.VariableNames)
        error('Input file must have columns named "Date" and "Value"');
    end
    
    % Convert date strings to datetime objects
    date_objects = datetime(Tab.Date);
    
    % Create a complete time vector from the first to the last date
    complete_date_range = (date_objects(1):date_objects(end))';
    
    % Initialize result vector with NaN values (no data for missing dates)
    full_data_vector = NaN(size(complete_date_range));
    
    % Fill in the available data
    for i = 1:length(date_objects)
        % Find the index in the complete range
        [~, idx] = ismember(date_objects(i), complete_date_range);
        if idx > 0
            full_data_vector(idx) = Tab.Value(i); % Assign value to the corresponding date
        end
    end
    
    % Convert complete_date_range to datenum format
    date_numbers = datenum(complete_date_range);
    
    % Store dates, values, and date numbers in a table
    result_table = table(complete_date_range, date_numbers, full_data_vector, ...
                         'VariableNames', {'dates', 'datenums', 'values'});
    
end
