%% Laden der Trajektorien 

clear all 

load('robotdata_ist.mat');
load('robotdata_soll.mat');

data_odom = table2array(robotdata_ist);
data_soll = table2array(robotdata_soll);

pathX = data_soll;
pathY = data_odom;

M = length(pathX);
N = length(pathY);

clear data_odom data_soll robotdata_ist robotdata_soll

%% CDTW

% Initalisierung der Arrays
AccumulatedDistance = zeros(M,N);
AccumulatedDistanceX = zeros(M,N);
AccumulatedDistanceY = zeros(M,N);
paramX = zeros(M,N);
paramY = zeros(M,N);

% Ausgangsposition
AccumulatedDistance(1,1) = euclDist(1,1,pathX,pathY);
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
[mindist, param] = minDistParam(pathX(1,:),pathX(2,:),pathY(2,:));
AccumulatedDistanceX(2,2) = AccumulatedDistanceX(1,1) + mindist;
paramX(2,2) = param;
[mindist, param] = minDistParam(pathY(1,:),pathY(2,:),pathX(2,:));
AccumulatedDistanceY(2,2) = AccumulatedDistanceY(1,1) + mindist;
paramY(2,2) = param;







%% Funktionen

% Berechnung des euclidischen Abstandes zwischen zwei Punkten
function distance = euclDist(i, j, pathX, pathY)
    distance = norm(pathX(i,:) - pathY(j,:));
end

% Berechnung des geringsten Abstands zwischen Bahnsegmet und Punkt
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