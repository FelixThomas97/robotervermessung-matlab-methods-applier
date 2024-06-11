%function result = LCSSRatio(traj1, traj2, pointSpacing, pointDistance, errorMarg, returnTrans)
% Function to calculate the ratio of the longest common subsequence to
% the shortest trajectory.
%
% Args:
%   traj1: An m x n matrix containing trajectory1. Here m is the number 
%          of points and n is the dimension of the points.
%   traj2: A k x n matrix containing trajectory2. Here k is the number 
%          of points and n is the dimension of the points. The two 
%          trajectories are not required to have the same number of points.
%   pointSpacing: An integer value of the maximum index difference between 
%                 trajectory1 and trajectory2 allowed in the calculation. 
%                 A negative value sets the point spacing to unlimited.
%   pointDistance: A floating point number representing the maximum 
%                  distance in each dimension allowed for points to be 
%                  considered equivalent.
%   errorMarg: A floating point error margin used to scale the accuracy 
%              and speed of the calculation.
%   returnTrans: A boolean value to allow the best translation found to 
%                be returned as well as the LCSS value if set to true.
% 
% Returns:
%   A floating point value is returned. This represents the maximum LCSS 
%   ratio obtained using the variables provided. If returnTrans is set to 
%   TRUE, then the LCSS ratio and the translations are returned as a 
%   vector. The first value of this vector is the LCSS ratio and the 
%   translations follow directly afterwards. If a problem occurs, then a 
%   string containing information about the problem is returned.

%%
clear;
load trajectoryrobot31710929195154314.mat
data = table2array(trajectoryrobot31710929195154314);
traj1 = data(:,2:4); % Ist
traj2 = data(:,10:12); % Soll

traj1 = traj1(~any(isnan(traj1),2),:);
traj2 = traj2(~any(isnan(traj2),2),:);


%%
%if nargin < 6
    returnTrans = false;
%end
%if nargin < 5
    errorMarg = 0.05;
%end
%if nargin < 4
    pointDistance = 20;
%end
%if nargin < 3
    pointSpacing = -1;
%end
%%

%%

% Calculating the number of points in each trajectory and the dimensions.
dimensions = size(traj1, 2);
length1 = size(traj1, 1);
length2 = size(traj2, 1);

% If a trajectory has no points then the ratio is 0.
if length1 == 0 || length2 == 0
    warning('At least one trajectory contains 0 points.');
    result = 0.0;
    return;
end

% Calculating the ratio based on the shortest trajectory.
length = min(length1, length2);

result = LCSS(traj1, traj2, pointSpacing, pointDistance, errorMarg, returnTrans) / length;

%end

%% Funktions

function result = TrajCheck(traj1, traj2)
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
        return;
    else
        result = -1;
    end
end


function result = LCSS(traj1, traj2, pointSpacing, pointDistance, errorMarg, returnTrans)
    % Function to calculate the longest common subsequence for two
    % given trajectories.
    %
    % Args:
    %   traj1: An m x n matrix containing trajectory1. Here m is the number 
    %          of points and n is the dimension of the points.
    %   traj2: A k x n matrix containing trajectory2. Here k is the number 
    %          of points and n is the dimension of the points. The two 
    %          trajectories are not required to have the same number of points.
    %   pointSpacing: An integer value of the maximum index difference between 
    %                 trajectory1 and trajectory2 allowed in the calculation. 
    %                 A negative value sets the point spacing to unlimited.
    %   pointDistance: A floating point number representing the maximum 
    %                  distance in each dimension allowed for points to be 
    %                  considered equivalent.
    %   errorMarg: A floating point error margin used to scale the accuracy 
    %              and speed of the calculation.
    %   returnTrans: A boolean value to allow the best translation found to 
    %                be returned as well as the LCSS value if set to true.
    %
    % Returns:
    %   An integer value is returned. This represents the maximum LCSS 
    %   value obtained using the variables provided. If returnTrans is set 
    %   to TRUE, then the LCSS value and the translations are returned as a 
    %   vector. The first value of this vector is the LCSS value and the 
    %   translations follow directly afterwards. If a problem occurs, then a 
    %   string containing information about the problem is returned.

    if nargin < 6
        returnTrans = false;
    end
    if nargin < 5
        errorMarg = 2;
    end
    if nargin < 4
        pointDistance = 20;
    end
    if nargin < 3
        pointSpacing = -1;
    end

    % Calculating the number of points in each trajectory and the dimensions.
    dimensions = size(traj1, 2);
    length1 = size(traj1, 1);
    length2 = size(traj2, 1);

    % If a trajectory has no points then there are 0 similar points.
    if length1 == 0 || length2 == 0
        warning('At least one trajectory contains 0 points.');
        result = 0;
        return;
    end

    % If the dimension is 0 then the points are considered equal.
    if dimensions == 0
        warning('The dimension is 0.');
        result = min(length1, length2);
        return;
    end

    % Setting the default point spacing if required.
    if pointSpacing < 0
        pointSpacing = max(length1, length2);
    end

    % Calculating the subsets of translations.
    translations = cell(1, dimensions);
    for d = 1:dimensions
        translations{d} = TranslationSubset(traj1(:, d), traj2(:, d), pointSpacing, pointDistance);
    end

    % Storing the most optimal translations and similarity found so far.
    similarity = LCSSCalc(traj1, traj2, pointSpacing, pointDistance);
    optimalTrans = zeros(1, dimensions);
    similarity = [similarity, optimalTrans];

    % Calculating how many translation possibilities are skipped for
    % every one that is checked using the error margin given.
    spacing = length(translations{1}) / (4 * pointSpacing / errorMarg);
    if spacing < 1
        spacing = 1;
    elseif spacing > (length(translations{1}) / 2.0)
        spacing = length(translations{1}) / 2.0;
    end
    spacing = floor(spacing);

    % Running the LCSS algorithm on each of the translations to be checked.
    similarity = SimLoop(traj1, traj2, pointSpacing, pointDistance, spacing, similarity, translations, dimensions, dimensions);

    % Returning the similarity and translations if requested.
    if returnTrans
        result = similarity;
    else
        % Returning the best similarity found.
        result = similarity(1);
    end
