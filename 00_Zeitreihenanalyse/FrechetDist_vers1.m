%% FrechetDist_vers1 

% load iso_path_C_1.mat

% Rechteck
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

pflag = 1;

%% Berechnung Frechet-Distanz in 3D

% Prüfen ob Vergleich der Zeitreihen möglich ist
if dim_X ~= dim_Y
    error('Die Bahnen müssen die gleiche Dimension haben')
elseif M == 0
    disp('Keine Punkte in Sollbahn vorhanden! Sollbahn muss generiert werden!')
    frechet_dist = 0;
    return;
end

% Berechnung der Frechet-Matrix
frechet_matrix = zeros(M, N);
for i = 1:M
    for j = 1:N
        if i == 1 && j == 1
            frechet_matrix(i,j) = fkt_euclDist(1,1,X,Y);                      
        elseif i > 1 && j == 1
            frechet_matrix(i,j) = max( frechet_matrix(i-1, 1), fkt_euclDist(i,1,X,Y)); 
        elseif i == 1 && j > 1
            frechet_matrix(i,j) = max( frechet_matrix(1, j-1), fkt_euclDist(1,j,X,Y));
        elseif i > 1 && j > 1
            frechet_matrix(i,j) = max( min([frechet_matrix(i-1, j), frechet_matrix(i-1, j-1), frechet_matrix(i, j-1)]), fkt_euclDist(i,j,X,Y));
        else
            frechet_matrix(i,j) = inf;
        end
    end
end

% Maximale Distanz zwischen zwei zugeordneten Punkten
frechet_dist = frechet_matrix(end,end);

% Finden der Zuordnungssequenz durch Backtracking 
frechet_path = zeros(N + M + 1, 2);  
frechet_matrix2 = [ones(1, N + 1) * inf; [ones(M, 1) * inf frechet_matrix]];  
xi = M + 1;
yj = N + 1;
count = 1;
% Ermittlung der minimalen Kosten pro Schritt durch die Kostenmatrix
while xi > 2 || yj > 2
    [~, index] = min([frechet_matrix2(xi - 1, yj) frechet_matrix2(xi - 1, yj - 1) frechet_matrix2(xi, yj - 1)]);
    if index == 1
        frechet_path(count, :) = [xi - 1 yj];
        xi = xi - 1;
    elseif index == 2
        frechet_path(count, :) = [xi - 1 yj - 1];
        xi = xi - 1; yj = yj - 1;
    elseif index == 3
        frechet_path(count, :) = [xi yj - 1];
        yj = yj - 1;
    end
    count = count + 1;
end

frechet_path = flip(frechet_path);                          % Umdrehen 
lastZero = find(frechet_path(:, 1) == 0, 1, 'last');        % Index der letzten Nullzeile
frechet_path = frechet_path(lastZero+1:end, :);             % Nullzeilen löschen
frechet_path = frechet_path -1;                             % Subtrahiere 1 von allen Indizes
frechet_path = [frechet_path; M N];                         % Füge das letzte Wertepaar hinzu

% Euklidische Distanz zwischen allen Punktpaaren der Zuordnungssequenz
frechet_distances = sqrt(sum((X(frechet_path(:,1),:) - Y(frechet_path(:,2),:)).^2,2));

% frechet_distances1 = zeros(length(frechet_path),1);
% for i = 1:1:length(frechet_path)
%     frechet_distances1(i) = norm(X(frechet_path(i,1),:)-Y(frechet_path(i,2),:));
% end
% IsEQUAL = frechet_distances1 -frechet_distances;

av_frechet = mean(frechet_distances);

%% Plot

if pflag 
figure('Name','Discrete Frechet Distance')
hold on
plot3(X(:,1),X(:,2),X(:,3),'o-b','linewidth',2,'markerfacecolor','b')
plot3(Y(:,1),Y(:,2),Y(:,3),'o-r','linewidth',2,'markerfacecolor','r')
for j=1:length(frechet_path)
  line([X(frechet_path(j,1),1) Y(frechet_path(j,2),1)],...
       [X(frechet_path(j,1),2) Y(frechet_path(j,2),2)],...
       [X(frechet_path(j,1),3) Y(frechet_path(j,2),3)],...
       'color','black');
end
[~,j] = max(frechet_distances);
line([X(frechet_path(j,1),1) Y(frechet_path(j,2),1)],...
       [X(frechet_path(j,1),2) Y(frechet_path(j,2),2)],...
       [X(frechet_path(j,1),3) Y(frechet_path(j,2),3)],...
       'color','black','linewidth',3);
j = length(frechet_path);
line([X(frechet_path(j,1),1) Y(frechet_path(j,2),1)],...
       [X(frechet_path(j,1),2) Y(frechet_path(j,2),2)],...
       [X(frechet_path(j,1),3) Y(frechet_path(j,2),3)],...
       'color',[0 0.8 0.5],'linewidth',3);
% j = length(frechet_path)-1;
% line([X(frechet_path(j,1),1) Y(frechet_path(j,2),1)],...
%        [X(frechet_path(j,1),2) Y(frechet_path(j,2),2)],...
%        [X(frechet_path(j,1),3) Y(frechet_path(j,2),3)],...
%        'color',[0.8 0.5 0],'linewidth',3);
end

%% Lösche Variablen

% clear x_soll x_ist y_soll y_ist z_soll z_ist t_soll t_ist i j data 
% clear M N dim_X dim_Y count xi yj mindist index