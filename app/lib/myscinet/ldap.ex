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

  defp transact(dn, pw, handler) do
    conf = config()

    hosts =
      conf[:hosts]
      |> String.split(",")
      |> Enum.map(&to_charlist/1)

    port = conf[:port]

    case :eldap.open(hosts, port: port, ssl: true, sslopts: [verify: :verify_none]) do
      {:ok, handle} ->
        result =
          case :eldap.simple_bind(handle, to_charlist(dn), to_charlist(pw)) do
            :ok -> handler.(handle)
            error -> error
          end

        :eldap.close(handle)
        result

      error ->
        error
    end
  end

  defp transact_as_admin(handler) do
    conf = config()
    transact(conf[:bind_dn], conf[:bind_pw], handler)
  end

  defp map_to_s(x), do: Enum.map(x, &IO.iodata_to_binary/1)

  # call :eldap.search and 'unpeel' the result into a map
  defp search(handle, opts) do
    case :eldap.search(handle, opts) do
      {:ok, {:eldap_search_result, entries, [], _}} ->
        results =
          for {:eldap_entry, _, entry} <- entries do
            for {k, vs} <- entry, do: {:erlang.list_to_atom(k), map_to_s(vs)}, into: %{}
          end

        {:ok, results}

      error ->
        error
    end
  end

  defp userinfo(handle, uid, dn) do
    uid = to_charlist(uid)
    dn = to_charlist(dn)

    with {:ok,
          [
            %{
              cn: [fullname],
              gidNumber: [gid],
              mail: emails,
              uid: [username],
              loginShell: [shell]
            }
          ]} <-
           search(handle,
             base: dn,
             scope: :eldap.baseObject(),
             filter: :eldap.present(~c"gidNumber"),
             attributes: [~c"cn", ~c"gidNumber", ~c"mail", ~c"uid", ~c"loginShell"]
           ),
         {:ok, results} <-
           search(handle,
             base: config()[:group_base],
             scope: :eldap.singleLevel(),
             filter:
               :eldap.or([
                 :eldap.equalityMatch(~c"memberUid", uid),
                 :eldap.equalityMatch(~c"gidNumber", gid)
               ]),
             attributes: [~c"cn"]
           ) do
      groups = for %{cn: [val]} <- results, do: val

      {:ok,
       %{
         fullname: fullname,
         username: username,
         groups: groups,
         emails: emails,
         shell: shell
       }}
    else
      error -> error
    end
  end

  def authenticate(username, password) do
    dn = uid2dn(username)

    transact(dn, password, fn handle ->
      case userinfo(handle, username, dn) do
        {:ok, %{shell: "/sbin/nologin"}} -> {:error, :nologin}
        {:ok, info} -> {:ok, info}
        error -> error
      end
    end)
  end

  def user_info(username) do
    transact_as_admin(&userinfo(&1, username, uid2dn(username)))
  end

  def user_search(q) do
    transact_as_admin(fn handle ->
      conf = config()
      q = to_charlist(q)
      attr = [~c"cn", ~c"mail", ~c"uid"]

      case search(handle,
             base: conf[:user_base],
             scope: :eldap.singleLevel(),
             filter:
               :eldap.or([
                 :eldap.substrings(~c"cn", [{:any, q}]),
                 :eldap.substrings(~c"uid", [{:any, q}]),
                 :eldap.substrings(~c"mail", [{:any, q}])
               ]),
             attributes: attr
           ) do
        {:ok, []} ->
          search(handle,
            base: conf[:user_base],
            scope: :eldap.singleLevel(),
            filter:
              :eldap.or([
                :eldap.approxMatch(~c"cn", q),
                :eldap.approxMatch(~c"mail", q)
              ]),
            attributes: attr
          )

        {:ok, results} ->
          {:ok, results}

        error ->
          error
      end
    end)
  end

  def group_members(group) do
    transact_as_admin(fn handle ->
      case search(handle,
             base: gid2dn(group),
             scope: :eldap.baseObject(),
             filter: :eldap.present(~c"memberUid"),
             attributes: [~c"memberUid"]
           ) do
        [%{memberUid: members}] -> members
        error -> error
      end
    end)
  end
end
