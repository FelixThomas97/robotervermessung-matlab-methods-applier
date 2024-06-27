%% Verbinden mit Datenbank

% Verbindung mit MongoDB
connectionString = 'mongodb+srv://felixthomas:felixthomas@cluster0.su3gj7l.mongodb.net/';
conn = mongoc(connectionString, 'robotervermessung');

% Check Verbindung
if isopen(conn)
    disp('Verbindung erfolgreich hergestellt');
else
    disp('Verbindung fehlgeschlagen');
end


%% Alternative 1: Lösche einen Eintrag in allen Collections aus der Datenbank

searchID = 'robot01719146835';
nheader = remove(conn,"header",['{"data_id": "', searchID, '"}'])
ndata = remove(conn,"data",['{"trajectory_header_id": "', searchID, '"}'])
nmetrics = remove(conn,"metrics",['{"trajectory_header_id": "', searchID, '"}'])
nspp = remove(conn,"single_point_precision",['{"trajectory_header_id": "', searchID, '"}'])

%% Alternative 2: Lösche alle Einträge in allen Collections aus der Datenbank

% Trajectory Header ID ohne die Nummer des Messdurchlaufs
baseSearchID = 'robot01719154511'; % Falls Segmente mit _ am Ende

% Anzahl der Queries
anzahl_querys = 4;

% Collections
collections = {"data", "header", "metrics", "single_point_precision"};


% Schleife zum Löschen der Einträge
for i = 1:anzahl_querys
    % Dynamisches Erzeugen der searchID
    searchID = [baseSearchID, num2str(i)];
    
    % Query für data, metrics und spp
    query1 = ['{"trajectory_header_id": "', searchID, '"}'];
    % Query für header
    query2 = ['{"data_id": "', searchID, '"}'];
    
    % Lösche Data
    nheader = remove(conn, collections{1}, query1)
    % Lösche Header
    ndata = remove(conn, collections{2}, query2)
    % Lösche Metrics
    nmetrics = remove(conn, collections{3}, query1)
    % Lösche SPP
    nspp = remove(conn, collections{4}, query1)

end
