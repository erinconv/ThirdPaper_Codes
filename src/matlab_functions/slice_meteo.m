function meteo_grid = slice_meteo(dates, meteo_grid)
    % slice_meteo - Filters meteorological data based on specified date range.
    %
    % Syntax: meteo_grid = slice_meteo(dates, meteo_grid)
    %
    % Inputs:
    %    dates      - A structure containing 'dateDebut' and 'dateFin' fields that define the simulation date range.
    %    meteo_grid - A structure containing meteorological data with fields 't', 'tMin', 'tMax', 'pTot', 
    %                 and optionally thermal model variables like 'rayonnement', 'nebulosite', etc.
    %
    % Outputs:
    %    meteo_grid - The filtered meteorological data structure based on the specified date range.

    % Generate a range of dates for simulation
    dates_sim = dates.dateDebut:dates.dateFin;
    % Filter out the dates not used for simulation
    [~, I, ~] = intersect(meteo_grid.t, dates_sim);
    
    % Slice the time variable to keep only the relevant dates
    meteo_grid.t = meteo_grid.t(I);
    
    % List of variable names to filter from the meteo_grid
    model_var_names = ["pTot", "tMax", "tMin", "pression", ...
                       "rayonnement", "vitesseVent", ...
                       "nebulosite", "surfacePressure", "longwaveRad"];

    % Filter the specified variables if they exist in the meteo_grid
    for var = model_var_names
        if isfield(meteo_grid, var)  % Check if the variable exists in meteo_grid
            meteo_grid.(var) = meteo_grid.(var)(I, :);  % Filter the variable based on the index
        end
    end
end
