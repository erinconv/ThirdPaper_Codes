function [coef, t, n] = nancorr(A, B)
    %NANCORR - Pearson correlation coefficient with NaN handling
    %
    % This function calculates the Pearson correlation coefficient between matrices
    % A and B while properly handling NaN (missing) values. It's an efficient
    % alternative to MATLAB's corr(A, B, 'rows','pairwise').
    %
    % Syntax:
    %   coef = NANCORR(A, B)
    %   [coef, t, n] = NANCORR(A, B)
    %
    % Input Arguments:
    %   A, B - Input matrices (single or double) with equal number of rows
    %         Each column represents a variable, each row represents an observation
    %
    % Output Arguments:
    %   coef - Matrix of Pearson correlation coefficients
    %   t    - Matrix of t-statistics for testing correlation significance
    %   n    - Matrix containing the number of pairwise complete observations
    %
    % Notes:
    %   - P-values can be calculated using: 2*tcdf(-abs(t), n - 2)
    %   - For numerical stability with large values, consider centering 
    %     the columns before calling nancorr
    %   - The implementation uses the computational formula for Pearson correlation:
    %     r = (Σxy - nμxμy)/(σx*σy), where μ is mean and σ is std deviation

    % Step 1: Create masks for missing (NaN/Inf) and present values
    Am = ~isfinite(A); % Mask for missing values in A
    Bm = ~isfinite(B); % Mask for missing values in B

    % Step 2: Create masks for present values, maintaining input data type
    if isa(class(A), 'single')
        Ap = single(~Am); % Present values mask for A (single precision)
        Bp = single(~Bm); % Present values mask for B (single precision)
    else
        Ap = double(~Am); % Present values mask for A (double precision)
        Bp = double(~Bm); % Present values mask for B (double precision)
    end

    % Step 3: Replace NaN/Inf with zeros for computation
    A(Am) = 0;
    B(Bm) = 0;

    % Step 4: Calculate components for correlation formula
    xy = A' * B;    % Sum of products (Σxy)
    n = Ap' * Bp;   % Number of pairwise complete observations

    % Calculate means using only pairwise complete observations
    mx = A' * Bp ./ n;  % Mean of x variables (μx)
    my = Ap' * B ./ n;  % Mean of y variables (μy)

    % Calculate sum of squares
    x2 = (A .* A)' * Bp;  % Sum of squared x values (Σx²)
    y2 = Ap' * (B .* B);  % Sum of squared y values (Σy²)

    % Step 5: Calculate standard deviations
    sx = sqrt(x2 - n .* (mx .^ 2));  % Standard deviation of x (σx)
    sy = sqrt(y2 - n .* (my .^ 2));  % Standard deviation of y (σy)

    % Step 6: Calculate correlation coefficient using the formula:
    % r = (Σxy - nμxμy)/(σx*σy)
    coef = (xy - n .* mx .* my) ./ (sx .* sy);

    % Step 7: Calculate t-statistic for hypothesis testing
    % t = r * sqrt((n-2)/(1-r²))
    t = coef .* sqrt((n - 2) ./ (1 - coef .^ 2));
end
