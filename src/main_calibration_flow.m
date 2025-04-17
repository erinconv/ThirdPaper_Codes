function main_calibration_flow(physiographic_results_path, flow_file_path, params_name, execution_dates, prefixName, CP, thermie)

    if nargin < 6
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

    % Objective function
    % objective_function_names = {'RMSE', 'NSE', 'LogNSE', 'KGE'}
    % Configuring the calibration environment for CMA-ES
    [defopts, sigma, x0] = get_opts_CMAES(prefixName, 1, params_struct);
    
    % Read the observed flow file
    observed_flow = read_observed_data(flow_file_path);
    
    % Split prefix string into prefixName and objective function name
    objective = set_objective_function(prefixName);

    

    % Call the objective function
    [xmin, fmin, counteval, stopflag, out, bestever] = ... 
    cmaes('objective_function', x0, sigma, defopts, ... 
        execution_dates, params_struct, basin_struct, meteo_grid, objective,observed_flow,CP);
    writematrix(bestever.x,append(prefixName,'_parameters.csv'),'Delimiter',',')
end

function objective = set_objective_function(prefixName)
    % Split prefix string into prefixName and objective function name
    % Select the objective function based on the prefix input name
    objective_name = split(prefixName, '/');
    objective_name = objective_name{end};

    if strcmp(objective_name, 'KGE')
        objective = 1;
    elseif strcmp(objective_name, 'NSE')
        objective = 2;
    elseif strcmp(objective_name, 'LogNSE')
        objective = 3;
    elseif strcmp(objective_name, 'RMSE')
        objective = 4;
    else
        error('Unknown objective function: %s', objective_name);
    end
end


