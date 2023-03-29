defmodule Sugarscape.Perlin do
  @moduledoc """
  An implementation of Perlin noise
  """

  # Reference: https://mrl.cs.nyu.edu/~perlin/noise/

  # Note: this file is ignored by the formatter due to the heavy
  # use of numerical code.

  import Bitwise

  # The static permutation array of size 256 defined by the Perlin noise algorithm
  @permutation [
    151, 160, 137,  91,  90,  15, 131,  13, 201,  95,  96,  53, 194, 233,   7, 225,
    140,  36, 103,  30,  69, 142,   8,  99,  37, 240,  21,  10,  23, 190,   6, 148,
    247, 120, 234,  75,   0,  26, 197,  62,  94, 252, 219, 203, 117,  35,  11,  32,
    57, 177,  33,  88, 237, 149,  56,  87, 174,  20, 125, 136, 171, 168,  68, 175,
    74, 165,  71, 134, 139,  48,  27, 166,  77, 146, 158, 231,  83, 111, 229, 122,
    60, 211, 133, 230, 220, 105,  92,  41,  55,  46, 245,  40, 244, 102, 143,  54,
    65,  25,  63, 161,   1, 216,  80,  73, 209,  76, 132, 187, 208,  89,  18, 169,
    200, 196, 135, 130, 116, 188, 159,  86, 164, 100, 109, 198, 173, 186,   3,  64,
    52, 217, 226, 250, 124, 123,   5, 202,  38, 147, 118, 126, 255,  82,  85, 212,
    207, 206,  59, 227,  47,  16,  58,  17, 182, 189,  28,  42, 223, 183, 170, 213,
    119, 248, 152,   2,  44, 154, 163,  70, 221, 153, 101, 155, 167,  43, 172,   9,
    129,  22,  39, 253,  19,  98, 108, 110,  79, 113, 224, 232, 178, 185, 112, 104,
    218, 246,  97, 228, 251,  34, 242, 193, 238, 210, 144,  12, 191, 179, 162, 241,
    81,  51, 145, 235, 249,  14, 239, 107,  49, 192, 214,  31, 181, 199, 106, 157,
    184,  84, 204, 176, 115, 121,  50,  45, 127,   4, 150, 254, 138, 236, 205,  93,
    222, 114,  67,  29,  24,  72, 243, 141, 128, 195,  78,  66, 215,  61, 156, 180
  ]

  # The duplicate permutation array of size 512 as defined in the Perlin noise algorithm
  @p Enum.concat(@permutation, @permutation)

  @doc """
  Generates a noise value in the range [-1, 1] for a given (x,y)-coordinate
  """
  @spec noise(float, float) :: float
  def noise(x, y), do: noise(x, y, 0.0)

  @doc """
  Generates a noise value in the range [-1, 1] for a given (x,y,z)-coordinate
  """
  @spec noise(float, float, float) :: float
  def noise(x, y, z), do: (2 / :math.sqrt(3)) * noise_helper(x, y, z) |> clamp()

  @doc """
  Generates a noise value in the range [-1, 1] for a given (x,y)- or (x,y,z)-coordinate
  """
  @spec noise({float, float} | {float, float, float}) :: float
  def noise({x, y}), do: noise(x, y, 0.0)
  def noise({x, y, z}), do: noise(x, y, z)

  @spec fade(float) :: float
  defp fade(t), do: t * t * t * (t * (t * 6 - 15) + 10)

  @spec lerp(float, float, float) :: float
  defp lerp(t, a, b), do: a + t * (b - a)

  @spec grad(integer, float, float, float) :: float
  defp grad(hash, x, y, z) do
    h = hash &&& 15
    u = if h < 8 do x else y end
    v =
      if h < 4 do
        y
      else
        if h == 12 or h == 14 do
          x
        else
          z
        end
      end

    (if (h &&& 1) == 0 do u else - u end) + (if (h &&& 2) == 0 do v else - v end)
  end

  # Perlin noise at a 3D point
  @spec noise_helper(float, float, float) :: float
  defp noise_helper(x, y, z) do
    # Find unit cube that contains point
    v_x = floor(x) &&& 255
    v_y = floor(y) &&& 255
    v_z = floor(z) &&& 255

    # Find relative x, y, z of point in cube
    x = x - floor(x)
    y = y - floor(y)
    z = z - floor(z)

    # Compute fade curves for each of x, y, z
    u = fade(x)
    v = fade(y)
    w = fade(z)

    # Hash coordinates of the 8 cube corners
    v_a  = Enum.at(@p,   v_x  ) + v_y
    v_b  = Enum.at(@p, v_x + 1) + v_y
    v_aa = Enum.at(@p,   v_a  ) + v_z
    v_ba = Enum.at(@p,   v_b  ) + v_z
    v_ab = Enum.at(@p, v_a + 1) + v_z
    v_bb = Enum.at(@p, v_b + 1) + v_z

    # And add blended results from 8 corners of cube
    lerp(w, lerp(v, lerp(u, grad(Enum.at(@p,  v_aa   ), x,       y,       z       ),
                            grad(Enum.at(@p,  v_ba   ), x - 1.0, y,       z       )),
                    lerp(u, grad(Enum.at(@p,  v_ab   ), x,       y - 1.0, z       ),
                            grad(Enum.at(@p,  v_bb   ), x - 1.0, y - 1.0, z       ))),
            lerp(v, lerp(u, grad(Enum.at(@p, v_aa + 1), x,       y,       z - 1.0 ),
                            grad(Enum.at(@p, v_ba + 1), x - 1.0, y,       z - 1.0 )),
                    lerp(u, grad(Enum.at(@p, v_ab + 1), x,       y - 1.0, z - 1.0 ),
                            grad(Enum.at(@p, v_bb + 1), x - 1.0, y - 1.0, z - 1.0 ))))
  end

  # Clamps a number to the range [-1, 1]
  @spec clamp(float) :: float
  defp clamp(number) do
    number
    |> max(-1.0)
    |> min(1.0)
  end
end
