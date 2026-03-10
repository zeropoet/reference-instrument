# Reference Instrument

A deterministic instrument for exploring relational symmetry in the 4×4 magic square.

Interaction is minimal: tiles are swapped until the structure converges.

Three invariants guide convergence:

- arithmetic (rows, columns, diagonals sum to 34)
- topology (canonical adjacency relationships)
- symmetry (membership in the canonical orbit)

When convergence occurs the instrument produces an artifact:

- `sigil.svg` — a trace of the exploration path
- artifact hash — cryptographic identity
- memory hash — encoded event history
- metadata — structural record

Artifacts are exported and archived as static files.

The public archive is available at:

[https://zeropoet.github.io/reference-instrument](https://zeropoet.github.io/reference-instrument)

Each artifact has a permanent address and a corresponding QR identity.

The instrument is implemented as a Swift iPhone application built on FoldKernel.
FoldKernel provides the deterministic mathematical core.

Structure:

```text
instrument
↓
artifact generation
↓
artifact archive
↓
public catalog
```

No network calls occur inside the instrument itself.
Artifacts are exported and committed to the archive repository.

Author: Zeropoet
