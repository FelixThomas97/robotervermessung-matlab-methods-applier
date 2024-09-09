%% Daten importieren
clear
tic
% filename = 'squares_isodiagonalA&B_300Hz_v2500_1.csv';
% filename = 'record_20240702_153511_squares_isodiagonalA&B_final.csv'; % 700Hz
% filename = 'record_20240702_155846_squares_isodiagonalA&B_final.csv'; % 250 Hz




% filename = 'record_20240711_144811_squares_isodiagonalA&B_15s_final.csv'; % 100Hz
% filename = 'record_20240711_164202_squares_isodiagonalA&B_final (1).csv'; % 300Hz

% filename = 'record_20240711_170652_squares_isodiagonalA&B_final (1).csv'; % 350Hz funzt nicht.
% filename = 'record_20240711_143408_squares_isodiagonalA&B_final.csv'; % Vicon Daten nicht aufgezeichnet. 

% filename = 'record_20240711_172935_all_final.csv';

 filename = 'record_20240715_145920_all_final.csv'; % 700Hz - 93 Segmente
% filename = 'record_20240715_143311_calibration_run_final.csv';
% filename = 'record_20240715_145153_all_final.csv'; % 700Hz - 483 Segmente
% filename = 'record_20240715_145153_1.csv';
% filename = 'record_20240715_145153_5.csv';
% filename = 'record_20240715_150237_all_final.csv'; % 700Hz - 183 Segmente


filename_calibration = 'record_20240715_143311_calibration_run_final.csv';

data = importfile_vicon_abb_sync(filename);
% Zeitstempel extrahieren
date_time = data.timestamp(1);
date_time = datetime(date_time,'ConvertFrom','epochtime','TicksPerSecond',1e9,'Format','dd-MMM-yyyy HH:mm:ss');
% --> Erster Zeitstempel der Datei!!!

%% %%%%%%%%%%%%%%%%%%%%%% MANUELLE EINGABE %%%%%%%%%%%%%%%%%%%%%%%%%%%%% %%

% Interpolierte Sollbahn nutzen (sonst ABB Websocket) 
generate_soll = true;

% Anzahl der Punkte der Sollbahn (falls generiert werden soll)
keypoints_faktor = 1;

% Anzahl der Segmente die zu einer Trajektorie/Gruppe zusammengefasst werden sollen
group_size = 4; 

% Metriken die berechnet werden sollen
euclidean = true;
dtw = true;
sidtw = true;
frechet = true;
lcss = true;

%%%% Kommt noch später !!!!
do_segments = true; 

% Gesamttrajectorie unterteilen (Sonst komplette Messung als eine Trajectory)
split = true;

% Plots an (Aus empfohlen sonst sehr viele Plots)
pflag = false;

% Upload in DATENBANK
upload2mongo = false;

upload2postgresql = true;

%%%%%%%% Dateneingabe Header %%%%%%%%%%
header_data = struct();
header_data.data_id = [];                               % automatisch
header_data.robot_model = "abb_irb4400";
header_data.start_time = [];
header_data.end_time = [];
header_data.real_robot = "true";
header_data.number_of_points_ist = [];                  % automatisch
header_data.number_of_points_soll = [];                 % automatisch
header_data.sample_frequency_ist = [];                  % automatisch
header_data.sample_frequency_soll = [];                 % automatisch
header_data.source_data_ist = "vicon";
header_data.source_data_soll = [];                      % automatisch für Interpolation und Websocket
header_data.upload_date = string(datetime('now','Format','dd-MMM-yyyy HH:mm:ss'));


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

freq_data = length(data_timestamps(:,1))/(data_timestamps(end,1)-data_timestamps(1,1));
% Bei einem Datensatz lagen mehr Geschwindigkeitsdaten vor ...
if length(vicon_velocity) > length(vicon_positions)
    vicon_velocity = vicon_velocity(1:length(vicon_positions),:);
end

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
vicon_positions = vicon_pose(:,1:3);

clear clean_NaN vicon_pose


%%% ABB Daten %%%%

% Indizes der Daten, die nicht NaN sind
idx_not_nan = ~isnan(data.ps_x);
counter = (1:1:size(data,1))';
idx_abb_positions = idx_not_nan.*counter;
idx_abb_positions(idx_not_nan==0) = [];

idx_not_nan = ~isnan(data.os_x);
counter = (1:1:size(data,1))';
idx_abb_orientation = idx_not_nan.*counter;
idx_abb_orientation(idx_not_nan==0) = [];

idx_not_nan = ~isnan(data.tcp_speeds);
counter = (1:1:size(data,1))';
idx_abb_velocity = idx_not_nan.*counter;
idx_abb_velocity(idx_not_nan==0) = [];

idx_not_nan = ~isnan(data.joint_1);
counter = (1:1:size(data,1))';
idx_abb_jointstates = idx_not_nan.*counter;
idx_abb_jointstates(idx_not_nan==0) = [];

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
% Orientierung - erster Wert
abb(1,5:8) = data_(idx_abb_orientation(1),28:31);
% Geschwindigkeit - erster Wert
abb(1,9) = data_(idx_abb_velocity(1),32);
% Joint States - erster Wert
abb(1,10:15) = data_(idx_abb_jointstates(1),33:38);


% Auffüllen der Spalten der ABB Matrix für alle Positionsdaten: 
% (Positionesdaten besitzen am meisten Elemente)

% Orientierung
search_term = idx_abb_orientation;
for i = 2:length(abb)-1
    
    % Vor jedem Durchlauf false setzen
    is_point = false;
    % Indizes der aufeinander folgenden Positionsdaten
    idx1 = idx_abb_positions(i);
    idx2 = idx_abb_positions(i+1) - 1;
    % Alle Indizes die dazwischen liegen
    idx_chain = idx1:idx2;
    % Überprüfen ob einer der Indizes bei der Orientierung vorkommt
    for j = 1:length(idx_chain)
        idx = idx_chain(j);
        % Wenn ja füge den Wert in data_abb hinzu
        if ismember(idx,search_term)
            idx_from_idx = find(search_term==idx);
            abb(i,5:8) = data_(search_term(idx_from_idx),28:31);
            is_point = true;
        end
    end
    % Wenn Index nicht vorkommt nimm den voherigen Wert
    if is_point == false
        abb(i,5:8) = abb(i-1,5:8);
    end
end
% letzten Wert noch gleich vorletzten Wert setzen
abb(end,5:8) = abb(end-1,5:8);

