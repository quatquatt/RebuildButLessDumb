{
  lib,
  writeShellApplication,
  jq,
  nixVersions,
  git,
}:

writeShellApplication {
  name = "dims"; # Difference In My Stats

  runtimeInputs = [
    jq
    git
  ];
  excludeShellChecks = [ "SC2181" ];

  text = ''
    set -e
    NIX=${lib.getExe nixVersions.latest}
    TMPDIR=$(mktemp -d)

    HEAD_REV=$(git rev-parse --abbrev-ref HEAD)
    REV_AFTER=$HEAD_REV
    REV_AFTER_PASSED=0

    while [[ $# -gt 0 ]]; do
      case $1 in
        -e|--expr)
          EXPR="$2"
          shift
          shift
          ;;
        -b|--before)
          REV_BEFORE="$2"
          shift
          shift
          ;;
        -a|--after)
          REV_AFTER=$2
          REV_AFTER_PASSED=1
          shift
          shift
          ;;
        --use-global-nix)
          NIX=nix
          shift
          ;;
        --*|-*)
          echo "Unknown option $1"
          exit 1
          ;;
        *)
          echo "Unknown positional argument $1"
          exit 1
          ;;
      esac
    done

    function cleanup() {
      if [[ $REV_AFTER_PASSED -ne 0 ]]; then
        git checkout --quiet "$HEAD_REV"
      fi
      if [[ $DID_STASH -ne 0 ]]; then
        git stash pop --quiet
      fi
      rm -rf "$TMPDIR"
    }
    trap cleanup EXIT

    if [[ -z ''${EXPR+x} ]]; then
      echo "-e / --expr must be passed!"
      exit 1
    elif [[ -z ''${REV_BEFORE+x} ]]; then
      echo "-b / --before must be passed!"
      exit 1
    fi

    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      echo "Must be within a git repo!"
      exit 1
    fi

    DID_STASH=0
    if [[ -n $(git status --porcelain -uno) ]]; then
      DID_STASH=1
      echo "Temporarily stashing local changes..."
      git stash push --quiet
    fi

    if [[ $DID_STASH -ne 0 ]]; then
      echo
    fi
    echo "Checking out revision '$REV_BEFORE'"
    git checkout --quiet "$REV_BEFORE"
    NIX_SHOW_STATS_PATH=$TMPDIR/before.json NIX_SHOW_STATS=1 $NIX eval --expr "$EXPR" --impure
    if [ $? -ne 0 ]; then
      cat "$TMPDIR/nix-output"
      exit 1
    fi

    echo
    echo "Checking out revision '$REV_AFTER'"
    git checkout --quiet "$REV_AFTER"
    NIX_SHOW_STATS_PATH=$TMPDIR/after.json NIX_SHOW_STATS=1 $NIX eval --expr "$EXPR" --impure
    if [ "$?" -ne 0 ]; then
      cat "$TMPDIR/nix-output"
      exit 1
    fi

    echo
    echo "Stats diff:"
    jq -s -f ${./dims.jq} "$TMPDIR/before.json" "$TMPDIR/after.json"
  '';
}
