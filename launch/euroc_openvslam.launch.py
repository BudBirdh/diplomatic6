# Built-in imports
from pathlib import Path
import sys
import os

import launch_ros.actions
# External imports
import launch
from launch.actions import IncludeLaunchDescription
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch import LaunchDescription
from ament_index_python.packages import get_package_share_directory
from launch_ros.actions import Node
from launch.substitutions import LaunchConfiguration

package_name = 'robot_bringup'

def generate_launch_description():
    use_sim_time = LaunchConfiguration('use_sim_time', default='true')

    sim_arg = launch.actions.DeclareLaunchArgument(
            'use_sim_time', default_value='false',
            description='Use simulation clock if true')
    ld = LaunchDescription()

    ##########################################################################
    # Robot Localization
    ##########################################################################

    rloc_params = str(
        Path(get_package_share_directory(package_name), 'params', 'rloc',
             'euroc.yaml'))

    euroc_urdf_path = str(
        Path(get_package_share_directory(package_name), 'params', 'urdf',
             'euroc_mav.urdf'))

    # *****test_ekf_localization_node_interfaces.test*****
    openvslam_odom_node = launch_ros.actions.Node(
        package='robot_localization',
        executable='ukf_node',
        name='openvslam_odom',
        output='screen',
        parameters=[{
            'use_sim_time': use_sim_time
        }, rloc_params],
        remappings=[('/odometry/filtered', '/openvslam_odom_obs'),
                    ('/odometry/filtered/pose', '/openvslam_odom/pose')])

    with open(euroc_urdf_path, 'r') as infp:
        robot_desc = infp.read()

    params = {'robot_description': robot_desc}
    rsp = launch_ros.actions.Node(package='robot_state_publisher',
                                  executable='robot_state_publisher',
                                  output='both',
                                  parameters=[
                                      {'use_sim_time': use_sim_time},
                                      params])


    ##########################################################################
    # Complementary Filter 
    ##########################################################################
    imu_node = launch_ros.actions.Node(     
         package = "imu_filter_madgwick",
         executable = "imu_filter_madgwick_node",
         name = "madgwick_filter",
         output = "screen",
         parameters=[{
             'stateless': False,
             'do_adaptive_gain': True,
             'use_mag': False,
             'gain': 0.1,
             'world_frame': "enu",
             'publish_tf': True,
             'publish_debug_topics': False,
             'orientation_stddev': 0.01,
             'fixed_frame': "odom",
             'remove_gravity_vector': True,
             "zeta": 1.9393e-5, 
             }],
         remappings=[('imu/data_raw', 'imu0'),('imu/data', 'imu/filter_data')]
         )

    ld.add_action(imu_node)
    #ld.add_action(openvslam_odom_node)
    ld.add_action(sim_arg)
    ld.add_action(rsp)
    return ld
