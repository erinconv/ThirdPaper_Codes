function [params_struct, basin_struct] = read_jsons(folder_path, params_name ,tri_s)
    % read_jsons - Reads JSON files containing parameters and basin structure.
    %
    % Syntax: [params_struct, basin_struct] = read_jsons(folder_path, params_name,tri_s)
    %
    % Inputs:
    %   folder_path - A string representing the path to the folder containing
    %                 the JSON files.
    %   tri_s       - A scalar value representing the impermeable surface
    %                 parameter. If not provided, defaults to 0.
    %
    % Outputs:
    %   params_struct - A structure containing parameters loaded from the
    %                   params.json file.
    %   basin_struct   - A structure containing basin information loaded from
    %                    the bassinVersant.json file.

    % Construct the full path to the basin JSON file
    bassin_json = fullfile(folder_path, 'results', 'bassinVersant.json');
    % Load the basin structure from the JSON file
    basin_struct = loadjson(bassin_json);   
    % Fix the structure
    basin_struct.carreauxEntiers = fix_struct(basin_struct.carreauxEntiers);
    basin_struct.carreauxPartiels = fix_struct(basin_struct.carreauxPartiels);
    

    % Construct the full path to the parameters JSON file
    params_json = fullfile(folder_path, 'results', params_name);
    % Load the parameters structure from the JSON file
    params_struct = loadjson(params_json);
    
    % Assign the tri_s value to the params structure for further processing
    if nargin < 3  % Check if tri_s is provided
        params_struct.sol.tri_s = tri_s;
    end
end