% Geschwindigkeit und Joint-States genau so wie bei Orientierung
search_term = idx_abb_velocity;
for i = 2:length(abb)-1  
    is_point = false;
    idx1 = idx_abb_positions(i);
    idx2 = idx_abb_positions(i+1) - 1;
    idx_chain = idx1:idx2;
    for j = 1:length(idx_chain)
        idx = idx_chain(j);
        if ismember(idx,search_term)
            idx_from_idx = find(search_term==idx);
            abb(i,9) = data_(search_term(idx_from_idx),32);
            is_point = true;
        end
    end
    if is_point == false
        abb(i,9) = abb(i-1,9);
    end
end
abb(end,9) = abb(end-1,9);

search_term = idx_abb_jointstates;
for i = 2:length(abb)-1  
    is_point = false;
    idx1 = idx_abb_positions(i);
    idx2 = idx_abb_positions(i+1) - 1;
    idx_chain = idx1:idx2;
    for j = 1:length(idx_chain)
        idx = idx_chain(j);
        if ismember(idx,search_term)
            idx_from_idx = find(search_term==idx);
            abb(i,10:15) = data_(search_term(idx_from_idx),33:38);
            is_point = true;
        end
    end
    if is_point == false
        abb(i,10:15) = abb(i-1,10:15);
    end
end
abb(end,10:15) = abb(end-1,10:15);

% Wenn neue Daten mit Ereignissen diese in Matrix einfügen
if events == true
    events_positions = data_(idx_abb_events,39:41);
    events_timestamps = data_timestamps(idx_abb_events,1);
    idx_time_events = zeros(length(events_timestamps),1);
    % Füge die Ereignisse an der Stelle ein wo die Timestamps am nächsten beieinander liegen 
    for i = 1:length(events_timestamps)
        diff = abs(abb(:,1) - events_timestamps(i));
        [~,idx] = min(diff);
        idx_time_events(i) = idx;
    end
    abb(idx_time_events,16:18) = data_(idx_abb_events,39:41);
    abb_events = abb(:,16:18);
end

% Daten in einzelne Vektoren aufteilen
abb_timestamps = abb(:,1);
abb_positions = abb(:,2:4);
abb_orientation = abb(:,5:8);
abb_velocity = abb(:,9);
abb_jointstats = abb(:,10:15);

clear idx idx1 idx2 idx_chain idx_from_idx is_point j i search_term vicon_pose diff

% Ausgabe der maximalen Geschwindigkeit
velocity_max_vicon = max(vicon_velocity(:,4));
velocity_max_abb = max(abb_velocity);

% Berechnung der Stützpunkte 
new_base_points(vicon_positions, events_positions,idx_abb_events,data_timestamps,vicon_timestamps)

%% Transformation der Koordinaten von Vicon-System zu Abb-System

% Ermittlung der Referenzwerte aus der Kalibirierungs-Messung
calibration_run(filename_calibration,events)

% Mittelwerte der Punkte
abb_mean = mean(abb_reference);
vicon_mean = mean(vicon_reference);

% Zentrierung in den Ursprung
abb_centered = (abb_reference-abb_mean);
vicon_centered = (vicon_reference-vicon_mean);

% Kovarianzmatrix
H = abb_centered' * vicon_centered;

% Singular Value Decomposition
[U, ~, V] = svd(H);

% Rotationsmatrix 
R = V *U';

% Translationsvektor
T = abb_mean - vicon_mean * R;

% Koordinatentransformation Referenz- und Gesamtbahn
vicon_reference_transformed = vicon_reference*R + T; 
vicon_transformed = vicon_positions*R + T;
base_points_vicon_transformed = base_points_vicon*R + T; 

clear U V T R H 

clear abb_mean abb_centered vicon_mean vicon_centered

%% Berechnungen mit den transformierten Daten

% Berechnung Abweichungen der Referenzdaten
diffs_reference = (vicon_reference_transformed-abb_reference);

dists_reference = zeros(length(diffs_reference),1);
for i = 1:length(diffs_reference)
    dists_reference(i) = norm(diffs_reference(i,:));
end

dists_mean = mean(dists_reference);
[dists_max, dists_idx_max] = max(abs(dists_reference));

[~,eucl_dists,~] = distance2curve(vicon_transformed,abb_positions,'linear');
eucl_mean = mean(eucl_dists);
eucl_max = max(eucl_dists);

clear diffs_reference eucl_dists i 

%% Vicon Zerteilen und Sollbahngenerierung

% Generiere Sollbahn mit den getriggerten Ereignissen aus der ABB-Steuerung
new_generate_soll_vicon_events(abb_base_points,vicon,vicon_transformed,base_points_vicon,base_points_idx,base_points_dist,keypoints_faktor, 1.5)

%% ABB zerteilen (Bahn beginnt ab erstem Ereigniss)

abb_events_idx = find(abb_events(:,1) ~=0);
segments_abb = cell(1,size(segments_ist,2));

for i = 1:1:size(segments_ist,2)
        segments_abb{i} = abb(abb_events_idx(i):abb_events_idx(i+1),:);
end

%%
% Die erste Position interssiert jetzt nichtmehr!
% abb_reference = abb_reference(2:end,:);
% vicon_reference_transformed = vicon_reference_transformed(2:end,:);

% Am häufigsten vorkommende Position aus ABB-Daten filtern
[C, ~, ic] = unique(abb_reference, 'rows');
counts_home = accumarray(ic, 1);

% Finden der häufigsten Positionen
[~, home_first_idx] = max(counts_home);
home_position = C(home_first_idx, :);

home_first_idx = ismember(abb_reference, home_position,'rows');
home_first_idx = find(home_first_idx,1);

clear counts_home C ic 
%% 
% Bestimmung der Homeposition und entsprechende Anzahl der Trajektorien 
traj_home_vicon = vicon_reference_transformed(home_first_idx,:); % Hier war vorher einfach die zweite Position festgelegt
traj_search = abs(vicon_reference_transformed-traj_home_vicon);

traj_search_norms = zeros(size(traj_search,1),1);
for i = 1:size(traj_search,1)
    traj_search_norms(i) = norm(traj_search(i,:));
end

% traj_home_vicon_idx = find(traj_search_norms == 0);
% traj_search_norms = traj_search_norms(traj_home_vicon_idx-1:end)
% traj_home_vicon_idx = find(traj_search_norms <= 1)

 traj_home_vicon_idx = find(traj_search_norms <= 5);
 num_trajectories = size(traj_home_vicon_idx,1)-1;

%% Bahnabschnitte zu Trajectorien zusammenfassen


% Anzahl der Bahnabschnitte
num_segments = size(segments_soll,2);
num_trajectories = floor(num_segments/group_size);

