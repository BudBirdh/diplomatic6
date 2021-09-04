echo "trying slam"
cd /opt/slam_ws/src/openvslam_ros
ros2 run openvslam_ros run_slam --rectify --eval-log -v orb_vocab.fbow -c /opt/openvslam/openvslam/example/euroc/EuRoC_stereo.yaml --map-db map.msg --ros-args -p use_sim_time:=True -r /camera/left/image_raw:=/cam0/image_raw -r /imu/filter_data:=/imu/filter_data -r /camera/right/image_raw:=/cam1/image_raw -p publish_tf:=False -r /openvslam_odom:=/openvslam_odom -p map_frame:=odom -p base_link:=cam0 &
ros_id=$!
ros2 launch robot_bringup euroc_openvslam.launch.py use_sim_time:=True &
imu_filter_id=$!
sleep 3;
cd ~/
echo "trying bag"
ros2 bag play MH_04_difficult --clock 1000 &
bag_id=$!
cd /opt/slam_ws/src/openvslam_ros
while true;do 
    echo "trying for bag existence of id ${bag_id}"
    sleep 3;
    if ! kill -0 $bag_id > /dev/null 2>&1; then
        echo "bag don't exist, exiting"
        break;
    fi
done
#send sig-int (ctrl+c)
echo "killing openvslam"
kill -2 $ros_id
kill -2 $imu_filter_id
#need to do this to get the run_slam killed too 
pkill -2 run_slam
pkill -2 robot_state
pkill imu
#sleep while the process dies
sleep 5 
while true;do 
    echo "waiting on existence of slam id ${ros_id}"
    sleep 3;
    if ! kill -0 $ros_id > /dev/null 2>&1; then
        echo "its dead, exiting"
        break;
    fi
    kill -2 $ros_id
    pkill -2 run_slam
done
mv frame_trajectory.txt ~/


