function result = NearlyEqual(rad, constrad, epsilon)
    absA = abs(rad);
    absB = abs(constrad);
    diff = abs(rad - constrad);

    if absA == absB % shortcut, handles infinities
        result = true;
% ------- Diese Bedingung weglassen da in diesem Fall Programmstopp -.-
    elseif rad == 0 || constrad == 0 || diff < eps
        % a oder b ist Null oder beide sind extrem nah an Null
        % relativer Fehler ist hier weniger bedeutend
        result = diff < (epsilon * eps);
        % result = true; 
    else % Verwende relativen Fehler
        result = diff / min(absA + absB, realmax) < epsilon;
    end
end
