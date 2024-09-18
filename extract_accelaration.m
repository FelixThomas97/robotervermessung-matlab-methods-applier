% Test: Beschleunigung extrahieren 

filename = 'record_20240715_145920_all_final.csv'; % 700Hz - 93 Segmente
% filename = 'record_20240715_144638_random_python_final.csv';
data = importfile_vicon_abb_sync(filename);

% Zeitstempel extrahieren
date_time = data.timestamp(1);
date_time = datetime(date_time,'ConvertFrom','epochtime','TicksPerSecond',1e9,'Format','dd-MMM-yyyy HH:mm:ss');

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

%% Plotssssssssssssss %%

% Farben
c1 = [0 0.4470 0.7410];
c2 = [0.8500 0.3250 0.0980];
c3 = [0.9290 0.6940 0.1250];
c4 = [0.4940 0.1840 0.5560];
c5 = [0.4660 0.6740 0.1880];
c6 = [0.3010 0.7450 0.9330];
c7 = [0.6350 0.0780 0.1840];

% Plot von gemessener Geschwindigkeit und Beschleunigung Vicon
% Plotten der Geschwindigkeit
f1 = figure('Name','Geschwindigkeiten & Beschleunigungen Vicon','Color','white','NumberTitle','off');
f1.Position(3:4) = [1520 840];
subplot(2,1,1)
title('Geschwindigkeiten')
hold on 
plot(vicon_timestamps,vicon_velocity(:,4),'LineWidth',1.5)
plot(vicon_timestamps,vicon_velocity(:,1),"Color",c2)
plot(vicon_timestamps,vicon_velocity(:,2),"Color",c4)
plot(vicon_timestamps,vicon_velocity(:,3),"Color",c5)
legend('magnitude','vel. x','vel. y','vel. z')
hold off
grid on
axis tight
xlabel('Zeit [s]')
ylabel('Geschwindigkeit [mm/s^2]')

% Plotten der Beschleunigungen 
subplot(2,1,2)
title('Beschleinugungen Vicon')
hold on 
plot(vicon_timestamps,vicon_accel(:,4),'LineWidth',1.5)
plot(vicon_timestamps,vicon_accel(:,1),"Color",c2)
plot(vicon_timestamps,vicon_accel(:,2),"Color",c4)
plot(vicon_timestamps,vicon_accel(:,3),"Color",c5)
legend('magnitude','acc. x','acc. y','acc. z')
hold off
grid on
axis tight
xlabel('Zeit [s]')
ylabel('Beschleunigung [mm/s^2]')

% Berechnung der Beschleunigungen 
% Timestamps neu
t1 = vicon_timestamps(1);
t2 = vicon_timestamps(end);
t = linspace(t1,t2,length(vicon_timestamps))';

% Differenzen Geschwindigkeit
dvx = diff(vicon_velocity(:,1));
dvy = diff(vicon_velocity(:,2));
dvz = diff(vicon_velocity(:,3));
dv = diff(vicon_velocity(:,4));
% Differenzen Timestamps
dt = diff(t);

% Beschleunigungen 
ax = dvx ./ (dt*1000);
ay = dvy ./ (dt*1000);
az = dvz ./ (dt*1000);
a = sqrt(ax.^2 + ay.^2 + az.^2);

% Plot der selbst berechneten und gemessenen Beschleunigungen Vicon 
f2 = figure('Name','Berechnete und gemessene Beschleunigungen (Vicon)','Color','white','NumberTitle','off');
f2.Position(3:4) = [1520 840];
subplot(2,1,1)
title('Beschleunigungen (berechnet)')
hold on
plot(t(1:end-1), a, 'LineWidth',1.5)
plot(t(1:end-1), ax, 'Color',c2)
plot(t(1:end-1), ay, 'Color',c4)
plot(t(1:end-1), az, 'Color',c5)
legend('magnitude','acc. x','acc. y','acc. z')
grid on 
axis tight
xlabel('Zeit [s]')
ylabel('Beschleunigung [m/s^2]')

subplot(2,1,2)
title('Beschleunigungen (Vicon)')
hold on
plot(vicon_timestamps,vicon_accel(:,4),'LineWidth',1.5)
plot(vicon_timestamps,vicon_accel(:,1),"Color", c2)
plot(vicon_timestamps,vicon_accel(:,2),"Color", c4)
plot(vicon_timestamps,vicon_accel(:,3),"Color", c5)
legend('magnitude','acc. x','acc. y','acc. z')
grid on 
axis tight
xlabel('Zeit [s]')
ylabel('Beschleunigung [m/s^2]')

% clear c1 c2 c3 c4 c5 c6 c7 f1 f2

%% Beschleunigungen ABB Websocket

% Geschwindigkeit bei den Websocketdaten nicht zu gebrauchen daher zunächst
% Geschwindigkeit über die Positionen ermitteln:

% ABB Daten von 1 Ereignis bis letztem Ereignis
abb_timestamps2 = abb_timestamps(idx_time_events(1):idx_time_events(end));
abb_positions2 = abb_positions(idx_time_events(1):idx_time_events(end),:);

% Vicon Daten ebenfallas zuschneiden

