function abb_data_provison(filename_excel)

%% ABB Robot Datenstruktur angleichen

data_ist = readtable(filename_excel);

% Gewünschte Reihenfolge der Spalten
col_order = {'Zeit',...
    'TCP_Position_X_PositionBezogenAufDasAktuelleWerkobjekt',...
    'TCP_Position_Y_PositionBezogenAufDasAktuelleWerkobjekt',...
    'TCP_Position_Z_PositionBezogenAufDasAktuelleWerkobjekt',...
    'TCP_GeschwindigkeitBezogenAufDasAktuelleWerkobjekt',...
    'TCP_MaximaleLineareBeschleunigungBezogenAufDasWelt_Koordinatens',...
    'Temperatur',...
    'J1',...
    'J2',...
    'J3',...
    'J4',...
    'J5',...
    'J6',...
    'q1_ist',...        % werden jetzt hier hinzugefügt --> Alter Codeausschnitt nicht mehr benötigt
    'q2_ist',...        %
    'q3_ist',...        %
    'q4_ist',...        % 
    'Position_PositionGe_ndert'};

% Spaltenbezeichnungen in der Tabelle
col_names = data_ist.Properties.VariableNames;

for i = 1:length(col_order)
    col_name = col_order{i};
    % Überprüfen, ob die Spalte vorhanden ist
    if ~ismember(col_name, col_names)
        % Fehlende Spalte mit Nullen hinzufügen (q1,q2,q3,q4)
        data_ist.(col_name) = zeros(height(data_ist), 1);
    end
end

% Temperatur auf 40 Grad setzen 
data_ist.Temperatur = ones(height(data_ist),1)*40;

% Tabelle in der gewünschten Reihenfolge neu anordnen
data_ist = data_ist(:, col_order);

%% Bereinigen der Daten anhand der Ereignisse, sodass Bahn in Home beginnt

events_ist = data_ist{:,end};
index_events = find(~cellfun('isempty', events_ist));

%% 
% Überprüfen ob Suchbegriff im ersten Ereignis vorkommt
search_term = 'prepare_for_path'; 
match = strfind(events_ist(index_events(1)), search_term);
% % % To-Do: Andere Bezeichner einfügen können % % % 

if ~isempty(match{1})
    % Daten löschen bis zum ersten mal Home erreicht ist 
    % --> wenn "prepare_for_path" dann zweites Ereignis, sonst das erste
    pfp_string = events_ist{index_events(1)};
    match = regexp(pfp_string,'\d+$','match');
    pfp_row = str2double(match);
    data_ist(1:index_events(2)-2,:) = []; 
    pfp = true; 
else
    data_ist(1:index_events(1)-2,:) = [];
    pfp_row = 0;
    pfp = false;
end


%% Extrahiere die Daten aus dem Table 
timestamp_ist = data_ist{:, 1};
x_ist = data_ist{:, 2};
y_ist = data_ist{:, 3};
z_ist = data_ist{:, 4};
tcp_velocity_ist = data_ist{:, 5};
tcp_acceleration_ist = data_ist{:, 6};
cpu_temperature_ist = data_ist{:, 7};
joint_states_ist = data_ist{:, 8:13};
q_ist = data_ist{:, 14:17};
events_ist = data_ist{:,18};
% Alle Events ohne Leerzeilen
events_all = rmmissing(events_ist);

% Data ist als double-Matrix ausgeben (ohne Events)
data_ist = [timestamp_ist x_ist y_ist z_ist tcp_velocity_ist tcp_acceleration_ist cpu_temperature_ist joint_states_ist q_ist];


%% Laden in Workspace
assignin("base", "events_all", events_all);           
assignin("base","events_ist", events_ist);
assignin('base','data_ist',data_ist);
assignin('base','pfp',pfp);
assignin('base','pfp_row',pfp_row);

end
