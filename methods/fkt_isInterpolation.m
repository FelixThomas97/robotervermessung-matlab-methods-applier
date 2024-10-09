% Prüfen ob übergebener Parameter zwischen Null und Eins liegt
function result = fkt_isInterpolation(param)
    result = param > 0 && param < 1;
end