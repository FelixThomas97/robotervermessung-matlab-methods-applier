%% Trajektorien Laden 

clear all

% load iso_path_A_1.mat
% load circle1.mat
load iso_path_B_real_1.mat
% load trajectoryrobot017139657492242258.mat
%%
% data = table2array(trajectoryrobot017139657492242258);
% 
% % Extrahieren Ist- und Sollbahnen mit Zeitstempeln und kartesischen Koordinaten
% x_ist = data(:,2);
% y_ist = data(:,3);
% z_ist = data(:,4);
% t_ist = data(:,1)/10^9;
% 
% x_soll = data(:,10);
% y_soll = data(:,11);
% z_soll = data(:,12);
% t_soll = data(:,9)/10^9;
% 
% bahn_ist = [x_ist y_ist z_ist];
% bahn_soll = [x_soll y_soll z_soll];
% bahn_ist = bahn_ist(~any(isnan(bahn_ist),2),:);
% bahn_soll = bahn_soll(~any(isnan(bahn_soll),2),:);
% 
% X = bahn_soll;
% Y = bahn_ist;

%%
% load('robotdata_ist.mat');
% load('robotdata_soll.mat');
% 
% data_odom = table2array(robotdata_ist);
% data_soll = table2array(robotdata_soll);
% 
figureson = 1;
% 
% X = data_soll;
% Y = data_odom;
% 
X = soll; 
Y = ist;
%%
M = length(X);
N = length(Y);

clear soll ist

%% Initialisierung der benötigten Variablein

AccumulatedDistance = zeros(M,N);
AccumulatedDistanceX = zeros(M,N);
AccumulatedDistanceY = zeros(M,N);
ParamX = zeros(M,N);
ParamY = zeros(M,N);
minParams = cell(M,N);
minParamsX = cell(M,N);
minParamsY = cell(M,N);

% Initialisierung der Anfangsbedingungen

AccumulatedDistance(1,1) = euclDist(1,1,X,Y);
AccumulatedDistanceX(1,1) = Inf;
AccumulatedDistanceY(1,1) = Inf;
ParamX(1,1) = NaN;
ParamY(1,1) = NaN;
minParams{1, 1} = [NaN, NaN];
minParamsX{1, 1} = [NaN, NaN];
minParamsY{1, 1} = [NaN, NaN];

% Folgende Variablen nur für Testzwecke
a0 = 0;
a1 = 0;
a2 = 0;
a3 = 0;
a4 = 0;
b0 = 0;
b1 = 0;
b2 = 0;
b3 = 0;
b4 = 0;
c1 = 0;
c2 = 0;
c3 = 0;
c4 = 0;
c5 = 0;
c6 = 0;
c7 = 0;


% Startwerte X
for i=2:1:M
    [mindist, param] = minDistParam(X(i-1,:),X(i,:),Y(1,:));
    AccumulatedDistanceX(i,1) = AccumulatedDistanceX(i-1,1) + mindist;
    AccumulatedDistanceY(i,1)= Inf;
    ParamX(i,1) = param;
    ParamY(i,1) = NaN;
    minParams{i,1} = [0,1];
    minParamsX{i,1} = [0,1];
    minParamsY{i,1} = [NaN,NaN];
    AccumulatedDistance(i,1) = AccumulatedDistance(i-1,1) + euclDist(i,1,X,Y);
    if IsInterpolation(ParamX(i,1)) && AccumulatedDistanceX(i,1) < AccumulatedDistance(i-1,1)
        AccumulatedDistance(i,1) = AccumulatedDistanceX(i,1) + euclDist(i,1,X,Y);
        minParams{i,1} = [ParamX(i,1),1];
        a0 = a0+1;
    end
end
% Startwerte Y
for j=2:1:N
    [mindist, param] = minDistParam(Y(j-1,:),Y(j,:),X(1,:));
    AccumulatedDistanceX(1,j) = Inf;
    AccumulatedDistanceY(1,j) = AccumulatedDistance(1,j-1) + mindist;
    ParamX(1,j) = NaN;
    ParamY(1,j) = param;
    minParams{1,j} = [1,0];
    minParamsX{1,j} = [NaN,NaN];
    minParamsY{1,j} = [1,0];
    AccumulatedDistance(1,j) = AccumulatedDistance(1,j-1) + euclDist(1,j,X,Y);
    if IsInterpolation(ParamX(1,j)) && AccumulatedDistanceY(1,j) < AccumulatedDistance(1,j-1)
        AccumulatedDistance(1,j) = AccumulatedDistanceY(1,j) + euclDist(1,j,X,Y);
        minParams{1,j} = [1,ParamY(1,j)];
        b0 = b0+1;
    end
