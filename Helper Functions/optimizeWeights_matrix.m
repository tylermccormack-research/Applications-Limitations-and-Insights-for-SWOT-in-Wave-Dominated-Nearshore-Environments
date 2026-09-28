function [w1_opt, w2_opt, y_hat_opt, error_opt] = optimizeWeights_matrix(x1, x2, y)
    % x1, x2, y: matrices of same size (e.g., 43x6)
    % Finds global optimal weights w1, w2 that minimize RMSE
    
    % Flatten everything into column vectors
    x1 = x1(:);
    x2 = x2(:);
    y  = y(:);
    
    % Error function (RMSE)
    errorFun = @(w1) mean((y - (w1*x1 + (1-w1)*x2)).^2);
    
    % Optimize w1 in [0,1]
    options = optimset('Display','off');
    w1_opt = fminbnd(errorFun, 0, 1, options);
    w2_opt = 1 - w1_opt;
    
    % Best fit estimate
    y_hat_opt = reshape(w1_opt*x1 + w2_opt*x2, size(y)); % reshape back to matrix size
    error_opt = sqrt(mean((y(:) - y_hat_opt(:)).^2));    % RMSE
end
