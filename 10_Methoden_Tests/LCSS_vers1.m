% % Test Test Test
clear;
load "data_robot01719160237_3".mat

% Daten Extrahieren
x = cell2mat(data.x_ist); y = cell2mat(data.y_ist); z = cell2mat(data.z_ist);
trajectory_ist = [x;y;z]';
x = cell2mat(data.x_soll); y = cell2mat(data.y_soll); z = cell2mat(data.z_soll);
trajectory_soll = [x;y;z]';
clear x y z
X = trajectory_soll; Y = trajectory_ist;
%%
% load trajectoryrobot31710929195154314.mat
% data = table2array(trajectoryrobot31710929195154314);
% X = data(:,2:4); % Ist
% Y = data(:,10:12); % Soll
% 
% X = X(~any(isnan(X),2),:);
% Y = Y(~any(isnan(Y),2),:);

%% 
% X = [1, 4, 2, 4, 5]';
% Y = [1, 2, 3, 4, 1]';

%%

M = size(X, 1);
N = size(Y, 1);

% In tslearn können hier die Beschränkungen von Sakoe & Chiba oder Itakura
%   als Maske verwendet werden Zeile 1738 ff. --> evtl. noch später implementieren 

mask = zeros(M,N); % keine Maske

% Euklidische Distanz
[xy,eucl_distances,t_a] = distance2curve(X,Y,'linear');

eucl_max = max(eucl_distances);
eucl_av = mean(eucl_distances);

% Maximaler Abstand der bei einer Zuordnung möglich ist!
% MUSS ANGEGEBEN WERDEN --> Möglichkeit: ca. den max. euclidischen Abstand
epsilon = eucl_max + 0.1*eucl_max;
epsilon = 0.025;
% epsilon = 0.9;

% DTW-Standard zum Vergleichen
pflag = 0;
[distances, dtw_max, dtw_av, accdist, dtw_X, dtw_Y, path, ix, iy, localdist] = fkt_dtw3d(X,Y,pflag);


%%

% Akkumulierte Kostenmatrix aller Bahnpunkte 
acc_cost_mat = lcss_accumulated_matrix(X, Y, epsilon, mask);
% Zuordnungssequenz der Bahnpunkte
lcss_path = return_lcss_path(X, Y, epsilon, mask, acc_cost_mat, M, N);
% LCSS-Score [0,1] --> 1 = die Bahnen sind nach dem Verfahren identisch!
lcss_score = double(acc_cost_mat(end, end)) / min([M, N])

% Punkte auf den Bahnen und Distanzen zwischen diesen Punkten
lcss_X = X(lcss_path(:,1),:);
lcss_Y = Y(lcss_path(:,2),:);
lcss_distances = zeros(length(lcss_path),1);
for i = 1:length(lcss_distances)
    lcss_distances(i) = fkt_euclDist(i,i,lcss_X,lcss_Y); 
end
% Maximaler und durschnittlicher Abstand
lcss_max = max(lcss_distances);
lcss_av = mean(lcss_distances);


%% Funktionen

% Berechnet die Akkumulierten Kosten
function acc_cost_mat = lcss_accumulated_matrix(s1, s2, epsilon, mask)    
    l1 = size(s1, 1);
    l2 = size(s2, 1);
    acc_cost_mat = zeros(l1 + 1, l2 + 1);

    for i = 2:l1 + 1
        for j = 2:l2 + 1
            if isfinite(mask(i - 1, j - 1)) % isfinite falls Itakura o. Sakoe Chiba noch implementiert wird
                if fkt_euclDist(i-1, j-1, s1, s2) <= epsilon
                    acc_cost_mat(i, j) = 1 + acc_cost_mat(i - 1, j - 1);
                else
                    acc_cost_mat(i, j) = max(acc_cost_mat(i, j - 1), acc_cost_mat(i - 1, j));
                end
            end
        end
    end
end