end

% Erstellung der akkumulierten Kostenmatrix aller Werte
for i=2:1:M
    for j=2:1:N

        [mindist, param] = minDistParam(X(i-1,:),X(i,:),Y(j,:));
        AccumulatedDistanceX(i,j) = mindist; 
        ParamX(i,j) = param;
        [mindist, param] = minDistParam(Y(j-1,:),Y(j,:),X(i,:));
        AccumulatedDistanceY(i,j) = mindist; 
        ParamY(i,j) = param;

        minCost = Inf;
        if IsInterpolation(ParamX(i,j))
            if AccumulatedDistanceX(i,j-1) < minCost && IsInterpolation(ParamX(i,j-1)) && ParamX(i,j-1)<= ParamX(i,j)
                minCost = AccumulatedDistanceX(i,j-1);
                minParamsX{i,j} = [ParamX(i,j-1),0];
                a1 = a1+1;
            elseif AccumulatedDistanceY(i-1,j) < minCost && IsInterpolation(ParamY(i-1,j))
                minCost = AccumulatedDistanceY(i-1,j);
                minParamsX{i,j} = [0,ParamY(i-1,j)];
                a2 = a2+1;
            elseif AccumulatedDistance(i-1,j) < minCost
                minCost = AccumulatedDistance(i-1,j);
                minParamsX{i,j} = [0,1];
                a3 = a3+1;
            elseif AccumulatedDistance(i-1,j-1) < minCost && ~IsInterpolation(ParamX(i,j-1)) && ~IsInterpolation(ParamY(i-1,j)) && euclDist(i-1,j-1,X,Y) <= euclDist(i-1,j,X,Y)
                minCost = AccumulatedDistance(i-1,j-1);
                minParamsX{i,j} = [0, 0];
                a4 = a4+1;
            end
        end

        AccumulatedDistanceX(i,j) = AccumulatedDistanceX(i,j) + minCost;

        minCost = Inf;
        if IsInterpolation(ParamY(i, j))
            if (AccumulatedDistanceX(i, j - 1) < minCost && IsInterpolation(ParamX(i, j - 1)))
                minCost = AccumulatedDistanceX(i, j - 1);
                minParamsY{i, j} = [ParamX(i, j - 1), 0];
                b1 = b1 +1;
            elseif (AccumulatedDistanceY(i - 1, j) < minCost && IsInterpolation(ParamY(i - 1, j)) && ParamY(i - 1, j) <= ParamY(i, j))
                minCost = AccumulatedDistanceY(i - 1, j);
                minParamsY{i, j} = [0, ParamY(i - 1, j)];
                b2 = b2 +1;
            elseif (AccumulatedDistance(i, j - 1) < minCost)
                minCost = AccumulatedDistance(i, j - 1);
                minParamsY{i, j} = [1, 0];
                b3 = b3 +1;
            elseif (AccumulatedDistance(i - 1, j - 1) < minCost && ~IsInterpolation(ParamX(i, j - 1)) && ~IsInterpolation(ParamY(i - 1, j)) && euclDist(i - 1, j - 1,X,Y) <= euclDist(i, j - 1,X,Y))
                minCost = AccumulatedDistance(i - 1, j - 1);
                minParamsY{i, j} = [0, 0];
                b4 = b4 +1;
            end
        end

        AccumulatedDistanceY(i, j) = AccumulatedDistanceY(i, j) + minCost;

        minCost = inf;
        if (IsInterpolation(ParamX(i, j)) && AccumulatedDistanceX(i, j) < minCost)
            minCost = AccumulatedDistanceX(i, j);
            minParams{i, j} = [ParamX(i, j), 1];
            c1 = c1 + 1;
        end
        if (IsInterpolation(ParamY(i, j)) && AccumulatedDistanceY(i, j) < minCost)
            minCost = AccumulatedDistanceY(i, j);
            minParams{i, j} = [1, ParamY(i, j)];
            c2 = c2 + 1;
        end
        if (AccumulatedDistanceX(i, j - 1) < minCost && IsInterpolation(ParamX(i, j - 1)) && euclDist(i, j,X,Y) <= euclDist(i, j - 1,X,Y) && ~IsInterpolation(ParamY(i, j)) && (ParamX(i, j) < ParamX(i, j - 1) || ~IsInterpolation(ParamX(i, j))))
            minCost = AccumulatedDistanceX(i, j - 1);
            minParams{i, j} = [ParamX(i, j - 1), 0];
            c3 = c3 + 1;
        end
        if (AccumulatedDistanceY(i - 1, j) < minCost && IsInterpolation(ParamY(i - 1, j)) && euclDist(i, j,X,Y) <= euclDist(i - 1, j,X,Y) && ~IsInterpolation(ParamX(i, j)) && (ParamY(i, j) < ParamY(i - 1, j) || ~IsInterpolation(ParamY(i, j))))
            minCost = AccumulatedDistanceY(i - 1, j);
            minParams{i, j} = [0, ParamY(i - 1, j)];
            c4 = c4 + 1;
        end
        if (AccumulatedDistance(i, j - 1) < minCost && ~IsInterpolation(ParamY(i, j)))
            minCost = AccumulatedDistance(i, j - 1);
            minParams{i, j} = [1, 0];
            c5 = c5 + 1;
        end
        if (AccumulatedDistance(i - 1, j) < minCost && ~IsInterpolation(ParamX(i, j)))
            minCost = AccumulatedDistance(i - 1, j);
            minParams{i, j} = [0, 1];
            c6 = c6 + 1;
        end
        if (AccumulatedDistance(i - 1, j - 1) < minCost && euclDist(i, j,X,Y) <= euclDist(i - 1, j,X,Y) && euclDist(i, j,X,Y) <= euclDist(i, j - 1,X,Y) && ~IsInterpolation(ParamX(i, j)) && ~IsInterpolation(ParamY(i, j)) && ~IsInterpolation(ParamX(i, j - 1)) && ~IsInterpolation(ParamY(i - 1, j)) && euclDist(i - 1, j - 1,X,Y) <= euclDist(i - 1, j,X,Y) && euclDist(i - 1, j - 1,X,Y) <= euclDist(i, j - 1,X,Y))
            minCost = AccumulatedDistance(i - 1, j - 1);
            minParams{i, j} = [0, 0];
            c7 = c7 + 1;
        end
        assert(minCost ~= inf);
        AccumulatedDistance(i, j) = minCost + euclDist(i, j,X,Y);
        summeabc = a0 + b0 + a1 + a2 + a3+ a4 + b1 + b2 + b3 + b4 + c1 + c2+ c3 + c4 + c5 + c6 +c7;     
    end
