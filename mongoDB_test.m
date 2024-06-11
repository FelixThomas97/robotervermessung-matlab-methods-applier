
% Verbindung mit MongoDB
connectionString = 'mongodb+srv://felixthomas:felixthomas@cluster0.su3gj7l.mongodb.net/';
conn = mongoc(connectionString, 'robotervermessung');

% Check Verbindung
if isopen(conn)
    disp('Verbindung erfolgreich hergestellt');
else
    disp('Verbindung fehlgeschlagen');
end

abfrage = false;
if abfrage == true
%% Abfrage für eine Collection

collection = 'data'; 

searchID = 'robot01710922643432725';  

% Query definieren
query = ['{"trajectory_header_id": "', searchID, '"}'];

% Abfrage ausführen
data1 = find(conn, collection, 'Query', query);

%% Abfrage für alle Collections

collections = {"data", "header", "metrics", "single_point_precision"}; 
% header funtkioniert nicht weil andere Bezeichnung

searchID = 'robot01710922643432725';
query = ['{"trajectory_header_id": "', searchID, '"}'];

data = find(conn, collections{1}, 'Query', query);
trajectory_header_id = find(conn, collections{2}, 'Query', query);
metrics = find(conn, collections{3}, 'Query', query);
spp = find(conn, collections{4}, 'Query', query);


% Verbindung schließen
close(conn);
end


%% Export eine Datei

trajectory_header_id = "robot0171629638116";


    filename = 'header_'+trajectory_header_id+'.json';
    jsonfile_header = fileread(filename);
    insert(conn,'header',jsonfile_header);

    filename = 'data_'+trajectory_header_id+'.json';
    jsonfile_data = fileread(filename);
    insert(conn,'data',jsonfile_data);

    filename = 'metrics_johnen_'+trajectory_header_id+'.json';
    jsonfile_metrics_johnen = fileread(filename);
    insert(conn,'metrics',jsonfile_metrics_johnen);

    filename = 'metrics_euclidean_'+trajectory_header_id+'.json';
    jsonfile_metrics_euclidean = fileread(filename);
    insert(conn,'metrics',jsonfile_metrics_euclidean)


% robot017162195001
%% Export alle Dateien
trajectory_header_id = "robot01716221276";

wdh_teilbahn = 16;

array = [];

split = true;
if split == true

    for i = 1:1:wdh_teilbahn

        filename = 'header_'+trajectory_header_id+string(i)+'.json';
        jsonfile_header = fileread(filename);
        insert(conn,'header',jsonfile_header)

        filename = 'data_'+trajectory_header_id+string(i)+'.json';
        jsonfile_data = fileread(filename);
        insert(conn,'data',jsonfile_data);

        filename = 'metrics_johnen_'+trajectory_header_id+string(i)+'.json';
        jsonfile_metrics_johnen = fileread(filename);
        insert(conn,'metrics',jsonfile_metrics_johnen);

        filename = 'metrics_euclidean_'+trajectory_header_id+string(i)+'.json';
        jsonfile_metrics_euclidean = fileread(filename);
        insert(conn,'metrics',jsonfile_metrics_euclidean);
    end

else
        filename = 'header_'+trajectory_header_id+'.json';
        jsonfile_header = fileread(filename);
        insert(conn,'header',jsonfile_header);

        filename = 'data_'+trajectory_header_id+'.json';
        jsonfile_data = fileread(filename);
        insert(conn,'data',jsonfile_data);

        filename = 'metrics_johnen_'+trajectory_header_id+'.json';
        jsonfile_metrics_johnen = fileread(filename);
        insert(conn,'metrics',jsonfile_metrics_johnen);

        filename = 'metrics_euclidean_'+trajectory_header_id+'.json';
        jsonfile_metrics_euclidean = fileread(filename);
        insert(conn,'metrics',jsonfile_metrics_euclidean)
          

end

%% Etwas löschen 
    searchID = 'robot0171629638116';
    n = remove(conn,"header",['{"data_id": "', searchID, '"}'])
    n = remove(conn,"data",['{"trajectory_header_id": "', searchID, '"}'])
    n = remove(conn,"metrics",['{"trajectory_header_id": "', searchID, '"}'])


% {recording_date: "2024-05-16T16:33:00.241866"}