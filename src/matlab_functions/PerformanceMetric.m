classdef PerformanceMetric
    % PerformanceMetric A class for calculating various hydrological performance metrics
    %   This class implements common performance metrics used in hydrological modeling
    %   to evaluate the agreement between observed and modeled data. It includes
    %   metrics such as R², KGE, RMSE, NSE, and others.
    %
    % Properties:
    %   observed - Vector of observed values
    %   modelled - Vector of modelled/predicted values
    %
    % Methods:
    %   R2      - Coefficient of determination (R²)
    %   KGE     - Kling-Gupta Efficiency
    %   RMSE    - Root Mean Square Error
    %   RRMSE   - Relative Root Mean Square Error
    %   BIAS    - Mean Bias
    %   PBIAS   - Percent Bias
    %   NSE     - Nash-Sutcliffe Efficiency
    %   LogNSE  - Logarithmic Nash-Sutcliffe Efficiency

    properties
        observed {mustBeNumeric}  % Vector of observed values
        modelled {mustBeNumeric}  % Vector of modelled/predicted values
    end

    methods
        function obj = PerformanceMetric()
            % PerformanceMetric Constructor
            % Initialize an empty PerformanceMetric object
        end

        function res = R2(obj)
            % R2 Calculate the coefficient of determination (R²)
            %   R² measures the proportion of variance in the dependent variable
            %   that is predictable from the independent variable.
            %
            % Returns:
            %   res - R² value ranging from -∞ to 1, where 1 indicates perfect fit
            
            p = polyfit(obj.observed, obj.modelled, 1);
            yfit = polyval(p, obj.observed);
            yresid = obj.modelled - yfit;
            SSresid = sum(yresid.^2);
            SStotal = (length(obj.modelled)-1) * var(obj.modelled);
            res = 1 - SSresid/SStotal;
        end

        function res = KGE(obj)
            % KGE Calculate the Kling-Gupta Efficiency
            %   KGE is a goodness-of-fit measure that combines correlation,
            %   bias, and variability components.
            %
            % Reference:
            %   Dr. Yaling Liu (cauliuyaling@gmail.com)
            %   GitHub: https://github.com/JGCRI/hydro-emulator/
            %
            % Returns:
            %   res - KGE value ranging from -∞ to 1, where 1 indicates perfect fit
            
            sdmodelled = std(obj.modelled, 'omitnan');
            sdobserved = std(obj.observed, 'omitnan');
            mmodelled = mean(obj.modelled, 'omitnan');
            mobserved = mean(obj.observed, 'omitnan');
            r = nancorr(obj.observed, obj.modelled);
            relvar = sdmodelled / sdobserved;
            bias = mmodelled / mobserved;

            res = 1 - sqrt(((r - 1)^2) + ((relvar - 1)^2) + ((bias - 1)^2));
        end

        function res = RMSE(obj)
            % RMSE Calculate the Root Mean Square Error
            %   RMSE measures the average magnitude of the prediction errors.
            %
            % Reference:
            %   https://www.sciencedirect.com/science/article/pii/S157495412200142X#bb0260
            %
            % Returns:
            %   res - RMSE value (same units as input data)
            
            res = sqrt(mean((obj.observed - obj.modelled).^2, 'omitnan'));
        end

        function res = RRMSE(obj)
            % RRMSE Calculate the Relative Root Mean Square Error
            %   RRMSE is RMSE expressed as a percentage of the observed mean.
            %
            % Reference:
            %   https://www.sciencedirect.com/science/article/pii/S157495412200142X#bb0260
            %
            % Returns:
            %   res - RRMSE value as percentage
            
            res = 100 * sqrt(mean((obj.observed - obj.modelled).^2, 'omitnan') / ...
                  sum(obj.observed, 'omitnan'));
        end

        function res = BIAS(obj)
            % BIAS Calculate the Mean Bias
            %   BIAS measures the average difference between modelled and observed values.
            %
            % Reference:
            %   https://www.sciencedirect.com/science/article/pii/S157495412200142X#bb0260
            %
            % Returns:
            %   res - BIAS value (same units as input data)
            
            res = mean((obj.modelled - obj.observed), 'omitnan');
        end

        function res = PBIAS(obj)
            % PBIAS Calculate the Percent Bias
            %   PBIAS measures the average tendency of simulated values to be
            %   larger or smaller than observed values.
            %
            % Reference:
            %   https://www.sciencedirect.com/science/article/pii/S157495412200142X#bb0260
            %
            % Returns:
            %   res - PBIAS value as percentage
            
            res = 100 * mean((obj.modelled - obj.observed), 'omitnan') / ...
                  sum(obj.observed, 'omitnan');
        end

        function res = NSE(obj)
            % NSE Calculate the Nash-Sutcliffe Efficiency
            %   NSE determines the relative magnitude of the residual variance
            %   compared to the observed data variance.
            %
            % Reference:
            %   AgriMetSoft.com
            %
            % Returns:
            %   res - NSE value ranging from -∞ to 1, where 1 indicates perfect fit
            
            numerator = sum((obj.modelled - obj.observed).^2, 'omitnan');
            denominator = sum((obj.observed - mean(obj.observed, 'omitnan')).^2, 'omitnan');
            res = 1 - (numerator / denominator);
        end

        function res = LogNSE(obj)
            % LogNSE Calculate the Logarithmic Nash-Sutcliffe Efficiency
            %   LogNSE is similar to NSE but uses log-transformed values, making it
            %   more sensitive to low flows.
            %
            % Reference:
            %   AgriMetSoft.com
            %
            % Returns:
            %   res - LogNSE value ranging from -∞ to 1, where 1 indicates perfect fit
            
            numerator = sum((log(obj.modelled) - log(obj.observed)).^2, 'omitnan');
            denominator = sum((log(obj.observed) - mean(log(obj.observed), 'omitnan')).^2, 'omitnan');
            res = 1 - (numerator / denominator);
        end
    end
end
