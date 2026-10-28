"""Reproduce ZKSF's engine runs for the ETH check with the public SDK, and check every certificate.

    pip install qsim-sdk zcc-verify qiskit
    export ZKSF_TOKEN=...        # an API key, made in the ZKSF console under Profile, Create API key
    python engine_runs_public.py --engines exact.cpu,exact.gpu,exact.tpu,qpu.rigetti,qpu.iqm.garnet,qpu.aqt.ibex

The formula (x0 OR NOT x1) AND (x1 OR NOT x2) AND (x2 OR NOT x0) has exactly 2 solutions, 000 and 111 (exhaustive
search below). With 2 solutions among 8, ONE Grover iteration puts all the probability on them, so an exact simulator
returns only 000 and 111, and quantum hardware shows how far its noise moves the result. The oracle is built from the
clauses alone, with one helper qubit per clause. Hardware costs real money, so run with --quote first.
Checking our published certificates needs no account, for example  zcc-verify c752e4db92bb418a
"""
import argparse
import itertools

import qsim_sdk
import zcc_verify
from qiskit import qasm2

FORMULA = [((0, True), (1, False)), ((1, True), (2, False)), ((2, True), (0, False))]  # (variable, positive)
QASM = """OPENQASM 2.0;
include "qelib1.inc";
qreg v[3];
qreg cl[3];
creg m[3];
h v[0]; h v[1]; h v[2];
x v[0]; ccx v[0],v[1],cl[0]; x cl[0]; x v[0];
x v[1]; ccx v[1],v[2],cl[1]; x cl[1]; x v[1];
x v[2]; ccx v[2],v[0],cl[2]; x cl[2]; x v[2];
h cl[2]; ccx cl[0],cl[1],cl[2]; h cl[2];
x v[2]; x cl[2]; ccx v[2],v[0],cl[2]; x v[2];
x v[1]; x cl[1]; ccx v[1],v[2],cl[1]; x v[1];
x v[0]; x cl[0]; ccx v[0],v[1],cl[0]; x v[0];
h v[0]; h v[1]; h v[2]; x v[0]; x v[1]; x v[2];
h v[2]; ccx v[0],v[1],v[2]; h v[2];
x v[0]; x v[1]; x v[2]; h v[0]; h v[1]; h v[2];
measure v[0] -> m[0];
measure v[1] -> m[1];
measure v[2] -> m[2];
"""

ap = argparse.ArgumentParser()
ap.add_argument("--engines", default="exact.cpu,exact.gpu,exact.tpu")
ap.add_argument("--shots", type=int, default=1000)
ap.add_argument("--quote", action="store_true", help="print each engine's price and stop")
args = ap.parse_args()

solutions = ["".join(str(b) for b in reversed(bits)) for bits in itertools.product([0, 1], repeat=3)
             if all(any(bits[v] == pos for v, pos in clause) for clause in FORMULA)]
print(f"exhaustive search: {len(solutions)} solutions {solutions}")
circuit = qasm2.loads(QASM)
client = qsim_sdk.Client()  # reads ZKSF_TOKEN
for engine in args.engines.split(","):
    quote = client.estimate(circuit, shots=args.shots, engine=engine)
    print(f"\n{engine}: quoted ${quote.get('predicted_cost_usd')}  {quote.get('reason') or ''}")
    if args.quote:
        continue
    job = client.run(circuit, shots=args.shots, engine=engine, timeout=7200)
    counts = job["result"]["counts"]
    share = sum(v for k, v in counts.items() if k.replace(" ", "") in solutions) / sum(counts.values())
    print(f"  job {job['id']}: {dict(sorted(counts.items(), key=lambda kv: -kv[1]))}")
    print(f"  share of shots on the solutions: {share:.1%} (exact simulation 100%, random guessing 25%)")
    cert = client.certificate(job["id"])
    report = zcc_verify.verify(zcc_verify.fetch(cert["cert_id"]))
    print(f"  certificate {cert['cert_id']} ({cert.get('protocol')}): zcc-verify {'passes' if report.ok else 'FAILS'}; "
          f"{cert.get('verify_url')}")
