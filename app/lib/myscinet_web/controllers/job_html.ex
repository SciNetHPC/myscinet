defmodule MySciNetWeb.JobHTML do
  use MySciNetWeb, :html
  import MySciNetWeb.Clusters

  embed_templates "job_html/*"

  def add_breakpoints(s) do
    {:safe, s |> String.replace("_", "_<wbr/>") |> String.replace("-", "-<wbr/>")}
  end

  def job_state_pretty(job) do
    if job.state == "CANCELLED by #{job.uid}" do
      "CANCELLED"
    else
      job.state
    end
  end

  attr :state, :string, required: true
  attr :class, :string, default: ""

  def job_state_icon(assigns) do
    {icon, color} =
      case assigns.state do
        "RUNNING" -> {"hero-arrow-path", "text-primary"}
        "COMPLETED" -> {"hero-check-circle", "text-success"}
        "TIMEOUT" -> {"hero-clock", "text-warning"}
        "FAILED" -> {"hero-x-circle", "text-error"}
        "NODE_FAIL" -> {"hero-exclamation-triangle", "text-error"}
        "CANCELLED" <> _ -> {"hero-stop-circle", "text-base-content/60"}
        _ -> {"hero-question-mark-circle", "text-base-content/60"}
      end

    assigns = assign(assigns, icon: icon, class: [assigns.class, color])

    ~H"""
    <.icon name={@icon} class={@class} />
    """
  end
end
