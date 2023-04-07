[![build and test](https://github.com/bmitc/sugarscape/actions/workflows/build-and-test.yml/badge.svg)](https://github.com/bmitc/sugarscape/actions/workflows/build-and-test.yml)

# Sugarscape

[In progress and not complete]

This is a from-scratch implementation in Elixir of the sugarscape and its various models as found in the book [*Growing Artifical Societies: Social Science from the Bottom Up*](https://mitpress.mit.edu/9780262550253/growing-artificial-societies/) by Joshua M. Epstein and Robert L. Axtell.

The core code is implemented as an [Elixir](https://elixir-lang.org/) Mix project, and then the visualization is done via [Livebook](https://livebook.dev/) notebooks. Agents and resources are placed on the sugarscape environment. Each of the agents, resources, and environment are given rules that govern their own behavior and interactions with the other components.

Here is a short video example that shows agents moving around on an environment with only sugar resources, eating them as they come across them, moving to areas with sugar, and the environment growing sugar back. In this particular example, agents have individual vision distance, metabolic rate, initial unique location, and initial sugar holdings. The grid locations contain sugar resources which have a total holding capacity, growback rate, and current level.

https://user-images.githubusercontent.com/65685447/230555197-7b1bb302-e516-4fd0-9dd3-d084989a9c60.mp4


More documentation will be added later, mostly as Livebook notebook content.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `sugarscape` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:sugarscape, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/sugarscape>.

