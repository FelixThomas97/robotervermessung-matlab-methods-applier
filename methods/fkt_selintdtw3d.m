function [distances, maxDistance, averageDistance, AccumulatedDistance, dtw_X, dtw_Y, MappingIndexes, ix, iy] = fkt_selintdtw3d(X,Y,pflag)

%% Beispieldaten (gehört nicht zur Funktion)
% load iso_path_B_real_1.mat
% X = soll; 
% Y = ist;
% pflag = 1;
% clear soll ist
%% Code der Funktion

if nargin < 3 
    pflag = false; 
end

% Initialisierung der Variablen
M = length(X);
N = length(Y);
AccumulatedDistance = zeros(M,N);
AccumulatedDistanceX = zeros(M,N);
AccumulatedDistanceY = zeros(M,N);
ParamX = zeros(M,N);
ParamY = zeros(M,N);
minParams = cell(M,N);
minParamsX = cell(M,N);
minParamsY = cell(M,N);

% Initialisierung der Anfangsbedingungen

AccumulatedDistance(1,1) = fkt_euclDist(1,1,X,Y);
AccumulatedDistanceX(1,1) = Inf;
AccumulatedDistanceY(1,1) = Inf;
ParamX(1,1) = NaN;
ParamY(1,1) = NaN;
minParams{1,1} = [NaN, NaN];
minParamsX{1,1} = [NaN, NaN];
minParamsY{1,1} = [NaN, NaN];

% Startwerte X
for i=2:1:M
    [mindist, param] = fkt_minDistParam(X(i-1,:),X(i,:),Y(1,:));
    AccumulatedDistanceX(i,1) = AccumulatedDistanceX(i-1,1) + mindist;
    AccumulatedDistanceY(i,1)= Inf;
    ParamX(i,1) = param;
    ParamY(i,1) = NaN;
    minParams{i,1} = [0,1];
    minParamsX{i,1} = [0,1];
    minParamsY{i,1} = [NaN,NaN];
    AccumulatedDistance(i,1) = AccumulatedDistance(i-1,1) + fkt_euclDist(i,1,X,Y);
    if fkt_isInterpolation(ParamX(i,1)) && AccumulatedDistanceX(i,1) < AccumulatedDistance(i-1,1)
        AccumulatedDistance(i,1) = AccumulatedDistanceX(i,1) + fkt_euclDist(i,1,X,Y);
        minParams{i,1} = [ParamX(i,1),1];
    end
end

% Startwerte Y
for j=2:1:N
    [mindist, param] = fkt_minDistParam(Y(j-1,:),Y(j,:),X(1,:));
    AccumulatedDistanceX(1,j) = Inf;
    AccumulatedDistanceY(1,j) = AccumulatedDistance(1,j-1) + mindist;
    ParamX(1,j) = NaN;
    ParamY(1,j) = param;
    minParams{1,j} = [1,0];
    minParamsX{1,j} = [NaN,NaN];
    minParamsY{1,j} = [1,0];
    AccumulatedDistance(1,j) = AccumulatedDistance(1,j-1) + fkt_euclDist(1,j,X,Y);
    if fkt_isInterpolation(ParamX(1,j)) && AccumulatedDistanceY(1,j) < AccumulatedDistance(1,j-1)
        AccumulatedDistance(1,j) = AccumulatedDistanceY(1,j) + fkt_euclDist(1,j,X,Y);
        minParams{1,j} = [1,ParamY(1,j)];
    end
end