end
clear a0 b0 a1  a2 a3 a4  b1  b2  b3  b4  c1 c2 c3  c4  c5  c6 c7;     
%%

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
        result = [X(1,:), Interpolate(Y(j - 1,:), Y(j,:), lastParam(2)); result];

    elseif j == 1
        result = [Interpolate(X(i - 1,:), X(i,:), lastParam(1)), Y(1,:); result];
    else
        result = [Interpolate(X(i - 1,:), X(i,:), lastParam(1)), Interpolate(Y(j - 1,:), Y(j,:), lastParam(2)); result];
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
dtwX = result(:,[1 2 3]);
dtwY = result(:, [4 5 6]);

% Distanzen zwischen den interpolierten Bahnen
distances = zeros(length(dtwX),1);
for i = 1:1:length(dtwX)
    dist = euclDist(i,i,dtwX,dtwY);
    distances(i,1) = dist;
end
% maximale und mittlere Distanz 
maxDistance = max(distances)
averageDistance = mean(distances)

%% Visualisierung

if figureson

    % Plot der Rohdaten und der interpolierten Bahn
    figure('Name','SelectIntDTW - Vergleich der Bahnen', 'NumberTitle','off');     
    subplot(1,2,1);
    hold on;
    plot3(X(:,1),X(:,2),X(:,3),'-bo', 'LineWidth', 1);
    plot3(Y(:,1),Y(:,2),Y(:,3),'-ro','LineWidth', 1);
    plot3(X(1,1), X(1,2), X(1,3), 'k','Marker','o', 'LineWidth', 10);
    hold off;
    axis padded;
    box on;
    grid on;
    legend('X','Y','Startpunkt');
    title('Original Bahnpunkte');
    xlabel('x');
    ylabel('y');
    zlabel('z');
    view(3);

    subplot(1,2,2);
    hold on;
    plot3(dtwX(:,1),dtwX(:,2),dtwX(:,3),'-bo', 'LineWidth', 1);
    plot3(dtwY(:,1),dtwY(:,2),dtwY(:,3),'-ro','LineWidth', 1);
    plot3(dtwX(1,1),dtwX(1,2),dtwX(1,3), 'k','Marker','o', 'LineWidth', 10);
    hold off;
    axis padded;
    grid on;
    legend('X','Y','Startpunkt');
    title('Durch DTW interpolierte Bahnpunkte');
    xlabel('x');
    ylabel('y');
    zlabel('z');
    view(3);

    % 3D Visualisierung der akkumulierten Distanzen 
    figure('Name','SelectIntDTW - Akkumulierte Distanz','NumberTitle','off');
    surf(AccumulatedDistance)
    hold on           
    imagesc(AccumulatedDistance)
    colormap("jet");
    xlabel('Pfad Y [Index]');
    ylabel('Pfad X [Index]');
    zlabel('Akkumulierte Kosten')
    axis padded;
    
    % 2D Visualisierung der akkumulierten Kosten samt Mapping 
    figure('Name','SelectIntDTW - Kostenkarte und optimaler Pfad','NumberTitle','off');
    hold on
    % main=subplot('Position',[0.19 0.19 0.67 0.79]);           
    imagesc(AccumulatedDistance)
    colormap("jet"); % colormap("turbo");
    colorb = colorbar;
    colorb.Label.String = 'Akkumulierte Kosten';
    plot(iy, ix,"-w","LineWidth",1)
    xlabel('Pfad Y [Index]');
    ylabel('Pfad X [Index]');
    axis([min(iy) max(iy) 1 max(ix)]);
    set(gca,'FontSize',10,'YDir', 'normal');

    % 3D - Visualierung der Zuordnung der Bahnpunkte
    figure('Name','SelectIntDistance - Zuordnung der Bahnpunkte','NumberTitle','off')
    hold on;
    plot3(dtwX(:,1),dtwX(:,2),dtwX(:,3),'-ko', 'LineWidth', 1);
    plot3(dtwY(:,1),dtwY(:,2),dtwY(:,3),'-ro','LineWidth', 1);
    for i = 1:1:length(dtwX)
        line([dtwY(i,1),dtwX(i,1)],[dtwY(i,2),dtwX(i,2)],[dtwY(i,3),dtwX(i,3)],'Color','red')
    end
    hold off;
    xlim auto
    ylim auto
    legend({'Soll-Bahn','Ist-Bahn'},'Location','northeast')
    fontsize(gca,20,"pixels")
    zlim auto;
    box on
    grid on
    view(3)
    xlabel("x [cm]","FontWeight","bold")
    ylabel("y [cm]","FontWeight","bold")
    zlabel("z [cm]","FontWeight","bold")

