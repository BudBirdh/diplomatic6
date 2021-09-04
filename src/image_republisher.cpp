
#include <image_transport/image_transport.hpp>
#include <image_transport/subscriber_filter.hpp>
#include <message_filters/subscriber.h>
#include <message_filters/synchronizer.h>
#include <message_filters/time_synchronizer.h>
#include <rclcpp/rclcpp.hpp>
#include <sensor_msgs/msg/image.hpp>

class image_republisher {
public:
  image_republisher()
      : node_(std::make_shared<rclcpp::Node>("image_republisher")),
        left_sf_(node_, "cam0/image_raw"),
        right_sf_(node_, "cam1/image_raw"),
        sync_(left_sf_, right_sf_, 10) {
    image_counter_ = 0;
    sync_.registerCallback(&image_republisher::image_callback, this);
    setParams();
    left_republisher_ = node_->create_publisher<sensor_msgs::msg::Image>(
        "cam0/image_raw/throttled", 10);
    right_republisher_ = node_->create_publisher<sensor_msgs::msg::Image>(
        "cam1/image_raw/throttled", 10);
  };
  std::shared_ptr<rclcpp::Node> node_;
  message_filters::Subscriber<sensor_msgs::msg::Image> left_sf_, right_sf_;
  std::shared_ptr<rclcpp::Publisher<sensor_msgs::msg::Image>> left_republisher_;
  std::shared_ptr<rclcpp::Publisher<sensor_msgs::msg::Image>>
      right_republisher_;
  message_filters::TimeSynchronizer<sensor_msgs::msg::Image,
                                    sensor_msgs::msg::Image>
      sync_;
  int republish_ratio_;
  int image_counter_;
  void setParams() {

    republish_ratio_ = 4;
    republish_ratio_ =
        node_->declare_parameter("republish_ratio", republish_ratio_);
  }

  void image_callback(const sensor_msgs::msg::Image::ConstSharedPtr &left,
                      const sensor_msgs::msg::Image::ConstSharedPtr &right) {
    if (!(image_counter_ % republish_ratio_)) {
      // publish images if we hit our ratio
      left_republisher_->publish(*left);
      right_republisher_->publish(*right);
    }
    image_counter_++;
  }
};

int main(int argc, char *argv[]) {
  rclcpp::init(argc, argv);
  auto republisher = std::make_shared<image_republisher>();
  rclcpp::spin(republisher->node_);
  rclcpp::shutdown();
}
