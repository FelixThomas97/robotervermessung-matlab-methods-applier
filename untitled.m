

if i == 1
    a = size(seg_sidtw_distances,1)
    aaa = [seg_sidtw_distances, table((1:1:a)','VariableNames',{'points_order'})];

    bbb = [seg_sidtw_distances, table((1:1:size(seg_sidtw_distances,1))','VariableNames',{'points_order'})];

end
%%

% Letztes Segment soll nicht ausgewertet werden
% Zeilenindex des ersten Auftretens finden
last_row = find(data_ist.segment_id == segment_ids{end,1}, 1)-1
