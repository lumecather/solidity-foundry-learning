# Solidity & Foundry Learning
 
Smart contracts written while learning Solidity and Foundry, from a first limited mint to an ERC-721 drop with an
allowlist, EIP-712 signatures, royalties and ERC-20 payments. Every contract is covered by Foundry tests, including
negative cases (reverts, access control, stolen signatures).
 
The NFT examples come from real work on the off-chain side: I build bots and backends that watch NFT reveals and
buy listings (web3.py, OpenSea Seaport, Flashbots). This repository is the on-chain side of the same problems.
 
## Contracts
 
| Contract | File | What it demonstrates |
|---|---|---|
| `MintLimiter` | `src/MintLimiter.sol` | Per-wallet mint limit, custom errors, events |
| `NFTRegistry` | `src/Registry.sol` | `storage` vs `memory` vs `calldata`; a lost-update bug (editing a `memory` copy) proven by a test; gas comparison of `calldata` vs `memory`; owner-only modifiers |
| `PaidMint` | `src/PaidMint.sol` | `payable` mint, refund of overpayment, `withdraw`, checks-effects-interactions |
| `Drop` | `src/Drop.sol` | Max supply, hidden metadata until a one-time reveal, `tokenURI` built from `baseURI` + id |
| `ZeppelinDrop` | `src/ZeppelinDrop.sol` | Full drop on OpenZeppelin v5: ERC-721 with `_safeMint`, Merkle allowlist, EIP-712 signature mint (server-signed, bound to `msg.sender`, with deadline and replay protection), `Ownable`, ERC-2981 royalties (5%), ERC-4906 `BatchMetadataUpdate` on reveal |
| `TokenMintDrop` | `src/TokenMintDrop.sol` | ERC-721 sold for an ERC-20 token: `approve` + `transferFrom` flow via `SafeERC20`, owner withdrawal of tokens |
| `TestUSD` | `src/TestUSD.sol` | Minimal ERC-20 with an open `mint`, used only in tests |
 
## What the tests cover
 
- Happy paths: mints, transfers, reveal, royalties, withdrawals.
- Reverts with exact custom errors, including errors with parameters (`abi.encodeWithSelector`).
- Access control: every owner-only function is called by a stranger and must revert.
- State after a revert: a failed call must not change balances or flags.
- Allowlist: an address in the Merkle tree mints, an address outside does not, a second claim reverts.
- Signatures: a valid server signature mints; the same signature used by another address fails; an expired
  signature fails.
- ETH accounting: exact price, overpayment refund, owner receives the revenue.
- Events checked with `vm.expectEmit`.
- Fuzz tests for access control and out-of-range token ids.
## Run
 
Requires [Foundry](https://book.getfoundry.sh/getting-started/installation).
 
```bash
git clone --recursive https://github.com/lumecather/solidity-foundry-learning.git
cd solidity-foundry-learning
forge build
forge test
```
 
If the repository was cloned without `--recursive`, run `forge install` first.
 
Useful flags:
 
```bash
forge test -vvv                              # traces of failing tests
forge test --match-contract ZeppelinDropTest # one test file
forge test --gas-report                      # gas per function
```
 
## Security notes
 
Things found and kept in mind while writing these contracts:
 
- **`_safeMint` and ETH refunds hand control to the receiver.** State (counters, claimed flags) is updated before
  them, so a re-entering receiver sees the new state.
- **Allowlist and signatures are bound to `msg.sender`.** Merkle proofs and signatures are public; taking the
  address from an argument would let anyone use someone else's proof or signature.
- **Signer key and owner key are different.** If the server's signing key leaks, the owner calls `setSigner` and
  every old signature stops working.
- **`renounceOwnership()`** before the reveal would lock `reveal` and `withdraw` forever.
- **Fee-on-transfer tokens** would make `TokenMintDrop` receive less than `price`. Not handled here; the fix is to
  compare the balance before and after the transfer.
- `TestUSD.mint` has no access control on purpose: it is a test token.
## Stack
 
Solidity 0.8, Foundry (forge, anvil, cast), OpenZeppelin Contracts v5, forge-std.
 