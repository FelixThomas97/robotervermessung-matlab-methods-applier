% Löschen des Workspace
clear; tic;
% Verbindung mit der Datenbank
conn = connecting_to_postgres;

%% Bestimmung der Änlichkeitsparameter (Anhand von gegebenen Punkten/Events)
% Festlegen nach einer Bahn für die änliche Bahnen gesucht werden sollen

bahn_id = '1719911918'; % Square mässig
bahn_id = '1721048209'; % andere Routine

query = sprintf('SELECT * FROM robotervermessung.bewegungsdaten.bahn_events WHERE bahn_id = ''%s''',bahn_id);
bahn_events = fetch(conn, query);

% Punkte/Events herrausfiltern
events_position = table2array(bahn_events(:,5:7));
events_orientation = table2array(bahn_events(:,8:11));

% Richtungsvektor, norm. Richtungsvektor und Länge der Bahnen berechnen
direction = zeros(height(bahn_events)-1,3);
distance = zeros(height(bahn_events)-1,1);
ndirection = zeros(height(bahn_events)-1,3);
quaternion_diff = zeros(height(bahn_events)-1,4);
for i = 1: height(bahn_events)-1
    direction(i,:) = events_position(i+1,:) - events_position(i,:);
    distance(i) = vecnorm((direction(i,:)));
    ndirection(i,:) = direction(i,:)./distance(i);
    quaternion_diff(i,:) = events_orientation(i+1,:) - events_orientation(i,:);
end

% Identifizierungsvektor über Länge und Richtung der Bahnabschnitte berechnen
bahn_ident = zeros(8, length(distance));
bahn_ident(1:3,:) = ndirection';
bahn_ident(4,:) = distance;
bahn_ident(5:8,:) = quaternion_diff';

%% Datenbank durchsuchen
query = sprintf('SELECT * FROM robotervermessung.bewegungsdaten.bahn_events');
all_events = fetch(conn, query);
all_events = sortrows(all_events,"timestamp");

% Tabelle nach Bahn-Ids filtern, die 10 Zeichen enthalten (neue gesplittete Daten)
if exist('all_events', 'var') && istable(all_events) && any(strcmp('bahn_id', all_events.Properties.VariableNames))
    % Filterkriterium: Länge der Strings in der Spalte 'bahn_id'
    isValidLength = cellfun(@(x) length(x) == 10, all_events.bahn_id); % isValidLength = strlength(all_events.bahn_id) == 10;
    
    % Nur Zeilen mit Strings von 10 Zeichen beibehalten
    all_events_filtered = all_events(isValidLength, :);   
else
    error('Die Tabelle "all_events" oder die Spalte "bahn_id" existiert nicht.');
end

% Extrahieren der Spalte 'bahn_id' der gefilteretden Daten
all_bahn_id_array = all_events_filtered.bahn_id;

% Finden der einzigartigen Einträge und deren Häufigkeit
[uniqueEntries, ~, indices] = unique(all_bahn_id_array, 'stable');
% Zählen der Häufigkeit jedes Eintrags
counts = accumarray(indices, 1); 
all_bahn_ids = table(uniqueEntries, counts, 'VariableNames', {'Bahn_ID', 'Häufigkeit'});
num_bahnen = sum(counts);

clear all_bahn_id_array uniqueEntries indices isValidLength direction distance ndirection quaternion_diff query
clear counts

% Initialisieren des Merkmal-Arrays aller Bahnen
all_ident = zeros(8,num_bahnen);

dir = zeros(num_bahnen,3);
dist = zeros(num_bahnen,1);
ndir = zeros(num_bahnen,3);
quat = zeros(num_bahnen,4);

% Alle Positionen und Orientierungen
all_positions = table2array(all_events_filtered(:,5:7));
all_orientations = table2array(all_events_filtered(:,8:11));

% Finden der Bahnindizes, welche min. genau so viele Positionen wie die gesuchte Bahn enthalten 
bahn_ids_idx = find(all_bahn_ids.("Häufigkeit") >= size(bahn_ident,2)+1);

% Berechnung der Merkmalsvektoren für alle Ereignisse
k = 1;
for i = 1:size(all_bahn_ids,1)
    for j = 1:all_bahn_ids.("Häufigkeit")(i)-1
        dir(k,:) = all_positions(k+1,:) - all_positions(k,:);
        dist(k) = vecnorm((dir(k,:)));
        ndir(k,:) = dir(k,:)./dist(k);
        quat(k,:) = all_orientations(k+1,:) - all_orientations(k,:);
        k = k + 1;
    end
    k = k + 1;
end

% Merkmalsvektor aller Bahnen in den Stützpunkten/Events
all_ident(1:3,:) = ndir';
all_ident(4,:) = dist;
all_ident(5:8,:) = quat';
% all_ident = [[0;0;0;0], all_ident]; % ohne Orientierung
all_ident = [zeros(8,1), all_ident];
% --> Die einzelnen Bahnen sind durch 0-Vektoren getrennt!
zero_columns = find(sum(all_ident) == 0)';


