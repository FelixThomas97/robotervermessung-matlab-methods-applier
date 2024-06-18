function abb_data_provison(filename_excel,interpolate)

%% ABB Robot Datenstruktur angleichen

data = readtable(filename_excel);

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
col_names = data.Properties.VariableNames;

for i = 1:length(col_order)
    col_name = col_order{i};
    % Überprüfen, ob die Spalte vorhanden ist
    if ~ismember(col_name, col_names)
        % Fehlende Spalte mit Nullen hinzufügen (q1,q2,q3,q4)
        data.(col_name) = zeros(height(data), 1);
    end
end

% Temperatur auf 40 Grad setzen 
data.Temperatur = ones(height(data),1)*40;

% Tabelle in der gewünschten Reihenfolge neu anordnen
data = data(:, col_order);

%% Bereinigen der Daten anhand der Ereignisse, sodass Bahn in Home beginnt

events = data{:,end};
index_events = find(~cellfun('isempty', events));

%% 
% Überprüfen ob Suchbegriff im ersten Ereignis vorkommt
search_term = 'prepare_for_path'; 
match = strfind(events(index_events(1)), search_term);
% % % To-Do: Andere Bezeichner einfügen können % % % 

if ~isempty(match{1})
    % Daten löschen bis zum ersten mal Home erreicht ist 
    % --> wenn "prepare_for_path" dann zweites Ereignis, sonst das erste
    pfp_string = events{index_events(1)};
    match = regexp(pfp_string,'\d+$','match');
    pfp_row = str2double(match);
    data(1:index_events(2)-2,:) = []; 
    pfp = true; 
else
    data(1:index_events(1)-2,:) = [];
    pfp_row = 0;
    pfp = false;
end


%% Extrahiere die Daten aus dem Table 
timestamp = data{:, 1};
x = data{:, 2};
y = data{:, 3};
z = data{:, 4};
tcp_velocity = data{:, 5};
tcp_acceleration = data{:, 6};
cpu_temperature = data{:, 7};
joint_states = data{:, 8:13};
q = data{:, 14:17};
events = data{:,18};
% Alle Events ohne Leerzeilen
events_all = rmmissing(events);

% Data ist als double-Matrix ausgeben (ohne Events)
data = [timestamp x y z tcp_velocity tcp_acceleration cpu_temperature joint_states q];

%% Extrahieren der Codezeilen wo Ereignisse stattfinden

% Suchen nach mehreren aufeinanderfolgenden Ziffern am Ende der Ereignisse
pattern = '\d+$'; 
matches = regexp(events_all, pattern, 'match');
% Strings in double umwandeln
events_all = cellfun(@str2double, matches);
% Erstes Ereignis extrahieren
first_event = events_all(1);

% Das gleiche für events_ist
matches = regexp(events, pattern, 'match'); 
emptyCells = cellfun('isempty', matches);       % Findet leere Zellen
matches(emptyCells) = {'0'};                    % Füllt leere Zellen mit Nullen
events = cellfun(@str2double, matches);

% Ereignisse wieder an data anhängen
data = [data events];

% Falls prepare_for_path, dann ignorieren dieses Ereignisses
if pfp
    events(events == pfp_row) = 0;
    events_all(events_all == pfp_row) = []; 
end

%% Laden in Workspace

% Unterscheidung ob Ist- oder Soll-Daten 
if nargin < 2
    assignin("base", "events_all_ist", events_all);           
    assignin("base","events_ist", events);
    assignin('base','data_ist',data);
    assignin('base','pfp_ist',pfp);
    assignin('base','pfp_row_ist',pfp_row);
elseif nargin == 2 && interpolate == false
    assignin("base", "events_all_soll", events_all);           
    assignin("base","events_soll", events);
    assignin('base','data_soll',data);
    assignin('base','pfp_soll',pfp);
    assignin('base','pfp_row_soll',pfp_row);
end
