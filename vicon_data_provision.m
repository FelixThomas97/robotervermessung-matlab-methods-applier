clear; 

abb = [133 -645 1990];

filename_vicon = "isodiagonalA_300hz_v100.csv";
data_table = readtable("isodiagonalA_300hz_v100.csv");

data = data_table{2:end,6:8};
x = data(:,1);
y = data(:,2);
z = data(:,3);

% data = Loop11isodiagonal{:,1:3};
% x = data(:,1);
% y = data(:,2);
% z = data(:,3);

% plot3(x,y,z)

% Diff = diff(x);
% Diff = abs(Diff);
% [min_diff, min_diff_index] = min(Diff);
% 
% 
% p1 = data(1,:); 

% Anzahl der Punkte
M = size(data, 1);

% Initialisieren des Vektors für die Abstände
distances = zeros(M-1, 1);

% Berechnung der Abstände
for i = 1:M-1
    % Differenz zwischen aufeinanderfolgenden Punkten
    diff = data(i+1, :) - data(i, :);
    % Euklidische Distanz
    distances(i) = norm(diff);
end

threshold = 0.02; 

% Mindestabstand in Indizes
min_index_distance = 200;

% Initialisieren der Arrays zur Speicherung der Ergebnisse
indices = [];
selected_points = [];

% Finden der Indizes der Abstände, die geringer als der Grenzwert sind
indices = find(distances < threshold);

% Speichern der Ergebnisse mit Mindestabstand in Indizes
last_saved_index = -min_index_distance;  % Initialisierung
for i = 1:length(indices)
    idx = indices(i);
    if idx - last_saved_index >= min_index_distance
        indices = [indices; idx];
        selected_points = [selected_points; data(idx, :)];
        last_saved_index = idx;
    end
end

%% Löschen gleichen Punkte
diff_selected_points = zeros(length(selected_points),1);
for i = 1:length(selected_points)-1
    % Differenz zwischen aufeinanderfolgenden Punkten
    diff = selected_points(i+1, :) - selected_points(i, :);
    % Euklidische Distanz
    diff_selected_points(i) = norm(diff);
end


index_equal_points = find(diff_selected_points <= threshold*10);


% Löschen des letzten Punktes
% points(end,:) = []; %%% Vielleicht nicht immer so!

% diff_selected_points(index_equal_points) = [];

diff_points = diff_selected_points;

diff_points(index_equal_points) = 0;

last_index = find(diff_points ~= 0,1, 'last');

last_index = last_index + 1; 

points = selected_points;
points(index_equal_points,:) = [];
points(end+1,:) =  selected_points(last_index,:);




plot3(points(:,1),points(:,2),points(:,3),'-o',LineWidth=3);


% tform = fitgeotrans(points1, points2, 'affine');