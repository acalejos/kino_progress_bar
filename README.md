# KinoProgressBar

KinoProgressBar is an Elixir library that provides interactive progress bars for Livebook using Kino. It allows you to easily create, update, and manage progress bars in your Livebook notebooks, enhancing the visual feedback for long-running processes or iterative tasks.

## Features

- Create customizable progress bars
- Update progress bar values and maximums dynamically
- Generate progress bars from enumerables
- Seamless integration with Livebook and Kino

## Installation

Add `kino_progress_bar` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:kino_progress_bar, "~> 0.3.0"}
  ]
end
```
## Usage
Here are some basic usage examples:
```elixir
# Create a new progress bar
progress_bar = KinoProgressBar.new(max: 100)

# Update the progress bar
KinoProgressBar.update(progress_bar, 50)

# Increment the value by 1
KinoProgressBar.increment(progress_bar)

# Decrement the value by arbitrary amount
KinoProgressBar.decrement(progress_bar, 5)

# Create a progress bar from an enumerable
1..100
|> KinoProgressBar.from_enumerable(progress_bar)
|> Enum.to_list()
```
For more detailed information and advanced usage, please refer to the HexDocs documentation.

## Documentation
Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/kino_progress_bar>.

## Contributing
Contributions are welcome! Please feel free to submit a Pull Request.

## License
This project is licensed under the MIT License - see the LICENSE file for details.