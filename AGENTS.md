# AGENTS.md

## Before changing code

- Read the README and the [contribution guidelines](https://github.com/Vectorized/solady/issues/19).
- Inspect the complete NatSpec, implementation, relevant tests, and history.
- Solady may intentionally differ from OpenZeppelin. A difference alone is not a defect.
- Do not copy isolated assembly idioms. Solady optimizations are context-dependent.
- Do not edit files marked as auto-generated. Change the corresponding generator under `prep/`.
- API documentation is generated from source NatSpec. Update the source comments first.

## Verifying changes

- After source changes, run `node prep/all` and then `forge fmt`.
- Plain `forge test` does not cover every path. Check `foundry.toml` for skipped paths and run
  the applicable profile from `.github/workflows/ci.yml`.
- Confirm that the relevant tests were actually selected.
- Repeat the applicable build or test command with `--via-ir`.
- For memory-safety changes, use the helpers in `test/utils/Brutalizer.sol`.

## Reporting defects

- State the exact commit tested, reachable call path, inputs, observed result, and expected result.
- If claiming security impact, show that an attacker controls the required inputs or state.
- Check the NatSpec, tests, history, and existing issues and pull requests before reporting.
- If the behavior is documented, explain why the documented contract itself is defective.
- A defensive change must fix a reachable failure. Consider its gas and bytecode cost.
- Do not contact maintainers or publish a suspected vulnerability yourself. Prepare a draft for
  human review. The human reporter should follow [SECURITY.md](SECURITY.md).