% Erstellung der akkumulierten Kostenmatrix aller Werte
for i=2:1:M
    for j=2:1:N

        [mindist, param] = fkt_minDistParam(X(i-1,:),X(i,:),Y(j,:));
        AccumulatedDistanceX(i,j) = mindist; 
        ParamX(i,j) = param;
        [mindist, param] = fkt_minDistParam(Y(j-1,:),Y(j,:),X(i,:));
        AccumulatedDistanceY(i,j) = mindist; 
        ParamY(i,j) = param;

        minCost = Inf;
        if fkt_isInterpolation(ParamX(i,j))
            if AccumulatedDistanceX(i,j-1) < minCost && fkt_isInterpolation(ParamX(i,j-1)) && ParamX(i,j-1)<= ParamX(i,j)
                minCost = AccumulatedDistanceX(i,j-1);
                minParamsX{i,j} = [ParamX(i,j-1),0];
            elseif AccumulatedDistanceY(i-1,j) < minCost && fkt_isInterpolation(ParamY(i-1,j))
                minCost = AccumulatedDistanceY(i-1,j);
                minParamsX{i,j} = [0,ParamY(i-1,j)];
            elseif AccumulatedDistance(i-1,j) < minCost
                minCost = AccumulatedDistance(i-1,j);
                minParamsX{i,j} = [0,1];
            elseif AccumulatedDistance(i-1,j-1) < minCost && ~fkt_interpolation(ParamX(i,j-1)) && ~fkt_interpolation(ParamY(i-1,j)) && fkt_euclDist(i-1,j-1,X,Y) <= fkt_euclDist(i-1,j,X,Y)
                minCost = AccumulatedDistance(i-1,j-1);
                minParamsX{i,j} = [0, 0];
            end
        end

        AccumulatedDistanceX(i,j) = AccumulatedDistanceX(i,j) + minCost;

        minCost = Inf;
        if fkt_isInterpolation(ParamY(i, j))
            if (AccumulatedDistanceX(i, j - 1) < minCost && fkt_isInterpolation(ParamX(i, j - 1)))
                minCost = AccumulatedDistanceX(i, j - 1);
                minParamsY{i, j} = [ParamX(i, j - 1), 0];
            elseif (AccumulatedDistanceY(i - 1, j) < minCost && fkt_isInterpolation(ParamY(i - 1, j)) && ParamY(i - 1, j) <= ParamY(i, j))
                minCost = AccumulatedDistanceY(i - 1, j);
                minParamsY{i, j} = [0, ParamY(i - 1, j)];
            elseif (AccumulatedDistance(i, j - 1) < minCost)
                minCost = AccumulatedDistance(i, j - 1);
                minParamsY{i, j} = [1, 0];
            elseif (AccumulatedDistance(i - 1, j - 1) < minCost && ~fkt_isInterpolation(ParamX(i, j - 1)) && ~fkt_isInterpolation(ParamY(i - 1, j)) && fkt_euclDist(i - 1, j - 1,X,Y) <= fkt_euclDist(i, j - 1,X,Y))
                minCost = AccumulatedDistance(i - 1, j - 1);
                minParamsY{i, j} = [0, 0];
            end
        end

        AccumulatedDistanceY(i, j) = AccumulatedDistanceY(i, j) + minCost;

        minCost = inf;
        if (fkt_isInterpolation(ParamX(i, j)) && AccumulatedDistanceX(i, j) < minCost)
            minCost = AccumulatedDistanceX(i, j);
            minParams{i, j} = [ParamX(i, j), 1];
        end
        if (fkt_isInterpolation(ParamY(i, j)) && AccumulatedDistanceY(i, j) < minCost)
            minCost = AccumulatedDistanceY(i, j);
            minParams{i, j} = [1, ParamY(i, j)];
        end
        if (AccumulatedDistanceX(i, j - 1) < minCost && fkt_isInterpolation(ParamX(i, j - 1)) && fkt_euclDist(i, j,X,Y) <= fkt_euclDist(i, j - 1,X,Y) && ~fkt_isInterpolation(ParamY(i, j)) && (ParamX(i, j) < ParamX(i, j - 1) || ~fkt_isInterpolation(ParamX(i, j))))
            minCost = AccumulatedDistanceX(i, j - 1);
            minParams{i, j} = [ParamX(i, j - 1), 0];
        end
        if (AccumulatedDistanceY(i - 1, j) < minCost && fkt_isInterpolation(ParamY(i - 1, j)) && fkt_euclDist(i, j,X,Y) <= fkt_euclDist(i - 1, j,X,Y) && ~fkt_isInterpolation(ParamX(i, j)) && (ParamY(i, j) < ParamY(i - 1, j) || ~fkt_isInterpolation(ParamY(i, j))))
            minCost = AccumulatedDistanceY(i - 1, j);
            minParams{i, j} = [0, ParamY(i - 1, j)];
        end
        if (AccumulatedDistance(i, j - 1) < minCost && ~fkt_isInterpolation(ParamY(i, j)))
            minCost = AccumulatedDistance(i, j - 1);
            minParams{i, j} = [1, 0];
        end
        if (AccumulatedDistance(i - 1, j) < minCost && ~fkt_isInterpolation(ParamX(i, j)))
            minCost = AccumulatedDistance(i - 1, j);
            minParams{i, j} = [0, 1];
        end
        if (AccumulatedDistance(i - 1, j - 1) < minCost && fkt_euclDist(i, j,X,Y) <= fkt_euclDist(i - 1, j,X,Y) && fkt_euclDist(i, j,X,Y) <= fkt_euclDist(i, j - 1,X,Y) && ~fkt_isInterpolation(ParamX(i, j)) && ~fkt_isInterpolation(ParamY(i, j)) && ~fkt_isInterpolation(ParamX(i, j - 1)) && ~fkt_isInterpolation(ParamY(i - 1, j)) && fkt_euclDist(i - 1, j - 1,X,Y) <= fkt_euclDist(i - 1, j,X,Y) && fkt_euclDist(i - 1, j - 1,X,Y) <= fkt_euclDist(i, j - 1,X,Y))
            minCost = AccumulatedDistance(i - 1, j - 1);
            minParams{i, j} = [0, 0];
        end
        assert(minCost ~= inf);
        AccumulatedDistance(i, j) = minCost + fkt_euclDist(i, j,X,Y);    
    end
end

% Backtracking/ dynamische Programmierung

i = M;
j = N;

MappingIndexes = [i j];        
result = [X(i,:) Y(j,:)];

lastParam = [0 0];