clear dir dist ndir quat i j k 
%%
% Finden der Indizes, bei denen eine neue Bahn beginnt
found_idx = [];
m = size(zero_columns,1);
for i = 1:m
    if i < size(zero_columns,1)
        difference = zero_columns(m) - zero_columns(m-1);
        if difference >= size(bahn_ident,2)+1
            found_idx = [found_idx; zero_columns(m)];
        end
    else 
        difference = zero_columns(m);
        if difference >= size(bahn_ident,2)+1
            found_idx = [found_idx; zero_columns(m)];
        end
    end
    m = m -1;
end

found_idx = flip(found_idx); 

% Finden des ersten Elements, ab dem die Bahnen geprüft werden!!!
% Überprüfen ob eine Nullspalte vor dem ersten Index liegt
if ~any(all(all_ident(:, 1:found_idx(1)-1) == 0, 1))
    a = 1;
else
    for i = 1:found_idx(1)-1
        % Prüfen, ob Nullspalte vorhanden ist
        if all(all_ident(:, found_idx(1)-i) == 0)
            a = found_idx(1)-i; 
            break;
        end
    end
end

found_idx = [a; found_idx];

clear a difference m i
%% Finden der gleichen Merkmalvektoren in allen Bahnen 

% Vektor der für gleiche Bahnabschnitte kennzeichnet und den Index der jeweiligen Bahn enthält
similarity = [];

threshold_direction = 0.1; % Maximal 10% Abweichung in der Richtung
threshold_length = 0.2; % Maximal 20% Abweichung in der Länge

sz_ident = size(bahn_ident,2);
for i = 1:size(found_idx,1)-1
    similarity = [similarity; 0 0 0]; % Zur Kennzeichnung, dass eine neue Bahn beginnt
    c = 0;
    last_idx = max(find(all(all_ident(:,found_idx(1) : found_idx(i+1)-1) == 0))); % Anfang des Bahnabschnitts
    comp = all_ident(:,last_idx+1:found_idx(i+1)-1); % Bahnabschnitt der mit dem verglichen wird
    df = 1 + size(comp,2) - sz_ident; % Anzahl der Kombinations-Möglichkeiten zwischen gesuchter und Vergleichsbahn
    
    % Vergleich der Merkmalsvektoren mit allen Möglichkeiten
    for j = 1:df
        for k = 1:sz_ident
            d = c + k;

% Überprüft auf exakte Gleichheit
            % if isequal(bahn_ident(:,k),comp(:,d))
            %     similarity = [similarity; 1 bahn_ids_idx(i)];
            % else
            %     similarity = [similarity;0 bahn_ids_idx(i)];
            % end

% Überprüfung mit Grenzwert
            dir1 = bahn_ident(1:3, k);
            dir2 = comp(1:3, d);
    
            % Prüfe die Winkelabweichung (1 - Cosinus des Winkels zwischen dir1 und dir2)
            direction_deviation = norm(dir1 - dir2);
    
            % Extrahiere die Längen (Zeile 4)
            len1 = bahn_ident(4, k);
            len2 = comp(4, d);
    
            % Berechne die relative Abweichung der Länge
            length_deviation = abs(len1 - len2) / max(len1, len2);
    
            % Überprüfe, ob beide Abweichungen innerhalb der Toleranzgrenzen liegen
            if direction_deviation <= threshold_direction && length_deviation <= threshold_length
                similarity = [similarity; 1 bahn_ids_idx(i) d];
            else
                similarity = [similarity; 0 bahn_ids_idx(i) d];
            end
        end
        c = c +1;        
    end
end

% Finden von Start und Ende der 1er-Sequenzen
differential = diff([0;similarity(:,1);0]);
start_idx = find(differential == 1); 
end_idx = find(differential == -1) - 1; 

% Länge jeder Sequenz berechnen
sequences_all_lengths = end_idx - start_idx + 1;

% Maximale Länge finden
sequences_max_length = max(sequences_all_lengths);

% Indizes der längsten Sequenzen speichern
sequences_longest = find(sequences_all_lengths == sequences_max_length);

% Ähnliche Bahnen identifizieren
sequences_longest_idx1 =  start_idx(sequences_longest);
sequences_longest_idx2 =  end_idx(sequences_longest);
aehnliche_bahnen_idx = similarity(sequences_longest_idx1,2);
aehnliche_bahnen = table2array(all_bahn_ids(aehnliche_bahnen_idx,1));

% Ausgabe der Bahn-Id's und Indizes aus similarity-Vektor
fprintf('Die größte Anzahl gleicher aufeinander folgender Punkte beträgt %d.\n', sequences_max_length);
for i = 1:length(sequences_longest)
    fprintf('Bahn_ID %s : Start bei %d, Ende bei %d.\n', ...
        aehnliche_bahnen(i,1), start_idx(sequences_longest(i)), end_idx(sequences_longest(i)));
    
end

clear c d df sz_ident i j k last_idx start_idx end_idx comp
clear dir1 dir2 len1 len2 direction_deviation length_deviation

%% Plotten aller Bahnen 

plot = 0;

if plot

