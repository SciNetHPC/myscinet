defmodule MySciNetWeb.JobHTML do
  use MySciNetWeb, :html

  embed_templates "job_html/*"

  defp split_jobid(jobid) do
    case String.split(jobid, "-") do
      [cluster, id] -> {cluster, id}
      _ -> {"balam", jobid} # XXX:TBD temporary fallback
    end
  end

end
