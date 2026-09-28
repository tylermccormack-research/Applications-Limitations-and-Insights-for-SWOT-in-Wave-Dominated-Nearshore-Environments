function [w1_opt, w2_opt, y_hat_opt, error_opt] = optimizeWeights(x1, x2, y)
    % x1, x2: calculated values (vectors or scalars)
    % y: insitu values (same size as x1, x2)
    % Returns optimal weights and minimized error
    
    % Define error function (Mean Squared Error)
    errorFun = @(w1) mean((y - (w1*x1 + (1-w1)*x2)).^2);
    
    % Optimize w1 in [0,1]
    options = optimset('Display','off');
    w1_opt = fminbnd(errorFun, 0, 1, options);
    w2_opt = 1 - w1_opt;
    
    % Compute best estimate and error
    y_hat_opt = w1_opt*x1 + w2_opt*x2;
    error_opt = sqrt(mean((y - y_hat_opt).^2)); % RMSE
    
end
