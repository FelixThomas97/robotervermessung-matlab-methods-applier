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
calibration(data_cal_ist,data_cal_soll)

clear data_cal data_cal_info diff_bahn_id min_diff_bahn_id min_idx opts_cal tablename_cal check_bahn_id
clear query_cal min_diff_idx
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
    transformation(segments_ist(i,:),trafo_rot, trafo_trans)
    segments_trafo(i,:) = pos_ist_trafo;
end

clear idx k seg_id query



%% Berechnung der Metriken

% Tabellen initialisieren
table_euclidean_info = table();
table_euclidean_distances = cell(num_segments+1,1);
table_sidtw_info = table();
table_sidtw_distances = cell(num_segments+1,1);
table_dtw_info = table();
table_dtw_distances = cell(num_segments+1,1);
table_dfd_info = table();
table_dfd_distances = cell(num_segments+1,1);
table_lcss_info = table();
table_lcss_distances = cell(num_segments+1,1);

% Berechnung der Metriken für alle Segmente
for i = 1:1:num_segments+1

    if istable(segments_trafo)
        segment_trafo = [segments_trafo.x_ist{i}, segments_trafo.y_ist{i}, segments_trafo.z_ist{i}];
        segment_soll = [segments_soll.x_soll{i}, segments_soll.y_soll{i}, segments_soll.z_soll{i}];
    end
    
    % Berechnung euklidischer Abstand
    [euclidean_ist,euclidean_distances,~] = distance2curve(segment_trafo,segment_soll,'linear');
    % Berechnung SIDTW
    [sidtw_distances, ~, ~, ~, sidtw_soll, sidtw_ist, ~, ~, ~] = fkt_selintdtw3d(segment_soll,segment_trafo,false);
    % Berechnung DTW
    [dtw_distances, ~, ~, ~, dtw_soll, dtw_ist, ~, ~, ~, ~] = fkt_dtw3d(segment_soll,segment_trafo,false);
    % Berechnung diskrete Frechet
    fkt_discreteFrechet(segment_soll,segment_trafo,false)
    % Berechnung LCSS
    [~, ~, lcss_distances, ~, ~, lcss_soll, lcss_ist, ~, ~] = fkt_lcss(segment_soll,segment_trafo,false);

    if i == 1
        % Euklidischer Abstand
        metric2postgresql('euclidean',euclidean_distances, segment_soll, euclidean_ist, bahn_id_, data_ist.segment_id(1))
        table_euclidean_info = seg_euclidean_info;
        table_euclidean_distances{1} = seg_euclidean_distances;
        % SIDTW
        metric2postgresql('sidtw', sidtw_distances, sidtw_soll, sidtw_ist, bahn_id_, data_ist.segment_id(1))
        table_sidtw_info = seg_sidtw_info;
        table_sidtw_distances{1} = seg_sidtw_distances;
        % DTW
        metric2postgresql('dtw',dtw_distances, dtw_soll, dtw_ist, bahn_id_, data_ist.segment_id(1))
        table_dtw_info = seg_dtw_info;
        table_dtw_distances{1} = seg_dtw_distances;
        % DFD
        metric2postgresql('dfd',frechet_distances, frechet_soll, frechet_ist, bahn_id_, data_ist.segment_id(1))
        table_dfd_info = seg_dfd_info;
        table_dfd_distances{1} = seg_dfd_distances;       
        % LCSS
        metric2postgresql('lcss',lcss_distances, lcss_soll, lcss_ist, bahn_id_, data_ist.segment_id(1))
        table_lcss_info = seg_lcss_info;
        table_lcss_distances{1} = seg_lcss_distances;

    else
        % Euklidischer Abstand
        metric2postgresql('euclidean',euclidean_distances, segment_soll, euclidean_ist, bahn_id_, segment_ids{i-1,:})
        table_euclidean_info(i,:) = seg_euclidean_info;
        table_euclidean_distances{i} = seg_euclidean_distances;
        % SIDTW
        metric2postgresql('sidtw',sidtw_distances, sidtw_soll, sidtw_ist, bahn_id_, segment_ids{i-1,:})
        table_sidtw_info(i,:) = seg_sidtw_info;
        table_sidtw_distances{i} = seg_sidtw_distances;
        % DTW
        metric2postgresql('dtw',dtw_distances, dtw_soll, dtw_ist, bahn_id_, segment_ids{i-1,:})
        table_dtw_info(i,:) = seg_dtw_info;
        table_dtw_distances{i} = seg_dtw_distances;
        % DFD
        metric2postgresql('dfd',frechet_distances, frechet_soll, frechet_ist, bahn_id_, segment_ids{i-1,:})
        table_dfd_info(i,:) = seg_dfd_info;
        table_dfd_distances{i} = seg_dfd_distances;
        % LCSS
        metric2postgresql('lcss',lcss_distances, lcss_soll, lcss_ist, bahn_id_, segment_ids{i-1,:})
        table_lcss_info(i,:) = seg_lcss_info;
        table_lcss_distances{i} = seg_lcss_distances;

    end
