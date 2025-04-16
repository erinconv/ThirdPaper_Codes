function resu = extract_results(y, thermie, fonteModule)
    % EXTRACT_RESULTS Extracts various results from the input structure.
    %
    %   resu = EXTRACT_RESULTS(y, thermie, fonteModule) takes in a structure
    %   'y' containing various state information and extracts relevant results
    %   based on the specified 'thermie' and 'fonteModule' parameters.
    %
    %   Inputs:
    %       y - Structure containing state information, including:
    %           - etatsCP: Data for partial squares (CP)
    %           - etatsCE: Data for water levels in different environments (CE)
    %           - etatsFonte: Data for source modules
    %           - etatsQualCP: Data for quality variables in partial squares (CP)
    %       thermie - Indicator for thermal calculations (1 for enabled, 0 for disabled).
    %       fonteModule - Indicator for the type of source module (1, 2, or 3).
    %
    %   Outputs:
    %       resu - Structure containing extracted results with the following fields:
    %           - CP: Results related to partial squares
    %           - CE: Results related to water levels and source modules

    % Extracting results for partial squares (CP)
    resu.CP.debit = cat(1, y.etatsCP(2:end).debit); % Discharge [m3 s-1]
    resu.CP.volume = cat(1, y.etatsCP(2:end).volume); % Volume [m3]
    resu.CP.apport = cat(1, y.etatsCP(2:end).apport); % Contribution [m3]
    
    % Extracting results for water levels in different reservoirs (CE)
    resu.CE.HNAPPE = cat(1, y.etatsCE(2:end).niveauEauNappe); % Water level in the aquifer [mm]
    resu.CE.HSOL = cat(1, y.etatsCE(2:end).niveauEauSol); % Water level in the soil [mm]
    resu.CE.HMAR = cat(1, y.etatsCE(2:end).niveauEauLacsMarais); % Water level in lakes and marshes [mm]
    
    % Conditional extraction based on fonteModule
    switch fonteModule
        case 1
            % Extracting snow-related variables for module 1
            resu.CE.stockNeigeClairiere = cat(1, y.etatsFonte(2:end).stockNeigeClairiere); % Snow stock in clearings
            resu.CE.stockNeigeForet = cat(1, y.etatsFonte(2:end).stockNeigeForet); % Snow stock in forests
            resu.CE.indexMurissementNeige = cat(1, y.etatsFonte(2:end).indexMurissementNeige); % Snow maturation index
            resu.CE.indexTempNeige = cat(1, y.etatsFonte(2:end).indexTempNeige); % Snow temperature index
            resu.CE.eauDisponible = cat(1, y.etatsFonte(2:end).eauDisponible); % Available water from snow
        case 2
            % Extracting variables for module 2
            resu.CE.eTg = cat(1, y.etatsFonte(2:end).eTg); % Ground temperature
            resu.CE.G = cat(1, y.etatsFonte(2:end).G); % Ground heat flux
            resu.CE.fonte_reel = cat(1, y.etatsFonte(2:end).fonte_reel); % Actual source
        case 3
            % Extracting variables for module 3 - (UEB model)
            resu.CE.w = cat(1, y.etatsFonte(2:end).w); % Snow water equivalent [m]
            resu.CE.ub = cat(1, y.etatsFonte(2:end).ub); % Energy balance [MJ m-2]
            resu.CE.E = cat(1, y.etatsFonte(2:end).E); % Water equivalence depth of sublimation [m]
            resu.CE.Mr = cat(1, y.etatsFonte(2:end).Mr); % Melt rate
            resu.CE.tausn = cat(1, y.etatsFonte(2:end).tausn); % Snow age
            resu.CE.tsurf = cat(1, y.etatsFonte(2:end).tsurf); % Snow surface temperature
            resu.CE.tave = cat(1, y.etatsFonte(2:end).tave); % Soil average temperature
            resu.CE.albedo = cat(1, y.etatsFonte(2:end).albedo); % Snow albedo
            resu.CE.Fm = cat(1, y.etatsFonte(2:end).Fm); % Mass balance [m d-1]
            resu.CE.Q = cat(1, y.etatsFonte(2:end).Q); % Energy balance [MJ m-2 d-1]
            resu.CE.Qm = cat(1, y.etatsFonte(2:end).Qm); % Heat flux from melting snow [MJ m-2 d-1]
            resu.CE.Qh = cat(1, y.etatsFonte(2:end).Qh); % Sensible heat flux [MJ m-2 d-1]
            resu.CE.Qe = cat(1, y.etatsFonte(2:end).Qe); % Latent heat flux [MJ m-2 d-1]
    end

    % Conditional extraction based on thermie
    if thermie == 1
        % Extracting thermal variables for partial squares (CP)
        resu.CP.temperature = cat(1, y.etatsQualCP(2:end).temperature); % Temperature of the water in the partial squares (°C)
        resu.CP.ruiss = cat(1, y.etatsQualCP(2:end).qruiss); % Heat advected from runoff [MJ]
        resu.CP.nappe = cat(1, y.etatsQualCP(2:end).qnappe); % Heat advected from groundwater [MJ]
        resu.CP.hypo = cat(1, y.etatsQualCP(2:end).qhypo); % Heat advected from the hyporheic zone [MJ]
        resu.CP.lacma = cat(1, y.etatsQualCP(2:end).qlacma); % Heat advected from lakes and marshes [MJ]
        resu.CP.radso = cat(1, y.etatsQualCP(2:end).qradso); % Net solar radiation [MJ]
        resu.CP.radin = cat(1, y.etatsQualCP(2:end).qradin); % Net infrared radiation [MJ]
        resu.CP.evap = cat(1, y.etatsQualCP(2:end).qevap); % Latent heat flux [MJ]
        resu.CP.conv = cat(1, y.etatsQualCP(2:end).qconv); % Sensible heat flux [MJ]
    end
end
