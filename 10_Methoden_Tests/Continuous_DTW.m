%% Laden der Trajektorien

clear all
% Laden der Trajektorien
% load circle1.mat
load iso_path_A_1.mat

pathX = soll'; 
pathY = ist';

% Plot erstellen
pflag = 1;
if pflag

figure
hold on

plot3(pathX(1,:), pathX(2,:), pathX(3,:), 'b','Marker','o', 'LineWidth', 2);
plot3(pathX(1,1), pathX(2,1), pathX(3,1), 'g','Marker','o', 'LineWidth', 10);

plot3(pathY(1,:), pathY(2,:), pathY(3,:), 'r','Marker','o', 'LineWidth', 2);
plot3(pathY(1,1), pathY(2,1), pathY(3,1), 'k','Marker','o', 'LineWidth', 10);

xlabel('X-Koordinate');
ylabel('Y-Koordinate');
zlabel('Z-Koordinate')
title('Vergleich zweier Zeitreihen');
legend;
grid on;
axis padded;
view(3)
hold off

end


% Benötigte Arrays
AccumulatedDistanceX = zeros(length(pathX), length(pathY));
AccumulatedDistanceY = zeros(length(pathX), length(pathY));
paramX = zeros(length(pathX), length(pathY));
paramY = zeros(length(pathX), length(pathY));
path = {};
pathIndexes = [];
% Ausgangsposition 
AccumulatedDistanceX(1,1) = euclDist(1,1,pathX,pathY);
AccumulatedDistanceY(1,1) = euclDist(1,1,pathX,pathY);

% Akkumuliere die Abstände/Kosten von pathX ausgehend von der ersten X-Position (1. Spalte)
% Berechnung der euklidischen Abstände aller Punkte von pathX zur 1. Position von pathY 
% Zuordnung aller Punkte von pathX auf 1. Position von pathY
for i=2:length(pathX)
    AccumulatedDistanceX(i,1) = AccumulatedDistanceX(i-1,1) + euclDist(i,1,pathX,pathY);
    AccumulatedDistanceY(i,1) = AccumulatedDistanceX(i,1);
end
% Akkumuliere die Abstände/Kosten von pathY ausgehend von der ersten Y-Position (1. Zeile)
% Berechnung der euklidischen Abstände aller Punkte von pathY zur 1. Position von pathX 
% Zuordnung aller Punkte von pathY auf 1. Position von pathX
for j=2:length(pathY)
    AccumulatedDistanceX(1,j) = AccumulatedDistanceX(1,j-1) + euclDist(1,j,pathX,pathY);
    AccumulatedDistanceY(1,j) = AccumulatedDistanceX(1,j);
end

% Akkumuliere den ersten geringsten Abstand/Kosten ausgehend vom Startpunkt
[mindist, param] = minDistParam(pathX(:,1),pathX(:,2),pathY(:,2));
AccumulatedDistanceX(2,2) = AccumulatedDistanceX(1,1) + mindist;
paramX(2,2) = param;
[mindist, param] = minDistParam(pathY(:,1),pathY(:,2),pathX(:,2));
AccumulatedDistanceY(2,2) = AccumulatedDistanceY(1,1) + mindist;
paramY(2,2) = param;

% Akkumuliere alle weiteren Ausgangswerte von pathX und Y (2. Spalte und Zeile)
for i = 3:length(pathX)
    [mindist, param] = minDistParam(pathX(:,i-1),pathX(:,i),pathY(:,2));
    AccumulatedDistanceX(i,2) = AccumulatedDistanceX(i-1, 1) + mindist;
    paramX(i,2) = param;
    [mindist, param] = minDistParam(pathY(:,1),pathY(:,2),pathX(:,i));
    AccumulatedDistanceY(i,2) = AccumulatedDistanceY(i-1, 1) + mindist;
    paramY(i,2) = param;
