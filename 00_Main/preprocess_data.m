function preprocess_data(data, interpolate)
% clear;
% load müll_soll.mat
% data = data_soll;
% clear data_soll

% %% 
% clear;
% % filename_excel_ist = 'iso_various_v2000_xx.xlsx';
% % filename_excel_ist = 'ist_iso_diagonal_l630_v2000_4x.xlsx';
% %filename_excel_soll = 'soll_iso_diagonal_l630_v2000_1x.xlsx';
% filename_excel_soll = 'soll_squares_l400_v1000_1x.xlsx'; %%%%% Keine Geschwindigkeit aufgezeichnet
% 
% 
% 
% % % Datenvorverarbeitung für durch ABB Robot Studio generierte Tabellen
% % data_provision(filename_excel_ist);
% % preprocess_data(table_ist)
% 
% % % Zerlegung der Bahnen in einzelne Segmente und vollständige Messdurchläufe
% % calc_abb_trajectories(data_ist,events_ist,events_all_ist);
% 
% % Überprüfen ob eine Sollbahn interpoliert werden muss
% if isempty(filename_excel_soll) == 1
%     interpolate = true;
% else
%     interpolate = false;
%     data_provision(filename_excel_soll,interpolate);
%     % calc_abb_trajectories(data_soll,events_soll,events_all_soll,interpolate)
% end
% 
% data = table_soll;

%% Datenbereinigung zu Beginn der Tabelle

% Bereinigen der Daten anhand der Ereignisse, sodass Bahn in Home beginnt
events = data{:,end};
events_index = find(~cellfun('isempty', events));

% Finden der Indizes, bei denen die Geschwindigkeit wieder 0 wird
zeros_index = find(data{:,5} == 0);

% Wenn keine Geschwindigkeit aufgezeichnet muss Berechnung über Ereignisse stattfinden
if length(zeros_index) == size(data,1)
    warning("Data does not contain velocity of the tcp! This can lead to errors!")
    zeros_index = [];
end


%%

% Überprüfen ob Suchbegriff im ersten Ereignis vorkommt
search_term = 'prepare_for_path'; 
prepare_for_path = strfind(events(events_index(1)), search_term);

% % % % To-Do: Andere Bezeichner einfügen können % % % %

% Entfernen aller Zeilen bis zum ersten mal Home erreicht ist 
%    wenn "prepare_for_path" das zweites Ereignis und von dort aus
%    starten wo die Geschwindigkeit das erste Mal Null ist.
if ~isempty(prepare_for_path{1})
    % Speichern des Ereignisses "prepare_for_path" in event_pfp
    string = events{events_index(1)};
    match = regexp(string,'\d+$','match');
    event_pfp = str2double(match);
    pfp = true;
    if ~isempty(zeros_index)
        % Entfernen der ungewünschten Daten bis erste Mal Home und Geschw. = 0
        scum_data = data(1:events_index(2),:);
        index_first_zero = find(scum_data{:,5} == 0, 1, 'last');
        data = data(index_first_zero:end,:); 
    else
        % Sonst Bereinigung anhand der Ereignisse 
        data(1:events_index(2)-2,:) = []; 
    end 
else
    event_pfp = 0;
    pfp = false;
    if ~isempty(zeros_index)
        % Entfernen aller Daten zu Beginn der Tabelle, bei denen die Geschwindigkeit 0 ist
        index_first_zero = find(data{:,5} ~= 0, 1, 'first'); % nicht erste 0 sondern erste ~=0
        data = data(index_first_zero-2:end, :);     %%%% Sicherheitshalber -2 falls Ereigniss davor liegt
    % Sonst Bereinigung anhand der Ereignisse 
    else
        if interpolate == false && nargin == 2
            data(1:events_index(1)-5,:) = []; %%%% evtl. einfach gar nix machen
        else
            data(1:events_index(1)-2,:) = [];
        end
    end
    
end

%% Extrahieren der Daten wo Ereignisse stattfinden und Geschwindigkeit Null ist

% Bereinigte Tabelle bis auf Ereignisse als double-Array
data_array = data{:,1:17};

% Aktualisieren der Events und Nullen anhand der bereinigten Tabelle 
events = data{:,18};
if ~isempty(zeros_index)
    zeros_index = find(data_array(:,5) == 0);
    % Nur den ersten Index bei aufeinanderfolgenden Nullen speichern
    zeros_index = zeros_index([true; diff(zeros_index) > 1]);
end
%%
% Suchen nach mehreren aufeinanderfolgenden Ziffern am Ende der Ereignisse
pattern = '\d+$'; 
matches = regexp(events, pattern, 'match'); 
emptyCells = cellfun('isempty', matches);       % Findet leere Zellen
matches(emptyCells) = {'0'};                    % Füllt leere Zellen mit Nullen
events = cellfun(@str2double, matches);         % In double umwandeln

% Indizes und Ereignisse kompakt
events_index = find(events ~= 0);
events_all = events(events_index);

% Ereignisse wieder an data anhängen
data_array = [data_array events];

% Falls prepare_for_path, dann ignorieren dieses Ereignisses
if pfp
    events(events == event_pfp) = 0;
    events_index = find(events ~= 0);
    events_all(events_all == event_pfp) = [];
end

% Laden in Workspace

% Unterscheidung ob Ist- oder Soll-Daten 
if nargin < 2
    assignin("base","events_index_ist", events_index);
    assignin("base", "events_all_ist", events_all);           
    assignin("base","events_ist", events);
    assignin('base','data_ist',data_array);
    assignin('base','pfp_ist',pfp);
    assignin('base','pfp_event_ist',event_pfp);
    assignin("base", "zeros_index_ist", zeros_index)
elseif nargin == 2 && interpolate == false
    assignin("base","events_index_soll", events_index);
    assignin("base", "events_all_soll", events_all);           
    assignin("base","events_soll", events);
    assignin('base','data_soll',data_array);
    assignin('base','pfp_soll',pfp);
    assignin('base','pfp_event_soll',event_pfp);
    assignin("base", "zeros_index_soll", zeros_index);
end

end