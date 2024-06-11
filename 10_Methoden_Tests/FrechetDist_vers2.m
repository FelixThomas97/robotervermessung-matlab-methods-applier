%% FrechetDist_vers1 

% load iso_path_C_1.mat

% % Rechteck
load trajectoryrobot31710929195154314.mat

% Kreis
% load trajectoryrobot117109292397507696.mat

data = table2array(trajectoryrobot31710929195154314);

% Extrahieren Ist- und Sollbahnen mit Zeitstempeln und kartesischen Koordinaten
x_ist = data(:,2);
y_ist = data(:,3);
z_ist = data(:,4);
t_ist = data(:,1);

x_soll = data(:,10);
y_soll = data(:,11);
z_soll = data(:,12);
t_soll = data(:,9);

% NaN-Werte aus Array's löschen
X = [x_soll y_soll z_soll t_soll];
X = X(~any(isnan(X),2),:);
Y = [x_ist y_ist z_ist t_ist];
Y = Y(~any(isnan(Y),2),:);


% Anzahl der Punkte und Dimension der Zeitreihen
[M, dim_X] = size(X);
[N, dim_Y] = size(Y);

% Berechnung der korrekten Zeitstempel beginnend bei Null
for i = 1:1:M
    X(i,4) = (X(i,4)-t_soll(1))/10^9;
end

for j = 1:1:N
    Y(j,4) = (Y(j,4)-t_ist(1))/10^9;
end

% Frequenz der Messung/ Berechnung
f_soll = length(X)/(X(end,4)-X(1,4));
f_ist = length(Y)/(Y(end,4)-Y(1,4));

% Vorerst ohne die Zeitstempel rechnen
Y = [x_ist y_ist z_ist];
X = [x_soll y_soll z_soll];
Y = Y(~any(isnan(Y),2),:);
X = X(~any(isnan(X),2),:);

%%

% Prüfen ob Vergleich der Zeitreihen möglich ist
if dim_X ~= dim_Y
    error('Die Bahnen müssen die gleiche Dimension haben')
elseif M == 0
    disp('Keine Punkte in Sollbahn vorhanden! Sollbahn muss generiert werden!')
    frechet_dist = 0;
    return;
end

% Kosten-/ Distanzmatrix aller Punkte 
trimmedDistanceMatrix = zeros(length(X),length(Y));
for i = 1:length(X)
    for j = 1:length(Y)
        trimmedDistanceMatrix(i,j) =  fkt_euclDist(i,j,X,Y);
    end
end

frechetMatrix = -1.*ones(size(trimmedDistanceMatrix));

% Schleife zur Berechnung der Frechet-Matrix
for i = 1:size(frechetMatrix, 1)
    for j = 1:size(frechetMatrix, 2)
        if i==1 && j==1
            % Entry 1,1 is always just the distance between first points
            frechetMatrix(i,j) = trimmedDistanceMatrix(1,1);
        elseif i>1 && j==1
            % Left column entries are the larger of the distance matrix entry or the upper neighbor
            frechetMatrix(i,j) = max(frechetMatrix(i-1,1), trimmedDistanceMatrix(i,1));
        elseif i==1 && j>1
            % Top row entries are the larger of the distance matrix entry or the left neighbor
            frechetMatrix(i,j) = max(frechetMatrix(1,j-1), trimmedDistanceMatrix(1,j));
        elseif i>1 && j>1
            % All other entries are the larger of the distance matrix entry or the minimum of the left, up-left, or up neighbors
            frechetMatrix(i,j) = max(min([frechetMatrix(i-1,j), frechetMatrix(i-1,j-1), frechetMatrix(i,j-1)]), trimmedDistanceMatrix(i,j));
        else
            % Shouldn't be able to reach here with valid i and j values
            error('i and j must be valid indices into the pairwise distance matrix!')
        end
    end
end

% % Vergleich der beiden Berechnungsverfahren der Frechetmatrix
% isequal(frechet_matrix,frechetMatrix)

%% 
counter1 = 0;
counter2 = 0;

% Build coupling sequence
leftIdx = 1;
upIdx = 2;
diagIdx = 3;
options = [leftIdx, upIdx, diagIdx];
[nPoints1, nPoints2] = size(trimmedDistanceMatrix);

