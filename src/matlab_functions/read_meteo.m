function grid = read_meteo(meteo)
    % This function reads meteorological data from a NetCDF file
    % and stores it in a structured format for further analysis.
    %
    % Input:
    %   meteo - A string representing the path to the NetCDF file
    %
    % Output:
    %   grid - A structure containing the meteorological data with fields
    %          corresponding to the variables defined in the CEQUEAU grid format.
    %          The fields include:
    %          - pTot: Total precipitation
    %          - tMax: Maximum temperature
    %          - tMin: Minimum temperature
    %          - pression: Atmospheric pressure
    %          - rayonnement: Radiation
    %          - vitesseVent: Wind speed
    %          - nebulosite: Cloudiness
    %          - surfacePressure: Surface pressure
    %          - longwaveRad: Longwave radiation
    %          - t: Time step

    % List of variable names corresponding to the CEQUEAU grid format
    var_names = ["pTot", "tMax", "tMin", "pression", ...
                 "rayonnement", "vitesseVent", ...
                 "nebulosite", "surfacePressure", "longwaveRad"];
    
    % Open the NetCDF file
    ncID = netcdf.open(meteo);
    
    % Create the meteogrid structure for CEQUEAU
    grid = struct();
    for i = 1:length(var_names)
        grid.(var_names(i)) = [];  % Initialize each field to an empty array
    end

    % Loop through each variable name to read data
    for idx = 1:length(var_names)
        % Attempt to get the variable ID for the current variable name
        try
            varID = netcdf.inqVarID(ncID, var_names(idx));
            % Read the variable data and transpose it
            varData = netcdf.getVar(ncID, varID);
            grid.(var_names(idx)) = varData';
        catch
            % Print a warning message if the variable does not exist
            fprintf('Warning: Variable "%s" does not exist in the NetCDF file.\n', var_names(idx));
        end
    end

    % Read the time step variable and store it in the grid structure
    try
        varID = netcdf.inqVarID(ncID, "pasTemp");
        grid.t = netcdf.getVar(ncID, varID);
    catch
        % Close the NetCDF file before raising an error
        netcdf.close(ncID);
        error('Error: Variable "pasTemp" does not exist in the NetCDF file.');
    end
    
    % Close the NetCDF file
    netcdf.close(ncID);
end
