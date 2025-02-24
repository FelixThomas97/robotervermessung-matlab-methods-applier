function uploadTransformedData(conn, bahn_id, calibration_id, data_ist, data_ist_trafo, q_transformed, schema)
    try
        % Erstelle Tabelle für transformierte Daten
        bahn_pose_trans = table('Size', [height(data_ist), 11], ...
            'VariableTypes', {'string', 'string', 'string', 'double', 'double', ...
                            'double', 'double', 'double', 'double', 'double', 'string'}, ...
            'VariableNames', {'bahn_id', 'segment_id', 'timestamp', 'x_trans', ...
                            'y_trans', 'z_trans', 'qx_trans', 'qy_trans', ...
                            'qz_trans', 'qw_trans', 'calibration_id'});
        
        % bahn_pose_trans.bahn_id = data_ist.bahn_id;
        calibration_ids = repelem(string(calibration_id),height(bahn_pose_trans))';
        bahn_pose_trans{:,:} = [data_ist{:,2:4}, data_ist_trafo, q_transformed(:,2), q_transformed(:,3), q_transformed(:,4), q_transformed(:,1), calibration_ids];
        
        % Upload zur Datenbank
        sqlwrite(conn, ['robotervermessung.' schema '.bahn_pose_trans'], bahn_pose_trans);
        disp(['Bahn-ID ' bahn_id ' erfolgreich in Datenbank geschrieben']);
        
    catch ME
        error('Fehler beim Datenbank-Upload: %s', ME.message);
    end
end