end 

    pflag = 0;
    [selintdtw_distances, selintdtw_max, selintdtw_av, selintdtw_accdist, selintdtw_X, selintdtw_Y, selintdtw_path, ix, iy] = fkt_selintdtw3d(X, Y,pflag);

    selintdtw_av
    selintdtw_max


     

%% Funktionen

% Berechnung des euclidischen Abstandes zwischen zwei Punkten
function distance = euclDist(i, j, pathX, pathY)
    distance = norm(pathX(i,:) - pathY(j,:));
end

% Berechnung des geringsten Abstands zwischen Bahnsegmet und Punkt (etwas abgeändert zu CDTW)
function [mindist, param] = minDistParam(x1, x2, y)
    dx = x2-x1;                                     % Bahnsegment 
    dy = y-x1;                                      % Abstand Punkt-Bahnsegment
    dxy = (dot(dy,dx)/(norm(dx)^2))*dx;             % Projektion dy auf dx
    if dot(dx,dy) > 0                               % gleiche Richtung: Winkel < 90°                              
        param = norm(dxy)/norm(dx);        
        if param > 1                               
            mindist = Inf;
        else
            mindist = norm(y-(x1+dxy));
        end
    elseif dot(dx,dy) == 0                          % senkrecht: Winkel = 90°;
        param = 0;
        mindist = norm(dy); 
    else                                            % entgegengesetze Richtung: Winkel > 90°
        param = -norm(dxy)/norm(dx);                 
        mindist = Inf;
    end
end

% Prüfen ob übergebener Parameter zwischen Null und Eins liegt
function result = IsInterpolation(param)
    result = param > 0 && param < 1;
end

% Berechnung der interpolierten Positionen
function interpolatedPosition = Interpolate(start, ende, parameter)
    interpolatedPosition = start + (ende - start) * parameter;
end
