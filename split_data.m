%% Laden der Daten 
clear;
filename = 'record_20240715_145153_all_final.csv'; % 700Hz - 483 Segmente

data = importfile_vicon_abb_sync(filename);
% Zeitstempel extrahieren
date_time = data.timestamp(1);
date_time = datetime(date_time,'ConvertFrom','epochtime','TicksPerSecond',1e9,'Format','dd-MMM-yyyy HH:mm:ss');

%% Daten aufteilen
datasplit1 = data(1:250000,:);
datasplit2 = data(250000:500000,:);
datasplit3 = data(500000:750000,:);
datasplit4 = data(750000:1000000,:);
datasplit5 = data(1000000:end,:);

%% Daten als .csv schreiben

writetable(datasplit1,'record_20240715_145153_1.csv');
writetable(datasplit2,'record_20240715_145153_2.csv');
writetable(datasplit3,'record_20240715_145153_3.csv');
writetable(datasplit4,'record_20240715_145153_4.csv');
writetable(datasplit5,'record_20240715_145153_5.csv');
%% Test 
% clear;
% filename = 'record_20240715_145153_1.csv'; % 700Hz - 483 Segmente
% 
% data = importfile_vicon_abb_sync(filename);
% % Zeitstempel extrahieren
% date_time = data.timestamp(1);
% date_time = datetime(date_time,'ConvertFrom','epochtime','TicksPerSecond',1e9,'Format','dd-MMM-yyyy HH:mm:ss');

