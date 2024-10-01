%% Eingabe der ID

bahn_id_ = '172104917';
segment_id_ = '172104917_4';

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

clear data_cal data_cal_info diff_bahn_id min_diff_bahn_id min_idx opts_cal tablename_cal check_bahn_id
clear query_cal

%% Suche nach der gewünschten ID
tablename1 = 'robotervermessung.bewegungsdaten.bahn_pose_ist';
tablename2 = 'robotervermessung.bewegungsdaten.bahn_position_soll';

opts1 = databaseImportOptions(conn,tablename1);
opts2 = databaseImportOptions(conn,tablename2);
% vars = opts1.SelectedVariableNames;
% varOpts = getoptions(opts,vars)

opts1.RowFilter = opts1.RowFilter.bahn_id == bahn_id_ & opts1.RowFilter.segment_id == segment_id_; 
opts2.RowFilter = opts1.RowFilter;

segment_ist = sqlread(conn,tablename1,opts1);
segment_ist = sortrows(segment_ist,'timestamp');

segment_soll = sqlread(conn,tablename2,opts2);
segment_soll = sortrows(segment_soll,'timestamp');

clear opts1 opts2 
% clear tablename1 tablename2

%%
% Extrahieren der Positionsdaten
pos_ist = [segment_ist.x_ist segment_ist.y_ist segment_ist.z_ist];
pos_soll = [segment_soll.x_soll segment_soll.y_soll segment_soll.z_soll];

% Positionsdaten für Koordinatentransformation
postgres_calibration_run(data_cal_ist,data_cal_soll)

% Koordinatentransformation
pos_ist_trafo = pos_ist * trafo_rot + trafo_trans;

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

%% Metriken berechnen


% Euklidische Abstände berechnen
[~,euclidean_distances,~] = distance2curve(pos_ist_trafo,pos_soll,'linear');
% Erstellen der PostgresSQL Datenstrukturen
postgres_euclidean(euclidean_distances, bahn_id_, segment_id_)

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

%%

% Extraktion der Inxizes der Segmente 
seg_id = split(data_ist.segment_id, '_');
seg_id = str2double(seg_id(:,2));
idx_new_seg_ist = zeros(num_segments,1);

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

a = cell(num_segments+1, 1);
b = cell(num_segments+1, 1);

a{1}= [data_ist.x_ist(1:idx_new_seg_ist(1)-1) data_ist.y_ist(1:idx_new_seg_ist(1)-1) data_ist.z_ist(1:idx_new_seg_ist(1)-1)];
% % Speichern der einzelnen Semgente in Struktur
for i = 1:num_segments
    if i == length(idx_new_seg_ist)
        a{i+1} = [data_ist.x_ist(idx_new_seg_ist(i):end) data_ist.y_ist(idx_new_seg_ist(i):end) data_ist.z_ist(idx_new_seg_ist(i):end)];
    else
        a{i+1}= [data_ist.x_ist(idx_new_seg_ist(i):idx_new_seg_ist(i+1)-1) data_ist.y_ist(idx_new_seg_ist(i):idx_new_seg_ist(i+1)-1) data_ist.z_ist(idx_new_seg_ist(i):idx_new_seg_ist(i+1)-1)];
    end
    
end


%%
% a = cell(3,1);
% 
% b = table_euclidean_distances;
% 
% a{3} = b;
% 
% bb = a{3};










