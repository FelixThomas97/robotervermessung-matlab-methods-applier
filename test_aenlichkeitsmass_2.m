% Löschen des Workspace
clear; tic;
% Verbindung mit der Datenbank
conn = connecting_to_postgres;

%% Bestimmung der Änlichkeitsparameter (Anhand von gegebenen Punkten/Events)
% Festlegen nach einer Bahn für die änliche Bahnen gesucht werden sollen
bahn_id = '1721048844'; % Square (5 Segmente)

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

clear bahn_id_array uniqueEntries indices

% Initialisieren des Merkmal-Arrays aller Bahnen
all_ident = zeros(4,counts_sum-length(counts));
dir = zeros(counts_sum-length(counts),3);
dist = zeros(counts_sum-length(counts),1);
ndir = zeros(counts_sum-length(counts),3);
% Alle Positionen
positions = table2array(all_events_filtered(:,5:7));

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

toc;
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