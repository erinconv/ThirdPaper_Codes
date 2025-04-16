function output_array = main_simulation(physiographic_results_path, params_name, execution_dates, output_vars, thermie)
    % MAIN_SIMULATION Executes the main simulation process for hydrological modeling.
    % 
    % Inputs:
    %   physiographic_results_path - Path to the directory containing physiographic results.
    %   params_name - Name of the parameters file (JSON).
    %   execution_dates - Dates for which the simulation is executed.
    %   thermie - Optional; flag to calculate quality (default is 0).
    %   output_vars - Optional; cell array of variable names to output (default is all variables).
    %
    % This function reads the necessary JSON files, meteorological data, and slices the data
    % according to the specified execution dates.

    if nargin < 5
        thermie = 0; % Default value for thermie if not provided
    end
    
    addpath(genpath('libs')) % Add libraries to the MATLAB path
    
    % Read the JSON files that contain the basin structure and parameters
    [params_struct, basin_struct] = read_jsons(physiographic_results_path, params_name, 0);
    
    % Set the quality calculation option based on the thermie flag
    params_struct.option.calculQualite = thermie;

    % Read the meteorological data from the specified file
    meteo_file = fullfile(physiographic_results_path, 'meteo', 'meteo_ERA_snow.nc');
    meteo_grid = read_meteo(meteo_file);
    
    % Slice the meteorological data according to the specified execution dates
    meteo_grid = slice_meteo(execution_dates, meteo_grid);

    % Perform CEQUEAU model simulations
    [y.etatsCE, y.etatsCP, y.etatsFonte, y.etatsEvapo, y.etatsBarrage, y.pasDeTemps,...
    y.avantAssimilationsCE, y.avantAssimilationsFonte, y.avantAssimilationsEvapo,y.etatsQualCP, y.avAssimQual] = ...
    cequeauQuantiteMex(execution_dates, params_struct, basin_struct, meteo_grid, [], [], [], []);

    % Extract the results from the CEQUEAU simulations
    resu = extract_results(y, thermie, params_struct.option.moduleFonte);
    
    % Select the CPs that have enough cumulated area based on the area threshold
    selected_cps = select_cps(basin_struct);
    % selected_cps = selected_cps';
    % Add the time vector to the results
    resu.t = meteo_grid.t';

    % Add the CPs to the results
    resu.CP.CPs = int16(linspace(1,size(resu.CP.debit,2),size(resu.CP.debit,2)));

    % List the variable names in the resu struct
    variable_names = fieldnames(resu.CP);
    
    % Filter the output variables based on user input
    if nargin < 4 || isempty(output_vars)
        output_vars = variable_names; % Default to all variables if none specified
    end
    
    % Create a multidimensional array to store each variable
    output_array = zeros(length(output_vars), length(resu.t), length(selected_cps));
    
    % Fill the output array with the corresponding variables
    for i = 1:length(output_vars)
        if ismember(output_vars{i}, variable_names)
            output_array(i, :, :) = resu.CP.(output_vars{i})(:,selected_cps);
        else
            warning(['Variable ' output_vars{i} ' is not available in the results.']);
        end
    end

end

