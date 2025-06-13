defmodule MySciNetWeb.JobHTML do
  use MySciNetWeb, :html

  embed_templates "job_html/*"

  defp split_jobid(jobid) do
    case String.split(jobid, "-") do
      [cluster, id] -> {cluster, id}
      _ -> {"balam", jobid} # XXX:TBD temporary fallback
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
    <.icon name={@icon} class={[@color, @class]} title={@state} />
    """
  end

end
