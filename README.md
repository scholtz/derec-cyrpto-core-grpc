# DeRec Cryptography in grpc docker server

This repo contains the grpc server which serves common cryptographic utilities needed to implement DeRec.

The docker image of this project can be used as side car for bigger projects that depend on DeRec protocol and are not written in Rust or Java.

Cryptography primitives were used from project https://github.com/derecalliance/cryptography

## Verifiable Secret Sharing

In order to generate shares of a secret of arbitrary length, we first encrypt the secret using a random (256-bit) AES key, and then secret share the AES key onto the shareholders (a.k.a. helpers). 
Reconstruction proceeds by first reconstructing the AES key from (a threshold number of) the shares, and then using the AES key to decrypt the encrypted secret bits.

In more detail, shares a generated by first sampling a random polynomial `f` (defined over a finite field of prime order) such that `f(0)` equals the AES key `k`. Then, a share is simply a point on the polynomial; i.e., a share is an encoding of `(x, f(x))`, for some arbitrary `x != 0`.
For `n` shareholders, we must compute `n` distinct points on the polynomial as the secret shares. Moreover, if the reconstruction threshold -- i.e., the number of shares needed to reconstruct the secret value `k` -- is desired to be some value `t <= n`, then `f` must be defined such that it has degree `t-1`. This ensures that any `t` points on the polynomials, i.e., any `t` shareholders, can combine their shares to reconstruct any point on the polynomial, including the point `f(0)` which encodes our secret.

When using vanilla Shamir secret sharing, a malicious shareholder can cause reconstruction to fail, or worse, decrypt to an incorrect or adversarially-chosen value. To address this threat, we implement a form of verifiable secret sharing, where each share is accompanied by authentication data that can be used to validate the share.

On generating the Shamir shares, the client generates a Merkle tree over all `n` shares, with each leaf node encoding a hash of a share's point `(x, f(x))`, and the root of the tree acting as a cryptographic commitment to all shares. Then, in addition to `(x, f(x))`, each shareholder is given, as authentication data, the Merkle opening proof for their share, which is a path of sibling hashes from the leaf node until the root node. During reconstruction, for each received share, the client will first hash the share's point `(x, f(x))`, and then verify the Merkle path up to the root node; the expected hash at the root node must equal the root node at the time of generating all shares.

There is a caveat that during reconstruction, in some settings such as DeRec's use case, the client may not have any prior state; i.e., the client does not know the expected Merkle root. We address this by replicating the Merkle root within each share that is given to a shareholder. During reconstruction, the client looks for a root value that is present in at least a threshold `t` number of received shares; otherwise, reconstruction aborts.

## Secure Channel

We implement sign-then-encrypt, where encryption is performed using the ECIES algorithm, and signing is performed using the ECDSA algorithm. Both algorithms use the secp256k1 curve.