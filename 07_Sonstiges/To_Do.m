%% Funktionen die ich noch einbinden muss!

% 1. Checking the trajectories.
    trajTest = TrajCheck(traj1, traj2);
    if ischar(trajTest)
        result = trajTest;
        return;
    end    

% 2. Eine Trajektorie hat keine Punkte
if length1 == 0 || length2 == 0
    warning('At least one trajectory contains 0 points.');
    result = 'At least one trajectory contains 0 points.';
    return;
end


% 3. Trajektorien sind dimensionslos
if dimensions == 0
    warning('The dimension is 0.');
    result = 0.0;
    return;
end

% 4. Eine Trajektorie hat nur einen Punkt
if length1 == 1 || length2 == 1
    leash = SinglePointCalc(traj1, traj2);
    if testLeash >= 0
        if testLeash >= leash
            result = true;
        else
            result = false;
        end
    else
        result = leash;
    end
    return;
end


% 5. Prüfen ob Vergleich der Trajektorien möglich ist
if dim_X ~= dim_Y
    error('Die Bahnen müssen die gleiche Dimension haben')
elseif M == 0
    disp('Keine Punkte in Sollbahn vorhanden! Sollbahn muss generiert werden!')
    frechet_dist = 0;
    return;
end

function result = TrajCheck(traj1, traj2)
    % TrajCheck - Check that trajectories are in matrix form and have
    % the same dimension.
    %
    % Args:
    %   traj1: An m x n matrix containing trajectory1. Here m is the number 
    %          of points and n is the dimension of the points.
    %   traj2: A k x n matrix containing trajectory2. Here k is the number 
    %          of points and n is the dimension of the points. The two 
    %          trajectories are not required to have the same number of points.
    %
    % Returns:
    %   If there is a problem with one of the checks then a string containing 
    %   information is returned. If all of the checks pass then -1 is returned.

    % Checking that the trajectories are matrices.
    if ~ismatrix(traj1) || ~ismatrix(traj2)
        warning('At least one trajectory is not a matrix.');
        result = 'At least one trajectory is not a matrix.';
        return;
    end
    
    % Checking trajectories have the same dimension.
    if size(traj1, 2) ~= size(traj2, 2)
        warning('The dimension of the trajectories does not match.');
        result = 'The dimension of the trajectories does not match.';
    else
        result = -1;
    end
end

%%