end

function translations = TranslationSubset(traj1, traj2, pointSpacing, pointDistance)
    % A function for calculating the subsets of translations to be tested
    % using the LCSS methods (this should not be called directly).
    %
    % Args:
    %   traj1: A vector containing one dimension of trajectory1.
    %   traj2: A vector containing one dimension of trajectory2.
    %   pointSpacing: An integer value of the maximum index difference between 
    %                 trajectory1 and trajectory2 allowed in the calculation.
    %   pointDistance: A floating point number representing the maximum 
    %                  distance in each dimension allowed for points to be 
    %                  considered equivalent.
    %
    % Returns:
    %   A vector of floating point numbers is returned containing the 
    %   translations calculated. This vector is sorted in ascending order.

    % Calculating the lengths of the trajectories.
    length1 = length(traj1);
    length2 = length(traj2);
    translations = [];

    for row = 1:length1
        % Calculating the relevant columns for each row.
        minCol = 1;
        maxCol = length2;

        if row > pointSpacing + 1
            minCol = row - pointSpacing;
        end
        if row < length2 - pointSpacing
            maxCol = row + pointSpacing;
        end

        if minCol <= maxCol
            for col = minCol:maxCol
                % Adding the new translations calculated from the distance boundaries.
                translations = [translations, (traj1(row) - traj2(col) + pointDistance)];
                translations = [translations, (traj1(row) - traj2(col) - pointDistance)];
            end
        end
    end

    % Returning the translations as a sorted vector.
    translations = sort(translations);
end

function similarity = LCSSCalc(traj1, traj2, pointSpacing, pointDistance, trans)
    % Function to calculate the LCSS of two trajectories using a set translation.
    %
    % Args:
    %   traj1: An m x n matrix containing trajectory1. Here m is the number 
    %          of points and n is the dimension of the points.
    %   traj2: A k x n matrix containing trajectory2. Here k is the number 
    %          of points and n is the dimension of the points. The two 
    %          trajectories are not required to have the same number of points.
    %   pointSpacing: An integer value of the maximum index difference between 
    %                 trajectory1 and trajectory2 allowed in the calculation. 
    %                 A negative value sets the point spacing to unlimited.
    %   pointDistance: A floating point number representing the maximum 
    %                  distance in each dimension allowed for points to be 
    %                  considered equivalent.
    %   trans: A vector containing translations in each dimension to be applied 
    %          to trajectory2 in this calculation.
    %
    % Returns:
    %   An integer value is returned. This represents the maximum LCSS value 
    %   obtained using the variables provided. If a problem occurs, then a 
    %   string containing information about the problem is returned.

    if nargin < 5
        trans = zeros(1, size(traj1, 2));
    end
    if nargin < 4
        pointDistance = 20;
    end
    if nargin < 3
        pointSpacing = -1;
    end

    % Checking the trajectories.
    trajTest = TrajCheck(traj1, traj2);
    if ischar(trajTest)
        similarity = trajTest;
        return;
    end

    % Calculating the number of points in each trajectory and the dimensions.
    dimensions = size(traj1, 2);
    length1 = size(traj1, 1);
    length2 = size(traj2, 1);

    % If a trajectory has no points then there are 0 similar points.
    if length1 == 0 || length2 == 0
        warning('At least one trajectory contains 0 points.');
        similarity = 0;
        return;
    end

    % If the dimension is 0 then the points are considered equal.
    if dimensions == 0
        warning('The dimension is 0.');
        similarity = min(length1, length2);
        return;
    end

    % Setting the default point spacing if required.
    if pointSpacing < 0
        pointSpacing = max(length1, length2);
    end

    % Rounding the point spacing if necessary.
    pointSpacing = round(pointSpacing);

    distMatrix = zeros(length1, length2);
    similarity = 0;

    for row = 1:length1
        % Calculating the relevant columns for each row.
        minCol = 1;
        maxCol = length2;
        if row > pointSpacing + 1
            minCol = row - pointSpacing;
        end
        if row < length2 - pointSpacing
            maxCol = row + pointSpacing;
        end

        if minCol <= maxCol
            for col = minCol:maxCol
                newValue = 0;
                finalValue = 0;

                % Calculating the new LCSS value for the current two points.
                % Checking the diagonal.
                if row ~= 1 && col ~= 1
                    newValue = distMatrix(row - 1, col - 1);
                    finalValue = newValue;
                end

                % Checking below.
                if row ~= 1
                    below = distMatrix(row - 1, col);
                    if below > finalValue
                        finalValue = below;
                    end
                end

                % Checking to the left.
                if col ~= 1
                    before = distMatrix(row, col - 1);
                    if before > finalValue
                        finalValue = before;
                    end
                end

                % Checking if the current points can increment the LCSS.
                if finalValue < newValue + 1
                    checkPoint = DistanceCheck(traj1(row, :), traj2(col, :) + trans, pointDistance, dimensions);
                    if checkPoint
                        newValue = newValue + 1;
                        finalValue = newValue;
                    end
                end

                % Updating the distance matrix.
                distMatrix(row, col) = finalValue;

                % Updating the similarity if a new maximum has been found.
                if finalValue > similarity
                    similarity = finalValue;
                end
            end
        end
    end

    % Returning the largest similarity.
    return;
