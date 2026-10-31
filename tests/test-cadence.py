"""Offline checks of actual scheduler expressions and fixture substitutions."""
import argparse
from pathlib import Path
import re
import shlex
import shutil
import subprocess
import unittest

parser = argparse.ArgumentParser()
parser.add_argument("--shell", default=shutil.which("sh"))
args, remaining = parser.parse_known_args()
ROOT = Path(__file__).resolve().parents[1]


@unittest.skipUnless(args.shell, "POSIX sh required")
class CadenceTest(unittest.TestCase):
    def shell(self, code):
        result = subprocess.run([args.shell, "-c", code], capture_output=True, text=True, timeout=10)
        self.assertEqual(0, result.returncode, result.stderr)
        return result.stdout.strip().splitlines()

    def test_slow_work_stays_thirty_seconds_with_one_second_poll(self):
        for name, variable in [("daemon.sh", "slow_tick"), ("watchdog.sh", "heartbeat_tick")]:
            source = (ROOT / "runtime" / name).read_text(encoding="utf-8")
            self.assertEqual(1, len(re.findall(r"/system/bin/sleep 1 [69]>&- & # fast-liveness-poll", source)))
            expression = next(line for line in source.splitlines() if line.strip().startswith(variable + "=$(("))
            ticks = self.shell(f'{variable}=0; tick=0\nwhile [ "$tick" -lt 91 ]; do\n[ "${variable}" -ne 0 ] || echo "$tick"\n{expression}\ntick=$((tick+1))\ndone')
            self.assertEqual(["0", "30", "60", "90"], ticks)

    def test_original_crash_backoff_durations_are_preserved(self):
        lines = (ROOT / "runtime/daemon.sh").read_text(encoding="utf-8").splitlines()
        index = next(i for i, line in enumerate(lines) if "child=; retry_ticks=$backoff_ticks" in line)
        actual = "\n".join(lines[index:index + 3])
        delays = self.shell('backoff_ticks=0\nfor failure in 1 2 3 4 5 6 7; do\n' + actual + '\necho "$retry_ticks"\ndone')
        self.assertEqual(["0", "2", "4", "8", "16", "30", "30"], delays)

    def test_acceleration_rewrites_only_marked_poll_not_stop_waits(self):
        source = (ROOT / "tests/test-reliability.sh").read_text(encoding="utf-8")
        rules = " ".join(line.strip().rstrip("\\").strip() for line in source.splitlines() if "-e " in line and "/system/bin/sleep" in line)
        self.assertTrue(rules)
        for name in ["daemon.sh", "watchdog.sh", "process.sh"]:
            path = shlex.quote((ROOT / "runtime" / name).as_posix())
            transformed = self.shell('BB=fixture-box; POLL_SECONDS=0.037\nsed ' + rules + " " + path)
            text = "\n".join(transformed)
            if name == "process.sh":
                self.assertIn("fixture-box sleep 0.1", text)
                self.assertNotIn("fixture-box sleep 0.037", text)
            else:
                poll = next(line for line in transformed if "# fast-liveness-poll" in line)
                self.assertIn("fixture-box sleep 0.037", poll)
                self.assertNotIn("sleep 0.1", poll)


if __name__ == "__main__":
    unittest.main(argv=[__file__] + remaining)