end

% Berechnung der Kennzahlen für die Gesamtmessung
table_all_info = table();
table_all_info.bahn_id = {bahn_id_};
table_all_info.calibration_id = {calibration_id};
table_all_info.min_distance = min(table_euclidean_info.euclidean_min_distance);
table_all_info.max_distance = max(table_euclidean_info.euclidean_max_distance);
table_all_info.average_distance = mean(table_euclidean_info.euclidean_average_distance);
table_all_info.standard_deviation = mean(table_euclidean_info.euclidean_standard_deviation);
table_all_info.metrik = "euclidean";

sidtw = table();
sidtw.bahn_id = {bahn_id_};  
sidtw.calibration_id = {calibration_id};  
sidtw.min_distance = min(table_sidtw_info.sidtw_min_distance); 
sidtw.max_distance = max(table_sidtw_info.sidtw_max_distance);
sidtw.average_distance = mean(table_sidtw_info.sidtw_average_distance);
sidtw.standard_deviation = mean(table_sidtw_info.sidtw_standard_deviation);
sidtw.metrik = "sidtw";

dtw = table();
dtw.bahn_id = {bahn_id_};  
dtw.calibration_id = {calibration_id};  
dtw.min_distance = min(table_dtw_info.dtw_min_distance); 
dtw.max_distance = max(table_dtw_info.dtw_max_distance);
dtw.average_distance = mean(table_dtw_info.dtw_average_distance);
dtw.standard_deviation = mean(table_dtw_info.dtw_standard_deviation);
dtw.metrik = "dtw";

dfd = table();
dfd.bahn_id = {bahn_id_};  
dfd.calibration_id = {calibration_id};  
dfd.min_distance = min(table_dfd_info.dfd_min_distance); 
dfd.max_distance = max(table_dfd_info.dfd_max_distance);
dfd.average_distance = mean(table_dfd_info.dfd_average_distance);
dfd.standard_deviation = mean(table_dfd_info.dfd_standard_deviation);
dfd.metrik = "dfd";

lcss = table();
lcss.bahn_id = {bahn_id_};  
lcss.calibration_id = {calibration_id};  
lcss.min_distance = min(table_lcss_info.lcss_min_distance); 
lcss.max_distance = max(table_lcss_info.lcss_max_distance);
lcss.average_distance = mean(table_lcss_info.lcss_average_distance);
lcss.standard_deviation = mean(table_lcss_info.lcss_standard_deviation);
lcss.metrik = "lcss";

table_all_info = [table_all_info; sidtw; dtw; dfd; lcss];

clear sidtw sidtw_distances sidtw_ist sidtw_soll seg_sidtw_info seg_sidtw_distances
clear dtw dtw_distances dtw_ist dtw_soll seg_dtw_info seg_dtw_distances
clear dfd frechet_distances frechet_ist frechet_soll frechet_path frechet_matrix frechet_dist frechet_av seg_dfd_info seg_dfd_distances
clear lcss lcss_distances lcss_ist lcss_soll seg_lcss_info seg_lcss_distances
clear euclidean_distances seg_euclidean_info seg_euclidean_distances
clear pos_ist_trafo segment_ist segment_soll segment_trafo i min_diff num_segments


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

