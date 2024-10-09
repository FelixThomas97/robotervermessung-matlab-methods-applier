% Berechnung der interpolierten Positionen
function interpolatedPosition = fkt_interpolate(start, ende, parameter)
    interpolatedPosition = start + (ende - start) * parameter;
end