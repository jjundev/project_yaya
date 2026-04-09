"""python -m harness 진입점."""
import sys

from harness.config import PipelineError
from harness.doctor import run_doctor


def main() -> None:
    if len(sys.argv) >= 2 and sys.argv[1] == "doctor":
        exit_code = run_doctor(sys.argv[2:])
        sys.exit(exit_code)

    if "--web" in sys.argv:
        from harness.web.app import start_server

        port = 8420
        if "--port" in sys.argv:
            idx = sys.argv.index("--port")
            port = int(sys.argv[idx + 1])
        start_server(port=port)
    else:
        from harness.cli import parse_args
        from harness.pipeline import run_pipeline

        args = parse_args()
        try:
            run_pipeline(args.feature, args.start_from, args.worktree_source)
        except PipelineError as e:
            print(str(e), file=sys.stderr)
            sys.exit(1)


if __name__ == "__main__":
    main()
