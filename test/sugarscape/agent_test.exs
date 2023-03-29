defmodule Sugarscape.AgentTest do
  use ExUnit.Case
  use PropCheck, default_opts: [{:numtests, 1_000}, :quiet]

  alias Sugarscape.Agent

  doctest Agent

  property "agent vision is within [1, 6]" do
    forall {x, y} <- {pos_integer(), pos_integer()} do
      agent = Agent.new({x, y})
      1 <= agent.vision and agent.vision <= 6
    end
  end

  property "agent metabolism is within [1, 4]" do
    forall {x, y} <- {pos_integer(), pos_integer()} do
      agent = Agent.new({x, y})
      1 <= agent.metabolism and agent.metabolism <= 4
    end
  end
end
