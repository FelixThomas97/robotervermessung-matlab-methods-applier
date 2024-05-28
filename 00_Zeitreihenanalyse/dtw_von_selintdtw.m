load testdaten_selintdtw.mat

testdata = struct_johnen{5};

dtw_X = testdata.dtw_X;
dtw_Y = testdata.dtw_Y;

dtw_distances = testdata.dtw_distances; 
dtw_path = testdata.dtw_path';
dtw_max = testdata.dtw_max_distance;
dtw_av = testdata.dtw_average_distance;

figure;

plot(dtw_distances)
title('Bahnabweichungen DTW Johnen')

pflag = 0;


[xxdtw_distances, xxdtw_max, xxdtw_av, xxdtw_accdist, xxdtw_X, xxdtw_Y, xxdtw_path, ~, ~, ~] = fkt_dtw3d(dtw_X,dtw_Y,pflag);

figure;

plot(xxdtw_distances)
title('Bahnabweichungen nach DTW von DTW Johnen')