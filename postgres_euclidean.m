function postgres_euclidean(euclidean_distances, bahn_id_, segment_id_)

euclidean_average_distance = mean(euclidean_distances);
euclidean_max_distance = max(euclidean_distances);
euclidean_min_distance = min(euclidean_distances);
euclidean_standard_deviation = std(euclidean_distances);

% Id's in Cell-Arrays konvertieren
bahn_id = {bahn_id_};
segment_id = {segment_id_};

% Tabellen anlegen
table_euclidean_info = table(bahn_id, segment_id, euclidean_min_distance, ...
                  euclidean_max_distance, euclidean_average_distance, ...
                  euclidean_standard_deviation);

% Vektor mit Replica der ID's erstellen
bahn_id = repelem(bahn_id, length(euclidean_distances),1);
segment_id = repelem(segment_id, length(euclidean_distances),1);

table_euclidean_distances = table(bahn_id, segment_id,euclidean_distances);


%% In Workspace laden 
assignin("base","table_euclidean_distances",table_euclidean_distances)
assignin("base","table_euclidean_info",table_euclidean_info)