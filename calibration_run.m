function calibration_run(filename,events)
% Koordinatentransformation mittels Kalibrierungsfahrt
% filename = 'record_20240715_143311_calibration_run_final.csv';

data = importfile_vicon_abb_sync(filename);
% Zeitstempel extrahieren
date_time = data.timestamp(1);
date_time = datetime(date_time,'ConvertFrom','epochtime','TicksPerSecond',1e9,'Format','dd-MMM-yyyy HH:mm:ss');

%% Daten vorbereiten

% Löschen nicht benötigten Timesstamps
data.sec =[];
data.nanosec = [];

% Double Array
data_ = table2array(data);

% Zeitstempel extrahieren
date_time = data.timestamp(1);
date_time = datetime(date_time,'ConvertFrom','epochtime','TicksPerSecond',1e9,'Format','dd-MMM-yyyy HH:mm:ss');

% Timestamps in Sekunden
data{:,1} = (data{:,1}- data{1,1})/1e9;
data_timestamps = data{:,1};
%%
%%% VICON DATEN %%%

if events == false
    % Umrechnen der Vicon Daten in mm (in den neueren Daten mit den Ereingnisse wurde diese schon umgerechnet)
    data{:,2:4} = data{:,2:4}*1000;
    data{:,9:12} = data{:,9:12}*1000;
    data{:,17:20} = data{:,17:20}*1000;
end

% Daten auslesen
vicon_pose = data{:,2:8};
vicon_velocity = data{:,9:16};
vicon_accel = data{:,17:24};

% Alle NaN Zeilen löschen
clean_NaN = all(isnan(vicon_pose),2);
vicon_pose = vicon_pose(~clean_NaN,:);
clean_NaN = all(isnan(vicon_velocity),2);
vicon_velocity = vicon_velocity(~clean_NaN,:);
clean_NaN = all(isnan(vicon_accel),2);
vicon_accel = vicon_accel(~clean_NaN,:);

% Pose Daten in Position und Orientierung aufteilen
vicon_positions = vicon_pose(:,1:3);
vicon_orientation = vicon_pose(:,4:end);

% Indizes der Zeilen die Daten beinhalten
idx_not_nan = ~isnan(data.pv_x);
counter = (1:1:size(data,1))';
idx_vicon = idx_not_nan.*counter;
idx_vicon(idx_not_nan==0) = [];

% Zeitstempel (umgerechnet und wo Positionsdaten vorliegen) - alle Werte
vicon_timestamps = data_timestamps(idx_vicon);

% Frequenz Vicon
freq_vicon = length(vicon_timestamps(:,1))/(vicon_timestamps(end,1)-vicon_timestamps(1,1));

% Datenpakete auf die gleiche Größe bringen
size_timestamp = length(vicon_timestamps);
size_pose = length(vicon_pose);
size_velocity = length(vicon_velocity);
size_accel = length(vicon_accel);
size_min = min([size_timestamp, size_pose, size_velocity, size_accel]);

vicon_accel = vicon_accel(1:size_min,:);
vicon_velocity = vicon_velocity(1:size_min,:);
vicon_pose = vicon_pose(1:size_min,:);
vicon_timestamps = vicon_timestamps(1:size_min,:);

% Array mit allen Vicon Daten
vicon = [vicon_timestamps vicon_pose vicon_velocity vicon_accel];

clear clean_NaN filename vicon_pose
clear size_timestamp size_pose size_velocity size_accel size_min

%%
%%% ABB Daten %%%%

% Indizes der Daten, die nicht NaN sind
idx_not_nan = ~isnan(data.ps_x);
counter = (1:1:size(data,1))';
idx_abb_positions = idx_not_nan.*counter;
idx_abb_positions(idx_not_nan==0) = [];

% Wenn Daten Ereignisse beinhalten (neue Daten)
if events == true
    idx_not_nan = ~isnan(data.ap_x);
    counter = (1:1:size(data,1))';
    idx_abb_events = idx_not_nan.*counter;
    idx_abb_events(idx_not_nan==0) = [];
end

clear idx_not_nan counter


% Initialisierung eines Arrays für alle Daten
abb = zeros(length(idx_abb_positions),15);
if events == true
    abb = zeros(length(idx_abb_positions),18);
end

% Zeitstempel (umgerechnet und wo Positionsdaten vorliegen) - alle Werte
abb(:,1) = data_timestamps(idx_abb_positions);

% Frequenz in der Positionen ausgegeben werden
freq_abb = length(abb(:,1))/(abb(end,1)-abb(1,1));

% Position - alle Werte
abb(:,2:4) = data_(idx_abb_positions(:),25:27);

