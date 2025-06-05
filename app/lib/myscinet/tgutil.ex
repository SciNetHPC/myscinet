defmodule MySciNet.Tgutil do
  use Ecto.Schema

  @primary_key false
  schema "tgutil" do
    field :nodename, :string
    field :time, :naive_datetime
    field :jobid, :string
    field :gpu, :integer
    field :memfree, :float
    field :buffers, :float
    field :cached, :float
    field :cpupercent, :float
    field :iowait, :float
    field :loadavg, :float
    field :dcgm_fi_dev_sm_clock, :float
    field :dcgm_fi_dev_mem_clock, :float
    field :dcgm_fi_dev_memory_temp, :float
    field :dcgm_fi_dev_gpu_temp, :float
    field :dcgm_fi_dev_power_usage, :float
    field :dcgm_fi_dev_total_energy_consumption, :string
    field :dcgm_fi_dev_pcie_replay_counter, :string
    field :dcgm_fi_dev_gpu_util, :float
    field :dcgm_fi_dev_mem_copy_util, :float
    field :dcgm_fi_dev_enc_util, :float
    field :dcgm_fi_dev_dec_util, :float
    field :dcgm_fi_dev_xid_errors, :float
    field :dcgm_fi_dev_power_violation, :string
    field :dcgm_fi_dev_thermal_violation, :string
    field :dcgm_fi_dev_sync_boost_violation, :string
    field :dcgm_fi_dev_board_limit_violation, :string
    field :dcgm_fi_dev_low_util_violation, :string
    field :dcgm_fi_dev_reliability_violation, :string
    field :dcgm_fi_dev_fb_free, :float
    field :dcgm_fi_dev_fb_used, :float
    field :dcgm_fi_dev_ecc_sbe_vol_total, :string
    field :dcgm_fi_dev_ecc_dbe_vol_total, :string
    field :dcgm_fi_dev_ecc_sbe_agg_total, :string
    field :dcgm_fi_dev_ecc_dbe_agg_total, :string
    field :dcgm_fi_dev_uncorrectable_remapped_rows, :string
    field :dcgm_fi_dev_correctable_remapped_rows, :string
    field :dcgm_fi_dev_row_remap_failure, :float
    field :dcgm_fi_dev_nvlink_crc_flit_error_count_total, :string
    field :dcgm_fi_dev_nvlink_crc_data_error_count_total, :string
    field :dcgm_fi_dev_nvlink_replay_error_count_total, :string
    field :dcgm_fi_dev_nvlink_recovery_error_count_total, :string
    field :dcgm_fi_dev_nvlink_bandwidth_l0, :string
    field :dcgm_fi_dev_nvlink_bandwidth_total, :string
    field :dcgm_fi_dev_vgpu_license_status, :float
    field :dcgm_fi_prof_gr_engine_active, :float
    field :dcgm_fi_prof_sm_active, :float
    field :dcgm_fi_prof_pipe_fp32_active, :float
    field :dcgm_fi_prof_pipe_fp16_active, :float
    field :dcgm_fi_prof_pcie_tx_bytes, :string
    field :dcgm_fi_prof_pcie_rx_bytes, :string
  end
end
