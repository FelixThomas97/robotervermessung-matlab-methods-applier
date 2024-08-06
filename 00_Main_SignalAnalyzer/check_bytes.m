function input_struct = check_bytes(input_struct, varargin)

%% Überprüfen ob die Kostenmatrizen die max. Bytes von MongoDB übersteigen
if nargin > 1
    argname = varargin{1};
else
    error('Es muss eine Metrik übergeben werden!');
end

if ~ischar(argname)
    error('Übergebenes Argument entspricht keiner Metrik!');
end

cellStruct = input_struct;

% Informationen des structs abrufen
info = whos('cellStruct');
info_bytes = info.bytes; 

% Maximale Dateigröße bei MongoDB
max_bytes = 16000000;

% Wenn Limit überschritten, löschen der Kostenmatrizen
if info_bytes > max_bytes
    warning('Die Größe der Kostenmatrix überschreitet das Limit von 16 MB.')
    if strcmp(argname, 'dtw') || strcmp(argname, 'sidtw')
        input_struct = rmfield(input_struct, 'dtw_accdist');
    elseif strcmp(argname, 'frechet')
        input_struct = rmfield(input_struct, 'frechet_matrix');
    elseif strcmp(argname, 'lcss')
        input_struct = rmfield(input_struct, 'lcss_matrix');
    else
        error('Übergebenes Argument entspricht keiner Metrik!');
    end
end


