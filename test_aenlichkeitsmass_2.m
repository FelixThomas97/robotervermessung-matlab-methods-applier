% Löschen des Workspace
clear; tic;
% Verbindung mit der Datenbank
conn = connecting_to_postgres;

%% Bestimmung der Änlichkeitsparameter (Anhand von gegebenen Punkten/Events)
% Festlegen nach einer Bahn für die änliche Bahnen gesucht werden sollen
bahn_id = '1721048844'; % Square (5 Segmente) % gibts auch nichtmehr
bahn_id = '1719911918';


query = sprintf('SELECT * FROM robotervermessung.bewegungsdaten.bahn_events WHERE bahn_id = ''%s''',bahn_id);
bahn_events = fetch(conn, query);

% Punkte/Events herrausfiltern
events = table2array(bahn_events(:,5:7));

% Richtungsvektor, norm. Richtungsvektor und Länge der Bahnen berechnen
direction = zeros(height(bahn_events)-1,3);
distance = zeros(height(bahn_events)-1,1);
ndirection = zeros(height(bahn_events)-1,3);
for i = 1: height(bahn_events)-1
    direction(i,:) = events(i+1,:) - events(i,:);
    distance(i) = vecnorm((direction(i,:)));
    ndirection(i,:) = direction(i,:)./distance(i);
end

% Identifizierungsvektor über Länge und Richtung der Bahnabschnitte berechnen
ident = zeros(4, length(distance));
ident(1:3,:) = ndirection';
ident(4,:) = distance;

%% Datenbank durchsuchen
query = sprintf('SELECT * FROM robotervermessung.bewegungsdaten.bahn_events');
all_events = fetch(conn, query);
all_events = sortrows(all_events,"timestamp");

% Tabelle nach Bahn-Ids filtern, die 10 Zeichen enthalten
if exist('all_events', 'var') && istable(all_events) && any(strcmp('bahn_id', all_events.Properties.VariableNames))
    % Filterkriterium: Länge der Strings in der Spalte 'bahn_id'
    isValidLength = cellfun(@(x) length(x) == 10, all_events.bahn_id); % isValidLength = strlength(all_events.bahn_id) == 10;
    
    % Nur Zeilen mit Strings von 10 Zeichen beibehalten
    all_events_filtered = all_events(isValidLength, :);   
else
    error('Die Tabelle "all_events" oder die Spalte "bahn_id" existiert nicht.');
end

% Extrahieren der Spalte 'bahn_id' der gefilteretden Daten
bahn_id_array = all_events_filtered.bahn_id;

% Finden der einzigartigen Einträge und deren Häufigkeit
[uniqueEntries, ~, indices] = unique(bahn_id_array, 'stable');
% Zählen der Häufigkeit jedes Eintrags
counts = accumarray(indices, 1); 
table_counts = table(uniqueEntries, counts, 'VariableNames', {'Bahn_ID', 'Häufigkeit'});
counts_sum = sum(counts);

clear bahn_id_array uniqueEntries indices isValidLength 

% Initialisieren des Merkmal-Arrays aller Bahnen
all_ident = zeros(4,counts_sum);

dir = zeros(counts_sum,3);
dist = zeros(counts_sum,1);
ndir = zeros(counts_sum,3);

% Alle Positionen
positions = table2array(all_events_filtered(:,5:7));

% Filtern der Bahn-Ids, welche mindestens so viele Positionen beinhalten
bahn_ids_idx = find(counts >= size(ident,2)+1);

%n Berechnung der Merkmalsvektoren für alle Ereignisse
k = 1;
for i = 1:length(counts)
    for j = 1:counts(i)-1
        dir(k,:) = positions(k+1,:) - positions(k,:);
        dist(k) = vecnorm((dir(k,:)));
        ndir(k,:) = dir(k,:)./dist(k);
        k = k + 1;
    end
    k = k + 1;
end

% Merkmalsvektor aller Bahnen in den Stützpunkten/Events
all_ident(1:3,:) = ndir';
all_ident(4,:) = dist;
all_ident = [[0;0;0;0], all_ident];
% --> Die einzelnen Bahnen sind durch 0-Vektoren getrennt!
zero_columns = find(sum(all_ident) == 0)';