%% 

% Berechnung aller Metriken für die gesamte Messaufnahme
evaluate_all = true;

if evaluate_all

    % Zur Sicherheit, damit nicht alle Daten ausgewertet werden !!!!!
    data_ist = data_ist(1:600,:);
    data_soll = data_soll(1:500,:);

    data_all_ist = table2array(data_ist(:,5:7));
    data_all_soll = table2array(data_soll(:,5:7));

    % Koordinatentrafo für alle Daten 
    transformation(data_all_ist,trafo_rot, trafo_trans)
    
    % Euklidischer Abstand 
    [euclidean_ist,euclidean_distances,~] = distance2curve(data_ist_trafo,data_all_soll,'linear');
    % % SIDTW
    [sidtw_distances, ~, ~, ~, sidtw_soll, sidtw_ist, ~, ~, ~] = fkt_selintdtw3d(data_all_soll,data_ist_trafo,false);
    % DTW
    [dtw_distances, ~, ~, ~, dtw_soll, dtw_ist, ~, ~, ~, ~] = fkt_dtw3d(data_all_soll,data_ist_trafo,false);
    % Frechet 
    fkt_discreteFrechet(data_all_soll,data_ist_trafo,false);
    % LCSS
    [~, ~, lcss_distances, ~, ~, lcss_soll, lcss_ist, ~, ~] = fkt_lcss(data_all_soll,data_ist_trafo,false);

    metric2postgresql('euclidean', euclidean_distances, data_all_soll, euclidean_ist, bahn_id_)
    metric2postgresql('sidtw', sidtw_distances, sidtw_soll, sidtw_ist, bahn_id_)
    metric2postgresql('dtw', dtw_distances, dtw_soll, dtw_ist, bahn_id_)
    metric2postgresql('dfd', frechet_distances, frechet_soll, frechet_ist, bahn_id_)
    metric2postgresql('lcss', lcss_distances, lcss_soll, lcss_ist, bahn_id_)

    % Anpassung der Spaltennamen für jede Tabelle
    seg_euclidean_info.Properties.VariableNames = {'bahn_id','min_distances', 'max_distance', 'average_distance', 'standard_deviation'};
    seg_sidtw_info.Properties.VariableNames = {'bahn_id','min_distances', 'max_distance', 'average_distance', 'standard_deviation'};
    seg_dtw_info.Properties.VariableNames = {'bahn_id','min_distances', 'max_distance', 'average_distance', 'standard_deviation'};
    seg_dfd_info.Properties.VariableNames = {'bahn_id','min_distances', 'max_distance', 'average_distance', 'standard_deviation'};
    seg_lcss_info.Properties.VariableNames = {'bahn_id','min_distances', 'max_distance', 'average_distance', 'standard_deviation'};
    
    table_all_info_2 = [seg_euclidean_info(1,:); seg_sidtw_info(1,:); seg_dtw_info(1,:); seg_dfd_info(1,:); seg_lcss_info(1,:)];

    table_all_info_2.metrik = {'euclidean'; 'sidtw'; 'dtw'; 'dfd'; 'lcss'};

    % Hinzufügen der calibration_id wenn diese existiert
    if exist('calibration_id', 'var') == 1
        calibration_ids = repelem(calibration_id, height(table_all_info_2),1);
        table_all_info_2.calibration_id = calibration_ids;
        table_all_info_2 = table_all_info_2(:,[{'bahn_id'},{'calibration_id'},{'min_distances'},{'max_distance'},{'average_distance'},{'metrik'}]);
        clear calibration_ids
    end

    clear sidtw_distances sidtw_ist sidtw_soll 
    clear dtw_distances dtw_ist dtw_soll 
    clear frechet_distances frechet_ist frechet_soll frechet_path frechet_matrix frechet_dist frechet_av 
    clear lcss_distances lcss_ist lcss_soll 
    clear euclidean_distances euclidean_ist


end


