function resu = filter_selected_cps(resu,selected_cps)
    % filter_selected_cps - Filters the selected partial squares from the input structure.
    %
    % Syntax: resu = filter_selected_cps(resu, selected_cps)
    %
    % Inputs:
    %   resu       - A structure containing a field 'CP' which holds partial squares.
    %   selected_cps - A vector of indices indicating which partial squares to keep.
    %
    % Outputs:
    %   resu       - The modified structure with filtered partial squares in 'CP'.
    %
    % Description:
    % This function iterates through the field names of the 'CP' structure within
    % the input 'resu'. It filters the partial squares based on the indices provided
    % in 'selected_cps'. If the field name is 'CPs', it filters the array directly;
    % otherwise, it filters the 2D array by columns.

    f_names = fieldnames(resu.CP); % Get the field names of the CP structure
    for i=1:size(f_names,1) % Iterate through each field name
        if strcmp(f_names{i},"CPs") % Check if the field is 'CPs'
            resu.CP.(f_names{i}) = resu.CP.(f_names{i})(selected_cps); % Filter the array
        else
            resu.CP.(f_names{i}) = resu.CP.(f_names{i})(:,selected_cps); % Filter the 2D array by columns
        end
    end
end

