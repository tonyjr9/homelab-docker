#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_STACKS=(network dashboard cloud media syncthing minecraft minecraft_keith)

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[1;33m'
blue='\033[0;34m'
cyan='\033[0;36m'
reset='\033[0m'

msg() { printf "%b\n" "$1"; }
info() { msg "${blue}[INFO]${reset} $*"; }
ok() { msg "${green}[OK]${reset} $*"; }
warn() { msg "${yellow}[WARN]${reset} $*"; }
err() { msg "${red}[ERR]${reset} $*" >&2; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || { err "Missing required command: $1"; exit 1; }
}

has_compose_file() {
  local stack="$1"
  [[ -f "$ROOT_DIR/$stack/docker-compose.yml" || -f "$ROOT_DIR/$stack/docker-compose.yaml" ]]
}

compose_file() {
  local stack="$1"
  if [[ -f "$ROOT_DIR/$stack/docker-compose.yml" ]]; then
    printf "%s" "$ROOT_DIR/$stack/docker-compose.yml"
  else
    printf "%s" "$ROOT_DIR/$stack/docker-compose.yaml"
  fi
}

stack_exists() {
  local stack="$1"
  [[ -d "$ROOT_DIR/$stack" ]] && has_compose_file "$stack"
}

resolve_stacks() {
  local requested=("$@")
  local out=()

  if [[ ${#requested[@]} -eq 0 ]]; then
    for s in "${DEFAULT_STACKS[@]}"; do
      stack_exists "$s" && out+=("$s")
    done
  else
    for s in "${requested[@]}"; do
      if [[ "$s" == "all" ]]; then
        for x in "${DEFAULT_STACKS[@]}"; do
          stack_exists "$x" && out+=("$x")
        done
        continue
      fi
      if stack_exists "$s"; then
        out+=("$s")
      else
        warn "Skipping '$s' (directory or compose file not found)"
      fi
    done
  fi

  printf '%s\n' "${out[@]}" | awk 'NF && !seen[$0]++'
}

run_compose() {
  local stack="$1"; shift
  info "$stack -> docker compose $*"
  docker compose -f "$(compose_file "$stack")" "$@"
}

status_stack() {
  local stack="$1"
  msg "${cyan}== $stack ==${reset}"
  docker compose -f "$(compose_file "$stack")" ps || true
  echo
}

logs_stack() {
  local stack="$1" service="${2:-}"
  if [[ -n "$service" ]]; then
    docker compose -f "$(compose_file "$stack")" logs -f --tail=100 "$service"
  else
    docker compose -f "$(compose_file "$stack")" logs -f --tail=100
  fi
}

doctor() {
  need_cmd docker
  info "Root directory: $ROOT_DIR"

  if docker info >/dev/null 2>&1; then
    ok "Docker daemon reachable"
  else
    err "Docker daemon not reachable"
  fi

  if docker network inspect proxy_network >/dev/null 2>&1; then
    ok "Docker network 'proxy_network' exists"
  else
    warn "Docker network 'proxy_network' does not exist"
  fi

  for stack in $(resolve_stacks all); do
    if stack_exists "$stack"; then
      ok "$stack compose found"
    fi
  done

  if [[ -f "$ROOT_DIR/.env" ]]; then
    ok "Root .env exists"
  else
    warn "Root .env missing"
  fi
}

usage() {
  cat <<'EOF'
Usage:
  ./manage.sh <command> [stack|all] [service]

Commands:
  list                  List available stacks
  status [stack|all]    Show docker compose ps for one or more stacks
  up [stack|all]        Start stack(s) in detached mode
  down [stack|all]      Stop and remove stack(s)
  restart [stack|all]   Restart stack(s)
  pull [stack|all]      Pull latest images for stack(s)
  update [stack|all]    Pull images and recreate stack(s)
  logs <stack> [svc]    Follow logs for a stack or one service
  ps                    Show docker ps
  doctor                Basic checks (.env, proxy_network, docker)
  menu                  Interactive menu
  help                  Show this help

Examples:
  ./manage.sh list
  ./manage.sh status all
  ./manage.sh up network
  ./manage.sh update media
  ./manage.sh logs dashboard homarr
EOF
}

list_stacks() {
  info "Available stacks"
  while read -r s; do
    [[ -n "$s" ]] && echo "- $s"
  done < <(resolve_stacks all)
}

menu_select_stacks() {
  mapfile -t stacks < <(resolve_stacks all)
  echo "Select target:"
  echo "0) all"
  local i=1
  for s in "${stacks[@]}"; do
    echo "$i) $s"
    ((i++))
  done
  read -rp "Choice: " choice

  if [[ "$choice" == "0" ]]; then
    printf "all"
    return
  fi

  if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice < i )); then
    printf "%s" "${stacks[$((choice-1))]}"
    return
  fi

  printf ""
}

interactive_menu() {
  while true; do
    echo
    echo "Homelab Docker Manager"
    echo "1) List stacks"
    echo "2) Status"
    echo "3) Start"
    echo "4) Stop"
    echo "5) Restart"
    echo "6) Pull"
    echo "7) Update"
    echo "8) Logs"
    echo "9) Docker ps"
    echo "10) Doctor"
    echo "0) Exit"
    read -rp "Choice: " choice

    case "$choice" in
      1) list_stacks ;;
      2) target="$(menu_select_stacks)"; [[ -n "$target" ]] && main status "$target" ;;
      3) target="$(menu_select_stacks)"; [[ -n "$target" ]] && main up "$target" ;;
      4) target="$(menu_select_stacks)"; [[ -n "$target" ]] && main down "$target" ;;
      5) target="$(menu_select_stacks)"; [[ -n "$target" ]] && main restart "$target" ;;
      6) target="$(menu_select_stacks)"; [[ -n "$target" ]] && main pull "$target" ;;
      7) target="$(menu_select_stacks)"; [[ -n "$target" ]] && main update "$target" ;;
      8)
        target="$(menu_select_stacks)"
        [[ -z "$target" || "$target" == "all" ]] && { warn "Choose a single stack for logs"; continue; }
        read -rp "Optional service name: " service
        main logs "$target" "$service"
        ;;
      9) docker ps ;;
      10) doctor ;;
      0) exit 0 ;;
      *) warn "Invalid choice" ;;
    esac
  done
}

