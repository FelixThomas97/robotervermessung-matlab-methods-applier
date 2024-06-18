%% 
clear;
% filename_excel_ist = 'iso_various_v2000_xx.xlsx';
filename_excel_ist = 'ist_iso_diagonal_l630_v2000_4x.xlsx';
% filename_excel_soll = 'soll_iso_diagonal_l630_v2000_1x.xlsx';
filename_excel_soll = 'soll_squares_l400_v1000_1x.xlsx'; %%%%% Keine Geschwindigkeit aufgezeichnet


%%
% Datenvorverarbeitung für durch ABB Robot Studio generierte Tabellen
data_provision(filename_excel_ist);
preprocess_data(table_ist)

% Zerlegung der Bahnen in einzelne Segmente und vollständige Messdurchläufe
calc_trajectories(data_ist,events_ist,zeros_index_ist);

% Überprüfen ob eine Sollbahn interpoliert werden muss
if isempty(filename_excel_soll) == 1
    interpolate = true;
else
    interpolate = false;
    data_provision(filename_excel_soll,interpolate);
    preprocess_data(table_soll, interpolate)
    calc_trajectories(data_soll,events_soll,zeros_index_soll,interpolate)
end

% Multiplikationsfaktor für die Anzahl der Punkte der Sollbahn
keypoints_faktor = 1;

% Einmal vorab die Base für die ID generieren
trajectory_header_id_base = "robot0"+string(round(posixtime(datetime('now','TimeZone','UTC'))));

%%