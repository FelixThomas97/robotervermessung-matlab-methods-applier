%% Funktionen

% Berechnung des eukl. Abstands zwischen zwei Punkten von X und Y
function distance = fkt_euclDist(i, j, X, Y)

    distance = norm(X(i,:) - Y(j,:));
end