trajectories_ist = cell(1,num_trajectories);
trajectories_soll = cell(1,num_trajectories);
trajectories_abb = cell(1,num_trajectories);

% Zusammenfassen der Segmente zu Trajektorien
j = 0; 
for i = 1:1:num_trajectories
    start = j+1;
    last = start+group_size-1;
    traj_ist = [];
    traj_soll = [];
    traj_abb = [];
    for j = start:1:last
        traj_ist = [traj_ist; segments_ist{j}];
        traj_soll = [traj_soll; segments_soll{j}];
        traj_abb = [traj_abb; segments_abb{j}]; 
    end
    trajectories_ist{i} = traj_ist;
    trajectories_soll{i} = traj_soll;  
    trajectories_abb{i} = traj_abb;
end

clear traj_ist traj_soll traj_abb

%% Vorbereiten für Upload in Datenbank 

% Einmal vorab die Base für die ID generieren
% trajectory_header_id_base = string(round(posixtime(datetime(date_time,'TimeZone','UTC'))));
% trajectory_header_id_base_segments = trajectory_header_id_base + "_";

trajectory_header_ids = strings(num_trajectories,1);

% Leere Cell-Arrays für die Bewegungsdaten und Header
struct_data = cell(1,num_trajectories);
struct_data_segments = cell(1,num_segments);
struct_header = cell(1,num_trajectories);
struct_header_segments = cell(1,num_segments);

% struct_group_segments = cell(1,num_segments);


% Datenbank Struktur für ganze Messfahrten
for i = 1:1:num_trajectories 

    % Geschwindigkeit (nur für generierte Sollbahn)
    defined_velocity = max(trajectories_ist{i}(:,12));

    % Zeitstempel extrahieren und abspeichern
    timestamp = [data_(idx_abb_events(i*group_size-group_size+1),1); data_(idx_abb_events(i*group_size+1),1) ];
    timestamp_formatted = datetime(timestamp(1),'ConvertFrom','epochtime','TicksPerSecond',1e9,'Format','dd-MMM-yyyy HH:mm:ss');
    trajectory_header_ids(i) = string(round(posixtime(datetime(timestamp_formatted,'TimeZone','UTC'))));

    % Funktionen zur Erzeugung der Datenstruktur für Soll und Istbahn
    if generate_soll == true
        datasoll_vicon(trajectories_soll{i}, defined_velocity, generate_soll);
    else
        datasoll_vicon(trajectories_abb{i}, defined_velocity, generate_soll);
    end
    new_dataist_vicon(trajectories_ist{i},trajectory_header_ids(i))

    % Istdaten in die Struktur schreiben
    struct_data{i} = data_ist_part;

    % Solldaten der Struktur hinzufügen
    fields_soll = fieldnames(data_soll_part);
    for j = 1:length(fields_soll)
        struct_data{i}.(fields_soll{j}) = data_soll_part.(fields_soll{j});
    end

    % Struktur für Header erzeugen
    if generate_soll == true
        new_header2struct(trajectory_header_ids(i), header_data, timestamp, trajectories_ist{i}, trajectories_soll{i}, generate_soll);
    else
        new_header2struct(trajectory_header_ids(i), header_data, timestamp, trajectories_ist{i}, trajectories_abb{i}, generate_soll);
    end
    struct_header{i} = header_data;
end

% Datenbank Struktur für einzelne Bahnabschnitte

trajectory_header_ids_segments = strings(num_segments,1);
segment_ids = strings(num_segments,1);

counter = 1;

for i = 1:1:num_segments

    % Geschwindigkeit (nur für generierte Sollbahn)
    defined_velocity = max(segments_ist{i}(:,12));

    % Zeitstempel extrahieren und abspeichern
    timestamp = [data_(idx_abb_events(i),1); data_(idx_abb_events(i+1),1) ];
    
    % ID's für die Zuordnung zur der Entsprechenden Gruppe
    if i <=  counter*group_size
        trajectory_header_ids_segments(i) = trajectory_header_ids(counter);
    else
        counter = counter +1;
        trajectory_header_ids_segments(i) = trajectory_header_ids(counter);
    end
    segment_ids(i) = trajectory_header_ids_segments(i) + "_" + num2str(i);


    % Funktionen zur Erzeugung der Datenstruktur für Soll und Istbahn
    if generate_soll == true
        datasoll_vicon(segments_soll{i}, defined_velocity, generate_soll);
    else
        datasoll_vicon(segments_abb{i}, defined_velocity, generate_soll);
    end
    new_dataist_vicon(segments_ist{i},trajectory_header_ids_segments(i),segment_ids(i))

    struct_data_segments{i} = data_ist_part;

    % Solldaten der Struktur hinzufügen
    fields_soll = fieldnames(data_soll_part);
    for j = 1:length(fields_soll)
        struct_data_segments{i}.(fields_soll{j}) = data_soll_part.(fields_soll{j});
    end

    % Struktur für Header erzeugen
    if generate_soll == true
        segment_header2struct(trajectory_header_ids_segments(i),segment_ids(i), timestamp, segments_ist{i}, segments_soll{i},generate_soll)
    else
        segment_header2struct(trajectory_header_ids_segments(i),segment_ids(i), timestamp, segments_ist{i}, segments_abb{i},generate_soll)
    end
    struct_header_segments{i} = header_data_segment;

end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% Berechnung der Metriken %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% - eucl   : Euklidischer Abstand
% - dtw    : Dynamic Time Warping (Standard)
% - sidtw  : Dynamic Time Warping mit selektiver Interpolation (Johnen)
% - frechet: Frechet Abstand
% - lcss   : Longest Common Subsequence

struct_euclidean = cell(1,num_trajectories);
struct_dtw = cell(1,num_trajectories);
struct_sidtw = cell(1,num_trajectories);
struct_frechet = cell(1,num_trajectories);
struct_lcss = cell(1,num_trajectories);

