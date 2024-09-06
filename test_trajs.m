%%
% Zusammenfassen der Segmente zu Trajektorien
% Anzahl der Bahnabschnitte
num_segments = size(segments_soll,2);
num_trajectories = floor(num_segments/group_size);

trajectories_ist = cell(1,num_trajectories);
trajectories_soll = cell(1,num_trajectories);

j = 0; 
for i = 1:1:num_trajectories
    start = j+1;
    last = start+group_size-1;
    traj_ist = [];
    traj_soll = [];
    for j = start:1:last
        traj_ist = [traj_ist; segments_ist{j}];
        traj_soll= [traj_soll; segments_soll{j}];
    end
    trajectories_ist{i} = traj_ist;
    trajectories_soll{i} = traj_soll;  
end

%%
%Eine Trajectorie nach der anderen plotten!
figure('Color','white');
for i = 1:size(trajectories_soll,2) 
    % figure('Color','white');
    % plot3(vicon_transformed(:,1),vicon_transformed(:,2),vicon_transformed(:,3),'k',LineWidth=3)
    hold on
    plot3(trajectories_ist{i}(:,2),trajectories_ist{i}(:,3),trajectories_ist{i}(:,4),'b')
    plot3(trajectories_abb{i}(:,2),trajectories_abb{i}(:,3),trajectories_abb{i}(:,4),'r')
    % plot3(trajectories_soll{i}(:,1),trajectories_soll{i}(:,2),trajectories_soll{i}(:,3),'r')
    legend('ist','soll')
    xlabel('x'); ylabel('y'); zlabel('z');
% axis equal
end
hold off

%%

date_time = trajectory_ist(1,1)
date_time = string(datetime(date_time,'ConvertFrom','epochtime','TicksPerSecond',1e9,'Format','dd-MMM-yyyy HH:mm:ss'))
