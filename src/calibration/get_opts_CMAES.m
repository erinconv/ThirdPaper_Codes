function [defopts, sigma, x0] = get_opts_CMAES(prefix, model, params_struct)
    % GET_OPTS_CMAES Get optimization options for CMA-ES algorithm
    %
    % Inputs:
    %   prefix        - Prefix for output files
    %   model        - Model type identifier (1: Hydrology, 2: Water Temperature)
    %   params_struct - Structure containing model parameters
    %
    % Outputs:
    %   defopts - Structure with CMA-ES options
    %   sigma   - Vector of initial step sizes
    %   x0      - Vector of initial parameter values
    
    switch model
        case 1  % Hydrological Module
            % Get the common hydrological parameters bounds (SOL)
            [lb_sol, ub_sol] = get_soil_bounds();
            
            % Get snow and evaporation bounds based on the selected snow module
            switch params_struct.option.moduleFonte
                case 1  % CEQUEAU Degree-day model
                    [lb_snow, ub_snow] = get_cequeau_snow_bounds();
                    [lb_evap, ub_evap] = get_cequeau_evap_bounds();
                    
                case 2  % CEMANEIGE model
                    [lb_snow, ub_snow] = get_cemaneige_bounds();
                    lb_evap = [];
                    ub_evap = [];
                    
                case 3  % UEB model
                    [lb_snow, ub_snow] = get_ueb_bounds();
                    [lb_evap, ub_evap] = get_ueb_evap_bounds();
                    
                otherwise
                    error('Unknown snow module type: %d', params_struct.option.moduleFonte);
            end
            
            % Combine all bounds
            lb = [lb_sol; lb_snow; lb_evap];
            ub = [ub_sol; ub_snow; ub_evap];
            
        case 2  % Water Temperature Module
            % Get water temperature parameters bounds
            [lb, ub] = get_water_temp_bounds();
            
        otherwise
            error('Unknown model type: %d', model);
    end

    % Calculate optimization parameters
    sigma = (ub - lb);
    x0 = (ub + lb) / 2;
    
    % Set CMA-ES options
    defopts.LBounds = lb;
    defopts.UBounds = ub;
    % defopts.LogPlot = 'on';
    defopts.SaveFilename = append(prefix, '_variablescmaes.mat');
    defopts.LogFilenamePrefix = prefix;
    defopts.MaxFunEvals = 3500;
    defopts.MaxIter = 4000;
end

function [lb, ub] = get_soil_bounds()
    % Common hydrological (SOL) parameters bounds
    lb = [
        0.01   % CIN    - Surface water coefficient
        0.01   % CVMAR  - Marshland coefficient
        0.001  % CVNB   - Lower reservoir coefficient
        0.01   % CVNH   - Upper reservoir coefficient
        0.001  % CVSB   - Base flow coefficient
        0.01   % CVSI   - Intermediate flow coefficient
        0.1    % XINFMA - Maximum infiltration
        5.0    % HINF   - Infiltration threshold
        0.0    % HINT   - Interflow threshold
        100.0  % HMAR   - Marshland threshold
        20.0   % HNAP   - Water table threshold
        0.10   % HPOT   - Potential retention threshold
        100.0  % HSOL   - Soil moisture threshold
        0.001  % HRIMP  - Impervious area threshold
        0.01   % EXXKT  - Transfer coefficient
    ];
    
    ub = [
        0.5    % CIN
        0.5    % CVMAR
        0.1    % CVNB
        0.5    % CVNH
        0.2    % CVSB
        0.5    % CVSI
        4.0    % XINFMA
        100.0  % HINF
        200.0  % HINT
        500.0  % HMAR
        200.0  % HNAP
        80.0   % HPOT
        300.0  % HSOL
        10.0   % HRIMP
        0.2    % EXXKT
    ];
end

function [lb, ub] = get_cequeau_snow_bounds()
    % CEQUEAU snow model parameters bounds
    lb = [
        -2.0   % strne_s - Snow retention coefficient
        0.0    % tfc_s   - Freezing temperature (forest)
        0.001  % tfd_s   - Freezing temperature (open)
        1.0    % tsc_s   - Melting temperature (forest)
        0.1    % tsd_s   - Melting temperature (open)
        0.4    % ttd     - Temperature threshold for precipitation
        13.0   % tts_s   - Snow transformation temperature
    ];
    
    ub = [
        1.0    % strne_s
        0.5    % tfc_s
        0.01   % tfd_s
        500    % tsc_s
        2.0    % tsd_s
        0.99   % ttd
        20.0   % tts_s
    ];
end

function [lb, ub] = get_cemaneige_bounds()
    % CEMANEIGE snow model parameters bounds
    lb = [
        -2.0   % strne   - Snow retention coefficient
        0.0    % Kf      - Melting factor
        -2.0   % Tf      - Melting temperature
        0.0    % CTg     - Cold content coefficient
        0.0    % theta   - Thermal state coefficient
        0.0    % Gseuil  - Threshold for snow accumulation
        0.0    % Zmed    - Median elevation
    ];
    
    ub = [
        2.0    % strne
        20.0   % Kf
        2.0    % Tf
        1.0    % CTg
        1.0    % theta
        100.0  % Gseuil
        3000.0 % Zmed
    ];
end

function [lb, ub] = get_ueb_bounds()
    % UEB snow model parameters bounds
    lb = [
        -2.0   % strne_s - Snow retention coefficient
        0.1    % K_s     - Conductivity parameter
        0.0001 % z0      - Roughness length
    ];
    
    ub = [
        2.0    % strne_s
        10.0   % K_s
        0.1    % z0
    ];
end

function [lb, ub] = get_cequeau_evap_bounds()
    % CEQUEAU evaporation parameters bounds
    lb = [
        0.001  % EVNAP - Evaporation coefficient
        0.20   % XAA   - Annual adjustment coefficient
        5.00   % XIT   - Temperature index coefficient
    ];
    
    ub = [
        0.3    % EVNAP
        5.0    % XAA
        50.0   % XIT
    ];
end

function [lb, ub] = get_ueb_evap_bounds()
    % UEB evaporation parameters bounds
    lb = [
        0.001  % EVNAP - Evaporation coefficient
        0.20   % XAA   - Annual adjustment coefficient
        5.00   % XIT   - Temperature index coefficient
    ];
    
    ub = [
        0.3    % EVNAP
        5.0    % XAA
        50.0   % XIT
    ];
end

function [lb, ub] = get_water_temp_bounds()
    % Water temperature module parameters bounds
    lb = [
        1.0    % COPROM  - Coefficient defining minimum river depth as ratio of width
        1.0    % COLARG  - Coefficient defining minimum river width
        1.0    % CRAYSO  - Weighting coefficient for solar (short wave) radiation
        1.0    % CRAYIN  - Weighting coefficient for infrared radiation
        0.5    % CEVAPO  - Weighting coefficient for evaporation (latent heat)
        1.0    % CCONVE  - Weighting coefficient for convection (sensible heat)
        50.0   % CRIGEL  - Freeze criterion for squares (min snow in mm)
        4.0    % TNAP    - Groundwater temperature (°C)
        5.0    % BASSOL  - Total precipitation for low solar radiation days (mm)
        0.0    % CORSOL  - Weighting coefficient for mean solar radiation
    ];
    
    ub = [
        2.0    % COPROM
        2.0    % COLARG
        3.0    % CRAYSO
        2.0    % CRAYIN
        2.0    % CEVAPO
        2.0    % CCONVE
        250.0  % CRIGEL
        8.0    % TNAP
        10.0   % BASSOL
        1.0    % CORSOL
    ];
end