for i = 1:1:num_trajectories

    trajectory_header_id = trajectory_header_ids(i);

    % Aktuelle Ist-Bahn
    trajectory_ist = trajectories_ist{i}(:, 2:4);

    % Aktuelle Soll-Bahn
    if generate_soll == false
        trajectory_soll = trajectories_abb{i}(:,2:4);
    else
        trajectory_soll = trajectories_soll{i}(:,1:3);
    end

    % Euklidsche Distanzen für die einzelnen Messfahrten
    if euclidean == true
        [eucl_interpolation,eucl_distances,~] = distance2curve(trajectory_ist,trajectory_soll,'linear');
        metric2struct_eucl(trajectory_soll, eucl_interpolation, eucl_distances,trajectory_header_id);           
        struct_euclidean{i} = metrics_euclidean;
    else
        clear struct_euclidean
    end

    % DTW für die einzelnen Messfahrten
    if dtw == true
        [dtw_distances, dtw_max, dtw_av, dtw_accdist, dtw_X, dtw_Y, dtw_path, ~, ~, ~] = ...
        fkt_dtw3d(trajectory_soll, trajectory_ist, pflag);
        metric2struct_dtw(trajectory_header_id, dtw_av, dtw_max, dtw_distances, dtw_accdist, dtw_path, dtw_X, dtw_Y);
        struct_dtw{i} = metrics_dtw;
    else
        clear struct_dtw
    end
    % SIDTW für die einzelnen Messfahrten
    if sidtw == true
        [sidtw_distances, sidtw_max, sidtw_av,...
            sidtw_accdist, sidtw_X, sidtw_Y, sidtw_path, ~, ~]...
            = fkt_selintdtw3d(trajectory_soll,trajectory_ist,pflag);
        metric2struct_sidtw(trajectory_header_id,sidtw_max, sidtw_av, ...
            sidtw_distances,sidtw_X,sidtw_Y,sidtw_accdist,sidtw_path);
        struct_sidtw{i} = metrics_johnen;
    else
        clear struct_sidtw
    end
    % Frechet-Distanz für die einzelnen Messfahrten
    if frechet == true
        fkt_discreteFrechet(trajectory_soll,trajectory_ist,pflag);
        metric2struct_frechet(trajectory_header_id, frechet_av, frechet_dist, frechet_distances, frechet_matrix, frechet_path);

        struct_frechet{i} = metrics_frechet;
    else
        clear struct_frechet
    end
    % LCSS für die einzelnen Trajectorien
    if lcss == true
        [lcss_av, lcss_max, lcss_distances, lcss_accdist, lcss_path, lcss_X, lcss_Y,lcss_score,lcss_epsilon] = fkt_lcss(trajectory_soll,trajectory_ist,pflag);
        metric2struct_lcss(trajectory_header_id, lcss_av, lcss_max, lcss_distances, lcss_accdist, lcss_path, lcss_X, lcss_Y,lcss_score,lcss_epsilon);

        struct_lcss{i} = metrics_lcss;
    else
        clear struct_lcss
    end

end


%% Berechnung der Metriken für die Bahnsegmente

% Berechnung der Metriken für die einzelnen Bahnabschnitte   
if do_segments == true

    struct_euclidean_segments = cell(1,num_segments);
    struct_dtw_segments = cell(1,num_segments);
    struct_sidtw_segments = cell(1,num_segments);
    struct_frechet_segments = cell(1,num_segments);
    struct_lcss_segments = cell(1,num_segments);

    for i= 1:1:num_segments
        
        % Header-ID's Aktualisieren
        trajectory_header_id = trajectory_header_ids_segments(i);
        segment_id = segment_ids(i);
        
        % Aktueller Ist-Bahnabschnitt
        segment_ist = segments_ist{i}(:, 2:4);

        % Aktueller Soll-Bahnabschnitt
        if generate_soll == false
            segment_soll = segments_abb{i}(:,2:4);
        else
            segment_soll = segments_soll{i}(:,1:3);
        end

         % Euklidische Distanzen für alle Bahnabschnitte
        if euclidean == true
            [eucl_interpolation,eucl_distances,~] = distance2curve(segment_ist,segment_soll,'linear');
            metric2struct_eucl(segment_soll, eucl_interpolation, eucl_distances,trajectory_header_id,segment_id);         
            struct_euclidean_segments{i} = metrics_euclidean;
        else
            clear struct_euclidean_segments
        end

        % DTW für alle Bahnabschnitte
        if dtw == true
            [dtw_distances, dtw_max, dtw_av, dtw_accdist, dtw_X, dtw_Y, dtw_path,  ~, ~, ~] = ...
            fkt_dtw3d(segment_soll, segment_ist, pflag);
            metric2struct_dtw(trajectory_header_id, dtw_av, dtw_max, dtw_distances, dtw_accdist, dtw_path, dtw_X, dtw_Y,segment_id);
            struct_dtw_segments{i} = metrics_dtw;
        else
            clear struct_dtw_segments
        end

        % SIDTW für alle Bahnabschnitte
        if sidtw == true
            [sidtw_distances, sidtw_max, sidtw_av,...
                sidtw_accdist, sidtw_X, sidtw_Y, sidtw_path, ~, ~]...
                = fkt_selintdtw3d(segment_soll,segment_ist,pflag);
            metric2struct_sidtw(trajectory_header_id,sidtw_max, sidtw_av, ...
                sidtw_distances,sidtw_X,sidtw_Y,sidtw_accdist,sidtw_path,segment_id);
            struct_sidtw_segments{i} = metrics_johnen;
        else
            clear struct_sidtw_segments
        end

        % Frechet-Distanz alle Bahnabschnitte
        if frechet == true
            fkt_discreteFrechet(segment_soll,segment_ist,pflag);
            metric2struct_frechet(trajectory_header_id, frechet_av, frechet_dist, frechet_distances, frechet_matrix, frechet_path,segment_id);
            
            struct_frechet_segments{i} = metrics_frechet;
        else
            clear struct_frechet_segments
        end
      
        % LCSS für alle Bahnabschnitte
        if lcss == true

            [lcss_av, lcss_max, lcss_distances, lcss_accdist, lcss_path, lcss_X, lcss_Y,lcss_score,lcss_epsilon] = fkt_lcss(segment_soll,segment_ist,pflag);
            metric2struct_lcss(trajectory_header_id, lcss_av, lcss_max, lcss_distances, lcss_accdist, lcss_path, lcss_X, lcss_Y,lcss_score,lcss_epsilon,segment_id);

            struct_lcss_segments{i} = metrics_lcss;
        else
            clear struct_lcss_segments
        end
    end
end

toc

%% Upload in Datenbank 

