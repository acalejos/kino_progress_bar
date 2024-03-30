defmodule KinoProgressBar do
  use Kino.JS
  use Kino.JS.Live

  def new(opts \\ []) do
    opts = Keyword.validate!(opts, value: 0, max: 1)
    Kino.JS.Live.new(__MODULE__, {opts[:value], opts[:max]})
  end

  def from_enumerable(enumerable, progress_bar) do
    # milliseconds
    update_interval = 100

    Kino.JS.Live.cast(progress_bar, {:update, %{value: 0, max: Enum.count(enumerable)}})

    Stream.transform(
      enumerable,
      fn -> {1, :erlang.system_time(:millisecond)} end,
      fn item, {acc, delta} ->
        current_time = :erlang.system_time(:millisecond)

        delta =
          if current_time - delta >= update_interval do
            Kino.JS.Live.cast(progress_bar, {:update, %{value: acc, max: nil}})
            current_time
          else
            delta
          end

        {[item], {acc + 1, delta}}
      end,
      fn {acc, _delta} ->
        Kino.JS.Live.cast(progress_bar, {:update, %{value: acc, max: nil}})
      end
    )
  end

  def update(progress_bar, value, max \\ nil) do
    Kino.JS.Live.cast(progress_bar, {:update, %{value: value, max: max}})
  end

  @impl true
  def init({value, max}, ctx) do
    {:ok, assign(ctx, max: max, value: value)}
  end

  @impl true
  def handle_connect(ctx) do
    value = if ctx.assigns.value, do: ~s(value="#{ctx.assigns.value}"), else: ""
    html = ~s(<progress id="kino_pb" #{value} max="#{ctx.assigns.max}"></progress>)
    {:ok, html, ctx}
  end

  @impl true
  def handle_cast({:update, %{value: value, max: max} = updates}, ctx) do
    broadcast_event(ctx, "update", updates)
    {:noreply, assign(ctx, value: value, max: max)}
  end

  asset "main.js" do
    """
    export function init(ctx, html) {
      ctx.root.innerHTML = html;

      ctx.handleEvent("update", ({max, value}) => {
        console.log(value);
        let pb = document.getElementById("kino_pb");
        if (max) {pb.max = max;}
        if (!value) {
          pb.removeAttribute('value')
        } else{
          pb.value = value;
        }
      });
    }
    """
  end
end
