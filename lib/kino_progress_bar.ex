defmodule KinoProgressBar do
  @moduledoc """
  A module for creating and managing progress bars in Livebook using Kino.

  This module provides functionality to create interactive progress bars,
  update their values, and handle progress for enumerables.
  """
  use Kino.JS
  use Kino.JS.Live

  @ets :kino_progress_bar
  @update_interval 100

  @doc """
  Creates a new progress bar.

  ## Options

    * `:max` - The maximum value of the progress bar (required).
    * `:value` - The initial value of the progress bar (default: 0).
    * `:style` - CSS style to be applied to the progress bar (default: "height: 100%;").

  ## Examples

      iex> KinoProgressBar.new(max: 100)
      iex> KinoProgressBar.new(max: 100, value: 50, style: "height: 20px; width: 100%;")

  """
  def new(opts \\ []) do
    if :ets.whereis(@ets) == :undefined do
      @ets =
        :ets.new(@ets, [:set, :named_table, read_concurrency: false, write_concurrency: false])
    end

    opts = Keyword.validate!(opts, [:max, value: 0, style: "height: 100%;"])
    Kino.JS.Live.new(__MODULE__, {opts[:value], opts[:max], opts[:style]})
  end

  @doc """
  Creates a progress bar from an enumerable, updating as the enumerable is processed.

  ## Parameters

    * `enumerable` - The enumerable to process.
    * `progress_bar` - The progress bar created with `new/1`.

  ## Examples

      iex> progress_bar = KinoProgressBar.new(max: 100)
      iex> KinoProgressBar.from_enumerable(1..100, progress_bar)
      #Stream<...>

  """
  def from_enumerable(enumerable, progress_bar) do
    save(progress_bar.pid, 0)
    send(progress_bar.pid, {:set_progress_bar, progress_bar})
    send(progress_bar.pid, :sample)

    Stream.transform(
      enumerable,
      fn -> 0 end,
      fn item, acc ->
        save(progress_bar.pid, item)
        {[item], acc + 1}
      end,
      fn acc ->
        Kino.JS.Live.cast(progress_bar, {:done, acc})
      end
    )
  end

  @doc """
  Updates the progress bar with a new value and optionally a new maximum.

  ## Parameters

    * `progress_bar` - The progress bar to update.
    * `value` - The new value to set.
    * `max` - The new maximum value (optional).

  ## Examples

      iex> progress_bar = KinoProgressBar.new(max: 100)
      iex> KinoProgressBar.update(progress_bar, 50)
      iex> KinoProgressBar.update(progress_bar, 75, 150)

  """
  def update(progress_bar, value) do
    Kino.JS.Live.cast(progress_bar, {:update, %{value: value}})
  end

  @doc """
  Updates the progress bar with a new value and a new maximum.

  ## Parameters

    * `progress_bar` - The progress bar to update.
    * `value` - The new value to set.
    * `max` - The new maximum value.

  ## Examples

      iex> progress_bar = KinoProgressBar.new(max: 100)
      iex> KinoProgressBar.update(progress_bar, 75, 150)

  """
  def update(progress_bar, value, max) do
    Kino.JS.Live.cast(progress_bar, {:update, %{value: value, max: max}})
  end

  @doc """
  Increments the progress bar value by 1.

  ## Parameters

    * `progress_bar` - The progress bar to increment.

  ## Examples

      iex> progress_bar = KinoProgressBar.new(max: 100)
      iex> KinoProgressBar.increment(progress_bar)

  """
  def increment(progress_bar) do
    increment(progress_bar, 1)
  end

  @doc """
  Increments the progress bar value by the specified step.

  ## Parameters

    * `progress_bar` - The progress bar to increment.
    * `step` - The value to increment by.

  ## Examples

      iex> progress_bar = KinoProgressBar.new(max: 100)
      iex> KinoProgressBar.increment(progress_bar, 5)

  """
  def increment(progress_bar, step) do
    Kino.JS.Live.cast(progress_bar, {:increment, %{step: step}})
  end

  @doc """
  Decrements the progress bar value by 1.

  ## Parameters

    * `progress_bar` - The progress bar to decrement.

  ## Examples

      iex> progress_bar = KinoProgressBar.new(max: 100)
      iex> KinoProgressBar.decrement(progress_bar)

  """
  def decrement(progress_bar) do
    decrement(progress_bar, 1)
  end

  @doc """
  Decrements the progress bar value by the specified step.

  ## Parameters

    * `progress_bar` - The progress bar to decrement.
    * `step` - The value to decrement by.

  ## Examples

      iex> progress_bar = KinoProgressBar.new(max: 100)
      iex> KinoProgressBar.decrement(progress_bar, 5)

  """
  def decrement(progress_bar, step) do
    Kino.JS.Live.cast(progress_bar, {:decrement, %{step: step}})
  end

  @impl true
  def init({value, max, style}, ctx) do
    {:ok, assign(ctx, max: max, value: value, style: style, done: false)}
  end

  @impl true
  def handle_connect(%{assigns: %{value: value, done: done, max: max, style: style}} = ctx) do
    html = """
      <div id="kino_pb" style="display: flex-row; height: 1.5rem;">
        <progress style="#{style}" value="#{value}" max="#{if(done, do: value, else: max)}">
        </progress>
        <span style="display: inline; font-size: 1rem">&nbsp;</span>
        <span style="display: none; color: green; height: 100%; font-size: 1.5rem">&#10003;</span>
      </div>
    """

    {:ok, html, ctx}
  end

  @impl true
  def handle_cast({:update, %{value: value} = updates}, ctx) do
    broadcast_event(ctx, "update", updates)
    {:noreply, assign(ctx, value: value, max: ctx.assigns.max)}
  end

  def handle_cast({:update, %{value: value, max: max} = updates}, ctx) do
    broadcast_event(ctx, "update", updates)
    {:noreply, assign(ctx, value: value, max: max)}
  end

  def handle_cast({:increment, %{step: step}}, ctx) do
    value = ctx.assigns.value + step
    broadcast_event(ctx, "update", %{value: value})
    {:noreply, assign(ctx, value: value)}
  end

  def handle_cast({:decrement, %{step: step}}, ctx) do
    value = ctx.assigns.value - step
    broadcast_event(ctx, "update", %{value: value})
    {:noreply, assign(ctx, value: value)}
  end

  @impl true
  def handle_cast({:done, value}, ctx) do
    broadcast_event(ctx, "done", %{value: value})
    {:noreply, assign(ctx, done: true)}
  end

  @impl true
  def handle_info({:set_progress_bar, progress_bar}, ctx) do
    {:noreply, assign(ctx, progress_bar: progress_bar)}
  end

  @impl true
  def handle_info(:sample, ctx) do
    pid = self()
    value = :ets.lookup_element(@ets, pid, 2)

    now = System.system_time(:millisecond)

    unless ctx.assigns.done do
      Process.send_after(self(), :sample, @update_interval)
    end

    Kino.JS.Live.cast(ctx.assigns.progress_bar, {:update, %{value: value, max: ctx.assigns.max}})
    {:noreply, assign(ctx, value: value, last_updated_at: now)}
  end

  defp save(pid, value) do
    :ets.insert(@ets, {pid, value})
  end

  asset "main.js" do
    """
    export function init(ctx, html) {
      ctx.root.innerHTML = html;
      ctx.handleEvent("update", ({max, value}) => {
        console.log(value);
        const [pb, counter_span, _] = document.getElementById("kino_pb").children;
        if (max) {pb.max = max;}
        if (!value) {
          pb.removeAttribute('value')
        } else {
          pb.value = value;
        }

        counter_span.innerText = `${value}/${max || "???"}`;
      });

      ctx.handleEvent("done", ({value}) => {
        const [pb, counter_span, done_check] = document.getElementById("kino_pb").children;
        pb.style.accentColor = "green";
        pb.value = value;
        pb.max = value;

        done_check.style.display = "inline";
      })
    }
    """
  end
end