if upload2mongo == true
    
    % Upload in Datenbank (nur wenn alle Metriken berechnet wurden)
    if euclidean && dtw && sidtw && frechet && lcss
    
        % Verbindung mit MongoDB
        connectionString = 'mongodb+srv://felixthomas:felixthomas@cluster0.su3gj7l.mongodb.net/';
        connection = mongoc(connectionString, 'robotervermessung');
        
        % Überprüfe Verbindung
        if isopen(connection)
            disp('Verbindung erfolgreich hergestellt');
        else
            disp('Verbindung fehlgeschlagen');
        end
    else
        error('Für den Upload in die Datenbank müssen alle Metriken berechnet werden!');
    end

    % Anzahl Trajektorien auf 1 setzen falls...
    if split == false
        num_trajectories = 1;

        a = cell(1,1);

        a{1} = struct_header;
        struct_header = a;

        a{1} = struct_data;
        struct_data = a;

        a{1} = struct_dtw;
        struct_dtw = a;

        a{1} = struct_sidtw;
        struct_sidtw = a;

        a{1} = struct_frechet;
        struct_frechet = a;

        a{1} = struct_euclidean;
        struct_euclidean = a; 

        a{1} = struct_lcss;
        struct_lcss = a; 

        clear a
    end

    for i = 1:1:num_trajectories
    
        % Löscht die Kostenmatrix falls Datenmenge zu groß für MongoDB
        struct_dtw{i} = check_bytes(struct_dtw{i},'dtw');
        struct_sidtw{i} = check_bytes(struct_sidtw{i},'sidtw');
        struct_frechet{i} = check_bytes(struct_frechet{i},'frechet');
        struct_lcss{i} = check_bytes(struct_lcss{i},'lcss');
        
        % Upload in Datenbank 
        insert(connection, 'header', struct_header{i});
        insert(connection, 'data', struct_data{i});     
        insert(connection, 'metrics', struct_sidtw{i});
        insert(connection, 'metrics', struct_euclidean{i});
        insert(connection, 'metrics', struct_dtw{i});
        insert(connection, 'metrics', struct_frechet{i});
        insert(connection, 'metrics', struct_lcss{i});
        if split == false
            disp('Die Gesamttrajektorie wurde erfolgreich hochgeladen: '+ trajectory_header_id_base);
        else
            disp('Die Trajektorien wurden separiert hochgeladen: '+ trajectory_header_id_base+num2str(i));
        end
    end
end

%%
pflag = false;
%% PLOTS
if pflag

%% Plots zur Überprüfung in welcher Reihenfolge die Segmente kommen
figure;
for i  = 1:1:size(segments_ist,2)
    plot3(segments_ist{i}(:,2),segments_ist{i}(:,3),segments_ist{i}(:,4))
    hold on
end
plot3(segments_ist{1}(1,2),segments_ist{1}(1,3),segments_ist{1}(1,4),'ko',LineWidth=3);
plot3(segments_ist{2}(1,2),segments_ist{2}(1,3),segments_ist{2}(1,4),'go',LineWidth=3);

%% Plot zur Überprüfung der Korrektheit der berechneten Stützpunkte
% points = base_points_vicon;
% points(:,1) = points(:,1)+1000;
% 
% figure('Color','white'); 
% plot3(vicon_positions(:,1),vicon_positions(:,2),vicon_positions(:,3),'r',LineWidth=2)
% hold on
% plot3(points(:,1),points(:,2),points(:,3),'b',LineWidth=2)
% axis equal
% plot3(points(1,1),points(1,2),points(1,3),'og',LineWidth=2)
% plot3(points(end,1),points(end,2),points(end,3),'ok',LineWidth=5)
% xlabel('x'); ylabel('y'); zlabel('z');

%% Plot der transformierten Vicon-Daten ins Abb-System 
figure('Color','white');
plot3(vicon_transformed(:,1),vicon_transformed(:,2),vicon_transformed(:,3))
hold on
% plot3(abb_reference(:,1),abb_reference(:,2),abb_reference(:,3))
plot3(abb_positions(:,1),abb_positions(:,2),abb_positions(:,3))
% plot3(vicon_reference_transformed(:,1),vicon_reference_transformed(:,2),vicon_reference_transformed(:,3))

% Dazuplotten der maximalen Abstände
plot3(abb_reference(dists_idx_max,1),abb_reference(dists_idx_max,2),abb_reference(dists_idx_max,3),'or',LineWidth=3)
plot3(vicon_reference_transformed(dists_idx_max,1),vicon_reference_transformed(dists_idx_max,2),vicon_reference_transformed(dists_idx_max,3),'ob',LineWidth=3)
legend('vicon transformed','abb','vicon')
view(2)
xlabel('x'); ylabel('y'); zlabel('z');
axis equal

%% Vergleich der Stützpunkte und ob diese zusammen passen
% Anfangs und Endpunkt der Stützpunkte bei ABB und transformierten Vicon-Daten
figure('Color','white'); 
plot3(events_positions(:,1),events_positions(:,2),events_positions(:,3),'k')
hold on
plot3(abb_positions(1,1),abb_positions(1,2),abb_positions(1,3),'og',LineWidth=3)
plot3(events_positions(1,1),events_positions(1,2),events_positions(1,3),'ok',LineWidth=3);
plot3(events_positions(end,1),events_positions(end,2),events_positions(end,3),'or',LineWidth=3);
xlabel('x'); ylabel('y'); zlabel('z');
axis padded
%%
figure('Color','white'); 
plot3(vicon_transformed(:,1),vicon_transformed(:,2),vicon_transformed(:,3),'k')
hold on
plot3(vicon_transformed(1,1),vicon_transformed(1,2),vicon_transformed(1,3),'ok',LineWidth=3);
plot3(vicon_transformed(end,1),vicon_transformed(end,2),vicon_transformed(end,3),'or',LineWidth=3);
xlabel('x'); ylabel('y'); zlabel('z');
axis equal
%%
figure('Color','white'); 
plot3(vicon_transformed(:,1),vicon_transformed(:,2),vicon_transformed(:,3),'k')
hold on
plot3(vicon_transformed(base_points_idx(1),1),vicon_transformed(base_points_idx(1),2),vicon_transformed(base_points_idx(1),3),'ok',LineWidth=3);
plot3(vicon_transformed(base_points_idx(end),1),vicon_transformed(base_points_idx(end),2),vicon_transformed(base_points_idx(end),3),'or',LineWidth=3);
xlabel('x'); ylabel('y'); zlabel('z');
axis equal
end

%%
%Eine Trajectorie nach der anderen plotten!
figure('Color','white');
for i = 1:size(trajectories_soll,2) 
    % figure('Color','white');
    % plot3(vicon_transformed(:,1),vicon_transformed(:,2),vicon_transformed(:,3),'k',LineWidth=3)
    hold on
    plot3(trajectories_ist{i}(:,2),trajectories_ist{i}(:,3),trajectories_ist{i}(:,4),'b')
    plot3(trajectories_soll{i}(:,1),trajectories_soll{i}(:,2),trajectories_soll{i}(:,3),'r')
    legend('ist','soll')
    xlabel('x'); ylabel('y'); zlabel('z');
% axis equal
end
hold off


