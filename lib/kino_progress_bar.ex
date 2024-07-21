defmodule KinoProgressBar do
  use Kino.JS
  use Kino.JS.Live

  @ets :kino_progress_bar
  @update_interval 100

  def new(opts \\ []) do
    if :ets.whereis(@ets) == :undefined do
      @ets =
        :ets.new(@ets, [:set, :named_table, read_concurrency: false, write_concurrency: false])
    end

    opts = Keyword.validate!(opts, [:max, value: 0, style: "height: 100%;"])
    Kino.JS.Live.new(__MODULE__, {opts[:value], opts[:max], opts[:style]})
  end

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

  def update(progress_bar, value, max \\ nil) do
    Kino.JS.Live.cast(progress_bar, {:update, %{value: value, max: max}})
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
  def handle_cast({:update, %{value: value, max: max} = updates}, ctx) do
    broadcast_event(ctx, "update", updates)
    {:noreply, assign(ctx, value: value, max: max)}
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
