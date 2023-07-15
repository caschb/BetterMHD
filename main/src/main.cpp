#include <Eigen/Dense>
#include <cmath>
#include <spdlog/spdlog.h>

template<class VectorType>
auto hyperbolic_tangent_transition(const double start,
  const double finish,
  const double width,
  const VectorType &vector)
{
  const auto half = 0.5;
  auto hyp_tan = [width, finish, start, half](const double val) {
    return (finish + start) * half + ((finish - start) * half) * tanh(val / width);
  };
  return vector.unaryExpr(hyp_tan);
}

int main()
{
  spdlog::info("Welcome to BetterMHD!");
  spdlog::info("Eigen version: {0}.{1}", EIGEN_MAJOR_VERSION, EIGEN_MINOR_VERSION);

  constexpr auto number_of_nodes{ 1000 };
  constexpr auto width = 0.0085;

  const auto x_field = Eigen::VectorXd::LinSpaced(number_of_nodes, -1, 1);

  const auto dx = abs(x_field[1] - x_field[0]);

  const auto gamma = 2.;

  const auto dt = 0.0005;
  const auto max_time = 0.20;

  const auto density = hyperbolic_tangent_transition(1., .125, width, x_field);
  const auto vel_x = hyperbolic_tangent_transition(.0, .0, width, x_field);
  const auto vel_y = hyperbolic_tangent_transition(.0, .0, width, x_field);
  const auto vel_z = hyperbolic_tangent_transition(.0, .0, width, x_field);
  const auto pressure = hyperbolic_tangent_transition(1., .1, width, x_field);


  return 0;
}