%%
% Alle Segmente nach der anderen plotten!
figure('Color','white');
for i = 1:size(segments_soll,2) 
    % figure('Color','white');
    % plot3(vicon_transformed(:,1),vicon_transformed(:,2),vicon_transformed(:,3),'k',LineWidth=3)
    hold on
    plot3(segments_ist{i}(:,2),segments_ist{i}(:,3),segments_ist{i}(:,4),'b')
    plot3(segments_soll{i}(:,1),segments_soll{i}(:,2),segments_soll{i}(:,3),'r')
    legend('ist','soll')
    xlabel('x'); ylabel('y'); zlabel('z');
% axis equal
end
hold off
%% Plotten einzelner Segmente
figure('Color','white');
% plot3(vicon_transformed(:,1),vicon_transformed(:,2),vicon_transformed(:,3),'k',LineWidth=3)
hold on
plot3(segments_ist{end-1}(:,2),segments_ist{end-1}(:,3),segments_ist{end-1}(:,4),'b')
plot3(segments_abb{end-1}(:,2),segments_abb{end-1}(:,3),segments_abb{end-1}(:,4),'r')
plot3(segments_ist{end}(:,2),segments_ist{end}(:,3),segments_ist{end}(:,4),'b')
plot3(segments_abb{end}(:,2),segments_abb{end}(:,3),segments_abb{end}(:,4),'r')
% plot3(segments_soll{1}(:,1),segments_soll{1}(:,2),segments_soll{1}(:,3),'r')
% plot3(segments_ist{82}(:,2),segments_ist{82}(:,3),segments_ist{82}(:,4),'b')
% plot3(segments_soll{82}(:,1),segments_soll{82}(:,2),segments_soll{82}(:,3),'r')
% plot3(segments_ist{83}(:,2),segments_ist{83}(:,3),segments_ist{83}(:,4),'b')
% plot3(segments_soll{83}(:,1),segments_soll{83}(:,2),segments_soll{83}(:,3),'r')
legend('ist','soll')
xlabel('x'); ylabel('y'); zlabel('z');
%% PLOT DER KOORDNIATENTRANSFORMATION

% blau = [0 0.4470 0.7410]; % Standard Blau
% rot = [0.78 0 0];
% 
% figure('Color','white');
% hold on
% % Dazuplotten der maximalen Abstände
% plot3(abb_reference(:,1),abb_reference(:,2),abb_reference(:,3),LineWidth=2)
% plot3(vicon_reference_transformed(:,1),vicon_reference_transformed(:,2),vicon_reference_transformed(:,3),Color=rot,LineWidth=2)
% % plot3(vicon_reference(:,1),vicon_reference(:,2),vicon_reference(:,3),Color=rot,LineWidth=2)
% legend('Steuerung','Vicon')
% view(3)
% xlabel('$x$'); ylabel('$y$'); zlabel('$z$');
% axis equal
% axis padded
% grid on

%% Plot der maximalen und mittleren Abweichungen

plot_errors(segments_ist,struct_dtw_segments,struct_frechet_segments,struct_lcss_segments,struct_sidtw_segments,struct_euclidean_segments);

