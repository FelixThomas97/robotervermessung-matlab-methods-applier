clear
filename = 'record_20240628_121243_squares_isodiagonalA&B_300Hz_final.csv';
data = importfile_vicon_abb_sync(filename);

% Löschen nicht benötigten Timesstamps
data.sec =[];
data.nanosec = [];

% Double Array
data_ = table2array(data);

% Timestamps in Sekunden
data{:,1} = (data{:,1}- data{1,1})/1e9;
data_frequency = length(data{:,1})/(data{end,1}-data{1,1});
data_timestamps = data{:,1};

% Umrechnen in mm
data{:,2:4} = data{:,2:4}*1000;
data{:,9:12} = data{:,9:12}*1000;
data{:,17:20} = data{:,17:20}*1000;

% Daten auslesen
data_vicon_pose = data{:,2:8};
data_vicon_velocity = data{:,9:16};
data_vicon_accel = data{:,17:24};

data_abb_position = data{:,25:27};
data_abb_orientation = data{:,28:31};
data_abb_velocity = data{:,32};
data_abb_jointstates = data{:,33:38};

% Alle NaN Zeilen löschen
clean_NaN = all(isnan(data_vicon_pose),2);
data_vicon_pose = data_vicon_pose(~clean_NaN,:);
clean_NaN = all(isnan(data_vicon_velocity),2);
data_vicon_velocity = data_vicon_velocity(~clean_NaN,:);
clean_NaN = all(isnan(data_vicon_accel),2);
data_vicon_accel = data_vicon_accel(~clean_NaN,:);

% ABB Daten leider verschieden viele NaN Zeilen ...
clean_NaN = all(isnan(data_abb_position),2);
data_abb_position = data_abb_position(~clean_NaN,:);
clean_NaN = all(isnan(data_abb_orientation),2);
data_abb_orientation = data_abb_orientation(~clean_NaN,:);
clean_NaN = all(isnan(data_abb_velocity),2);
data_abb_velocity = data_abb_velocity(~clean_NaN,:);
clean_NaN = all(isnan(data_abb_jointstates),2);
data_abb_jointstates = data_abb_jointstates(~clean_NaN,:);

clear clean_NaN filename

%% ABB Data Preperation

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

clear idx_not_nan counter

% Initialisierung eines Arrays für alle Daten
data_abb = zeros(length(data_abb_position),15);

% Zeitstempel (umgerechnet und wo Positionsdaten vorliegen) - alle Werte
data_abb(:,1) = data_timestamps(idx_abb_positions);
% Position - alle Werte
data_abb(:,2:4) = data_(idx_abb_positions(:),25:27);
% Orientierung - erster Wert
data_abb(1,5:8) = data_(idx_abb_orientation(1),28:31);
% Geschwindigkeit - erster Wert
data_abb(1,9) = data_(idx_abb_velocity(1),32);
% Joint States - erster Wert
data_abb(1,10:15) = data_(idx_abb_jointstates(1),33:38);


% for j = 2:1:length(data_abb_orientation)
%     if idx_abb_orientation(j) > idx_abb_positions(j) && idx_abb_orientation(j) < idx_abb_positions(j+1)
%         % Orientierung
%         data_abb(j,5:8) = data_(idx_abb_orientation(j),28:31);
%     end
% end
idx_test = zeros(length(data_abb_orientation),1);
for i = 2:1:length(data_abb)
    
    % Hier Problem !
    search_term = idx_abb_orientation(i); 

    idx1 = idx_abb_positions(i);
    idx2 = idx_abb_positions(i+1)-1;
    idx_chain = idx1:1:idx2;
    if ismember(search_term, idx_chain)
        data_abb(i,5:8) = data_(idx_abb_orientation(i),28:31);
    end
    
end

