function generate_soll(segments_ist,trajectories_ist,events_all_ist,keypoints_faktor)

%% Generiere Sollbahn für die einzelnen Bahnabschnitte

segments_soll = cell(1,length(segments_ist));
num_segment = size(segments_soll,2);

for i = 1:1:num_segment

    segment_ist = segments_ist{i}(:,2:4);
    num_soll = abs(round(length(segment_ist)*keypoints_faktor)); % aufrunden und immer positiv
    first_point = segment_ist(1,:);
    last_point = segment_ist(end,:);

    % Lineare Interpolation zwischen Anfangs- und Endpunkt des Segments mit gleichbleibenden Abständen
    segment_soll = interp1([0 1], [first_point; last_point], linspace(0, 1, num_soll)); 
    
    % Eintragen in Cell-Array
    segments_soll{i} = segment_soll;
end

%% Zusammensetzen der Sollbahn-Abschnitte für gesamte Bahnen

index_first_elements = find(events_all_ist == events_all_ist(1));
segments_per_traj = diff(index_first_elements);

trajectories_soll = cell(1,length(trajectories_ist));
count = 1;

for i = 1:1:length(segments_per_traj)+1
    b = zeros(1,3);
    if i < length(segments_per_traj)+1
        k = segments_per_traj(i);

        for j = 1:1:k
            a = segments_soll{count};
            b = [b; a(1:end,:)]; % Damit die Elemente nicht doppelt evtl. -1 vorkommen!
            count = count + 1;
        end

    else

        for j = count:1:num_segment
        a = segments_soll{j};
        b = [b;a];
        end

    end
    b = b(2:end,:);
    trajectories_soll{i} = b;
end

%% Laden in Workspace

assignin("base","segments_soll",segments_soll)
assignin("base","trajectories_soll",trajectories_soll)
% assignin("base","segments_per_traj",segments_per_traj)
end