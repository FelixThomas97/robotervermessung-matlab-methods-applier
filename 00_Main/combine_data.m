function combine_data(elements_ist, elements_soll)

% clear
% load müll2
%%
% Anzahl der Messfahrten/Bahnabschnitte von Ist- und Sollbahn
s_ist = size(elements_ist, 2);
s_soll = size(elements_soll, 2);

% Fallunterscheidung, Anzahl der Messfahrten/Bahnabschnitte durch Istbahn bestimmt! 
if s_ist > s_soll

    diff = s_ist - s_soll;
    new_elements = cell(1, s_soll + diff);        
    % Aufüllen mit allen aufgezeichneten Sollbahnen/Bahnabschnitten
    new_elements(1:s_soll) = elements_soll;
    
    % Auffüllen der restlichen Elemente durch Wiederholung 
    for i = s_soll+1:s_soll+diff
        new_elements{i} = elements_soll{mod(i-1, s_soll) + 1}; % mod damit Index Grenze nicht übersteigt 
    end
    elements_soll = new_elements;
% Abschneiden der überschüssigen Sollbahnen/Bahnabschnitte
elseif s_ist < s_soll

    new_elements = cell(1,s_ist);
    for i = 1:s_ist
        new_elements{i} = elements_soll{i};
    end
    elements_soll = new_elements;
end
% Sind die Anzahl der Messfahrten/Bahnabschnitte gleich, passiert nichts

%% Laden in Workspace
assignin("base","elements_soll",elements_soll)

end