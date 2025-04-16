function cps = select_cps(basin_struct, area_th)
    % SELECT_CPS Selects critical points (cps) based on area threshold.
    % 
    % Inputs:
    %   basin_struct - A structure containing partial squares with fields:
    %                   - CPid: Identifier for the critical point.
    %                   - cumulArea: Cumulative area of the partial square.
    %   area_th - A threshold value for area, used to filter critical points.
    %
    % Outputs:
    %   cps - A vector of selected critical point identifiers that exceed the area threshold.

    % If area_th is not provided, set it to 0.5
    if nargin < 2
        area_th = 0.01;
    end

    % Initialize arrays to hold critical point IDs and their corresponding areas
    cps = zeros(size(basin_struct.carreauxPartiels, 2), 1);
    area = zeros(size(basin_struct.carreauxPartiels, 2), 1);
    
    % Loop through each partial square to extract CPid and cumulArea
    for i = 1:size(basin_struct.carreauxPartiels, 2)
        cps(i) = basin_struct.carreauxPartiels(i).CPid; % Store CPid
        area(i) = basin_struct.carreauxPartiels(i).cumulArea; % Store cumulative area
    end
    
    % Select the cps based on the area threshold
    idx_cps = area > area_th * max(area); % Determine which areas exceed the threshold
    cps = cps(idx_cps); % Filter cps based on the index of selected areas
end