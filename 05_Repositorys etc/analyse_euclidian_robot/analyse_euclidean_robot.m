load('robotdata_ist.mat');
load('robotdata_soll.mat');
%%
data_odom = table2array(robotdata_ist);
x_odom = data_odom(:,1);
y_odom = data_odom(:,2);
z_odom = data_odom(:,3);

data_soll = table2array(robotdata_soll);
x_soll = data_soll(:,1);
y_soll = data_soll(:,2);
z_soll = data_soll(:,3);


curvexy = [x_soll, y_soll, z_soll];
mapxy = [x_odom y_odom z_odom];
[xy,distance,t] = distance2curve(curvexy,mapxy,'linear');

figure(2)
hold on
plot3(curvexy(:,1),curvexy(:,2),curvexy(:,3),'ko')
line([mapxy(:,1),xy(:,1)]',[mapxy(:,2),xy(:,2)]',[mapxy(:,3),xy(:,3)]','color',"red")
plot3(x_odom,y_odom,z_odom, 'LineWidth',3,'Color','#003560')
% plot3(x_soll,y_soll,z_soll, 'LineWidth',3,'Color','red')

xlim auto
ylim auto
%legend({'Setpoints','Position Error'},'Location','northeast',"FontWeight", "bold")
fontsize(gca,20,"pixels")
zlim auto;
box on
grid on
view(3)
xlabel("x [cm]","FontWeight","bold")
ylabel("y [cm]","FontWeight","bold")
zlabel("z [cm]","FontWeight","bold")

avg_distance = mean(distance);


hold off






