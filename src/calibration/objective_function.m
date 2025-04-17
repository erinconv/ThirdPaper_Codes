function F = objective_function(x, execution_dates, params_struct, basin_struct, meteo_grid, objective, observed_flow, CP)
% OBJECTIVE_FUNCTION Calculates the objective function value for hydrological model calibration
%
% Inputs:
%   x              - Vector of parameters to calibrate
%   execution      - Execution time period
%   params_struct  - Structure containing model parameters
%   basin_struct   - Structure containing basin characteristics
%   meteo_grid     - Meteorological input data
%   objective      - Type of objective function to use:
%                    1: KGE (Kling-Gupta Efficiency)
%                    2: NSE (Nash-Sutcliffe Efficiency)
%                    3: LogNSE (Log Nash-Sutcliffe Efficiency)
%                    4: RMSE (Root Mean Square Error)
%   flow_file      - File containing observed flow data
%   CP             - Control point index
%
% Output:
%   F - Objective function value (to be minimized)

    % 1. Update Soil Parameters
    % Update hydrological parameters in the params_struct
    params_struct = update_soil_parameters(x, params_struct);
    
    % Update transfer parameter
    params_struct.transfert.exxkt = x(15);
    
    % % 2. Update Snow Melt and Evaporation Parameters based on selected module
    params_struct = update_snow_evap_parameters(params_struct, x);

    a = 1;
    
    % 3. Run CEQUEAU Model Simulation
    % Execute the hydrological model with updated parameters
    [y.etatsCE, y.etatsCP, y.etatsFonte, y.etatsEvapo, y.etatsBarrage, y.pasDeTemps,...
    y.avantAssimilationsCE, y.avantAssimilationsFonte, y.avantAssimilationsEvapo,y.etatsQualCP, y.avAssimQual] = ...
    cequeauQuantiteMex(execution_dates, params_struct, basin_struct, meteo_grid, [], [], [], []);
    
    % 4. Process Results
    % Extract and organize simulation results
    resu = extract_results(y, params_struct.option.calculQualite, params_struct.option.moduleFonte);
    resu.t = meteo_grid.t';
    resu.CP.CPs = int16(linspace(1, size(resu.CP.debit,2), size(resu.CP.debit,2)));
    
    % 5. Compare with Observations

    
    % Calculate performance metrics
    metrics = PerformanceMetric;
    [~, idx, idy] = intersect(observed_flow.datenums, resu.t);
    metrics.observed = single(observed_flow.values(idx));
    metrics.modelled = single(resu.CP.debit(idy, CP));
    
    % 6. Calculate Final Objective Function Value
    % Select and calculate the appropriate objective function
    F = calculate_objective_value(metrics, objective);
end

function params_struct = update_soil_parameters(x, params_struct)
    % Helper function to update soil parameters
    params_struct.sol.cin_s = x(1);    % Surface water coefficient
    params_struct.sol.cvmar = x(2);    % Marshland coefficient
    params_struct.sol.cvnb_s = x(3);   % Lower reservoir coefficient
    params_struct.sol.cvnh_s = x(4);   % Upper reservoir coefficient
    params_struct.sol.cvsb = x(5);     % Base flow coefficient
    params_struct.sol.cvsi_s = x(6);   % Intermediate flow coefficient
    params_struct.sol.xinfma = x(7);   % Maximum infiltration
    params_struct.sol.hinf_s = x(8);   % Infiltration threshold
    params_struct.sol.hint_s = x(9);   % Interflow threshold
    params_struct.sol.hmar = x(10);    % Marshland threshold
    params_struct.sol.hnap_s = x(11);  % Water table threshold
    params_struct.sol.hpot_s = x(12);  % Potential retention threshold
    params_struct.sol.hsol_s = x(13);  % Soil moisture threshold
    params_struct.sol.hrimp_s = x(14); % Impervious area threshold
end

function params_struct = update_snow_evap_parameters(params_struct, x)
    % Helper function to update snow melt and evaporation parameters
    switch params_struct.option.moduleFonte
        case 1  % CEQUEAU Degree-day model
            params_struct = update_cequeau_params(x, params_struct);
            params_struct = update_cequeau_evapo_params(x, params_struct);
            
        case 2  % CEMANEIGE model
            params_struct = update_cemaneige_params(x, params_struct);
            
        case 3  % UEB model
            params_struct = update_ueb_params(x, params_struct);
            params_struct = update_cequeau_evapo_params_ueb(x, params_struct);
    end
end

function params_struct = update_cequeau_params(x, params_struct)
    % Helper function for CEQUEAU snow parameters
    params_struct.fonte.cequeau.strne_s = x(16);  % Snow retention coefficient
    params_struct.fonte.cequeau.tfc_s = x(17);    % Freezing temperature (forest)
    params_struct.fonte.cequeau.tfd_s = x(18);    % Freezing temperature (open)
    params_struct.fonte.cequeau.tsc_s = x(19);    % Melting temperature (forest)
    params_struct.fonte.cequeau.tsd_s = x(20);    % Melting temperature (open)
    params_struct.fonte.cequeau.ttd = x(21);      % Temperature threshold for precipitation type
    params_struct.fonte.cequeau.tts_s = x(22);    % Snow transformation temperature
end

function params_struct = update_cemaneige_params(x, params_struct)
    % Helper function for CEMANEIGE parameters
    params_struct.fonte.cemaNeige.strne = x(16);   % Snow retention coefficient
    params_struct.fonte.cemaNeige.Kf = x(17);      % Melting factor
    params_struct.fonte.cemaNeige.Tf = x(18);      % Melting temperature
    params_struct.fonte.cemaNeige.CTg = x(19);     % Cold content coefficient
    params_struct.fonte.cemaNeige.theta = x(20);   % Thermal state coefficient
    params_struct.fonte.cemaNeige.Gseuil = x(21);  % Threshold for snow accumulation
    params_struct.fonte.cemaNeige.Zmed = x(22);    % Median elevation
end

function params_struct = update_ueb_params(x, params_struct)
    % Helper function for UEB parameters
    params_struct.fonte.UEB.strne_s = x(16);  % Snow retention coefficient
    params_struct.fonte.UEB.K_s = x(17);      % Conductivity parameter
    params_struct.fonte.UEB.z0 = x(18);       % Roughness length
end

function params_struct = update_cequeau_evapo_params(x, params_struct)
    % Helper function for CEQUEAU evaporation parameters
    params_struct.evapo.cequeau.evnap = x(23);  % Evaporation coefficient
    params_struct.evapo.cequeau.xaa = x(24);    % Annual adjustment coefficient
    params_struct.evapo.cequeau.xit = x(25);    % Temperature index coefficient
end

function  params_struct = update_cequeau_evapo_params_ueb(x, params_struct)
    % Helper function for CEQUEAU evaporation parameters with UEB
    params_struct.evapo.cequeau.evnap = x(19);  % Evaporation coefficient
    params_struct.evapo.cequeau.xaa = x(20);    % Annual adjustment coefficient
    params_struct.evapo.cequeau.xit = x(21);    % Temperature index coefficient
end

function F = calculate_objective_value(metrics, objective)
    % Helper function to calculate the final objective value
    switch objective
        case 1
            F = 1 - metrics.KGE;       % Minimize negative KGE
        case 2
            F = 1 - metrics.NSE;       % Minimize negative NSE
        case 3
            F = 1 - metrics.LogNSE;    % Minimize negative LogNSE
        otherwise
            F = metrics.RMSE;          % Minimize RMSE
    end
end