end
% Zuordnung aller Werte von pathY auf den 2. Wert von pathX
for j = 3:length(pathY)
    [mindist, param] = minDistParam(pathX(:,1),pathX(:,2),pathY(:,j));
    AccumulatedDistanceX(2,j) = AccumulatedDistanceX(1, j-1) + mindist;
    paramX(2,j) = param;
    [mindist, param] = minDistParam(pathY(:,j-1),pathY(:,j),pathX(:,2));
    AccumulatedDistanceY(2,j) = AccumulatedDistanceY(1, j-1) + mindist;
    paramY(2,j) = param;
end

for i = 3:length(pathX)
    for j = 3:length(pathY)
        % Prüfung ob der akkumulierte Abstand X an voheriger Position
        % kürzer ist als der akkumulierte Abstand Y
        if AccumulatedDistanceX(i,j-1) < AccumulatedDistanceY(i-1,j)
            % X Abstand geringer: Addiere zu dem Abstand des vorherigen X die X und Y Abstände  
            [mindist, param] = minDistParam(pathX(:,i-1), pathX(:,i), pathY(:,j));
            AccumulatedDistanceX(i,j) = AccumulatedDistanceX(i,j-1) + mindist;
            paramX(i,j) = param;
            [mindist, param] = minDistParam(pathY(:,j-1), pathY(:,j), pathX(:,i));
            AccumulatedDistanceY(i,j) = AccumulatedDistanceY(i,j-1) + mindist;
            paramY(i,j) = param; 
        else
            % Y Abstand geringer: Addiere zu dem Abstand des vorherigen Y die X und Y Abstände  
            [mindist, param] = minDistParam(pathX(:,i-1), pathX(:,i), pathY(:,j));
            AccumulatedDistanceX(i,j) = AccumulatedDistanceY(i-1,j) + mindist;
            paramX(i,j) = param;
            [mindist, param] = minDistParam(pathY(:,j-1), pathY(:,j), pathX(:,i));
            AccumulatedDistanceY(i,j) = AccumulatedDistanceY(i-1,j) + mindist;
            paramY(i,j) = param;
        end
    end
end

clear param mindist

% AccX: Zeile  --> Zuordnung der Bahnsegmente Xi-Xi-1 auf Punkt Y
% AccX: Spalte --> Zuordnung der Punkte Yi auf Bahnsegment X
% AccY: Zeile  --> Zuordnung der Punkte Xi auf Bahnsegment Y
% AccY: Spalte --> Zuordnung der Bahnsegmente Yi-Yi-1 auf Punkt X

%% Backtracking


while i > 1 || j > 1
    if i == 1
        j = j - 1;
    elseif j == 1
        i = i - 1;
    else
        pathIndexes{end+1} = [i,j];
        if AccumulatedDistanceX(i,j-1) < AccumulatedDistanceY(i-1,j)
            % Berechnung des nächsten Punktes
            nextX = pathX(:,i-1) + (pathX(:,i) - pathX (:,i-1)) * paramX(i,j-1);
            path{end+1} = [nextX, pathY(:,j-1)];
            if paramX(i,j-1) == 0
                i = i - 1;
            end
            j = j - 1;
        else
            % Berechnung des nächsten Punktes 
            nextY = pathY(:,j-1) + (pathY(:,j) - pathY(:,j-1) * paramY(i-1,j));
            path{end+1} = [pathX(:,i-1), nextY];
            if paramY(i-1,j) == 0
                j = j-1;
            end
            i = i-1;
        end
    end
end

% Aus den Cell-Array's Matrizen machen
pathVector = cell2mat(pathIndexes)';                % Transformation in Spaltenvektor
indexes = zeros(length(pathIndexes),2);
for k = 2:2:length(pathVector)
        indexes(k,1) = pathVector(k-1);
        indexes(k,2) = pathVector(k);
end
indexes(all(indexes == 0, 2), :) = [];              % Nullzeilen löschen
indexes = flip(indexes);
ix = indexes(:,1);
iy = indexes(:,2);

