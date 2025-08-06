defmodule MySciNetWeb.Permissions do

  def contains_staff_group?(groups) do
    "scinet" in groups or "cc_staff" in groups
  end

  def contains_superuser_group?(groups) do
    "scinet" in groups
  end

  def is_staff_user?(conn) do
    conn.assigns[:current_user] && contains_staff_group?(conn.assigns.current_user.groups)
  end

  def is_superuser?(conn) do
    conn.assigns[:current_user] && contains_superuser_group?(conn.assigns.current_user.groups)
  end

end