%% Upload in PostgreSQL 
if upload2postgresql == true
    
    % Verbindung mit PostgreSQL
    datasource = "RobotervermessungMATLAB";
    username = "postgres";
    password = "200195Beto";
    conn = postgresql(datasource,username,password);

    % Überprüfe Verbindung
    if isopen(conn)
        disp('Verbindung erfolgreich hergestellt');
    else
        disp('Verbindung fehlgeschlagen');
    end

    postgres_data = table();
    postgres_data_segments = table();
    postgres_dtw = table();
    postgres_dtw_segments = table();
    postgres_euclidean = table();
    postgres_euclidean_segments = table();
    postgres_frechet = table();
    postgres_frechet_segments = table();
    postgres_header = table();
    postgres_header_segments = table();
    postgres_lcss = table();
    postgres_lcss_segments = table();
    postgres_sidtw = table();
    postgres_sidtw_segments = table();

    for i = 1:length(struct_data)
        row = struct2table(struct_data{i}, "AsArray", true);
        
        % Format string columns
        row.trajectory_header_id = string(row.trajectory_header_id{1});
        row.segment_id = string(row.segment_id{1});
        
        % Identify and format double array columns to PostgreSQL array format
        for col = row.Properties.VariableNames
            if isnumeric(row.(col{1}){1})
                % Convert double array to PostgreSQL array format
                row.(col{1}) = {sprintf('{%s}', strjoin(string(row.(col{1}){1}), ','))};
            end
        end
        
        postgres_data = [postgres_data; row];
    end

    for i = 1:length(struct_data_segments)
        row = struct2table(struct_data_segments{i}, "AsArray", true);
        
        % Format string columns
        row.trajectory_header_id = string(row.trajectory_header_id{1});
        row.segment_id = string(row.segment_id{1});
        
        % Format double array columns to PostgreSQL array format
        doubleColumns = row.Properties.VariableNames(3:end);
        for col = doubleColumns
            row.(col{1}) = {sprintf('{%s}', strjoin(string(row.(col{1}){1}), ','))};
        end
        
        postgres_data_segments = [postgres_data_segments; row];
    end

    for i = 1:length(struct_dtw)
        row = struct2table(struct_dtw{i}, "AsArray", true);
        
        % Format string columns
        row.trajectory_header_id = string(row.trajectory_header_id);
        row.segment_id = string(row.segment_id);
        
        % Identify and format double array columns to PostgreSQL array format
        for col = row.Properties.VariableNames
            colData = row.(col{1});
            
            % Handle cases where the data is within a cell array
            if iscell(colData)
                colData = colData{1};
            end
            
            % Check if the data is a numeric array with more than one element
            if isnumeric(colData) && ismatrix(colData) && numel(colData) > 1
                % Convert double array to PostgreSQL array format
                row.(col{1}) = {sprintf('{%s}', strjoin(string(colData), ','))};
            end
        end
        
        postgres_dtw = [postgres_dtw; row];
    end

    for i = 1:length(struct_dtw_segments)
        row = struct2table(struct_dtw_segments{i}, "AsArray", true);
        
        % Format string columns
        row.trajectory_header_id = string(row.trajectory_header_id);
        row.segment_id = string(row.segment_id);
        
        % Identify and format double array columns to PostgreSQL array format
        for col = row.Properties.VariableNames
            colData = row.(col{1});
            
            % Handle cases where the data is within a cell array
            if iscell(colData)
                colData = colData{1};
            end
            
            % Check if the data is a numeric array with more than one element
            if isnumeric(colData) && ismatrix(colData) && numel(colData) > 1
                % Convert double array to PostgreSQL array format
                row.(col{1}) = {sprintf('{%s}', strjoin(string(colData), ','))};
            end
        end
        
        postgres_dtw_segments = [postgres_dtw_segments; row];
    end

    for i = 1:length(struct_sidtw)
        row = struct2table(struct_sidtw{i}, 'AsArray', true);
        
        % Format string columns
        row.trajectory_header_id = string(row.trajectory_header_id);
        row.segment_id = string(row.segment_id);
        
        % Identify and format double array columns to PostgreSQL array format
        for col = row.Properties.VariableNames
            colData = row.(col{1});
            
            % Handle cases where the data is within a cell array
            if iscell(colData)
                colData = colData{1};
            end
            
            % Special handling for dtw_X, dtw_Y, dtw_accdist, and dtw_path
            if ismember(col, {'dtw_X', 'dtw_Y', 'dtw_accdist', 'dtw_path'})
                if isnumeric(colData) && ismatrix(colData)
                    % For 2D arrays (e.g., dtw_X, dtw_Y)
                    if size(colData, 2) > 1
                        arrayStr = arrayfun(@(r) sprintf('{%s}', strjoin(string(colData(r,:)), ',')), 1:size(colData,1), 'UniformOutput', false);
                        row.(col{1}) = {sprintf('{%s}', strjoin(arrayStr, ','))};
                    else
                        % For 1D arrays (e.g., dtw_accdist)
                        row.(col{1}) = {sprintf('{%s}', strjoin(string(colData), ','))};
                    end
                elseif isstruct(colData)
                    % For struct arrays (e.g., dtw_path)
                    jsonArray = arrayfun(@(s) ...
                        sprintf('{"x": %f, "y": %f}', s.x, s.y), ...
                        colData, 'UniformOutput', false);
                    row.(col{1}) = {sprintf('[%s]', strjoin(jsonArray, ','))};
                end
            elseif isnumeric(colData) && ismatrix(colData) && numel(colData) > 1
                % Convert other numeric arrays to PostgreSQL array format
                row.(col{1}) = {sprintf('{%s}', strjoin(string(colData(:)'), ','))};
            end
        end
        
        postgres_sidtw = [postgres_sidtw; row];
    end

    for i = 1:length(struct_euclidean)
        row = struct2table(struct_euclidean{i}, "AsArray", true);
        
        % Format string columns
        row.trajectory_header_id = string(row.trajectory_header_id);
        row.segment_id = string(row.segment_id);
        
        % Identify and format double array columns to PostgreSQL array format
        for col = row.Properties.VariableNames
            colData = row.(col{1});
            
            % Handle cases where the data is within a cell array
            if iscell(colData)
                colData = colData{1};
            end
            
            % Special handling for the euclidean_intersections struct
            if isstruct(colData) && strcmp(col, 'euclidean_intersections')
                % Convert the struct into a JSON-like string
                jsonArray = arrayfun(@(s) ...
                    sprintf('{"x": [%s], "y": [%s], "z": [%s]}', ...
                    strjoin(string(s.x), ','), ...
                    strjoin(string(s.y), ','), ...
                    strjoin(string(s.z), ',')), ...
                    colData, 'UniformOutput', false);
                row.(col{1}) = {sprintf('[%s]', strjoin(jsonArray, ','))};
            end
            
            % Check if the data is a numeric array with more than one element
            if isnumeric(colData) && ismatrix(colData) && numel(colData) > 1
                % Convert double array to PostgreSQL array format
                row.(col{1}) = {sprintf('{%s}', strjoin(string(colData), ','))};
            end
        end
        
        postgres_euclidean = [postgres_euclidean; row];
    end

    for i = 1:length(struct_euclidean_segments)
        row = struct2table(struct_euclidean_segments{i}, "AsArray", true);
        
        % Format string columns
        row.trajectory_header_id = string(row.trajectory_header_id);
        row.segment_id = string(row.segment_id);
        
        % Identify and format double array columns to PostgreSQL array format
        for col = row.Properties.VariableNames
            colData = row.(col{1});
            
            % Handle cases where the data is within a cell array
            if iscell(colData)
                colData = colData{1};
            end
            
            % Special handling for the euclidean_intersections struct
            if isstruct(colData) && strcmp(col, 'euclidean_intersections')
                % Convert the struct into a JSON-like string
                jsonArray = arrayfun(@(s) ...
                    sprintf('{"x": [%s], "y": [%s], "z": [%s]}', ...
                    strjoin(string(s.x), ','), ...
                    strjoin(string(s.y), ','), ...
                    strjoin(string(s.z), ',')), ...
                    colData, 'UniformOutput', false);
                row.(col{1}) = {sprintf('[%s]', strjoin(jsonArray, ','))};
            end
            
            % Check if the data is a numeric array with more than one element
            if isnumeric(colData) && ismatrix(colData) && numel(colData) > 1
                % Convert double array to PostgreSQL array format
                row.(col{1}) = {sprintf('{%s}', strjoin(string(colData), ','))};
            end
        end
        
        postgres_euclidean_segments = [postgres_euclidean_segments; row];
    end

    for i = 1:length(struct_frechet)
        row = struct2table(struct_frechet{i}, "AsArray", true);
        
        % Format string columns
        row.trajectory_header_id = string(row.trajectory_header_id);
        row.segment_id = string(row.segment_id);
        
        % Identify and format double array columns to PostgreSQL array format
        for col = row.Properties.VariableNames
            colData = row.(col{1});
            
            % Handle cases where the data is within a cell array
            if iscell(colData)
                colData = colData{1};
            end
            
            % Check if the data is a numeric array with more than one element
            if isnumeric(colData) && ismatrix(colData) && numel(colData) > 1
                % Convert double array to PostgreSQL array format
                row.(col{1}) = {sprintf('{%s}', strjoin(string(colData), ','))};
            end
        end
        
        postgres_frechet = [postgres_frechet; row];
    end

    for i = 1:length(struct_frechet_segments)
        row = struct2table(struct_frechet_segments{i}, "AsArray", true);
        
        % Format string columns
        row.trajectory_header_id = string(row.trajectory_header_id);
        row.segment_id = string(row.segment_id);
        
        % Identify and format double array columns to PostgreSQL array format
        for col = row.Properties.VariableNames
            colData = row.(col{1});
            
            % Handle cases where the data is within a cell array
            if iscell(colData)
                colData = colData{1};
            end
            
            % Check if the data is a numeric array with more than one element
            if isnumeric(colData) && ismatrix(colData) && numel(colData) > 1
                % Convert double array to PostgreSQL array format
                row.(col{1}) = {sprintf('{%s}', strjoin(string(colData), ','))};
            end
        end
        
        postgres_frechet_segments = [postgres_frechet_segments; row];
    end

    for i = 1:length(struct_header)
        row = struct2table(struct_header{i}, "AsArray", true);
        
        % Format string columns
        row.data_id = string(row.data_id);        
        % Identify and format double array columns to PostgreSQL array format
        for col = row.Properties.VariableNames
            colData = row.(col{1});
            
            % Handle cases where the data is within a cell array
            if iscell(colData)
                colData = colData{1};
            end
            
            % Check if the data is a numeric array with more than one element
            if isnumeric(colData) && ismatrix(colData) && numel(colData) > 1
                % Convert double array to PostgreSQL array format
                row.(col{1}) = {sprintf('{%s}', strjoin(string(colData), ','))};
            end
        end
        
        postgres_header = [postgres_header; row];
    end

    for i = 1:length(struct_header_segments)
        row = struct2table(struct_header_segments{i}, "AsArray", true);
        
        % Format string columns
        row.trajectory_header_id = string(row.trajectory_header_id);
        row.segment_id = string(row.segment_id);

        % Identify and format double array columns to PostgreSQL array format
        for col = row.Properties.VariableNames
            colData = row.(col{1});
            
            % Handle cases where the data is within a cell array
            if iscell(colData)
                colData = colData{1};
            end
            
            % Check if the data is a numeric array with more than one element
            if isnumeric(colData) && ismatrix(colData) && numel(colData) > 1
                % Convert double array to PostgreSQL array format
                row.(col{1}) = {sprintf('{%s}', strjoin(string(colData), ','))};
            end
        end
        
        postgres_header_segments = [postgres_header_segments; row];
    end

    for i = 1:length(struct_lcss)
        row = struct2table(struct_lcss{i}, "AsArray", true);
        
        % Format string columns
        row.trajectory_header_id = string(row.trajectory_header_id);
        row.segment_id = string(row.segment_id);
        
        % Identify and format double array columns to PostgreSQL array format
        for col = row.Properties.VariableNames
            colData = row.(col{1});
            
            % Handle cases where the data is within a cell array
            if iscell(colData)
                colData = colData{1};
            end
            
            % Check if the data is a numeric array with more than one element
            if isnumeric(colData) && ismatrix(colData) && numel(colData) > 1
                % Convert double array to PostgreSQL array format
                row.(col{1}) = {sprintf('{%s}', strjoin(string(colData), ','))};
            end
        end
        
        postgres_lcss = [postgres_lcss; row];
    end

    for i = 1:length(struct_lcss_segments)
        row = struct2table(struct_lcss_segments{i}, "AsArray", true);
        
        % Format string columns
        row.trajectory_header_id = string(row.trajectory_header_id);
        row.segment_id = string(row.segment_id);
        
        % Identify and format double array columns to PostgreSQL array format
        for col = row.Properties.VariableNames
            colData = row.(col{1});
            
            % Handle cases where the data is within a cell array
            if iscell(colData)
                colData = colData{1};
            end
            
            % Check if the data is a numeric array with more than one element
            if isnumeric(colData) && ismatrix(colData) && numel(colData) > 1
                % Convert double array to PostgreSQL array format
                row.(col{1}) = {sprintf('{%s}', strjoin(string(colData), ','))};
            end
        end
        
        postgres_lcss_segments = [postgres_lcss_segments; row];
    end

    for i = 1:length(struct_sidtw_segments)
        row = struct2table(struct_sidtw_segments{i}, 'AsArray', true);
        
        % Format string columns
        row.trajectory_header_id = string(row.trajectory_header_id);
        row.segment_id = string(row.segment_id);
        
        % Identify and format double array columns to PostgreSQL array format
        for col = row.Properties.VariableNames
            colData = row.(col{1});
            
            % Handle cases where the data is within a cell array
            if iscell(colData)
                colData = colData{1};
            end
            
            % Special handling for dtw_X, dtw_Y, dtw_accdist, and dtw_path
            if ismember(col, {'dtw_X', 'dtw_Y', 'dtw_accdist', 'dtw_path'})
                if isnumeric(colData) && ismatrix(colData)
                    % For 2D arrays (e.g., dtw_X, dtw_Y)
                    if size(colData, 2) > 1
                        arrayStr = arrayfun(@(r) sprintf('{%s}', strjoin(string(colData(r,:)), ',')), 1:size(colData,1), 'UniformOutput', false);
                        row.(col{1}) = {sprintf('{%s}', strjoin(arrayStr, ','))};
                    else
                        % For 1D arrays (e.g., dtw_accdist)
                        row.(col{1}) = {sprintf('{%s}', strjoin(string(colData), ','))};
                    end
                elseif isstruct(colData)
                    % For struct arrays (e.g., dtw_path)
                    jsonArray = arrayfun(@(s) ...
                        sprintf('{"x": %f, "y": %f}', s.x, s.y), ...
                        colData, 'UniformOutput', false);
                    row.(col{1}) = {sprintf('[%s]', strjoin(jsonArray, ','))};
                end
            elseif isnumeric(colData) && ismatrix(colData) && numel(colData) > 1
                % Convert other numeric arrays to PostgreSQL array format
                row.(col{1}) = {sprintf('{%s}', strjoin(string(colData(:)'), ','))};
            end
        end
        
        postgres_sidtw_segments = [postgres_sidtw_segments; row];
    end

    % Close connection after all operations are done
    %sqlwrite(conn,"trajectories.trajectories_header", postgres_header);
    %sqlwrite(conn,"trajectories.trajectories_header_segments", postgres_header_segments);
    %sqlwrite(conn,"trajectories.trajectories_data", postgres_data);
    %sqlwrite(conn,"trajectories.trajectories_data", postgres_data_segments);
    %sqlwrite(conn,"trajectories.trajectories_metrics_euclidean", postgres_euclidean);
    %sqlwrite(conn,"trajectories.trajectories_metrics_euclidean", postgres_euclidean_segments);
    %sqlwrite(conn,"trajectories.trajectories_header_segments", postgres_header_segments);

    
end

%% UPLOAD VON DATEN


    %sqlwrite(conn, "trajectories.trajectories_metrics_dtw_johnen", postgres_sidtw_segments);
    %sqlwrite(conn, "trajectories.trajectories_metrics_discrete_frechet", postgres_frechet);
    %sqlwrite(conn, "trajectories.trajectories_metrics_discrete_frechet", postgres_frechet_segments);
    %sqlwrite(conn, "trajectories.trajectories_metrics_lcss", postgres_lcss);
    %sqlwrite(conn, "trajectories.trajectories_metrics_lcss", postgres_lcss_segments);



