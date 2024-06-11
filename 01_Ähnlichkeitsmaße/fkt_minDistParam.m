% Berechnung des geringsten Abstands zwischen Bahnsegmet und Punkt (etwas abgeändert zu CDTW)
function [mindist, param] = fkt_minDistParam(x1, x2, y)
    dx = x2-x1;                                     % Bahnsegment 
    dy = y-x1;                                      % Abstand Punkt-Bahnsegment
    dxy = (dot(dy,dx)/(norm(dx)^2))*dx;             % Projektion dy auf dx
    if dot(dx,dy) > 0                               % gleiche Richtung: Winkel < 90°                              
        param = norm(dxy)/norm(dx);        
        if param > 1                               
            mindist = Inf;
        else
            mindist = norm(y-(x1+dxy));
        end
    elseif dot(dx,dy) == 0                          % senkrecht: Winkel = 90°;
        param = 0;
        mindist = norm(dy); 
    else                                            % entgegengesetze Richtung: Winkel > 90°
        param = -norm(dxy)/norm(dx);                 
        mindist = Inf;
    end
end