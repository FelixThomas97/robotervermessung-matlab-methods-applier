function distance = EuclDist(i, j, pathX, pathY)

    % Berechnung des eukl. Abstands zwischen zwei Punkten von pathX und Y
    distance = norm(pathX(:,i) - pathY(:,j));
end