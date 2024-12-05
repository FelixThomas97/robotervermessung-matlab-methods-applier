function calibration(data_cal_ist,data_cal_soll)

ist_time = double(string(data_cal_ist.timestamp));
ist = [data_cal_ist.x_ist data_cal_ist.y_ist data_cal_ist.z_ist];
soll_time = double(string(data_cal_soll.timestamp));
soll_reference = [data_cal_soll.x_reached data_cal_soll.y_reached data_cal_soll.z_reached];

diffs = diff(ist);
dists = sqrt(sum(diffs.^2,2));

% Abstand 0.5

% Bestimmung der naheliegensten Timestamps zwischen Ereigniss und Vicon-Daten
ist_base_idx = zeros(length(soll_time),1);
for i = 1:length(ist_base_idx)
    [~,idx] = min(abs(soll_time(i)-ist_time));
    ist_base_idx(i) = idx;
end

% Vicon-Positionen an den naheliegendsten Timestamps
ist_base_timestamps = ist_time(ist_base_idx);
ist_base_points = ist(ist_base_idx,:);

% Bestimmung und mitteln der aller Punkte in der Nähe der Referenzpunkte
threshold = 0.25; % --> War ein guter Wert bei 700Hz !

ist_reference = zeros(length(ist_base_idx),3);
for i = 1:length(ist_base_idx)
    idx = ist_base_idx(i);
    buffer = []; 
    
    % Extrahiere die Daten, solange der Abstand kleiner als der Schwellwert ist
    while idx <= length(dists) && dists(idx) < threshold
        buffer(end + 1) = idx;
        idx = idx + 1; 
    end  
    ist_reference(i,:) = mean(ist(buffer,:));
end

% Löschen von NaN Einträgen (kommt vor wenn die obige while-Schleife nicht durchläuft)
findnans = isnan(ist_reference(:,1));
nans = find(findnans == 1);
ist_reference(nans,:) = [];
soll_reference(nans,:) = [];
ist_base_points(nans,:) = [];


% Test zur Überprüfung der Abstände zwischen den neuen gemittelten
% Positionen und den Positionen bei den Timestamps
test_diffs = ist_reference - ist_base_points;
test_dists = sqrt(sum(test_diffs.^2,2));


%% Koordinatentransformation

% Mittelwerte der Punkte
soll_mean = mean(soll_reference);
ist_mean = mean(ist_reference);

% Zentrierung in den Ursprung
soll_centered = (soll_reference-soll_mean);
ist_centered = (ist_reference-ist_mean);

% Kovarianzmatrix
H = soll_centered' * ist_centered;

% Singular Value Decomposition
[U, ~, V] = svd(H);

% Rotationsmatrix 
trafo_rot = V *U';

% Translationsvektor
trafo_trans = soll_mean - ist_mean * trafo_rot;

% Koordinatentransformation Referenz- und Gesamtbahn
ist_reference_transformed = ist_reference * trafo_rot + trafo_trans; 
ist_transformed = ist * trafo_rot + trafo_trans;

% % Test zur Überprüfung der Konsistenz der Koordinatentransformation
test_diffs2 = ist_reference_transformed - soll_reference;
test_dists2 = sqrt(sum(test_diffs2.^2,2));

% %% Test Plot 
% figure
% plot3(ist_base_points(:,1),ist_base_points(:,2),ist_base_points(:,3));
% hold on 
% plot3(soll_reference(:,1),soll_reference(:,2),soll_reference(:,3));
% plot3(ist_reference_transformed(:,1),ist_reference_transformed(:,2),ist_reference_transformed(:,3));

%% Trans. und Rot. Matrix in Workspace laden

assignin("base","trafo_rot",trafo_rot)
assignin("base","trafo_trans",trafo_trans)



