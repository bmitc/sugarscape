defmodule Sugarscape.PerlinTest do
  use ExUnit.Case
  use PropCheck, default_opts: [{:numtests, 10_000}, :quiet]

  alias Sugarscape.Perlin

  doctest Perlin

  property "Perlin noise range is [-1, 1]" do
    forall {x, y, z} <- {int(), int(), int()} do
      perlin = Perlin.noise(x, y, z)
      -1.0 <= perlin and perlin <= 1.0
    end
  end

  property "Perlin noise for integers is 0" do
    forall {x, y, z} <- {int(), int(), int()} do
      Perlin.noise(x, y, z) == 0.0
    end
  end
end