% Berechnet den Pfad 
function lcss_path = return_lcss_path(s1, s2, epsilon, mask, acc_cost_mat, sz1, sz2)
 i = sz1;
    j = sz2;
    lcss_path = [];

    while i > 0 && j > 0 % && ein entscheidender Unterschied zu DTW
        if isfinite(mask(i, j))
            if fkt_euclDist(i, j, s1, s2) <= epsilon
                lcss_path = [lcss_path; i, j];
                i = i - 1;
                j = j - 1;
            elseif acc_cost_mat(i, j + 1) > acc_cost_mat(i + 1, j)
                i = i - 1;
            else
                j = j - 1;
            end
        else % Wird nie durchlaufen ohne Maske
            if i > 1 && acc_cost_mat(i - 1, j) == acc_cost_mat(i, j)
                i = i - 1;
            else
                j = j - 1;
            end
        end
    end

    lcss_path = flip(lcss_path, 1) ;
    
end

%% Plots Kostenmatrix und Pfad

% Akkumulierte Kostenmatrix und Pfad plotten

% Plot der akkumulierten Kostenmatrix
figure;
imagesc(acc_cost_mat);
colormap('sky');
colorbar;
hold on;

% % Pfad auf der akkumulierten Kostenmatrix plotten
% for k = 1:length(lcss_path)
%     i = lcss_path(k, 1); 
%     j = lcss_path(k, 2); 
%     plot(j, i, 'o', 'MarkerSize', 5, 'MarkerFaceColor', 'g', 'MarkerEdgeColor', 'g');
%     plot(j, i, 'o', 'MarkerSize', 5, 'MarkerFaceColor', 'k', 'MarkerEdgeColor', 'k');
% end

% Liniensegmenten für den Pfad zeichnen
for k = 1:length(lcss_path)-1
    i1 = lcss_path(k, 1);
    j1 = lcss_path(k, 2);
    i2 = lcss_path(k+1, 1);
    j2 = lcss_path(k+1, 2);
    plot([j1 j2], [i1 i2],'-k', 'LineWidth', 2.5);
end

title('Accumulated Cost Matrix with LCSS Path');
xlabel('s2 Index');
ylabel('s1 Index');

% Setzt die Achsen so, dass der Ursprung unten links liegt
set(gca, 'YDir', 'normal');


%% Plots

pflag = 1;
if pflag
% Plot der dem Pfad zugehörigen Punkte
figure;
hold on;
grid on;

% Darstellung der ursprünglichen Zeitreihen
plot3(X(:,1), X(:,2), X(:,3), '-bx', 'LineWidth', 1.5, 'MarkerSize', 5, 'MarkerFaceColor', 'b');
plot3(Y(:,1), Y(:,2), Y(:,3), '-rx', 'LineWidth', 1.5, 'MarkerSize', 5, 'MarkerFaceColor', 'b');

% Darstellung der Punkte und Verbindungslinien
plot3(lcss_X(:,1), lcss_X(:,2), lcss_X(:,3), '-go', 'LineWidth', 1.5, 'MarkerSize', 5, 'MarkerFaceColor', 'b');
plot3(lcss_Y(:,1), lcss_Y(:,2), lcss_Y(:,3), '-ko', 'LineWidth', 1.5, 'MarkerSize', 5, 'MarkerFaceColor', 'r');
for k = 1:length(lcss_path)    
    % Verbindungslinien
    plot3([lcss_X(k,1), lcss_Y(k,1)], [lcss_X(k,2), lcss_Y(k,2)], [lcss_X(k,3), lcss_Y(k,3)], 'k-');
end

j = length(lcss_path);
plot3(Y(1,1), Y(1,2), Y(1,3), '-bx', 'LineWidth', 1.5, 'MarkerSize', 10, 'MarkerFaceColor', 'b');
line([X(lcss_path(j,1),1) Y(lcss_path(j,2),1)],...
       [X(lcss_path(j,1),2) Y(lcss_path(j,2),2)],...
       [X(lcss_path(j,1),3) Y(lcss_path(j,2),3)],...
       'color',[0 0.8 0.5],'linewidth',3);

title('Matched Points with LCSS Path');
xlabel('X');
ylabel('Y');
zlabel('Z');
legend({'s1 Points', 's2 Points', 'Matching Lines'}, 'Location', 'best');
view(2);

