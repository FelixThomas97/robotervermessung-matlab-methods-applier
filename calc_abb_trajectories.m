function calc_abb_trajectories(data,events,events_all,interpolate)

%% Separieren der Bahn in Bahnabschnitte

% Finden der Zellen die Ereignisse beinhalten (Schon pfp bereinigt)
index_segment = find(events ~= 0);
num_segment = length(index_segment);

% Cell-Array zum abspeichern der einzelnen Bahnabschnitte
segments = cell(1,num_segment);

% Segmente abspeichern in Cell-Array, letztes Segment bis zum letzten Punkt
for i = 1:1:num_segment

    if i < num_segment
        segments{i} = data(index_segment(i)-1:index_segment(i+1)-2,:);
    elseif i == num_segment
        segments{i} = data(index_segment(i)-1:end,:);
    end
end

%% Separieren der einzelnen Ist-Bahnen

% Indizes der Startwerte ermitteln
first_event = events_all(1);
index_trajectory = find(events == first_event);
% Anzahl der Messfahrten anhand aller Vorkommen des Startwerts ermitteln
num_trajectories = length(index_trajectory);

% Cell-Array zum abspeichern der einzelnen Messfahrten
trajectories = cell(1,num_trajectories);

% Messfahrten abspeichern in Cell-Array, letzte bis zum letzten Punkt
for i = 1:1:num_trajectories

        if i < num_trajectories
            trajectories{i} = data(index_trajectory(i)-1:index_trajectory(i+1)-2,:);
        elseif i == num_trajectories
            trajectories{i} = data(index_trajectory(i)-1:end,:);
        end
end

%% Laden in Workspace

if nargin < 4
    assignin("base","segments_ist",segments)
    assignin("base","trajectories_ist",trajectories)
    assignin("base","num_segment",num_segment)
    assignin("base","index_trajectory",index_trajectory)
elseif nargin == 4 && interpolate == false
    assignin("base","segments_soll",segments)
    assignin("base","trajectories_soll",trajectories)
end