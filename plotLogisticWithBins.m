function plotLogisticWithBins(x, y, nBins, col)
    x = double(x(:));
    y = double(y(:));

    % --- Logistic regression ---
    [b, ~, stats] = glmfit(x, y, 'binomial', 'link', 'logit');
    xfit  = linspace(min(x), max(x), 200)';
    yfit  = glmval(b, xfit, 'logit');
    pVal  = stats.p(2);   % p-value for the pupil predictor

    plot(xfit, yfit, '-', 'Color', col, 'LineWidth', 2);
    hold on;

    % --- Binned CR% points ---
    edges    = quantile(x, linspace(0, 1, nBins+1));
    edges(1) = edges(1) - eps;
    binMeans = zeros(nBins, 1);
    binCRpct = zeros(nBins, 1);
    for k = 1:nBins
        inBin       = x > edges(k) & x <= edges(k+1);
        binMeans(k) = mean(x(inBin));
        binCRpct(k) = mean(y(inBin));
    end
    disp(numel(x));
    disp(edges);
    disp(binMeans);
    disp(binCRpct);
    scatter(binMeans, binCRpct, 60, col, 'filled', 'HandleVisibility', 'off');

    % --- p-value annotation ---
    if pVal < 0.001
        pStr = 'p < 0.001';
    else
        pStr = sprintf('p = %.3f', pVal);
    end
    text(0.05, 0.95, pStr, 'Units', 'normalized', 'Color', col, ...
        'FontSize', 10, 'VerticalAlignment', 'top');

    ylim([0 1]);
end