% Ermittlung der Zeitstempel wo Ereignisse stattfinden
idx_nearest_vicon = zeros(length(idx_time_events),1);
for i = 1:length(idx_time_events)
    [~,idx] = min(abs(events_timestamps(i)-vicon_timestamps));
    % Nächstliegender Index des des Zeitstempels bei Vicon 
    idx_nearest_vicon(i) = idx;
end
events_timestamps_vicon = vicon_timestamps(idx_nearest_vicon);

vicon_timestamps2 = vicon_timestamps(idx_nearest_vicon(1):idx_nearest_vicon(end));
vicon_positions2 = vicon_positions(idx_nearest_vicon(1):idx_nearest_vicon(end),:);

t1 = events_timestamps_vicon(1);
t2 = events_timestamps_vicon(end);
t_vicon = linspace(t1,t2,length(vicon_timestamps2))'; 

% Zeitstempel ABB
t1 = abb_timestamps2(1); 
t2 = abb_timestamps2(end); 
t = linspace(t1,t2,length(abb_timestamps2))'; 
% t = abb_timestamps;

% Test mit Mittelwertfilter

window = 37; 

ma_filter = (1/window)* ones (1,window);
abbx_filtered = filter(ma_filter,1,abb_positions2(:,1));
abby_filtered = filter(ma_filter,1,abb_positions2(:,2));
abbz_filtered = filter(ma_filter,1,abb_positions2(:,3));

abb_filtered = [abbx_filtered abby_filtered abbz_filtered];

% figure
% plot(abb_positions(:,1))
% hold on 
% plot(abbx_filtered)

vx = diff(abbx_filtered) ./ diff(t);
vy = diff(abby_filtered) ./ diff(t);
vz = diff(abbz_filtered) ./ diff(t);

v = sqrt(vx.^2 + vy.^2 + vz.^2);


% Plot von gemessener Geschwindigkeit und Beschleunigung Vicon
% Plotten der Geschwindigkeit
f1 = figure('Name','Geschwindigkeiten Vicon und ABB-Websocket','Color','white','NumberTitle','off');
f1.Position(3:4) = [1520 840];
subplot(2,1,1)
title('Geschwindigkeit Vicon')
hold on 
plot(t_vicon,vicon_velocity(idx_nearest_vicon(1):idx_nearest_vicon(end),4),'LineWidth',1.5)
plot(t_vicon,vicon_velocity(idx_nearest_vicon(1):idx_nearest_vicon(end),1),"Color",c2)
plot(t_vicon,vicon_velocity(idx_nearest_vicon(1):idx_nearest_vicon(end),2),"Color",c4)
plot(t_vicon,vicon_velocity(idx_nearest_vicon(1):idx_nearest_vicon(end),3),"Color",c5)
legend('magnitude','vel. x','vel. y','vel. z')
hold off
grid on
axis tight
xlim([7 t(end)])
xlabel('Zeit [s]')
ylabel('Geschwindigkeit [mm/s^2]')

% Plot Geschwindigkeit Abb Websocket
subplot(2,1,2)
title('Geschwindigkeit (ABB Websocket)')
hold on
plot(t(1:end-1), v, 'LineWidth',1.5)
plot(t(1:end-1), vx, 'Color',c2)
plot(t(1:end-1), vy, 'Color',c4)
plot(t(1:end-1), vz, 'Color',c5)
legend('magnitude','vel. x','vel. y','vel. z')
grid on 
axis tight
xlim([7 t(end)])
xlabel('Zeit [s]')
ylabel('Beschleunigung [m/s^2]')

%% Plot ABB Websocket Beschleunigung

% ax = diff(vx) ./ (diff(t(1:end-1))*36000);  
% ay = diff(vy) ./ (diff(t(1:end-1))*36000);  
% az = diff(vz) ./ (diff(t(1:end-1))*36000);

ax = diff(vx) ./ (diff(t(1:end-1))*1000);  
ay = diff(vy) ./ (diff(t(1:end-1))*1000);  
az = diff(vz) ./ (diff(t(1:end-1))*1000); 

a = sqrt(ax.^2 + ay.^2 + az.^2);

% Plot der selbst berechneten Beschleunigungen und Vicon 
f3 = figure('Name','Beschleunigungen Websocket','Color','white','NumberTitle','off');
f3.Position(3:4) = [1520 840];
subplot(2,1,1)
title('Beschleunigungen (ABB Websocket)')
hold on
plot(t(1:end-2), a, 'LineWidth',1.5)
plot(t(1:end-2), ax, 'Color',c2)
plot(t(1:end-2), ay, 'Color',c4)
plot(t(1:end-2), az, 'Color',c5)
legend('magnitude','acc. x','acc. y','acc. z')
grid on 
axis tight
xlim([2 t(end)])
xlabel('Zeit [s]')
ylabel('Beschleunigung [m/s^2]')

subplot(2,1,2)
title('Beschleunigungen (Vicon)')
hold on
plot(vicon_timestamps,vicon_accel(:,4),'LineWidth',1.5)
plot(vicon_timestamps,vicon_accel(:,1),"Color", c2)
plot(vicon_timestamps,vicon_accel(:,2),"Color", c4)
plot(vicon_timestamps,vicon_accel(:,3),"Color", c5)
legend('magnitude','acc. x','acc. y','acc. z')
grid on 
axis tight
xlim([2 t(end)])
xlabel('Zeit [s]')
ylabel('Beschleunigung [m/s^2]')