% Wenn neue Daten mit Ereignissen diese in Matrix einfügen
if events == true
    events_positions = data_(idx_abb_events,39:41);
    events_timestamps = data_timestamps(idx_abb_events,1);
    idx_time_events = zeros(length(events_timestamps),1);
    % Füge die Ereignisse an der Stelle ein wo die Timestamps am nächsten beieinander liegen 
    for i = 1:length(events_timestamps)
        difference = abs(abb(:,1) - events_timestamps(i));
        [~,idx] = min(difference);
        idx_time_events(i) = idx;
    end
    abb(idx_time_events,16:18) = data_(idx_abb_events,39:41);
    abb_events = abb(:,16:18);
end

% Daten in einzelne Vektoren aufteilen
abb_timestamps = abb(:,1);
abb_positions = abb(:,2:4);

clear idx idx1 idx2 idx_chain idx_from_idx is_point j i search_term data_ vicon_pose difference

%% Herausfiltern der Vicon-Daten die den Ereignissen entsprechen


% Ermittlung des Startpunkts in den Koordinatensystemen über Mittelwert
abb_diffs = diff(abb_positions);
abb_dists = sqrt(sum(abb_diffs.^2, 2));
vicon_diffs = diff(vicon_positions);
vicon_dists = sqrt(sum(vicon_diffs.^2,2));

% Ermittlung des ersten Referenzpunktes anhand Abstand zwischen den Punkten
first_idx_abb = find(abb_dists > 0.05,1);
p1_abb = mean(abb_positions(1:first_idx_abb-1,:));
first_idx_vicon = find(vicon_dists > 0.05,1);
p1_vicon = mean(vicon_positions(1:first_idx_vicon-1,:));

% Ermittlung der Zeitstempel wo Ereignisse stattfinden
idx_nearest_vicon = zeros(length(events_timestamps),1);
for i = 1:length(events_timestamps)
    [~,idx] = min(abs(events_timestamps(i)-vicon_timestamps));
    % Nächstliegender Index des des Zeitstempels bei Vicon 
    idx_nearest_vicon(i) = idx;
end
events_timestamps_vicon = vicon_timestamps(idx_nearest_vicon);

% % Ermittlung der Punkte anhand der Stillstandzeiten 
% % --> funktioniert leider nicht, da unterschiedliche Stillstandzeiten 
% min_index_distance = round(freq_vicon*1.5);
% a = mean(vicon_dists(idx_nearest_vicon(2):idx_nearest_vicon(2)+min_index_distance))

% Schwellwert für die Annahme, dass der Roboter stillsteht
threshold = 0.15;  % Zuverlässigster Wert bei 700Hz

vicon_base_points = zeros(length(idx_nearest_vicon),3);
% Finden und mitteln aller Vicon-Daten die in einer Ecke liegen 
for i = 1:length(idx_nearest_vicon)
    idx = idx_nearest_vicon(i); 
    buffer = []; 
    
    % Extrahiere die Daten, solange der Abstand kleiner als der Schwellwert ist
    while idx <= length(vicon_dists) && vicon_dists(idx) < threshold
        buffer(end + 1) = idx;
        idx = idx + 1; 
    end  
    vicon_base_points(i,:) = mean(vicon_positions(buffer,:));
end

% Erstellen der Transformationsvektoren (Referenzpunkte) + Startwert
abb_reference = [p1_abb; events_positions]; 
vicon_reference = [p1_vicon; vicon_base_points];

%%
% Berechnung der Abstände zwischen den Punkten der Viconmessung
dists = zeros(length(vicon_reference)-1,1);
for i = 1:length(vicon_reference)-1
    diffs = vicon_reference(i+1, :) - vicon_reference(i, :);
    dists(i) = norm(diffs);
end

%% Koordinatentransformation
% 
% % Mittelwerte der Punkte
% abb_mean = mean(abb_reference);
% vicon_mean = mean(vicon_reference);
% 
% % Zentrierung in den Ursprung
% abb_centered = (abb_reference-abb_mean);
% vicon_centered = (vicon_reference-vicon_mean);
% 
% % Kovarianzmatrix
% H = abb_centered' * vicon_centered;
% 
% % Singular Value Decomposition
% [U, ~, V] = svd(H);
% 
% % Rotationsmatrix 
% R = V *U';
% 
% % Translationsvektor
% T = abb_mean - vicon_mean * R;
% 
% % Koordinatentransformation Referenz- und Gesamtbahn
% vicon_reference_transformed = vicon_reference*R + T; 
% vicon_transformed = vicon_positions*R + T;


%% Plot 
% figure; 
% view(3)
% plot3(vicon_reference(:,1),vicon_reference(:,2),vicon_reference(:,3))
% hold on
% plot3(abb_reference(:,1),abb_reference(:,2),abb_reference(:,3))
% plot3(vicon_transformed(:,1),vicon_transformed(:,2),vicon_transformed(:,3))


%% Laden in den Workspace

assignin('base','abb_reference',abb_reference)
assignin("base","vicon_reference",vicon_reference)

end
