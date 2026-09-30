#!/usr/bin/env bash

# Shared shell helpers for k6 launcher scripts.

# Print usage instructions to stdout. example_config is shown as an illustrative
# value only - it is not a default; a config file must always be supplied.
k6_print_usage() {
  local example_config="$1"
  echo "Usage: $0 <config-file> [-useDashboard] [-useSummary] [-includeJsonResults]"
  echo "Example: $0 ${example_config}"
  echo "Example: $0 ${example_config} -useDashboard"
  echo "Example: $0 ${example_config} -useSummary"
  echo "Example: $0 ${example_config} -includeJsonResults"
}

# Sanitize a string for use as a filesystem path segment.
# Replaces any characters outside [A-Za-z0-9._-] with hyphens, collapses
# consecutive hyphens, and strips leading/trailing hyphens. Falls back to
# "config" if the result is empty.
k6_sanitize_name() {
  local raw_name="$1"
  local safe_name
  safe_name=$(printf '%s' "$raw_name" | sed -E 's/[^A-Za-z0-9._-]+/-/g; s/-+/-/g; s/^-+//; s/-+$//')
  if [[ -z "$safe_name" ]]; then
    safe_name="config"
  fi
  printf '%s' "$safe_name"
}

# Locate the JS launcher file and return its absolute path.
# Checks scripts/ subdirectory first, then the k6 root, to support both
# the standard layout and any root-level overrides.
k6_resolve_launcher_path() {
  local script_dir="$1"
  local launcher_file="$2"

  if [[ -f "${script_dir}/scripts/${launcher_file}" ]]; then
    printf '%s' "${script_dir}/scripts/${launcher_file}"
    return 0
  fi

  if [[ -f "${script_dir}/${launcher_file}" ]]; then
    printf '%s' "${script_dir}/${launcher_file}"
    return 0
  fi

  echo "Error: Launcher file not found in scripts/ or k6 root: ${launcher_file}" >&2
  return 1
}

k6_resolve_config_path() {
  local script_dir="$1"
  local config_file="$2"

  # Resolve relative to CWD (common case: running launcher from the k6 root).
  # Always return absolute path so k6's open() resolves correctly from the JS script location.
  if [[ -f "$config_file" ]]; then
    printf '%s' "$(cd "$(dirname "$config_file")" && pwd)/$(basename "$config_file")"
    return 0
  fi

  # Resolve relative to script_dir (launcher invoked from outside the k6 root).
  # script_dir is always absolute, so this produces a fully-qualified path.
  if [[ -f "${script_dir}/${config_file}" ]]; then
    printf '%s' "${script_dir}/${config_file}"
    return 0
  fi

  echo "Error: Config file not found: ${config_file}" >&2
  return 1
}

