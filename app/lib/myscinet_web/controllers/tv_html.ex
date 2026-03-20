defmodule MySciNetWeb.TvHTML do
  use MySciNetWeb, :html

  embed_templates "tv_html/*"

  # Each cluster card is 49 chars wide total:
  #   │ + [47 inner chars] + │
  # Inner layout:  [space] + [45 content chars] + [space]
  @iw 47
  @cw 45
  @max_login_rows 3

  def cluster_card(cluster, now_unix) do
    nodes = cluster.nodes
    nodes_running = Map.get(cluster, :nodesRunning, 0.0)
    active_count = Map.get(cluster, :active_count, 0)
    queued_count = Map.get(cluster, :queued_count, 0)
    active_secs = Map.get(cluster, :active_procsecs, 0)
    queued_secs = Map.get(cluster, :queued_procsecs, 0)
    cluster_time = Map.get(cluster, :time, 0)
    login_stats = Map.get(cluster, :login_stats, [])

    online = now_unix - cluster_time < 600
    utilization = if nodes > 0, do: 100.0 * nodes_running / nodes, else: 0.0
    days = if nodes > 0, do: (active_secs + queued_secs) / (86400.0 * nodes), else: 0.0
    total_jobs = active_count + queued_count

    status_color = if online, do: "#00e887", else: "#ff5555"
    status_str = if online, do: "● ONLINE", else: "○  STALE"

    util_color =
      cond do
        utilization >= 95 -> "#00e887"
        utilization < 85 -> "#ff5555"
        true -> "#ffcc44"
      end

    util_str = "#{Float.round(utilization, 1)}%"
    days_str = to_string(Float.round(days, 1))

    bar_filled = round(utilization / 100 * @cw) |> min(@cw) |> max(0)
    bar = String.duplicate("█", bar_filled) <> String.duplicate("░", @cw - bar_filled)

    top = "┌#{String.duplicate("─", @iw)}┐"
    sep = "├#{String.duplicate("─", @iw)}┤"
    bot = "└#{String.duplicate("─", @iw)}┘"
    blank = "│#{String.duplicate(" ", @iw)}│"

    row = fn text ->
      "│ #{String.pad_trailing(to_string(text), @cw)} │"
    end

    stat_row = fn label, value ->
      label_s = to_string(label)
      value_s = to_string(value)
      gap = @cw - String.length(label_s) - String.length(value_s)
      "│ #{label_s}#{String.duplicate(" ", max(0, gap))}#{value_s} │"
    end

    # Title: name left-aligned, status right-aligned
    status_len = String.length(status_str)
    name_space = @cw - status_len - 1
    name_str = cluster.name |> String.slice(0, name_space) |> String.pad_trailing(name_space)
    title = "│ #{name_str} <span style='color:#{status_color}'>#{status_str}</span> │"

    # Utilization bar (colored)
    bar_html = "│ <span style='color:#{util_color}'>#{bar}</span> │"

    # Login node rows (2 per row, padded to @max_login_rows)
    login_pairs = Enum.zip(cluster.logins, login_stats) |> Enum.chunk_every(2)

    login_rows =
      Enum.map(login_pairs, fn pairs ->
        # Compute visible length first (for correct padding), then build with spans
        visible_parts = Enum.map(pairs, fn {name, _} -> "● #{name}" end)
        visible_text = Enum.join(visible_parts, "   ")
        padding = String.duplicate(" ", max(0, @cw - String.length(visible_text)))

        html_parts =
          Enum.map(pairs, fn {name, status} ->
            {dot, color} =
              case status do
                nil ->
                  {"○", "#555555"}

                s ->
                  cpu = Map.get(s, :cpu, 0.0)
                  memfree = Map.get(s, :memfree, 100.0)
                  load = Map.get(s, :load, 0.0)

                  cond do
                    cpu > 80.0 or memfree < 25.0 or load > 96.0 -> {"●", "#ff5555"}
                    cpu > 50.0 or memfree < 50.0 or load > 48.0 -> {"●", "#ffcc44"}
                    true -> {"●", "#00e887"}
                  end
              end

            "<span style='color:#{color}'>#{dot}</span> #{name}"
          end)

        html_text = Enum.join(html_parts, "   ")
        "│ #{html_text}#{padding} │"
      end)

    padded_login_rows =
      login_rows ++ List.duplicate(blank, max(0, @max_login_rows - length(login_rows)))

    lines =
      [top, title, sep, blank] ++
        [
          stat_row.("Nodes", "#{nodes_running} / #{nodes}"),
          stat_row.("Utilization", util_str),
          bar_html,
          blank,
          stat_row.("Queue", "#{total_jobs} jobs"),
          stat_row.("Days of Work", days_str),
          blank,
          row.("Login Nodes")
        ] ++
        padded_login_rows ++
        [blank, bot]

    Enum.join(lines, "\n")
  end
end
