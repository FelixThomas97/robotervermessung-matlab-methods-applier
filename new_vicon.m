clear
% filename = 'squares_isodiagonalA&B_300Hz_v2500_1.csv';
filename = 'record_20240702_153511_squares_isodiagonalA&B_final.csv';
% filename = 'record_20240702_155846_squares_isodiagonalA&B_final.csv';
data = importfile_vicon_abb_sync(filename);

% Wenn die Transformation anhand der Timestamps erfolgen soll (Sonst über Ereignisse und Stützpunkte)!
sync_time = false;

% Löschen nicht benötigten Timesstamps
data.sec =[];
data.nanosec = [];

% Double Array
data_ = table2array(data);

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

% Array mit allen Vicon Daten
vicon = [vicon_timestamps vicon_pose vicon_velocity vicon_accel];

clear clean_NaN filename vicon_pose


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


%% Füllen der Spalten der ABB Matrix für alle Positionsdaten: 
% Ausgangslage ist, dass die Positionesdaten am meisten Zellen besitzen 

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

clear idx idx1 idx2 idx_chain idx_from_idx is_point j i search_term data_ vicon_pose diff

% % Ausgabe der maximalen Geschwindigkeit
% velocity_max_vicon = max(vicon_velocity(:,4));
% velocity_max_abb = max(abb_velocity);

%% Koordinaten Trasformation

% Schrittweite der Indizes für die nach gleichen Punkten gesucht wird
min_index_distance = round(freq_vicon/2);
% Herrausfinden der Stützpunkte und deren Indizes sowie den Abständen
vicon_get_basepoints(vicon_positions, min_index_distance);

% Ersten Punkt mitteln und Standabweichung 
p1 = vicon_positions(1:idx_vicon_base_points(1),:);
stdev_p1 = std(p1);
stdevnorm_p1 = norm(stdev_p1)*10;
p1 = mean(p1);

% Berechnung erneut mit Standabweichung
vicon_get_basepoints(vicon_positions, min_index_distance,stdevnorm_p1);

% clear min_index_distance stdevnorm_p1 stdev_p1


%% Plotten 


% points = vicon_base_points;
% points(:,1) = points(:,1)+1000;
% 
% figure('Color','white'); 
% plot3(vicon_positions(:,1),vicon_positions(:,2),vicon_positions(:,3),'r',LineWidth=2)
% hold on
% plot3(points(:,1),points(:,2),points(:,3),'b',LineWidth=2)
% axis equal
% plot3(points(1,1),points(1,2),points(1,3),'og',LineWidth=2)
% plot3(points(end,1),points(end,2),points(end,3),'ok',LineWidth=5)

%% Transformation der Koordinaten von Vicon-System zu Abb-System

if sync_time == true 
    % Ermittlung von Referenzpunkten für die Koordinatentransformation
    % --> hier anhand von Punkten deren Timestamps sehr nahe beieinander liegen
    sync_indizes = [];
    for i = 1:length(abb_timestamps)
        for j = 1:length(vicon_timestamps)
            if abs(abb_timestamps(i)-vicon_timestamps(j)) < 1*1e-4 % max Intervall zwischen zwie Timestamps
                sync_indizes = [sync_indizes; i j];
            end
        end
    end

    % Erstellen der Transformationsvektoren (Referenzpunkte)
    abb_reference = abb_positions(sync_indizes(:,1),:);
    vicon_reference = vicon_positions(sync_indizes(:,2),:);

