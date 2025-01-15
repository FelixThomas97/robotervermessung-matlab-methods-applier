% Test Ähnlichkeitsmaß
clear;
tic;

calculate = false; 

% bahn_id = '172104917'; % random
bahn_id = '172070918'; % iso-square + diagonal --> exisitiert nicht mehr :o
bahn_id = '172071283'; % squares die vertikal nach unten gehen
bahn_id = '172079427'; % iso-square + diagonal

% Verbinden mit Datenbank
datasource = "RobotervermessungMATLAB";
username = "felixthomas";
password = "manager";
conn = postgresql(datasource,username,password);

% Überprüfe Verbindung
if isopen(conn)
    disp('Verbindung erfolgreich hergestellt');
else
    disp('Verbindung fehlgeschlagen');
end

clear datasource username password

query = sprintf('SELECT * FROM robotervermessung.bewegungsdaten.bahn_events WHERE bahn_id = ''%s''',bahn_id);

data = fetch(conn,query);

num_events = size(data,1);
events = data(:,5:7);

direction = zeros(height(data)-1,1);
distance = zeros(height(data)-1,1);
ndirection = zeros(height(data)-1,3);
for i = 1:height(data)-1
    % normalisierte Richtungsvektoren berechen
    events(i,:) = (events(i+1,:)-events(i,:));
    direction(i) = vecnorm(table2array(events(i,:)));
    distance(i) = sqrt(table2array(events(i,1))^2+table2array(events(i,2))^2+table2array(events(i,3))^2);
    ndirection(i,:) = table2array(events(i,:))./direction(i);
end

% Ähnlichkeitsvektor
similarity = zeros(4, length(distance));
similarity(1:3,:) = ndirection';
similarity(4,:) = distance;

%%

n = size(similarity, 2); % Anzahl der Spalten
result = false(n); % Matrix zur Speicherung der Ergebnisse
paare = [];
% paare2 = [];

% Schwellwert 
threshold = 0.1;

for i = 1:n
    for j = i+1:n

% Prüft auf exakte Gleichheit
        % % result(i, j) = all(A(:,i) == A(:,j)); % Vergleicht Spalte i mit Spalte j
        % % if result(i,j) == 1
        % %     paare2 = [paare2; i,j];
        % % end

% Prüft auf Gleichheit bezüglich Schwellwert
        % Berechnet die Euklidische Distanz zwischen den einzelnen Spalten 
        dist = norm(similarity(:,i) - similarity(:,j)); 
        
        % Prüft, ob der Abstand unter dem Schwellenwert liegt
        if dist <= threshold
            result(i, j) = true; 
            paare = [paare; i, j];
        end
    end
end

%%
% Zweite Schleife: Überprüfung auf aufeinanderfolgende Gleichheit
sequenzen = []; % Speicher für Startindex und Länge der Sequenzen
for k = 1:size(paare, 1)
    i = paare(k, 1); % Erste Spalte des Paares
    j = paare(k, 2); % Zweite Spalte des Paares
    count = 0; % Zählt die Länge der Sequenz
    
    % Überprüfen, wie viele Spalten aufeinanderfolgend gleich sind
    while i+count <= n && j+count <= n % Grenze der Matrix beachten
        dist = norm(similarity(:,i+count) - similarity(:,j+count)); % Abstand für die Spalten (i+count) und (j+count)
        if dist <= threshold
            count = count + 1; % Erhöht die Sequenzlänge
        else
            break; % Sequenz endet, wenn ein Paar nicht gleich ist
        end
    end
    
    % Speichern, wenn die Sequenz länger als 1 ist
    % (Größer 0 wenn auch einzelne Sequenzen gezält werden sollen!)
    if count > 0
        sequenzen = [sequenzen; i, j, count]; % Speichert Startindizes und Länge
    end
end

sequencen_sortiert = sortrows(sequenzen,3,'descend');
toc;
%% Vergleich der Sequenzen

% Daten aus der Datenbank ziehen!