x = pathX(:,ix);
y = pathY(:,iy);

clear k i j nextX nextY

%% Plotten des Mapping Pfades und der Kostenmatrix

if pflag

figure('Name','DTW - Akkumulierte Distanz','NumberTitle','off');
surf(AccumulatedDistanceY)
hold on           
imagesc(AccumulatedDistanceY)
colormap("jet");
xlabel('Pfad Y [Index]');
ylabel('Pfad X [Index]');
zlabel('Akkumulierte Kosten')
axis padded;

figure('Name','Continuous DTW mit Mapping','NumberTitle','off');

% main=subplot('Position',[0.19 0.19 0.67 0.79]);           
imagesc(AccumulatedDistanceX)
colormap("jet"); % colormap("turbo");
colorb = colorbar;
colorb.Label.String = 'Akkumulierte Kosten';

% --------To-Do: Colorbar normen auf 1----------
% set(colorb,'FontSize',10,'YTickLabel','');
% set(colorb,'FontSize',10;
hold on
plot(iy,ix,"-w","LineWidth",1)
xlabel('Pfad Y [Index]');
ylabel('Pfad X [Index]');
axis([min(iy) max(iy) 1 max(ix)]);
% axis([1 length(pathY) 1 length(pathX)])
set(gca,'FontSize',10,'YDir', 'normal');                          % Y-Achse umdrehen damit von unten nach oben! 

end

M = length(pathX);
N = length(pathY);


% figure('Name','Verzerrte Signale', 'NumberTitle','off');
% 
% subplot(1,2,1);
% hold on;
% plot3(pathX(1,:),pathX(2,:),pathX(3,:),'-bx', 'LineWidth', 2);
% %plot3(pathY(1,:),pathY(2,:),pathY(3,:),':r.','LineWidth', 2);
% hold off;
% %    axis([1 max(M,N) min(min(pathX),min(pathY)) 1.1*max(max(pathX),max(pathY))]);
% grid on;
% legend('signal 1','signal 2');
% title('Original signals');
% xlabel('x');
% ylabel('y');
% zlabel('z');
% view(3);

% subplot(1,2,2);
% hold on;
% plot3(x(1,:),x(2,:),x(3,:),'-bx', 'LineWidth', 2);
% %plot3(y(1,:),y(2,:),y(3,:),':r.','LineWidth', 2);
% hold off;
% %    axis([1 max(M,N) min(min(pathX),min(pathY)) 1.1*max(max(pathX),max(pathY))]);
% grid on;
% legend('signal 1','signal 2');
% title('Original signals');
% xlabel('x');
% ylabel('y');
% zlabel('z');
% view(3);


%% Berechnung des geringsten Abstands zwischen Bahnsegmet und Punkt
function [mindist, param] = minDistParam(x1, x2, y)
    dx = x2-x1;                                     % Bahnsegment 
    dy = y-x1;                                      % Abstand Punkt-Bahnsegment
    dxy = (dot(dy,dx)/(norm(dx)^2))*dx;             % Projektion dy auf dx
    angle = dot(dx,dxy)/(norm(dx)*norm(dxy));       % Cosinus zwischen dx und dxy
    if dot(dx,dy) == 0 || angle < 0                 % Zuordnung y-x1 (x1 liegt hinter y oder orthogonal)
        param = 0;
        mindist = norm(dy); 
    else
        param = norm(dxy)/norm(dx);                 % Liegt dxy zwischen x1 und x2 ?    
        if param > 1                                % nein --> Zuordnung y-x2
            param = 1;
            mindist = norm(y-x2);                   
        else                                        % ja --> Zuordnung y-x'
            mindist = norm(y-(x1+dxy));
        end
    end
end


%% Berechnung des Euklidischen Abstands zwischen 2 Punkten
function euclDist = euclDist(i,j,pathX, pathY)
    euclDist = norm(pathX(:,i) - pathY(:,j));
end