% Build sample coupling sequence (typically non-unique)
couplingSequence = zeros(nPoints1 + nPoints2, 2);
r = nPoints1;
c = nPoints2;
couplingSequence(1,:) = [nPoints1, nPoints2];
stepCount = 2; % first step already entered
while r>1 && c>1
    % Consider the three neighbors
    leftNeighbor = {r,c-1};
    upNeighbor = {r-1,c};
    leftUpNeighbor = {r-1,c-1};
    % First criterion, which has the minimum frechetDist value?
    frechetVals = [frechetMatrix(leftNeighbor{:}),...
        frechetMatrix(upNeighbor{:}), ...
        frechetMatrix(leftUpNeighbor{:})];
    minFrechet = min(frechetVals);
    minFrechetMask = frechetVals == minFrechet;
    if sum(minFrechetMask) > 1
        counter1 = counter1+1;
        % If more than one have the same, then prefer the one which has a
        % smaller distMatrix value.
        distMatrixVals = [trimmedDistanceMatrix(leftNeighbor{:}), trimmedDistanceMatrix(upNeighbor{:}), trimmedDistanceMatrix(leftUpNeighbor{:})];
        minDistVal = min(distMatrixVals(minFrechetMask));
        minDistValMask = distMatrixVals(minFrechetMask)==minDistVal;
        if sum(minDistValMask) > 1
            % If more than one have the same, prefer the one which aims more
            % directly towards the 1,1 corner
            if r > c+1
                % prefer up
                preferenceOrder = [upIdx, diagIdx, leftIdx];
            elseif c > r+1
                % prefer left
                preferenceOrder = [leftIdx, diagIdx, upIdx];
            else
                % prefer diagonal
                if r==c
                    % prefer up as second choice (arbitrary choice)
                    preferenceOrder = [diagIdx, upIdx, leftIdx];
                elseif r>c
                    % prefer up as second choice
                    preferenceOrder = [diagIdx, upIdx, leftIdx];
                else % r<c
                    % prefer left as second choice
                    preferenceOrder = [diagIdx, leftIdx, upIdx];
                end
            end
            % Choose the highest preference of those with the same
            % minimum distance value
            frechetOptions = options(minFrechetMask);
            distOptions = frechetOptions(minDistValMask);
            if intersect(preferenceOrder(1), distOptions)
                chosen = preferenceOrder(1);
            elseif intersect(preferenceOrder(2), distOptions)
                chosen = preferenceOrder(2);
            else
                error('Something went wrong. There should be at least two options at this point, and so it shouldn''t be possible to be forced to the 3rd choice!')
            end
        else
            counter2 = counter2 +1;
            % Only one choice after distance comparison
            frechetOptions = options(minFrechetMask);
            chosen = frechetOptions(minDistValMask);
        end
    else
        % only one choice after frechet comparison
        chosen = options(minFrechetMask);
    end
    % Update r and c and add chosen pairing to the coupling sequence
    if chosen==leftIdx
        c = c-1;
    elseif chosen==upIdx
        r = r-1;
    elseif chosen==diagIdx
        r = r-1;
        c = c-1;
    else
        error('Chosen should be 1,2, or 3, but is not.')
    end
    couplingSequence(stepCount,:) = [r,c];
    % Increment step count
    stepCount = stepCount+1;
end % end of while

firstZero = find(couplingSequence(:, 1) == 0, 1, 'first');
couplingSequence = couplingSequence(1:firstZero-1, :);
couplingSequence = flip(couplingSequence);

% Euklidische Distanz zwischen allen Punktpaaren der Zuordnungssequenz
frechet_distancesv2 = sqrt(sum((X(couplingSequence(:,1),:) - Y(couplingSequence(:,2),:)).^2,2));
max_frechetv2 = max(frechet_distancesv2);
av_frechetv2 = mean(frechet_distancesv2);

%%
figure('Name','Discrete Frechet Distance')
hold on
plot3(X(:,1),X(:,2),X(:,3),'o-b','linewidth',2,'markerfacecolor','b')
plot3(Y(:,1),Y(:,2),Y(:,3),'o-r','linewidth',2,'markerfacecolor','r')
for j=1:length(couplingSequence)
  line([X(couplingSequence(j,1),1) Y(couplingSequence(j,2),1)],...
       [X(couplingSequence(j,1),2) Y(couplingSequence(j,2),2)],...
       [X(couplingSequence(j,1),3) Y(couplingSequence(j,2),3)],...
       'color','black');
end

%% Lösche Variablen

clear x_soll x_ist y_soll y_ist z_soll z_ist t_soll t_ist i j data 
clear M N dim_X dim_Y count xi yj lastZero mindist index
