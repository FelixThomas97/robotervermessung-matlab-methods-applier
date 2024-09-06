function metric2struct_eucl(trajectory_soll, eucl_intepolation,eucl_distances,trajectory_header_id,segment_id)


    % Mittleren Abstand usw. 
    eucldist_av = mean(eucl_distances);
    eucldist_max = max(eucl_distances);
    eucldist_stddev = std(eucl_distances);

    % Intersections berechnen 
    numPoints = size(eucl_intepolation, 1);
    lines = zeros(numPoints, 6);

    for j = 1:numPoints      
        % Speichern der Koordinaten in der Matrix
        lines(j, 1:3) = trajectory_soll(j, :)/1000; % Startpunkt (x, y, z)
        lines(j, 4:6) = eucl_intepolation(j, :)/1000;    % Endpunkt (x, y, z)
    end

    % Konvertieren der lines-Matrix in eine Struktur
    euclidean_intersections = struct();
    for j = 1:numPoints
        euclidean_intersections(j).x = [lines(j, 1), lines(j, 4)];
        euclidean_intersections(j).y = [lines(j, 2), lines(j, 5)];
        euclidean_intersections(j).z = [lines(j, 3), lines(j, 6)];
    end
    
    % Erzeugen des Structs
    metrics_euclidean = struct();
    % Wenn kein i eingeht dann nur die Base-ID
    if nargin < 5
        metrics_euclidean.trajectory_header_id = trajectory_header_id;
        metrics_euclidean.segment_id = trajectory_header_id;
    else
        metrics_euclidean.trajectory_header_id = trajectory_header_id;
        metrics_euclidean.segment_id = segment_id;
    end
    % Euklidische Distanz
    metrics_euclidean.euclidean_distances = eucl_distances/1000;
    metrics_euclidean.euclidean_max_distance = eucldist_max/1000;
    metrics_euclidean.euclidean_average_distance = eucldist_av/1000;
    metrics_euclidean.euclidean_standard_deviation = eucldist_stddev/1000;
    metrics_euclidean.euclidean_intersections = euclidean_intersections; 
    metrics_euclidean.metric_type = 'euclidean';


    %% Metrics in Workspace
    assignin("base","metrics_euclidean",metrics_euclidean)
    assignin("base","eucldist_max",eucldist_max)
    assignin("base","eucldist_av",eucldist_av)
    assignin("base","eucldist_stddev",eucldist_stddev)
    assignin("base","euclidean_intersections",euclidean_intersections)