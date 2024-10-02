%% Eingabe der ID

bahn_id_ = '172104917';


%% Verbindung mit PostgreSQL

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

clear datasource username password

%% Suche nach zugehörigem "Calibration Run"

query_cal = 'SELECT * FROM robotervermessung.bewegungsdaten.bahn_info WHERE robotervermessung.bewegungsdaten.bahn_info.calibration_run = true';

% Abfrage ausführen und Ergebnisse abrufen
data_cal_info = fetch(conn, query_cal);

% Finden des zugehörigen Calibration Runs anhand der kürzesten vergangen Zeit
check_bahn_id = str2double(data_cal_info.bahn_id);
diff_bahn_id = check_bahn_id - str2double(bahn_id_);

[min_diff,min_diff_idx] = min(abs(diff_bahn_id));

% Wenn eine Kalibierungsdatei vorliegt wird diese für die
% Koordinatentransformation genutzt, ansonsten die wird die gewählte Datei
% selbst verwendet. 
if diff_bahn_id(min_diff_idx) < 0
    calibration_id = data_cal_info{min_diff_idx,'bahn_id'};
    disp('Kalibrierungs-Datei vorhanden! ID der Messaufnahme: ' + calibration_id)
else
    calibration_id = bahn_id_;
    disp('Zu dem ausgewählten Datensatz liegt keine Kalibirierungsdatei vor!')
end

% Extrahieren der Calibrierungs-Daten
tablename_cal = 'robotervermessung.bewegungsdaten.bahn_events';
opts_cal = databaseImportOptions(conn,tablename_cal);
opts_cal.RowFilter = opts_cal.RowFilter.bahn_id == calibration_id;
data_cal_soll = sqlread(conn,tablename_cal,opts_cal);
data_cal_soll = sortrows(data_cal_soll,'timestamp');

tablename_cal = 'robotervermessung.bewegungsdaten.bahn_pose_ist';
opts_cal = databaseImportOptions(conn,tablename_cal);
opts_cal.RowFilter = opts_cal.RowFilter.bahn_id == calibration_id;
data_cal_ist= sqlread(conn,tablename_cal,opts_cal);
data_cal_ist = sortrows(data_cal_ist,'timestamp');

% Positionsdaten für Koordinatentransformation
postgres_calibration_run(data_cal_ist,data_cal_soll)

clear data_cal data_cal_info diff_bahn_id min_diff_bahn_id min_idx opts_cal tablename_cal check_bahn_id
clear query_cal min_diff_idx min_diff
clear data_cal_ist data_cal_soll

%% Anzahl an Segmenten bestimmen 

