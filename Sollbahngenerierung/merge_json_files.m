function merge_json_files(file1, file2, combined_file)
    % Ler o primeiro arquivo JSON
    fid = fopen(file1);
    if fid == -1
        error('Cannot open %s', file1);
    end
    data1 = fread(fid, '*char')';
    fclose(fid);
    json1 = jsondecode(data1);
    
    % Ler o segundo arquivo JSON
    fid = fopen(file2);
    if fid == -1
        error('Cannot open %s', file2);
    end
    data2 = fread(fid, '*char')';
    fclose(fid);
    json2 = jsondecode(data2);
    
    % Combinar as estruturas de dados
    combined_data = json1;
    fields = fieldnames(json2);
    for i = 1:numel(fields)
        field = fields{i};
        combined_data.(field) = json2.(field);
    end
    
    % Escrever a estrutura de dados combinada de volta para um novo arquivo JSON
    fid = fopen(combined_file, 'w');
    if fid == -1
        error('Cannot create %s', combined_file);
    end
    json_str = jsonencode(combined_data);
    fwrite(fid, json_str, 'char');
    fclose(fid);
end