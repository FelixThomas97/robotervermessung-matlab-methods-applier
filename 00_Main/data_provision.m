function data_provision(filename_excel,interpolate)

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
    'TCP_Orientierung_Q1BezogenAufDasAktuelleWerkobjekt',...        
    'TCP_Orientierung_Q2BezogenAufDasAktuelleWerkobjekt',...        
    'TCP_Orientierung_Q3BezogenAufDasAktuelleWerkobjekt',...        
    'TCP_Orientierung_Q4BezogenAufDasAktuelleWerkobjekt',...         
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

if nargin < 2
    assignin("base","table_ist",data);
elseif nargin == 2 && interpolate == false
    assignin("base","table_soll",data);
end

% %% Bereinigen der Daten anhand der Ereignisse, sodass Bahn in Home beginnt
% 
% events = data{:,end};
% index_events = find(~cellfun('isempty', events));
% 
% % 
% % Überprüfen ob Suchbegriff im ersten Ereignis vorkommt
% search_term = 'prepare_for_path'; 
% match = strfind(events(index_events(1)), search_term);
% % % % To-Do: Andere Bezeichner einfügen können % % % 
% 
% if ~isempty(match{1})
%     % Daten löschen bis zum ersten mal Home erreicht ist 
%     % --> wenn "prepare_for_path" dann zweites Ereignis, sonst das erste
%     pfp_string = events{index_events(1)};
%     match = regexp(pfp_string,'\d+$','match');
%     pfp_row = str2double(match);
%     scum_data = data(1:index_events(2),:);
%     index_first_zero = find(scum_data{:,5} == 0, 1, 'last');
%     data = data(index_first_zero:end,:);
%     % data(1:index_events(2)-2,:) = []; 
%     pfp = true; 
% else
%     % Entfernen aller Zeilen zu Beginn der Tabelle, bei denen die Geschwindigkeit 0 ist
%     index_first_zero = find(data{:,5} ~= 0, 1, 'first');
%     data = data(index_first_zero-2:end, :);
%     pfp_row = 0;
%     pfp = false;
% end
% 
% 
% %% Extrahiere die Daten aus dem Table 
% 
% events = data{:,18};
% data = data{:,1:17};
% % Alle Events ohne Leerzeilen
% events_all = rmmissing(events);
% 
% % Finden der Indizes, bei denen die Geschwindigkeit wieder 0 wird
% index_zeros = find(data(:,5) == 0);
% 
% % Nur den ersten Index bei aufeinanderfolgenden Nullen speichern
% index_zeros = index_zeros([true; diff(index_zeros) > 1]);
% 
% %% Extrahieren der Codezeilen wo Ereignisse stattfinden
% 
% % Suchen nach mehreren aufeinanderfolgenden Ziffern am Ende der Ereignisse
% pattern = '\d+$'; 
% matches = regexp(events_all, pattern, 'match');
% % Strings in double umwandeln
% events_all = cellfun(@str2double, matches);
% % Erstes Ereignis extrahieren
% first_event = events_all(1);
% 
% % Das gleiche für events_ist
% matches = regexp(events, pattern, 'match'); 
% emptyCells = cellfun('isempty', matches);       % Findet leere Zellen
% matches(emptyCells) = {'0'};                    % Füllt leere Zellen mit Nullen
% events = cellfun(@str2double, matches);
% 
% % Ereignisse wieder an data anhängen
% data = [data events];
% 
% % Falls prepare_for_path, dann ignorieren dieses Ereignisses
% if pfp
%     events(events == pfp_row) = 0;
%     events_all(events_all == pfp_row) = []; 
% end
% 
% %% Laden in Workspace
% 
% % Unterscheidung ob Ist- oder Soll-Daten 
% if nargin < 2
%     assignin("base", "events_all_ist", events_all);           
%     assignin("base","events_ist", events);
%     assignin('base','data_ist',data);
%     assignin('base','pfp_ist',pfp);
%     assignin('base','pfp_row_ist',pfp_row);
%     assignin("base", "index_zeros_ist", index_zeros);
% elseif nargin == 2 && interpolate == false
%     assignin("base", "events_all_soll", events_all);           
%     assignin("base","events_soll", events);
%     assignin('base','data_soll',data);
%     assignin('base','pfp_soll',pfp);
%     assignin('base','pfp_row_soll',pfp_row);
%     assignin("base", "index_zeros_soll", index_zeros);
% end

end
