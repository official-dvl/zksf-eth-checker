#!/usr/bin/env bash
# Replicate ZKSF's check of openai/math 7ef5c0cc5ca4 ("The Exponential Time Hypothesis is False").
# Needs Docker, about 20 GB of disk, and ideally 24 GB+ of memory for the build. Run from this folder.
# Isolation is a Docker container with no network, as a non-root user. The checker's additional file-level layer
# (landrun) needs Linux 7.2+, so on older kernels the integrity checks in README.md stand in for it.
set -euo pipefail
COMMIT=7ef5c0cc5ca4b0e072b7a050fca09ab24bc6fa3a
IMG=zksf-eth-check

docker build -t "$IMG" .
docker build --network none -f Dockerfile.bigstack -t "$IMG:bigstack" .   # nanoda with a 1 GiB thread stack
docker volume create eth-work
docker run --rm -u root -v eth-work:/work "$IMG" chown checker:checker /work   # a new volume's root is root's

# Stage A, the only step with network, clones at the pinned commit and fetches the official Mathlib cache. Never run `lake update`.
docker run --rm --user checker -v eth-work:/work -w /work "$IMG" bash -c "
  git clone --filter=blob:none --no-checkout https://github.com/openai/math.git && cd math &&
  git sparse-checkout set lean && git checkout $COMMIT && cd lean && lake exe cache get"

# Run 1, with no network, uses the published configuration unchanged. About 1.5 h on 18 threads.
docker run --rm --network none --user checker -v eth-work:/work -w /work/math/lean "$IMG" bash -c "
  COMPARATOR_LANDRUN=/home/checker/bin/landrun COMPARATOR_LEAN4EXPORT=/home/checker/bin/lean4export \
  lake env comparator ComparatorChallenges/SubexponentialSAT.json"

# Run 2, with no network, is the same with the independent nanoda kernel switched on. The challenge's build outputs are
# moved aside first so the challenge is rebuilt, and the config copy lives outside the repository. nanoda's stock 16 MiB
# thread stack overflows on this proof, so this uses the :bigstack image, whose 1 GiB stack is the only change.
docker run --rm --network none --user checker -v eth-work:/work -w /work/math/lean "$IMG:bigstack" bash -c '
  set -e
  for f in $(find .lake/build -path "*ComparatorChallenges/SubexponentialSAT*" -type f); do
    mkdir -p "/work/aside/$(dirname "$f")"; mv "$f" "/work/aside/$f"; done
  mkdir -p /work/configs
  python3 -c "import json; c = json.load(open(\"ComparatorChallenges/SubexponentialSAT.json\")); c[\"enable_nanoda\"] = True; json.dump(c, open(\"/work/configs/SubexponentialSAT.nanoda.json\", \"w\"), indent=2)"
  COMPARATOR_LANDRUN=/home/checker/bin/landrun COMPARATOR_LEAN4EXPORT=/home/checker/bin/lean4export \
  COMPARATOR_NANODA=/home/checker/bin/nanoda_bin_bigstack lake env comparator /work/configs/SubexponentialSAT.nanoda.json'

# The cutoff, in Lean, against the proof's own definitions (read-only, no network)
docker run --rm --network none --user checker -v eth-work:/work:ro -v "$PWD":/zksf:ro -w /work/math/lean "$IMG" \
  lake env lean /zksf/cutoff_check.lean

# The cutoff, in exact integer arithmetic
python3 cutoff_threshold.py