% Auslesen der Anzahl der Segmente der gesamten Messaufnahme
query = ['SELECT bahn_id, np_ereignisse FROM robotervermessung.bewegungsdaten.bahn_info ' ...
         'WHERE robotervermessung.bewegungsdaten.bahn_info.bahn_id = ''' bahn_id_ ''''];
num_segments = fetch(conn, query);
num_segments = num_segments.np_ereignisse;

% Auslesen der gesamten Ist-Daten
query = ['SELECT * FROM robotervermessung.bewegungsdaten.bahn_pose_ist ' ...
        'WHERE robotervermessung.bewegungsdaten.bahn_pose_ist.bahn_id = ''' bahn_id_ ''''];
data_ist = fetch(conn, query);
data_ist = sortrows(data_ist,'timestamp');

% Auslesen der gesamten Soll-Daten
query = ['SELECT * FROM robotervermessung.bewegungsdaten.bahn_position_soll ' ...
        'WHERE robotervermessung.bewegungsdaten.bahn_position_soll.bahn_id = ''' bahn_id_ ''''];
data_soll = fetch(conn, query);
data_soll = sortrows(data_soll,'timestamp');

%% Extraktion und Separation der Segmente der Gesamtaufname

% Alle Segment-ID's 
query = ['SELECT segment_id FROM robotervermessung.bewegungsdaten.bahn_events ' ...
    'WHERE robotervermessung.bewegungsdaten.bahn_events.bahn_id = ''' bahn_id_ ''''];

segment_ids = fetch(conn,query);

% % % IST-DATEN % % %
% Extraktion der Indizes der Segmente 
seg_id = split(data_ist.segment_id, '_');
seg_id = str2double(seg_id(:,2));
idx_new_seg_ist = zeros(num_segments,1);


% Suche nach den Indizes bei denen sich die Segmentnr. ändert
k = 0;
idx = 1;
for i = 1:1:length(seg_id)
    if seg_id(i) == k
        idx = idx + 1;
    else
        k = k +1;
        idx_new_seg_ist(k) = idx;
        idx = idx+1;
    end
end

% Speichern der einzelnen Semgente in Tabelle
segments_ist = array2table([{data_ist.segment_id(1)} data_ist.x_ist(1:idx_new_seg_ist(1)-1) data_ist.y_ist(1:idx_new_seg_ist(1)-1) data_ist.z_ist(1:idx_new_seg_ist(1)-1)], "VariableNames",{'segment_id','x_ist','y_ist','z_ist'});

for i = 1:num_segments

    if i == length(idx_new_seg_ist)
        segments_ist(i+1,:) = array2table([{segment_ids{i,:}} data_ist.x_ist(idx_new_seg_ist(i):end) data_ist.y_ist(idx_new_seg_ist(i):end) data_ist.z_ist(idx_new_seg_ist(i):end)]);
    else
        segments_ist(i+1,:) = array2table([{segment_ids{i,:}} data_ist.x_ist(idx_new_seg_ist(i):idx_new_seg_ist(i+1)-1) data_ist.y_ist(idx_new_seg_ist(i):idx_new_seg_ist(i+1)-1) data_ist.z_ist(idx_new_seg_ist(i):idx_new_seg_ist(i+1)-1)]);
    end

end

% % % SOLL-DATEN % % %
seg_id = split(data_soll.segment_id, '_');
seg_id = str2double(seg_id(:,2));
idx_new_seg_soll = zeros(num_segments,1);

k = 0;
idx = 1;
for i = 1:1:length(seg_id)
    if seg_id(i) == k
        idx = idx + 1;
    else
        k = k +1;
        idx_new_seg_soll(k) = idx;
        idx = idx+1;
    end
end

segments_soll = array2table([{data_soll.segment_id(1)} data_soll.x_soll(1:idx_new_seg_soll(1)-1) data_soll.y_soll(1:idx_new_seg_soll(1)-1) data_soll.z_soll(1:idx_new_seg_soll(1)-1)], "VariableNames",{'segment_id','x_soll','y_soll','z_soll'});
for i = 1:num_segments
    if i == length(idx_new_seg_soll)
        segments_soll(i+1,:) = array2table([{segment_ids{i,:}} data_soll.x_soll(idx_new_seg_soll(i):end) data_soll.y_soll(idx_new_seg_soll(i):end) data_soll.z_soll(idx_new_seg_soll(i):end)]);
    else
        segments_soll(i+1,:)= array2table([{segment_ids{i,:}} data_soll.x_soll(idx_new_seg_soll(i):idx_new_seg_soll(i+1)-1) data_soll.y_soll(idx_new_seg_soll(i):idx_new_seg_soll(i+1)-1) data_soll.z_soll(idx_new_seg_soll(i):idx_new_seg_soll(i+1)-1)]);
    end    
end

% Koordinatentransformation für alle Segemente
segments_trafo = table();
for i = 1:1:num_segments+1
    postgres_coord_trafo(segments_ist(i,:),trafo_rot, trafo_trans)
    segments_trafo(i,:) = pos_ist_trafo;
end

clear idx k seg_id

%% Berechnung der Metriken

%%%%%%%% Euklidean %%%%%%%%

% Berechnung der euklidsichen Abstände für alle Segmente
table_euclidean_info = table();
table_euclidean_distances = cell(num_segments+1,1);
for i = 1:1:num_segments+1

    if istable(segments_trafo)
        segment_trafo = [segments_trafo.x_ist{i}, segments_trafo.y_ist{i}, segments_trafo.z_ist{i}];
        segment_soll = [segments_soll.x_soll{i}, segments_soll.y_soll{i}, segments_soll.z_soll{i}];
    end
    
    [~,euclidean_distances,~] = distance2curve(segment_trafo,segment_soll,'linear');

    if i == 1
        postgres_euclidean(euclidean_distances, bahn_id_, data_ist.segment_id(1))
        table_euclidean_info = seg_euclidean_info;
        table_euclidean_distances{1} = seg_euclidean_distances; 
    else
        postgres_euclidean(euclidean_distances, bahn_id_, segment_ids{i-1,:})
        table_euclidean_info(i,:) = seg_euclidean_info;
        table_euclidean_distances{i} = seg_euclidean_distances; 
    end
end

% Berechnung der euklidischen Kennzahlen für die Gesamtmessung
table_eucl_all_info = table();
table_eucl_all_info.bahn_id = {bahn_id_};
table_eucl_all_info.calibration_id = {calibration_id};
table_eucl_all_info.euclidean_min_distance = min(table_euclidean_info.euclidean_min_distance);
table_eucl_all_info.euclidean_max_distance = max(table_euclidean_info.euclidean_max_distance);
table_eucl_all_info.euclidean_average_distance = mean(table_euclidean_info.euclidean_average_distance);
table_eucl_all_info.euclidean_standard_deviation = mean(table_euclidean_info.euclidean_standard_deviation);

clear euclidean_distances seg_euclidean_info seg_euclidean_distances
clear pos_ist_trafo segment_ist segment_soll segment_trafo

%% Plotten der transformierten Positionen 

% % Farben
% c1 = [0 0.4470 0.7410];
% c2 = [0.8500 0.3250 0.0980];
% c3 = [0.9290 0.6940 0.1250];
% c4 = [0.4940 0.1840 0.5560];
% c5 = [0.4660 0.6740 0.1880];
% c6 = [0.3010 0.7450 0.9330];
% c7 = [0.6350 0.0780 0.1840];
% 
% figure 
% plot3(pos_ist_trafo(:,1),pos_ist_trafo(:,2),pos_ist_trafo(:,3),Color=c1)
% hold on
% plot3(pos_soll(:,1),pos_soll(:,2),pos_soll(:,3))
% plot3(pos_soll(1,1),pos_soll(1,2),pos_soll(1,3),'ok',LineWidth=3)
% plot3(pos_soll(end,1),pos_soll(end,2),pos_soll(end,3),'or',LineWidth=3)
% 
% view(2)

% clear c1 c2 c3 c4 c5 c6 c7 