main() {
  local command="${1:-menu}"
  shift || true

  case "$command" in
    help|-h|--help) usage ;;
    list) list_stacks ;;
    ps) docker ps ;;
    doctor) doctor ;;
    menu) interactive_menu ;;
    status)
      mapfile -t stacks < <(resolve_stacks "$@")
      for stack in "${stacks[@]}"; do status_stack "$stack"; done
      ;;
    up)
      mapfile -t stacks < <(resolve_stacks "$@")
      for stack in "${stacks[@]}"; do run_compose "$stack" up -d; done
      ;;
    down)
      mapfile -t stacks < <(resolve_stacks "$@")
      for stack in "${stacks[@]}"; do run_compose "$stack" down; done
      ;;
    restart)
      mapfile -t stacks < <(resolve_stacks "$@")
      for stack in "${stacks[@]}"; do run_compose "$stack" restart; done
      ;;
    pull)
      mapfile -t stacks < <(resolve_stacks "$@")
      for stack in "${stacks[@]}"; do run_compose "$stack" pull; done
      ;;
    update)
      mapfile -t stacks < <(resolve_stacks "$@")
      for stack in "${stacks[@]}"; do
        run_compose "$stack" pull
        run_compose "$stack" up -d
      done
      ;;
    logs)
      local stack="${1:-}"
      local service="${2:-}"
      [[ -z "$stack" ]] && { err "logs requires a stack name"; usage; exit 1; }
      stack_exists "$stack" || { err "Unknown stack: $stack"; exit 1; }
      logs_stack "$stack" "$service"
      ;;
    *)
      err "Unknown command: $command"
      usage
      exit 1
      ;;
  esac
}

main "$@"