% Wie oft befindet sich eine Sequenz innerhalb der eigenen Messaufnahme -->
% num_events

query = sprintf('SELECT * FROM robotervermessung.bewegungsdaten.bahn_pose_trans WHERE bahn_id = ''%s''',bahn_id);
pose_ist = fetch(conn,query);
pose_ist = sortrows(pose_ist,"timestamp");

% query = sprintf('SELECT * FROM robotervermessung.bewegungsdaten.bahn_position_soll WHERE bahn_id = ''%s''',bahn_id);
% pose_soll = fetch(conn,query);

% Anfangs- und End-Indizes der Sequenzen in den IST-Daten finden
idx11 = find(pose_ist.segment_id == string(bahn_id)+"_"+string(sequencen_sortiert(1,1)),1);
idx21 = find(pose_ist.segment_id == string(bahn_id)+"_"+string(sequencen_sortiert(1,2)),1);

idx12 = sequencen_sortiert(1,3)+sequencen_sortiert(1,1)-1;
idx22 = sequencen_sortiert(1,3)+sequencen_sortiert(1,2)-1;

idx12 = find(pose_ist.segment_id == string(bahn_id)+"_"+string(idx12));
idx12 = idx12(end);
idx22 = find(pose_ist.segment_id == string(bahn_id)+"_"+string(idx22));
idx22 = idx22(end);

bahn_seq1 = pose_ist(idx11:idx12,:);
bahn_seq2 = pose_ist(idx21:idx22,:);

seq1 = table2array(bahn_seq1(:,4:6));
seq2 = table2array(bahn_seq2(:,4:6));

%% Mehtoden berechnen 
if calculate
    tic;
    [distancesDTW, maxDTW, averageDTW, ~, dtw_X, dtw_Y, path_dtw, ~, ~, ~] = fkt_dtw3d(seq1,seq2,0)
    [distancesSIDTW, maxSIDTW, averageSIDTW, ~, sidtw_X, sidtw_Y,path_sidtw, ~, ~] = fkt_selintdtw3d(seq1,seq2,0)
    [xy,distanceEucl,t_a] = distance2curve(seq1,seq2,'linear')
    maxEucl = max(distanceEucl);
    averageEucl = mean(distanceEucl);
    toc;
end
%% Für alle DATEN
tic

% Alle Ereignisse aus der Datenbank ziehen 
query = sprintf('SELECT * FROM robotervermessung.bewegungsdaten.bahn_events');

data_all = fetch(conn, query);
data_all = sortrows(data_all,"timestamp");

events_all = data_all(:,5:7);

direction_all = zeros(height(data_all)-1,1);
distance_all = zeros(height(data_all)-1,1);
ndirection_all = zeros(height(data_all)-1,3);
for i = 1:height(data_all)-1
    % normalisierte Richtungsvektoren berechen
    events_all(i,:) = (events_all(i+1,:)-events_all(i,:));
    direction_all(i) = vecnorm(table2array(events_all(i,:)));
    % distance_all(i) = sqrt(table2array(events_all(i,1))^2+table2array(events_all(i,2))^2+table2array(events_all(i,3))^2);
    ndirection_all(i,:) = table2array(events_all(i,:))./direction_all(i);
end

% Ähnlichkeitsvektor
similarity_all = zeros(4, length(distance_all));
similarity_all(1:3,:) = ndirection_all';
similarity_all(4,:) = distance_all;

toc

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

%%
% Beispiel-Daten: Aufsteigend sortierter Vektor mit Duplikaten
vec = table2array(data_all(:,4));
vec = str2double(vec);
%%

% Finden von Duplikaten und ihren Indizes
[~, uniqueIndices] = unique(vec, 'stable'); % Indizes der eindeutigen Elemente
allIndices = 1:length(vec); % Alle Indizes
duplicateIndices = setdiff(allIndices, uniqueIndices); % Indizes der Duplikate

% Entfernen der Duplikate
vecWithoutDuplicates = vec(uniqueIndices);



