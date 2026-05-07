# syna attestation bundles

Public hardware-attestation proofs (`.syna`, CBOR-framed) consumed by
the syna NixOS module. Not secrets; safe to commit.

## Refresh

Each bundle ages with the underlying cert chain. Re-export when:

- the device is re-provisioned (key regenerated)
- you rotate to a new attestation root
- a tripwire test in syna flags upcoming root expiry

## Producing a bundle

`fafnir` (jester):

```
ssh jester 'syna export fafnir' > config/syna/attestations/jester-fafnir.syna
```

Replay before committing:

```
syna verify config/syna/attestations/jester-fafnir.syna
```

