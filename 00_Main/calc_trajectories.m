function calc_trajectories(data, events, zeros_index, interpolate)
% clear
% load müll
% %load ohne_geschw.mat
% 
% data = data_soll; 
% events = events_soll; 
% events_index = events_index_soll;
% % events_index = find(events ~= 0);
% zeros_index = zeros_index_soll;
% 
% interpolate = false;

%% Überprüfung ob Events mit Geschwindkeit = 0 in Zusammhang stehen
% % % % To-Do: Das muss noch überarbeitet werden % % % %
% z.B. muss überprüft werden ob überhaupt anhand der Nullen eine Aussage
% über die Bahnen getroffen werden kann: Z.B. bei Überschleifen nie = 0 !!!

events_index = find(events ~= 0);

% Überprüfen ob die Null-Indizies zwischen oder gleich den Ereignissen liegen
num_segment = 0;
for i = 1:length(events_index)
    if i <= length(zeros_index)-1
        % Addiere ein Segment wenn Ereignis i zwischen Nullen i und i+1 liegt
        if events_index(i) >= zeros_index(i) && events_index(i) <= zeros_index(i+1)
            num_segment = num_segment +1;
        else
            warning(['Element %d von events_index (%d) liegt nicht zwischen Element %d (%d) und Element %d (%d) von zeros_index.' ...
                ' Dies führt möglicherweise zu Fehlern in der weiteren Berechnung'], i, events_index(i), i, zeros_index(i), i+1, zeros_index(i+1));
        end
    end 
end
% Finale Abfage und setzen eines Status
if num_segment == length(events_index)
    % Anzahl stimmt überein
    zeros_not_fit = false;
else
    % Anzahl stimmt nicht überein
    zeros_not_fit = true;
end

%% Aufteilen der Bahnen in einzelne Bahnabschnitte

% Wenn Anzahl Anzahl übereinstimmt sind die Nullen der Startpunkt
if zeros_not_fit == false

    % Cell-Array zum abspeichern der einzelnen Bahnabschnitte
    segments = cell(1,num_segment);

    % Segmente abspeichern in Cell-Array, letztes Segment bis zum letzten Punkt
    for i = 1:1:num_segment
    
        %%%%%% kommt für jedes Segment ein Punkt dazu und nach letzter Null wird abgeschnitten
        segments{i} = data(zeros_index(i):zeros_index(i+1),:); 
    end

% Wenn die Anzahl nicht Übereinstimmt werden nur die Ereignisse betrachtet
else

    % Cell-Array zum abspeichern der einzelnen Bahnabschnitte
    segments = cell(1,length(events_index));
    num_segment = length(events_index);

    % Segmente abspeichern in Cell-Array, letztes Segment bis zum letzten Punkt
    for i = 1:1:num_segment
        if i == 1 && num_segment > 1
            if interpolate == false && nargin == 4 
                segments{i} = data(1:events_index(i+1)-5,:);
            else
                segments{i} = data(1:events_index(i+1)-2,:);
            end
        % Falls nur ein Segment
        elseif num_segment == 1
            segments{i} = data(1:end,:); 
        elseif i < num_segment
            if interpolate == false && nargin == 4 
                segments{i} = data(events_index(i)-4:events_index(i+1)-5,:);
            else
                segments{i} = data(events_index(i)-1:events_index(i+1)-2,:);
            end
        elseif i == num_segment
            if interpolate == false && nargin == 4 
                segments{i} = data(events_index(i)-4:end,:);
            else
                segments{i} = data(events_index(i)-1:end,:);
            end
        end
    end
end

%% Separieren der einzelnen Ist-Bahnen

% Indizes der Startwerte ermitteln
first_event = events(events_index(1));
index_trajectory = find(events == first_event);
% Anzahl der Messfahrten anhand aller Vorkommen des Startwerts ermitteln
num_trajectories = length(index_trajectory);

%%%%%%%%%%%% To Do für später:
% Prüfen bis zu welchem Ereignis die letzte Trajektorie geht 
% last_trajectory = events(index_trajectory(end):end);
% num_events_last_traj = find(last_trajectory ~= 0);
%%%%%%%%%%%%


% Gleiches Vorgehen wie bei den Bahnabschnitten
if zeros_not_fit == false 

    % Cell-Array zum abspeichern der einzelnen Messfahrten
    trajectories = cell(1,num_trajectories);

    % Messfahrten abspeichern in Cell-Array, letzte bis zum letzten Punkt
     for i = 1:1:num_trajectories
        
        % Springt zum ersten Ereignis der Trajektorie und sucht von dort aus nach der ersten Null
        if i == 1 && num_trajectories > 1
            buffer = data(1:index_trajectory(i+1),:);
            index_first_zero = find(buffer(:,5) == 0, 1, 'last');
            trajectories{i} = data(1:index_first_zero-1,:); %%%%% -1 evtl weg falls nicht 0
        elseif num_trajectories == 1
            trajectories{i} = data(1:zeros_index(end),:); %%%%% Muss geändert falls abgebrochene Trajektorien berücksichtigt
        elseif i < num_trajectories
            buffer = data(index_first_zero+1:index_trajectory(i+1),:);
            count = index_first_zero + find(buffer(:,5) == 0, 1, 'last');
            trajectories{i} = data(index_first_zero:count-1,:); %%%%% -1 evtl weg falls nicht 0
            index_first_zero = count;
        else % i == num_trajectories
            % Letzte Trajektorie bis zum Ende
            trajectories{i} = data(index_first_zero:end,:);
        end
     end

% Orientierung nur an den Ereignissen
else
    % Cell-Array zum abspeichern der einzelnen Messfahrten
    trajectories = cell(1,num_trajectories);

    % Messfahrten abspeichern in Cell-Array, letzte bis zum letzten Punkt
    for i = 1:1:num_trajectories
            if i == 1 && num_trajectories > 1
                if interpolate == false && nargin == 4 
                    trajectories{i} = data(1:index_trajectory(i+1)-5,:);   %%%%% erhöht wenn interpolate an
                else
                    trajectories{i} = data(1:index_trajectory(i+1)-2,:);   
                end
            elseif num_trajectories == 1
                trajectories{i} = data(1:end,:); %%%%% Muss geändert falls abgebrochene Trajektorien berücksichtigt
            elseif i < num_trajectories
                if interpolate == false && nargin == 4 
                    trajectories{i} = data(index_trajectory(i)-4:index_trajectory(i+1)-5,:);
                else
                    trajectories{i} = data(index_trajectory(i)-1:index_trajectory(i+1)-2,:);
                end
            else % i == num_trajectories
                if interpolate == false && nargin == 4 
                    trajectories{i} = data(index_trajectory(i)-4:end,:);
                else
                    trajectories{i} = data(index_trajectory(i)-1:end,:);
                end
            end
    end
end
%% In Workspace laden 

if nargin < 4
    assignin("base","segments_ist",segments)
    assignin("base","trajectories_ist",trajectories)
elseif nargin == 4 && interpolate == false
    assignin("base","segments_soll",segments)
    assignin("base","trajectories_soll",trajectories)
end
end