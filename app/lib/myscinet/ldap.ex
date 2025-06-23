defmodule MySciNet.LDAP do
  # Fetch config at runtime for runtime configurability
  defp config, do: Application.get_env(:myscinet, __MODULE__)

  defp uid2dn(uid) when is_binary(uid) do
    uid = Regex.replace(~r/[^a-zA-Z0-9_]/, uid, "")
    ~c"uid=#{uid},#{config()[:user_base]}"
  end

  defp gid2dn(gid) when is_binary(gid) do
    gid = Regex.replace(~r/[^a-zA-Z0-9]/, gid, "")
    ~c"cn=#{gid},#{config()[:group_base]}"
  end

  defp open() do
    hosts = config()[:hosts]
      |> String.split(",")
      |> Enum.map(&to_charlist/1)
    port = config()[:port]
    {:ok, handle} = :eldap.open(hosts, port: port,
      ssl: true, sslopts: [verify: :verify_none])
    handle
  end

  defp connect() do
    handle = open()
    :ok = :eldap.simple_bind(handle, to_charlist(config()[:bind_dn]), to_charlist(config()[:bind_pw]))
    handle
  end

  defp map_to_s(x), do: Enum.map(x, &IO.iodata_to_binary/1)

  # call :eldap.search and 'unpeel' the result into a map
  defp search(handle, opts) do
    case :eldap.search(handle, opts) do
      {:ok, {:eldap_search_result, entries, []}} ->
        for {:eldap_entry,_,entry} <- entries do
          for {k,vs} <- entry, do: {:erlang.list_to_atom(k),map_to_s(vs)}, into: %{}
        end
      _ ->
        []
    end
  end

  defp userinfo(handle, uid, dn) when is_list(uid) and is_list(dn) do
    results = search(handle,
      base: dn,
      scope: :eldap.baseObject(),
      filter: :eldap.present(~c"gidNumber"),
      attributes: [~c"cn", ~c"gidNumber", ~c"mail", ~c"uid", ~c"loginShell"])
    [%{cn: [fullname], gidNumber: [gid], mail: emails, uid: [username], loginShell: [shell]}] = results

    results = search(handle,
      base: config()[:group_base],
      scope: :eldap.singleLevel(),
      filter: :eldap.or([:eldap.equalityMatch(~c"memberUid", uid),
                         :eldap.equalityMatch(~c"gidNumber", gid)]),
      attributes: [~c"cn"])
    groups = for %{cn: [val]} <- results, do: val

    %{fullname: fullname, username: username, groups: groups, emails: emails, shell: shell}
  end

  def authenticate(username, password) do
    uid = to_charlist username
    pw = to_charlist password
    dn = uid2dn username
    handle = open()
    result = case :eldap.simple_bind(handle, dn, pw) do
      :ok ->
        case userinfo(handle, uid, dn) do
          %{shell: "/sbin/nologin"} -> :error
          info -> {:ok, info}
        end
      _ ->
        :error
    end
    :eldap.close(handle)
    result
  end

  def user_info(username) do
    uid = to_charlist username
    dn = uid2dn username
    handle = connect()
    info = userinfo(handle, uid, dn)
    :eldap.close(handle)
    info
  end

  def user_search(q) do
    q = to_charlist q
    handle = connect()
    attr = [~c"cn", ~c"mail", ~c"uid"]
    results = search(handle,
      base: config()[:user_base],
      scope: :eldap.singleLevel(),
      filter: :eldap.or([
        :eldap.substrings(~c"cn", [{:any, q}]),
        :eldap.substrings(~c"uid", [{:any, q}]),
        :eldap.substrings(~c"mail", [{:any, q}])]),
      attributes: attr)
    results = case length(results) do
      0 -> search(handle,
        base: config()[:user_base],
        scope: :eldap.singleLevel(),
        filter: :eldap.or([
          :eldap.approxMatch(~c"cn", q),
          :eldap.approxMatch(~c"mail", q)]),
        attributes: attr)
      _ -> results
    end
    :eldap.close(handle)
    results
  end

  def group_members(group) do
    handle = connect()
    [%{memberUid: members}] = search(handle,
      base: gid2dn(group),
      scope: :eldap.baseObject(),
      filter: :eldap.present(~c"memberUid"),
      attributes: [~c"memberUid"])
    :eldap.close(handle)
    members
  end
end