# Entry point for all launcher scripts. Resolves paths, builds the timestamped
# output directory under logs/<scenario_type>/<config_name>/<timestamp>/, then
# invokes k6 with the appropriate flags and captures structured output files.
k6_run_launcher() {
  local script_dir="$1"
  local scenario_type="$2"
  local launcher_file="$3"
  local usage_example_config="$4"
  shift 4

  local include_json_results=false
  local use_dashboard=false
  local use_summary=false
  local config_file_input=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -includeJsonResults)
        include_json_results=true
        shift
        ;;
      -useDashboard)
        use_dashboard=true
        shift
        ;;
      -useSummary)
        use_summary=true
        shift
        ;;
      -h|--help)
        k6_print_usage "$usage_example_config"
        exit 0
        ;;
      -*)
        echo "Error: Unknown option: $1" >&2
        k6_print_usage "$usage_example_config"
        exit 1
        ;;
      *)
        if [[ -n "$config_file_input" ]]; then
          echo "Error: Only one config file may be provided." >&2
          k6_print_usage "$usage_example_config"
          exit 1
        fi
        config_file_input="$1"
        shift
        ;;
    esac
  done

  if [[ -z "$config_file_input" ]]; then
    k6_print_usage "$usage_example_config"
    exit 1
  fi

  local config_file
  config_file=$(k6_resolve_config_path "$script_dir" "$config_file_input")

  local launcher_path
  launcher_path=$(k6_resolve_launcher_path "$script_dir" "$launcher_file")

  # Prepare variables for output file paths with sanitized names.
  local timestamp raw_config_name safe_config_name run_dir output_file summary_file console_file dashboard_file startup_log
  timestamp=$(date +%Y%m%d-%H%M%S)
  raw_config_name=$(basename "$config_file")
  raw_config_name="${raw_config_name%.*}"
  safe_config_name=$(k6_sanitize_name "$raw_config_name")
  run_dir="${script_dir}/logs/${scenario_type}/${safe_config_name}/${timestamp}"
  output_file="${run_dir}/results.json"
  summary_file="${run_dir}/summary.json"
  console_file="${run_dir}/console.log"
  dashboard_file="${run_dir}/dashboard.html"
  startup_log="${run_dir}/startup.log"

  # Prepare variables for dashboard configuration. The dashboard is off by default to avoid
  # resource and port contention on large test runs; pass -useDashboard to enable it.
  # Individual settings can still be overridden via K6_WEB_DASHBOARD* env vars if needed.
  local dashboard_enabled dashboard_host dashboard_port dashboard_period dashboard_open dashboard_display_host dashboard_url
  dashboard_enabled="false"
  if [[ "$use_dashboard" == true ]]; then
    dashboard_enabled="${K6_WEB_DASHBOARD:-true}"
  fi
  dashboard_host="${K6_WEB_DASHBOARD_HOST:-0.0.0.0}"
  dashboard_port="${K6_WEB_DASHBOARD_PORT:-5665}"
  dashboard_open="${K6_WEB_DASHBOARD_OPEN:-false}"
  dashboard_period="${K6_WEB_DASHBOARD_PERIOD:-30s}"
  dashboard_display_host="$dashboard_host"
  if [[ "$dashboard_display_host" == "0.0.0.0" ]]; then
    dashboard_display_host="localhost"
  fi
  dashboard_url="http://${dashboard_display_host}:${dashboard_port}"

  # Create any needed output directories.
  mkdir -p "$run_dir"

  # Prepare the arguments for k6 using separate arrays of flags for clarity and separation of purpose where possible.
  # Note: The "--log-format raw" flag is used to ensure that console output without formatting (eg. JSON remains JSON).
  local -a k6_base_args k6_out_args k6_summary_args k6_env_args k6_args
  k6_base_args=(
    run
    --log-format raw
    --console-output="${console_file}"
  )

  # This is an optional flag which can produce VERY LARGE FILES, use with caution!
  k6_out_args=()
  if [[ "$include_json_results" == true ]]; then
    k6_out_args=(--out "json=${output_file}")
  fi

  # Optional flag to export the aggregated summary JSON at end-of-run.
  k6_summary_args=()
  if [[ "$use_summary" == true ]]; then
    k6_summary_args=(--summary-export="${summary_file}")
  fi

  # Special flags to be set as environment variables in the script.
  k6_env_args=(
    --env "CONFIG_FILE=${config_file}"
    --env "SUMMARY_DIR=${run_dir}"
  )

  # Chain the arrays together to form the final k6 arguments array, with the launcher path at the end.
  k6_args=(
    "${k6_base_args[@]}"
    "${k6_out_args[@]}"
    "${k6_summary_args[@]}"
    "${k6_env_args[@]}"
    "${launcher_path}"
  )

  # Build the full k6 command string for startup logging, including inline env vars.
  local k6_cmd_display
  if [[ "$dashboard_enabled" == true ]]; then
    k6_cmd_display="K6_WEB_DASHBOARD=true K6_WEB_DASHBOARD_HOST=$(printf '%q' "${dashboard_host}") K6_WEB_DASHBOARD_PORT=$(printf '%q' "${dashboard_port}") K6_WEB_DASHBOARD_OPEN=$(printf '%q' "${dashboard_open}") K6_WEB_DASHBOARD_PERIOD=$(printf '%q' "${dashboard_period}") K6_WEB_DASHBOARD_EXPORT=$(printf '%q' "${dashboard_file}") k6 $(printf '%q ' "${k6_args[@]}")"
  else
    k6_cmd_display="K6_WEB_DASHBOARD=false k6 $(printf '%q ' "${k6_args[@]}")"
  fi

  # Report run configuration and the full command line; tee to startup.log so it is captured even if k6 fails.
  {
    echo "Startup Log - $(date)"
    echo "Scenario Type  : ${scenario_type}"
    echo "Config File    : ${config_file}"
    echo "Launcher       : ${launcher_path}"
    echo "Run Directory  : ${run_dir}"
    echo "Console Log    : ${console_file}"
    if [[ "$use_summary" == true ]]; then
      echo "Summary File   : ${summary_file}"
    fi
    if [[ "$include_json_results" == true ]]; then
      echo "Results JSON   : ${output_file}"
    fi
    if [[ "$dashboard_enabled" == true ]]; then
      echo "Dashboard URL  : ${dashboard_url}"
      echo "Dashboard HTML : ${dashboard_file}"
    fi
    echo ""
    echo "Full k6 Command:"
    echo "  ${k6_cmd_display}"
  } | tee "${startup_log}"

  # See OUTPUT.md for more information about the various output files produced.
  # All K6_WEB_DASHBOARD* env vars are set explicitly here so the script is the sole source of truth.
  if [[ "$dashboard_enabled" == true ]]; then
    K6_WEB_DASHBOARD="true" \
    K6_WEB_DASHBOARD_HOST="${dashboard_host}" \
    K6_WEB_DASHBOARD_PORT="${dashboard_port}" \
    K6_WEB_DASHBOARD_OPEN="${dashboard_open}" \
    K6_WEB_DASHBOARD_PERIOD="${dashboard_period}" \
    K6_WEB_DASHBOARD_EXPORT="${dashboard_file}" \
    k6 "${k6_args[@]}"
  else
    K6_WEB_DASHBOARD="false" \
    k6 "${k6_args[@]}"
  fi
}