%% 
figure;
% Subplot 1: Ursprüngliche Trajektorien
subplot(1, 2, 1);
hold on;
grid on;
plot3(X(:,1), X(:,2), X(:,3), 'b-', 'LineWidth', 1.5);
plot3(Y(:,1), Y(:,2), Y(:,3), 'r-', 'LineWidth', 1.5);
title('Original Trajectories');
xlabel('X');
ylabel('Y');
zlabel('Z');
legend({'s1 Trajectory', 's2 Trajectory'}, 'Location', 'best');
view(3);

% Subplot 2: LCSS Pfad und zugehörige Punkte
subplot(1, 2, 2);
hold on;
grid on;

% Punkte der beiden Trajektorien entlang des Pfads
lcss_X = X(lcss_path(:,1), :);
lcss_Y = Y(lcss_path(:,2), :);

% Darstellung der Punkte und Verbindungslinien
    % Punkte
    plot3(lcss_X(:,1), lcss_X(:,2), lcss_X(:,3), '-bo', 'MarkerSize', 5, 'MarkerFaceColor', 'b');
    plot3(lcss_Y(:,1), lcss_Y(:,2), lcss_Y(:,3), '-ro', 'MarkerSize', 5, 'MarkerFaceColor', 'r');
for k = 1:length(lcss_path)    
    % Verbindungslinien
    plot3([lcss_X(k,1), lcss_Y(k,1)], [lcss_X(k,2), lcss_Y(k,2)], [lcss_X(k,3), lcss_Y(k,3)], 'k-');
end

title('LCSS Path with Matched Points');
xlabel('X');
ylabel('Y');
zlabel('Z');
legend({'s1 Points', 's2 Points', 'Matching Lines'}, 'Location', 'best');
view(3);

end
% Plot nur mit Punkten

% Plot der dem Pfad zugehörigen Punkte
figure;
hold on;
grid on;

% Darstellung der ursprünglichen Zeitreihen
plot3(X(:,1), X(:,2), X(:,3), '-bx', 'LineWidth', 1, 'MarkerSize', 5, 'MarkerFaceColor', 'b');
plot3(Y(:,1), Y(:,2), Y(:,3), '-rx', 'LineWidth', 1, 'MarkerSize', 5, 'MarkerFaceColor', 'b');


for k = 1:length(lcss_path) 
    % Darstellung der Punkte und Verbindungslinien
    plot3(lcss_X(k,1), lcss_X(k,2), lcss_X(k,3), 'go', 'MarkerSize', 5, 'MarkerFaceColor', 'b');
    plot3(lcss_Y(k,1), lcss_Y(k,2), lcss_Y(k,3), 'ko', 'MarkerSize', 5, 'MarkerFaceColor', 'r');
    % Verbindungslinien
    plot3([lcss_X(k,1), lcss_Y(k,1)], [lcss_X(k,2), lcss_Y(k,2)], [lcss_X(k,3), lcss_Y(k,3)], 'k-');
end

j = length(lcss_path);
plot3(Y(1,1), Y(1,2), Y(1,3), '-bx', 'LineWidth', 1.5, 'MarkerSize', 10, 'MarkerFaceColor', 'b');
line([X(lcss_path(j,1),1) Y(lcss_path(j,2),1)],...
       [X(lcss_path(j,1),2) Y(lcss_path(j,2),2)],...
       [X(lcss_path(j,1),3) Y(lcss_path(j,2),3)],...
       'color',[0 0.8 0.5],'linewidth',3);

title('Matched Points with LCSS Path');
xlabel('X');
ylabel('Y');
zlabel('Z');
legend({'s1 Points', 's2 Points', 'Matching Lines'}, 'Location', 'best');
view(3);

%% To-Dos

% Mal versuchen umzudrehen, dass die längere Bahn allen Punkten zugeordnet
% wird, auch wenn es dann zu Dopplungen bei der kürzeren Bahn kommt

% Wenn der Abstand eines anderen Punktes geringer ist soll dieser dem
% nächsten auf der Bahn zugeordnet werden.

% Bei Flip von Soll zu Ist Bahn und umgekehrt verändert sich die Zuordnung
% maßgebliche und damit auch der max und av Abstand