figure;
plot3(events_position(:,1),events_position(:,2),events_position(:,3),'Marker','x')
xlabel('x');ylabel('y');zlabel('z');
hold on

for i = 1:1:length(aehnliche_bahnen)
    query = sprintf("SELECT * FROM robotervermessung.bewegungsdaten.bahn_events WHERE bahn_id = '%s'",aehnliche_bahnen(i)); 
    act_bahn = fetch(conn,query);
    pos = table2array(act_bahn(:,5:7));
    plot3(pos(:,1),pos(:,2),pos(:,3),'Marker','o')
    title(aehnliche_bahnen(i))
    % keyboard; % Code anhalten
end

end

%% Tabelle mit Informationen zu den ähnlichen Bahnen anlegen

if ~isempty(aehnliche_bahnen)
    BAHNVERGLEICH  = table('Size',[0 9],'VariableTypes',{'string', 'string', 'string', 'string','double','double','double','double','double'}, ...
        'VariableNames',{'bahn_id','robot_model','source_ist','source_soll','tcp_speed','max_abweichung_soll','avg_abweichung_soll','euclidean','sidtw'});
    query = sprintf("SELECT * FROM robotervermessung.bewegungsdaten.bahn_position_soll WHERE bahn_id = '%s'",bahn_id);
    bahn_points = fetch(conn,query);
    bahn_points = table2array(bahn_points(:,5:7));

% Abfrage der relevanten Informationen der ähnlichen Bahnen 
for i = 1:1:size(aehnliche_bahnen,1)
    % Geschwindigkeit
    query = sprintf("SELECT * FROM robotervermessung.bewegungsdaten.bahn_twist_ist WHERE bahn_id = '%s'",aehnliche_bahnen(i)); 
    act_bahn = fetch(conn,query);
    max_speed = max(act_bahn.tcp_speed_ist);
    % Roboter-Modell und Quelle der Daten
    query = sprintf("SELECT * FROM robotervermessung.bewegungsdaten.bahn_info WHERE bahn_id = '%s'",aehnliche_bahnen(i)); 
    act_bahn = fetch(conn,query);
    robot_model = act_bahn.robot_model;
    source_ist = act_bahn.source_data_ist;
    source_soll = act_bahn.source_data_soll;
    % Abweichungen (euklidischer Abstand) der Soll-Positionsdaten beider Bahnen
    query = sprintf("SELECT * FROM robotervermessung.bewegungsdaten.bahn_position_soll WHERE bahn_id = '%s'",aehnliche_bahnen(i));
    act_bahn = fetch(conn,query);
    points = table2array(act_bahn(:,5:7));
    [~,dists,~] = distance2curve(points,bahn_points,'linear');
    max_dist = max(dists);
    mean_dist = mean(dists);

    % % TO-DO: Auswertung SIDTW und EUCLIDEAN hinzufügen

    % % TO-DO: Orientierungen vergleichen

    % Anhängen der Daten in die Tabelle 
    BAHNVERGLEICH{end+1,:} = [aehnliche_bahnen(i),robot_model,source_ist,source_soll,max_speed,max_dist,mean_dist,0,0];
end
end


clear source_ist source_soll robot_model max_speed dists max_dist mean_dist act_bahn points 
clear i query

toc;
%% 
% Überprüfen ob die Orientierungen übereinstimmen

query = sprintf("SELECT * FROM robotervermessung.bewegungsdaten.bahn_events WHERE bahn_id = '%s'",aehnliche_bahnen(1));
act_bahn = fetch(conn,query);
act_quat = table2array(act_bahn(:,8:11));
act_quat_diff = diff(act_quat)';

quat_diff = bahn_ident(5:8,:)-act_quat_diff; 
quat_compare = [];

% Schreibt Einsen in den Vektor
for i = 1:size(quat_diff,2)
    if norm(quat_diff(:,i)) <= 0.05
        quat_compare(end+1) = 1;
    else
        quat_compare(end+1) = 0;
    end
end



%% TO-DO



% Ähnlichkeit auch für Teilabschnite anderer Bahnen?

% Informationen über die gleichen Bahnen abrufen: 
% euclidean_mean, sidtw_mean, Geschwindigkeit, robot_model, source_data_soll
% Orientierungswerte vergleichen ?
% Geschwindigkeitswerte vergleichen ?
% Punkte (Ereignisse) vergleichen ?


% TODO:

%%% FRAGE: WAS VERGLEICHEN ? In eigener Messaufnahme SOLL und IST Daten
%%% In unterschiedlichen Messaufnahmen nur IST Daten?

% Ausgabe der Sequenzen und benötigten Parameter der gefunden
% Messaufnahmen, z.B. Robotertyp, Aufzeichnungsdatum etc. 

% !!!!!! WENN DATEN MIT GLEICHEN TIMESTAMP DOPPELT VORLIEGEN MÜSSEN DIE
% DOPPPELTEN DATEN GELÖSCHT WERDEN !!!!!!!
% ---> GROßES PROBLEM DA NICHT ALLE SEQUENZEN ÜBERLAPPEN 
