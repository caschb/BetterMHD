#include <Eigen/Dense>
#include <cmath>
#include <spdlog/spdlog.h>

namespace GlobalValues
{
  constexpr auto number_of_parameters{8};
}

template<class VectorType>
auto hyperbolic_tangent_transition(const double start,
  const double finish,
  const double width,
  const VectorType &vector)
{
  constexpr auto half{ 0.5 };
  auto hyp_tan = [width, finish, start](const double val) {
    return (finish + start) * half + ((finish - start) * half) * tanh(val / width);
  };
  return vector.unaryExpr(hyp_tan);
}

template<class VectorType>
auto getU(
  const VectorType &mag_field_x,
  const VectorType &mag_field_y,
  const VectorType &mag_field_z,
  const VectorType &density,
  const VectorType &vel_x,
  const VectorType &vel_y,
  const VectorType &vel_z,
  const VectorType &pressure
)
{
}

int main()
{
  spdlog::info("Welcome to BetterMHD!");
  spdlog::info("Eigen version: {0}.{1}", EIGEN_MAJOR_VERSION, EIGEN_MINOR_VERSION);

  constexpr auto number_of_nodes{ 1000 };
  constexpr auto width{ 0.0085 };
  constexpr auto gamma{ 2. }; // γ
  constexpr auto time_step{ 0.0005 };
  constexpr auto max_time{ 0.20 };

  const auto x_field = Eigen::Vector<double, number_of_nodes>::LinSpaced(number_of_nodes, -1., 1.);
  const auto dx{ abs(x_field[1] - x_field[0]) };

  const auto density{ hyperbolic_tangent_transition(1., .125, width, x_field) }; // ρ
  const auto vel_x{ hyperbolic_tangent_transition(0., 0., width, x_field) }; // Vx
  const auto vel_y{ hyperbolic_tangent_transition(0., 0., width, x_field) }; // Vy
  const auto vel_z{ hyperbolic_tangent_transition(0., 0., width, x_field) }; // Vz
  const auto pressure{ hyperbolic_tangent_transition(1., .1, width, x_field) }; // p

  const auto mag_field_x{ hyperbolic_tangent_transition(.75, .75, width, x_field) }; // Bx
  const auto mag_field_y{ hyperbolic_tangent_transition(1., -1., width, x_field) }; // By
  const auto mag_field_z{ hyperbolic_tangent_transition(0., 0., width, x_field) }; // Bz
  return 0;
}