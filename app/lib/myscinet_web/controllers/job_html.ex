defmodule MySciNetWeb.JobHTML do
  use MySciNetWeb, :html

  embed_templates "job_html/*"

  def add_underscore_breaks(s) do
    {:safe, String.replace(s, "_", "_<wbr/>")}
  end

  def cluster_cpumem(cluster) do
    case cluster do
      "balam" -> 1000
      _ -> 768
    end
  end

  defp cluster_name(slug) do
    case slug do
      "tric" -> "trillium"
      "trig" -> "trillium-gpu"
      _ -> slug
    end
  end

  defp split_jobid(jobid) do
    case String.split(jobid, ":") do
      [slug, id] -> {cluster_name(slug), id}
      _ -> nil
    end
  end

  attr :state, :string, required: true
  attr :class, :string, default: ""

  def job_state_icon(assigns) do
    {icon, color} =
      case assigns.state do
        "RUNNING"        -> {"hero-arrow-path",           "text-primary"}
        "COMPLETED"      -> {"hero-check-circle",         "text-success"}
        "TIMEOUT"        -> {"hero-clock",                "text-warning"}
        "FAILED"         -> {"hero-x-circle",             "text-error"}
        "NODE_FAIL"      -> {"hero-exclamation-triangle", "text-error"}
        "CANCELLED" <> _ -> {"hero-stop-circle",          "text-base-content/60"}
        _                -> {"hero-question-mark-circle", "text-base-content/60"}
      end

    assigns = assign(assigns, icon: icon, color: color)

    ~H"""
    <.icon name={@icon} class={[@color, @class]} />
    """
  end

end
