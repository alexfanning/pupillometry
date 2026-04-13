%% Local function: fit line + R value
function plotFitLine(x, y, col)
    % Remove NaNs
    valid = ~isnan(x) & ~isnan(y);
    x = x(valid);
    y = y(valid);
    if numel(x) < 2; return; end

    % Linear fit
    p    = polyfit(x, y, 1);
    xfit = linspace(min(x), max(x), 100);
    yfit = polyval(p, xfit);
    plot(xfit, yfit, '-', 'Color', col, 'LineWidth', 1.2, 'HandleVisibility', 'off');

    % Pearson r
    r = corr(x, y);
    % Place r text near top of line
    text(xfit(end), yfit(end), sprintf('  r=%.2f', r), ...
        'Color', col, 'FontSize', 9, 'HandleVisibility', 'off');
end