% Finden der Bahnindizes, welche min. genau so viele Positionen wie die gesuchte Bahn enthalten 
found_idx = [];
m = size(zero_columns,1);
for i = 1:m
    if i < size(zero_columns,1)
        difference = zero_columns(m) - zero_columns(m-1);
        if difference >= size(ident,2)+1
            found_idx = [found_idx; zero_columns(m)];
        end
    else 
        difference = zero_columns(m);
        if difference >= size(ident,2)+1
            found_idx = [found_idx; zero_columns(m)];
        end
    end
    m = m -1;
end
found_idx = flip(found_idx);

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
%% 
similarity = [];

sz_ident = size(ident,2);
for i = 1:size(found_idx,1)-1
    similarity = [similarity; 0 0]; % Zur Kennzeichnung, dass eine neue Bahn beginnt
    c = 0;
    last_idx = max(find(all(all_ident(:,found_idx(1) : found_idx(i+1)-1) == 0)));
    comp = all_ident(:,last_idx+1:found_idx(i+1)-1);
    % comp = all_ident(:,2:7);
    df = 1 + size(comp,2) - sz_ident;
    for j = 1:df
        for k = 1:sz_ident
            d = c + k;
            if isequal(ident(:,k),comp(:,d))
                similarity = [similarity; 1 bahn_ids_idx(i)];
            else
                similarity = [similarity;0 bahn_ids_idx(i)];
            end
        end
        c = c +1;
        
    end
end

toc;

differential = diff([0;similarity(:,1);0]); % Differenzen berechnen (mit Puffer 0 am Anfang und Ende)
start_idx = find(differential == 1); % Start der Einsen-Sequenzen
end_idx = find(differential == -1) - 1; % Ende der Einsen-Sequenzen

% Länge jeder Sequenz berechnen
lengths = end_idx - start_idx + 1;

% Maximale Länge finden
maxLength = max(lengths);

% Indizes der längsten Sequenzen speichern
longestSequences = find(lengths == maxLength);

% Ähnliche Bahnen identifizieren
a =  start_idx(longestSequences);
aenliche_bahnen_idx = similarity(a,2);
aehnliche_bahnen = table2array(table_counts(aenliche_bahnen_idx,1));

% Ausgabe der Bahn-Id's und Indizes aus similarity-Vektor
fprintf('Die größte Anzahl gleicher aufeinander folgender Punkte beträgt %d.\n', maxLength);
for i = 1:length(longestSequences)
    fprintf('Bahn_ID %s : Start bei %d, Ende bei %d.\n', ...
        aehnliche_bahnen(i,1), start_idx(longestSequences(i)), end_idx(longestSequences(i)));
    
end
%%
% 
% i = 1;
% a = max(find(all(all_ident(:,found_idx(i) : found_idx(2+1)-1) == 0)))
% 
% 
% aa = all_ident(:,a+1:found_idx(2+1)-1);


%% TO-DO

%%% FRAGE: WAS VERGLEICHEN ? In eigener Messaufnahme SOLL und IST Daten
%%% In unterschiedlichen Messaufnahmen nur IST Daten? 

% Berechnung der Abweichungen zwischen ähnlichen Sequenzen innerhalb der
% gleichen Messaufnahme

% Finden von ähnlichen Sequenzen in anderen Messaufnahmen 
% --> Muss über die Events laufen sonst zu ineffizient

% Berechnnung der Abweichungen ähnlicher Sequenzen aus verschiedenen
% Messaufnahmen 

% Ausgabe der Sequenzen und benötigten Parameter der gefunden
% Messaufnahmen, z.B. Robotertyp, Aufzeichnungsdatum etc. 

% !!!!!! WENN DATEN MIT GLEICHEN TIMESTAMP DOPPELT VORLIEGEN MÜSSEN DIE
% DOPPPELTEN DATEN GELÖSCHT WERDEN !!!!!!!
% ---> GROßES PROBLEM DA NICHT ALLE SEQUENZEN ÜBERLAPPEN 