while i > 1 || j > 1
    % Eckpunkt
    if (lastParam(1) == 0 && lastParam(2) == 0) || (lastParam(1) == 0 && lastParam(2) == 1) || (lastParam(1) == 1 && lastParam(2) == 0)
        lastParam = minParams{i,j};
    % Interpolationspunkt X-Kante
    elseif (lastParam(1) > 0 && lastParam(2) == 0) || (lastParam(1) > 0 && lastParam(2) == 1)
        lastParam = minParamsX{i,j};
    % Interpolationspunkt Y-Kante
    elseif (lastParam(1) == 0 && lastParam(2) > 0) || (lastParam(1) == 1 && lastParam(2) > 0) 
        lastParam = minParamsY{i,j};
    else
        error('Ungültiger Zustand.');
    end

    if i == 1
        result = [X(1,:), fkt_interpolate(Y(j - 1,:), Y(j,:), lastParam(2)); result];

    elseif j == 1
        result = [fkt_interpolate(X(i - 1,:), X(i,:), lastParam(1)), Y(1,:); result];
    else
        result = [fkt_interpolate(X(i - 1,:), X(i,:), lastParam(1)), fkt_interpolate(Y(j - 1,:), Y(j,:), lastParam(2)); result];
    end
    
    MappingIndexes = [i - 1 + lastParam(1), j - 1 + lastParam(2); MappingIndexes];
    assert(i - 1 + lastParam(1) >= 0);
    assert(j - 1 + lastParam(2) >= 0);

    if lastParam(1) == 0
        i = i - 1;
    end
    if lastParam(2) == 0
        j = j - 1;
    end
end

% Indizes der inderpolierten Bahnpunkte
ix = MappingIndexes(:,1);       
iy = MappingIndexes(:,2);
% Interpolierte Bahnen
dtw_X = result(:,[1 2 3]);
dtw_Y = result(:, [4 5 6]);

% Distanzen zwischen den interpolierten Bahnen
distances = zeros(length(dtw_X),1);
for i = 1:1:length(dtw_X)
    dist = fkt_euclDist(i,i,dtw_X,dtw_Y);
    distances(i,1) = dist;
end
% maximale und mittlere Distanz 
maxDistance = max(distances);
averageDistance = mean(distances);
minDistance = min(distances);
%% Visualiesierung

if pflag

% 
% Farben Für Bahnvergleich
blau = [0 0.4470 0.7410]; % Standard Blau
rot = [0.78 0 0];

% Für Plots Verfahren
c1 = [0 0.4470 0.7410];
c2 = [0.8500 0.3250 0.0980];
c3 = [0.9290 0.6940 0.1250];
c4 = [0.4940 0.1840 0.5560];
c5 = [0.4660 0.6740 0.1880];
c6 = [0.3010 0.7450 0.9330];
c7 = [0.6350 0.0780 0.1840];

% 2D Visualisierung der akkumulierten Kosten samt Mapping 
    figure('Name','SelectiveInterpolationDTW - Kostenkarte und optimaler Pfad','NumberTitle','off');
    hold on
    % main=subplot('Position',[0.19 0.19 0.67 0.79]);           
    imagesc(AccumulatedDistance)
    colormap("turbo"); % colormap("turbo");
    colorb = colorbar;
    colorb.Label.String = 'Akkumulierte Kosten';
    plot(iy, ix,"-w","LineWidth",1)
    xlabel('Pfad Y [Index]');
    ylabel('Pfad X [Index]');
    axis([min(iy) max(iy) 1 max(ix)]);
    set(gca,'FontSize',10,'YDir', 'normal');

% Plot der beiden Bahnen und Zuordnung
% figure('Color','white');
% hold on
% plot3(ist(:,1),ist(:,2),ist(:,3),Color= c1,LineWidth=1.5,Marker = "o",MarkerFaceColor= c1)
% plot3(soll(:,1),soll(:,2),soll(:,3),Color= rot,LineWidth=1.5,Marker = "square",MarkerFaceColor=rot)
    figure('Color','white','Name','SelectiveInterpolationDTW - Zuordnung der Bahnpunkte','NumberTitle','off')
    hold on;
    grid on;
    box on;
    plot3(dtw_X(:,1),dtw_X(:,2),dtw_X(:,3),Color= rot,LineWidth=1.5,Marker = "square",MarkerFaceColor=rot,MarkerSize=4);
    plot3(dtw_Y(:,1),dtw_Y(:,2),dtw_Y(:,3),Color= c1,LineWidth=1.5,Marker = "o",MarkerFaceColor= c1,MarkerSize=4);
    for i = 1:1:length(dtw_X)
        line([dtw_Y(i,1),dtw_X(i,1)],[dtw_Y(i,2),dtw_X(i,2)],[dtw_Y(i,3),dtw_X(i,3)],'Color','black')
    end
    view(300, 40)
    legend({'Sollbahn','Istbahn','Abweichung'},'Location','northeast',"FontWeight", "bold")
    xlabel("x [mm]","FontWeight","bold")
    ylabel("y [mm]","FontWeight","bold")
    zlabel("z [mm]","FontWeight","bold")
    hold off
    axis padded
 end

end

% assignin("base",'sidtw_min_distance',minDistance)

