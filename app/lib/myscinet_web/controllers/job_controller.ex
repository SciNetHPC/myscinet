defmodule MySciNetWeb.JobController do
  use MySciNetWeb, :controller

  alias MySciNet.Repo
  alias MySciNet.Jsum
  import Ecto.Query
  import MySciNetWeb.Permissions
  import MySciNetWeb.Clusters

  @page_size 20

  defp query_authz(query, conn) do
    username = conn.assigns.current_user.username
    groups = conn.assigns.current_user.groups

    cond do
      is_staff_user?(conn) ->
        # staff can see all jobs
        query

      "def-#{username}" in groups ->
        # PIs can see their group's jobs
        query
        |> where(
          [j],
          j.username == ^username or
            like(j.account, ^"___-#{username}") or
            like(j.account, ^"___-#{username}-a_")
        )

      true ->
        # everyone else can only see their own jobs
        query |> where(username: ^username)
    end
  end

  def index(conn, params) do
    page = Map.get(params, "p", "1") |> String.to_integer()
    offset = (page - 1) * @page_size

    jobsq =
      Jsum
      |> query_authz(conn)
      |> order_by([j], desc: j.start)
      |> limit(^@page_size)
      |> offset(^offset)

    filters =
      Map.get(params, "q", "")
      |> String.trim()
      |> MySciNet.JobQuery.parse()

    {conn, jobsq} =
      case filters do
        {:ok, ast} ->
          {conn, jobsq |> apply_filters(ast)}

        error ->
          dbg(error)
          {conn |> put_flash(:error, "Invalid query"), jobsq}
      end

    jobs = jobsq |> Repo.all()

    render(conn, "index.html",
      page_title: "jobs",
      jobs: jobs,
      page: page
    )
  end

  defp apply_filters(query, []), do: query

  defp apply_filters(query, filters) do
    case filters_and(filters) do
      {dynamic, []} ->
        query |> where(^dynamic)

      {_, errors} ->
        dbg(errors)
        query
    end
  end

  defp filters_and(filters) do
    Enum.reduce(filters, {dynamic(true), []}, fn
      filter, {good, bad} ->
        case filter_to_dynamic_fragment(filter) do
          {:ok, dynamic} ->
            {dynamic(^good and ^dynamic), bad}

          error ->
            {good, [error | bad]}
        end
    end)
  end

  defp filters_or(filters) do
    Enum.reduce(filters, {dynamic(false), []}, fn
      filter, {good, bad} ->
        case filter_to_dynamic_fragment(filter) do
          {:ok, dynamic} ->
            {dynamic(^good or ^dynamic), bad}

          error ->
            {good, [error | bad]}
        end
    end)
  end

  defp filter_to_dynamic_fragment(filter) do
    case filter do
      {:number, n} ->
        {:ok, dynamic([j], like(j.jobid, ^"%:#{n}") or like(j.jobid, ^"%:#{n}\\_%"))}

      {:ident, x} ->
        {:ok, dynamic([j], ilike(j.jobname, ^"%#{x}%"))}

      {:string, x} ->
        {:ok, dynamic([j], ilike(j.jobname, ^"%#{x}%"))}

      {:is_eq, :cluster, {:ident, cluster}} ->
        slug =
          case get_cluster(to_string(cluster)) do
            %{slug_psql: slug_psql} -> slug_psql
            _ -> cluster
          end

        {:ok, dynamic([j], ilike(j.jobid, ^"#{slug}:%"))}

      {:is_eq, :user, {:ident, u}} ->
        {:ok, dynamic([j], j.username == ^to_string(u))}

      {:is_eq, :user, {:number, n}} ->
        {:ok, dynamic([j], j.uid == ^n)}

      {:is_eq, :group, {:ident, g}} ->
        {:ok, dynamic([j], like(j.account, ^"%-#{g}%"))}

      {:is_eq, :group, {:number, n}} ->
        {:ok, dynamic([j], j.gid == ^n)}

      {:is_eq, :state, {:ident, s}} ->
        {:ok, dynamic([j], ilike(j.state, ^"#{s}%"))}

      {:is_eq, :nodes, {:number, n}} ->
        {:ok, dynamic([j], j.nnodes == ^n)}

      {:is_lt, :nodes, {:number, n}} ->
        {:ok, dynamic([j], j.nnodes < ^n)}

      {:is_le, :nodes, {:number, n}} ->
        {:ok, dynamic([j], j.nnodes <= ^n)}

      {:is_gt, :nodes, {:number, n}} ->
        {:ok, dynamic([j], j.nnodes > ^n)}

      {:is_ge, :nodes, {:number, n}} ->
        {:ok, dynamic([j], j.nnodes >= ^n)}

      {op, :time, {:string, t}} when op in [:is_lt, :is_le, :is_gt, :is_ge] ->
        case parse_naive_datetime(t) do
          {:ok, dt} ->
            case op do
              :is_lt -> {:ok, dynamic([j], j.start < ^dt)}
              :is_le -> {:ok, dynamic([j], j.start <= ^dt)}
              :is_gt -> {:ok, dynamic([j], j.start > ^dt)}
              :is_ge -> {:ok, dynamic([j], j.start >= ^dt)}
            end

          error ->
            error
        end

      {:||, filters} ->
        case filters_or(filters) do
          {dynamic, []} -> {:ok, dynamic}
          {_, errors} -> {:errors, errors}
        end

      {:&&, filters} ->
        case filters_and(filters) do
          {dynamic, []} -> {:ok, dynamic}
          {_, errors} -> {:errors, errors}
        end

      unrecognized ->
        {:error, :unrecognized_filter, unrecognized}
    end
  end

  defp parse_naive_datetime(t) when is_binary(t) do
    case Date.from_iso8601(t) do
      {:ok, date} ->
        {:ok, NaiveDateTime.new!(date, ~T[00:00:00])}

      _ ->
        case NaiveDateTime.from_iso8601(t) do
          {:ok, dt} ->
            {:ok, dt}

          error ->
            error
        end
    end
  end

  def show(conn, %{"cluster" => cluster_slug, "id" => cluster_job_id}) do
    id = to_psql_jobid(cluster_slug, cluster_job_id)

    job =
      Jsum
      |> query_authz(conn)
      |> where(jobid: ^id)
      |> Repo.one()

    case job do
      nil ->
        conn
        |> put_status(:not_found)
        |> text("not found or not permitted")

      _ ->
        row = Repo.get_by(MySciNet.Jscript, jobid: id)
        script = row && row.jobscript

        row = Repo.get_by(MySciNet.Jcom, jobid: id)

        command =
          case row && row.jobcom do
            nil ->
              nil

            str ->
              str
              |> String.replace(
                "/opt/slurm/bin/sbatch --export=NONE --get-user-env=L",
                "sbatch"
              )
              |> String.replace(
                "/opt/slurm/bin/sbatch --export=NONE",
                "sbatch"
              )
          end

        row = Repo.get_by(MySciNet.Jenv, jobid: id)
        env = row && row.jobenv

        # cache authorization
        Cachex.put(:myscinet_cache, {:job_authz, id, conn.assigns.current_user.username}, true,
          ttl: :timer.seconds(3600)
        )

        render(conn, "show.html",
          page_title: "job #{cluster_slug}/#{cluster_job_id}",
          command: command,
          job: job,
          env: env,
          script: script
        )
    end
  end

  def perf(conn, %{"cluster" => cluster_slug, "id" => cluster_job_id}) do
    id = to_psql_jobid(cluster_slug, cluster_job_id)

    {table, cols} =
      if get_cluster(cluster_slug).gpu? do
        {:utilgpu,
         [
           :nodename,
           :gpu,
           :cpupercent,
           :memfree,
           :buffers,
           :cached,
           :dcgm_fi_prof_gr_engine_active,
           :dcgm_fi_prof_pipe_fp16_active,
           :dcgm_fi_prof_pipe_fp32_active,
           :dcgm_fi_prof_pipe_fp64_active,
           :dcgm_fi_prof_pipe_tensor_active,
           :dcgm_fi_prof_sm_active,
           :dcgm_fi_prof_sm_occupancy
         ]}
      else
        {:utilcpu,
         [
           :nodename,
           :memfree,
           :buffers,
           :cached,
           :cpupercent,
           :iowait,
           :loadavg,
           :freq,
           :cpi,
           :powerl3,
           :mflops,
           :smflops,
           :memread,
           :memwrite,
           :portxmitdata,
           :portrcvdata,
           :portxmitpkts,
           :portrcvpkts
         ]}
      end

    cols = Enum.join(Enum.map(cols, &Atom.to_string/1), ",")
    escaped_id = String.replace(id, "'", "''")

    case Cachex.get(:myscinet_cache, {:job_authz, id, conn.assigns.current_user.username}) do
      {:ok, true} ->
        query =
          "COPY (SELECT to_char(time,'YYYY-MM-DD\"T\"HH24:MI:SS') as time,#{cols} FROM #{table} WHERE jobid = '#{escaped_id}' ORDER BY time) TO STDOUT CSV HEADER"

        conn =
          conn
          |> put_resp_content_type("text/csv")
          |> put_resp_header("cache-control", "max-age=120, private")
          |> send_chunked(:ok)

        Repo.transaction(fn ->
          Ecto.Adapters.SQL.stream(MySciNet.Repo, query)
          |> Stream.map(&chunk(conn, &1.rows))
          |> Stream.run()
        end)

        conn

      _ ->
        conn
        |> put_status(:not_found)
        |> text("not found or not permitted")
    end
  end
end
