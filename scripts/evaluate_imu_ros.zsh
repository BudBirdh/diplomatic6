mkdir  results/euroc_ros_imu_MH_04
mkdir  results/euroc_ros_imu_MH_04/comparisons
mv stamped_groundtruth.txt results/euroc_ros_imu_MH_04
mv eval_cfg.yaml results/euroc_ros_imu_MH_04 
for i in `seq 1 30`;do 
    ./run_imu.zsh
    cp frame_trajectory.txt results/euroc_ros_imu_MH_04/stamped_traj_estimate.txt
    #no plots because it's painful to produce
    python3 rpg_trajectory_evaluation/scripts/analyze_trajectory_single.py results/euroc_ros_imu_MH_04 --no_plot
    rm results/euroc_ros_imu_MH_04/comparisons/$i -r
    mkdir results/euroc_ros_imu_MH_04/comparisons/$i
    mv results/euroc_ros_imu_MH_04/saved_results/ results/euroc_ros_imu_MH_04/comparisons/$i 
    cp results/euroc_ros_imu_MH_04/stamped_groundtruth.txt results/euroc_ros_imu_MH_04/comparisons/$i 
    mv results/euroc_ros_imu_MH_04/stamped_traj_estimate.txt results/euroc_ros_imu_MH_04/comparisons/$i 

    
done

