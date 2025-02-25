function getSegments(conn, bahn_id, schema, evaluate_orientation, evaluate_velocity, trafo_rot, trafo_trans, q_transform)
%% Auslesen der für die entsprechende Auswertung benötigten Daten

% Anzahl der Segmente der gesamten Messaufnahme bestimmen 
query = ['SELECT * FROM robotervermessung.' schema '.bahn_info ' ...
         'WHERE robotervermessung.' schema '.bahn_info.bahn_id = ''' bahn_id ''''];
data_info = fetch(conn, query);
num_segments = data_info.np_ereignisse;

% Orientierungsdaten
if evaluate_velocity == false && evaluate_orientation == true

    % Auslesen der gesamten Ist-Daten
    query = ['SELECT * FROM robotervermessung.' schema '.bahn_pose_ist ' ...
            'WHERE robotervermessung.' schema '.bahn_pose_ist.bahn_id = ''' bahn_id ''''];
    data_ist = fetch(conn, query);
    data_ist = sortrows(data_ist,'timestamp');
    
    % Auslesen der gesamten Soll-Daten
    query = ['SELECT * FROM robotervermessung.' schema '.bahn_orientation_soll ' ...
            'WHERE robotervermessung.' schema '.bahn_orientation_soll.bahn_id = ''' bahn_id ''''];
    data_soll = fetch(conn, query);
    data_soll = sortrows(data_soll,'timestamp');
    
    q_ist = table2array(data_ist(:,8:11));
    q_ist = [q_ist(:,4), q_ist(:,1), q_ist(:,2), q_ist(:,3)];
    euler_ist = quat2eul(q_ist,"XYZ");
    euler_ist = rad2deg(euler_ist);

    position_ist = table2array(data_ist(:,5:7));
       
    % Koordinatentransfromation
    coordTransformation(position_ist, trafo_rot, trafo_trans);

    % Winkeltransformation
    q_transformed = transformQuaternion(data_ist, data_soll, q_transform, trafo_rot);

% Geschwindigkeitsdaten aus Positionsdaten
elseif evaluate_velocity == true && evaluate_orientation == false 

    % Auslesen der gesamten Ist-Daten
    query = ['SELECT * FROM robotervermessung.' schema '.bahn_twist_ist ' ...
            'WHERE robotervermessung.' schema '.bahn_twist_ist.bahn_id = ''' bahn_id ''''];
    data_ist = fetch(conn, query);
    data_ist = sortrows(data_ist,'timestamp');
    
    % Auslesen der gesamten Soll-Daten
    query = ['SELECT * FROM robotervermessung.' schema '.bahn_position_soll ' ...
            'WHERE robotervermessung.' schema '.bahn_position_soll.bahn_id = ''' bahn_id ''''];
    data_soll = fetch(conn, query);
    data_soll = sortrows(data_soll,'timestamp');

    % Geschwindigkeitsdaten präperieren 
    velocityPreparation(data_soll, data_ist)

% Positionsdaten
else
    % Auslesen der gesamten Ist-Daten
    query = ['SELECT * FROM robotervermessung.' schema '.bahn_pose_ist ' ...
            'WHERE robotervermessung.' schema '.bahn_pose_ist.bahn_id = ''' bahn_id ''''];
    data_ist = fetch(conn, query);
    data_ist = sortrows(data_ist,'timestamp');
    
    % Auslesen der gesamten Soll-Daten
    query = ['SELECT * FROM robotervermessung.' schema '.bahn_position_soll ' ...
            'WHERE robotervermessung.' schema '.bahn_position_soll.bahn_id = ''' bahn_id ''''];
    data_soll = fetch(conn, query);
    data_soll = sortrows(data_soll,'timestamp');

end
%% Extraktion und Separation der Segmente der Gesamtaufname

% Alle Segment-ID's 
query = ['SELECT segment_id FROM robotervermessung.' schema '.bahn_events ' ...
    'WHERE robotervermessung.' schema '.bahn_events.bahn_id = ''' bahn_id ''''];
segment_ids = fetch(conn,query);

% % % IST-DATEN % % %
% Extraktion der Indizes der Segmente 
seg_id = split(data_ist.segment_id, '_');
seg_id = double(string(seg_id(:,2)));
idx_new_seg_ist = zeros(num_segments,1);

% Suche nach den Indizes bei denen sich die Segmentnr. ändert
k = 0;
idx = 1;
for i = 1:1:length(seg_id)
    if seg_id(i) == k
        idx = idx + 1;
    else
        k = k +1;
        idx_new_seg_ist(k) = idx;
        idx = idx+1;
    end
end

% % % SOLL-DATEN % % %
seg_id = split(data_soll.segment_id, '_');
seg_id = double(string(seg_id(:,2)));
idx_new_seg_soll = zeros(num_segments,1);

k = 0;
idx = 1;
for i = 1:1:length(seg_id)
    if seg_id(i) == k
        idx = idx + 1;
    else
        k = k +1;
        idx_new_seg_soll(k) = idx;
        idx = idx+1;
    end
end


if evaluate_velocity == true && evaluate_orientation == false 

    disp('Es wird die Geschwindigkeit ausgewertet!')

    % Speichern der einzelnen Semgente in Tabelle
    segments_ist = array2table([{string(bahn_id_)+"_0"} table2array(data_ist(1:idx_new_seg_ist(1)-1,[3,4]))], "VariableNames",{'segment_id','tcp_speed_ist'});
   
    for i = 1:num_segments
    
        if i == length(idx_new_seg_ist)
            segments_ist(i+1,:) = array2table([{segment_ids{i,:}} data_ist.tcp_speed_ist(idx_new_seg_ist(i):end)]);
        else
            segments_ist(i+1,:) = array2table([{segment_ids{i,:}} data_ist.tcp_speed_ist(idx_new_seg_ist(i):idx_new_seg_ist(i+1)-1)]);
        end
    
    end
    
    if idx_new_seg_soll(1) == 1
        segments_soll = array2table([{string(bahn_id_)+"_0"} table2array(data_soll(1:idx_new_seg_soll(1),[3,4]))], "VariableNames",{'segment_id','tcp_speed_soll'});
    else
        segments_soll = array2table([{string(bahn_id_)+"_0"} table2array(data_soll(1:idx_new_seg_soll(1)-1,[3,4]))], "VariableNames",{'segment_id','tcp_speed_soll'});
    end
    for i = 1:num_segments
        if i == length(idx_new_seg_soll)
            segments_soll(i+1,:) = array2table([{segment_ids{i,:}} data_soll.tcp_speed_soll(idx_new_seg_soll(i):end)]);
        else
            segments_soll(i+1,:)= array2table([{segment_ids{i,:}} data_soll.tcp_speed_soll(idx_new_seg_soll(i):idx_new_seg_soll(i+1)-1)]);
        end    
    end
    
elseif evaluate_velocity == false && evaluate_orientation == true

    disp('Es wird die Orientierung ausgewertet!')
    
    % First segment IST data (quaternions)
    segments_ist = array2table([{data_ist.segment_id(1)} ...
                              data_ist.qw_ist(1:idx_new_seg_ist(1)-1) ...
                              data_ist.qx_ist(1:idx_new_seg_ist(1)-1) ...
                              data_ist.qy_ist(1:idx_new_seg_ist(1)-1) ...
                              data_ist.qz_ist(1:idx_new_seg_ist(1)-1)], ...
                              'VariableNames', {'segment_id', 'qw_ist', 'qx_ist', 'qy_ist', 'qz_ist'});
    
    % Remaining IST segments
    for i = 1:num_segments
        if i == length(idx_new_seg_ist)
            % Last segment
            segments_ist(i+1,:) = array2table([{segment_ids{i,:}} ...
                                             data_ist.qw_ist(idx_new_seg_ist(i):end) ...
                                             data_ist.qx_ist(idx_new_seg_ist(i):end) ...
                                             data_ist.qy_ist(idx_new_seg_ist(i):end) ...
                                             data_ist.qz_ist(idx_new_seg_ist(i):end)]);
        else
            % Middle segments
            segments_ist(i+1,:) = array2table([{segment_ids{i,:}} ...
                                             data_ist.qw_ist(idx_new_seg_ist(i):idx_new_seg_ist(i+1)-1) ...
                                             data_ist.qx_ist(idx_new_seg_ist(i):idx_new_seg_ist(i+1)-1) ...
                                             data_ist.qy_ist(idx_new_seg_ist(i):idx_new_seg_ist(i+1)-1) ...
                                             data_ist.qz_ist(idx_new_seg_ist(i):idx_new_seg_ist(i+1)-1)]);
        end
    end
    
    % First segment SOLL data
    segments_soll = array2table([{data_soll.segment_id(1)} ...
                                data_soll.qw_soll(1:idx_new_seg_soll(1)-1) ...
                                data_soll.qx_soll(1:idx_new_seg_soll(1)-1) ...
                                data_soll.qy_soll(1:idx_new_seg_soll(1)-1) ...
                                data_soll.qz_soll(1:idx_new_seg_soll(1)-1)], ...
                                'VariableNames', {'segment_id', 'qw_soll', 'qx_soll', 'qy_soll', 'qz_soll'});
    
    % Remaining SOLL segments
    for i = 1:num_segments
        if i == length(idx_new_seg_soll)
            segments_soll(i+1,:) = array2table([{segment_ids{i,:}} ...
                                              data_soll.qw_soll(idx_new_seg_soll(i):end) ...
                                              data_soll.qx_soll(idx_new_seg_soll(i):end) ...
                                              data_soll.qy_soll(idx_new_seg_soll(i):end) ...
                                              data_soll.qz_soll(idx_new_seg_soll(i):end)]);
        else
            segments_soll(i+1,:) = array2table([{segment_ids{i,:}} ...
                                              data_soll.qw_soll(idx_new_seg_soll(i):idx_new_seg_soll(i+1)-1) ...
                                              data_soll.qx_soll(idx_new_seg_soll(i):idx_new_seg_soll(i+1)-1) ...
                                              data_soll.qy_soll(idx_new_seg_soll(i):idx_new_seg_soll(i+1)-1) ...
                                              data_soll.qz_soll(idx_new_seg_soll(i):idx_new_seg_soll(i+1)-1)]);
        end
    end
    
    % Initialize transformation results
    segments_trafo = table();
    q_transformed_all = [];
    
    % Transform each segment
    for i = 1:num_segments+1
        % Extract quaternions for current segment
        segment_ist = table2struct(segments_ist(i,:));
        segment_soll = table2struct(segments_soll(i,:));
        
        % Create temporary tables with the segment data
        data_ist_seg = table(segment_ist.qw_ist, segment_ist.qx_ist, segment_ist.qy_ist, segment_ist.qz_ist, ...
                            'VariableNames', {'qw_ist', 'qx_ist', 'qy_ist', 'qz_ist'});
        data_soll_seg = table(segment_soll.qw_soll, segment_soll.qx_soll, segment_soll.qy_soll, segment_soll.qz_soll, ...
                             'VariableNames', {'qw_soll', 'qx_soll', 'qy_soll', 'qz_soll'});
        
        % Transform using existing function
        q_transformed = transformQuaternion(data_ist_seg, data_soll_seg, q_transform, trafo_rot);

        % Add row to segments_trafo
        segments_trafo(i,:) = table({segments_ist.segment_id(i)}, ...
                               {q_transformed(:,1)}, {q_transformed(:,2)}, ...
                               {q_transformed(:,3)}, {q_transformed(:,4)}, ...
                               'VariableNames', {'segment_id', 'qw_trans', 'qx_trans', 'qy_trans', 'qz_trans'});
    
        % Accumulate all transformed quaternions
        q_transformed_all = [q_transformed_all; q_transformed];
    end

    
%%%%%%% Sonst automatisch Auswertung von Positionsdaten 
else

    disp('Es wird die Position ausgewertet!')

    % Speichern der einzelnen Semgente in Tabelle
    segments_ist = array2table([{data_ist.segment_id(1)} data_ist.x_ist(1:idx_new_seg_ist(1)-1) data_ist.y_ist(1:idx_new_seg_ist(1)-1) data_ist.z_ist(1:idx_new_seg_ist(1)-1)], "VariableNames",{'segment_id','x_ist','y_ist','z_ist'});
    
    for i = 1:num_segments
        if i == length(idx_new_seg_ist)
            segments_ist(i+1,:) = array2table([{segment_ids{i,:}} data_ist.x_ist(idx_new_seg_ist(i):end) data_ist.y_ist(idx_new_seg_ist(i):end) data_ist.z_ist(idx_new_seg_ist(i):end)]);
        else
            segments_ist(i+1,:) = array2table([{segment_ids{i,:}} data_ist.x_ist(idx_new_seg_ist(i):idx_new_seg_ist(i+1)-1) data_ist.y_ist(idx_new_seg_ist(i):idx_new_seg_ist(i+1)-1) data_ist.z_ist(idx_new_seg_ist(i):idx_new_seg_ist(i+1)-1)]);
        end
    end
    
    if idx_new_seg_soll(1) == 1
        segments_soll = array2table([{data_soll.segment_id(1)} data_soll.x_soll(1:idx_new_seg_soll(1)) data_soll.y_soll(1:idx_new_seg_soll(1)) data_soll.z_soll(1:idx_new_seg_soll(1))], "VariableNames",{'segment_id','x_soll','y_soll','z_soll'});
    else
        segments_soll = array2table([{data_soll.segment_id(1)} data_soll.x_soll(1:idx_new_seg_soll(1)-1) data_soll.y_soll(1:idx_new_seg_soll(1)-1) data_soll.z_soll(1:idx_new_seg_soll(1)-1)], "VariableNames",{'segment_id','x_soll','y_soll','z_soll'});
    end
    for i = 1:num_segments
        if i == length(idx_new_seg_soll)
            segments_soll(i+1,:) = array2table([{segment_ids{i,:}} data_soll.x_soll(idx_new_seg_soll(i):end) data_soll.y_soll(idx_new_seg_soll(i):end) data_soll.z_soll(idx_new_seg_soll(i):end)]);
        else
            segments_soll(i+1,:)= array2table([{segment_ids{i,:}} data_soll.x_soll(idx_new_seg_soll(i):idx_new_seg_soll(i+1)-1) data_soll.y_soll(idx_new_seg_soll(i):idx_new_seg_soll(i+1)-1) data_soll.z_soll(idx_new_seg_soll(i):idx_new_seg_soll(i+1)-1)]);
        end    
    end
    
    % Koordinatentransformation für alle Segemente
    segments_trafo = table();
    for i = 1:1:num_segments+1
        coordTransformation(segments_ist(i,:),trafo_rot, trafo_trans)
        segments_trafo(i,:) = pos_ist_trafo;
    end

end

% Löschen des Segment 0: 
segments_soll = segments_soll(2:end,:);
segments_ist = segments_ist(2:end,:);
if evaluate_velocity == false
    segments_trafo = segments_trafo(2:end,:);
end
num_segments = num_segments -1;

%% Laden in Workspace
assignin("base","num_segments",num_segments)
assignin("base","segment_ids",segment_ids)
assignin("base","data_ist",data_ist)
assignin("base","data_soll",data_soll)
assignin("base","segments_ist",segments_ist)
assignin("base","segments_soll",segments_soll)
assignin("base","segments_trafo",segments_trafo)
if evaluate_orientation
        assignin('base', 'q_transformed', q_transformed_all);
end