end

function check = DistanceCheck(point1, point2, dist, dimensions)
    % A function to check whether two points lie within some distance
    % in every dimension.
    %
    % Args:
    %   point1: An n dimensional vector representing point1.
    %   point2: An n dimensional vector representing point2.
    %   dist: A floating point number representing the maximum distance in 
    %         each dimension allowed for points to be considered equivalent.
    %   dimensions: An integer representing the number of dimensions being 
    %               checked. This defaults to the length of the first vector.
    %
    % Returns:
    %   A boolean value is returned. The value is true if the points are 
    %   within the distance in every dimension and false if not.

    if nargin < 4
        dimensions = length(point1);
    end
    
    % Initializing to TRUE which is returned if the check is successful.
    check = true;
    
    for d = 1:dimensions
        if check
            newDist = abs(point1(d) - point2(d));
            % If the points are not within the distance in a dimension
            % then FALSE is returned.
            if ~(abs(newDist - dist) < eps * 1000) && newDist > dist
                check = false;
            end
        end
    end
    
    % Returning the boolean value.
    return;
end

function similarity = SimLoop(traj1, traj2, pointSpacing, pointDistance, spacing, similarity, translations, dimensions, dimLeft , currentTrans)
    % Function to loop over and test the trajectories using the different
    % translations in each dimension (this should not be called directly).
    %
    % Args:
    %   traj1: An m x n matrix containing trajectory1. Here m is the number 
    %          of points and n is the dimension of the points.
    %   traj2: A k x n matrix containing trajectory2. Here k is the number 
    %          of points and n is the dimension of the points. The two 
    %          trajectories are not required to have the same number of points.
    %   pointSpacing: An integer value of the maximum index difference between 
    %                 trajectory1 and trajectory2 allowed in the calculation. 
    %                 A negative value sets the point spacing to unlimited.
    %   pointDistance: A floating point number representing the maximum 
    %                  distance in each dimension allowed for points to be 
    %                  considered equivalent.
    %   spacing: The integer spacing between each translation that will 
    %            be tested.
    %   similarity: A vector containing the current best similarity and 
    %               translations calculated.
    %   translations: A list of vectors containing the translations in 
    %                 each dimension.
    %   dimensions: An integer representing the number of dimensions being 
    %               used for the calculation.
    %   dimLeft: An integer number of dimensions which have not been 
    %            looped over yet.
    %   currentTrans: A vector containing the current translation being tested.
    %
    % Returns:
    %   Returns the current best LCSS value and the translations that created 
    %   this as a vector.

    if nargin < 9
        currentTrans = zeros(1, dimensions);
    end
    
    thisDim = 1 + dimensions - dimLeft;
    prevTrans = [];

    for i = spacing:spacing:length(translations{thisDim})
        % The newest translation.
        currentTrans(thisDim) = translations{thisDim}(round(i));

        % Skipping translations which have already been checked.
        if ~(abs(currentTrans(thisDim) - prevTrans) < eps * 1000)
            if dimLeft > 1
                similarity = SimLoop(traj1, traj2, pointSpacing, pointDistance, spacing, similarity, translations, dimensions, dimLeft - 1, currentTrans);
            else
                % Running the LCSS algorithm on each of the translations to be checked.
                newValue = LCSSCalc(traj1, traj2, pointSpacing, pointDistance, currentTrans);

                % Keeping the new similarity and translations if they are better than the previous best.
                if newValue > similarity(1)
                    similarity(1) = newValue;
                    for d = 1:dimensions
                        similarity(d + 1) = currentTrans(d);
                    end
                end
            end
            prevTrans = currentTrans(thisDim);
        end
    end

    % Returning the vector containing the current best similarity with translations.
    % return similarity
end