% Wenn die Transformation anhand der ermittelten Stützpunkte erfolgen soll
else

    % Ermittlung des Startpunkts im ABB Koordinatensystem über Mittelwert
    diffs = diff(abb_positions);
    dists = sqrt(sum(diffs.^2, 2));
    
    % Erste Index der Distanz der größer ist
    first_idx = find(dists > 0.05,1);
    p1_abb = mean(abb_positions(1:first_idx-1,:));

    % Erstellen der Transformationsvektoren (Referenzpunkte)
    abb_reference = [p1_abb; events_positions];
    % abb_reference = events_positions;
    vicon_reference = vicon_base_points;

    % Überprüfen der Dimensionen der Transformationsvektoren
    if ~isequal(size(abb_reference), size(vicon_reference))
        error('Die Referenzpunkte für die Koordinatentransformation haben eine unterschiedliche Anzahl an Elementen! Setzen Sie den Paramater sync_time = true oder passen Sie die Anzahl der vicon_base_points oder events_positions an!');
    end
    
end
%%

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

clear U V T R H 

% Berechnung Abweichungen der Referenzdaten
diffs_reference = (vicon_reference_transformed-abb_reference);
diffs_reference_norm = norm(diffs_reference)/length(diffs_reference);

a = zeros(length(diffs_reference),1);
for i = 1:length(diffs_reference)
    a(i) = norm(diffs_reference(i,:));
end

diffs_mean = mean(a);
[diffs_max, diffs_idx_max] = max(abs(a));

[eucl_interpolation,eucl_distances,eucl_t] = distance2curve(vicon_transformed,abb_positions,'linear');
eucl_mean = mean(eucl_distances);
eucl_max = max(eucl_distances);

%%
figure;
plot3(vicon_transformed(:,1),vicon_transformed(:,2),vicon_transformed(:,3))
hold on
plot3(abb_reference(:,1),abb_reference(:,2),abb_reference(:,3))
% plot3(abb_positions(:,1),abb_positions(:,2),abb_positions(:,3))
plot3(vicon_reference_transformed(:,1),vicon_reference_transformed(:,2),vicon_reference_transformed(:,3))

% Dazuplotten der maximalen Abstände
plot3(abb_reference(diffs_idx_max,1),abb_reference(diffs_idx_max,2),abb_reference(diffs_idx_max,3),'or',LineWidth=3)
plot3(vicon_reference_transformed(diffs_idx_max,1),vicon_reference_transformed(diffs_idx_max,2),vicon_reference_transformed(diffs_idx_max,3),'ob',LineWidth=3)
legend('vicon transformed','abb','vicon')
view(2)

% % VERGLEICH DER STÜTZPUNKTE UND OB DIESE ZUSAMMENPASSEN
% % Anfangs und Endpunkt der Stützpunkte bei ABB und transformierten Vicon-Daten
% figure('Color','white'); 
% plot3(events_positions(:,1),events_positions(:,2),events_positions(:,3),'k')
% hold on
% plot3(abb_positions(1,1),abb_positions(1,2),abb_positions(1,3),'og',LineWidth=3)
% plot3(events_positions(1,1),events_positions(1,2),events_positions(1,3),'ok',LineWidth=3);
% plot3(events_positions(end,1),events_positions(end,2),events_positions(end,3),'or',LineWidth=3);
% axis equal
% 
% figure('Color','white'); 
% plot3(vicon_transformed(:,1),vicon_transformed(:,2),vicon_transformed(:,3),'k')
% hold on
% plot3(vicon_transformed(1,1),vicon_transformed(1,2),vicon_transformed(1,3),'ok',LineWidth=3);
% plot3(vicon_transformed(end,1),vicon_transformed(end,2),vicon_transformed(end,3),'or',LineWidth=3);
% axis equal
% 
% figure('Color','white'); 
% plot3(vicon_transformed(:,1),vicon_transformed(:,2),vicon_transformed(:,3),'k')
% hold on
% plot3(vicon_transformed(idx_vicon_base_points(1),1),vicon_transformed(idx_vicon_base_points(1),2),vicon_transformed(idx_vicon_base_points(1),3),'ok',LineWidth=3);
% plot3(vicon_transformed(idx_vicon_base_points(end),1),vicon_transformed(idx_vicon_base_points(end),2),vicon_transformed(idx_vicon_base_points(end),3),'or',LineWidth=3);
% axis equal