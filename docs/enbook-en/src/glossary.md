# Glossary

- **ABI:** the machine-level agreement for calling functions and representing
  values across separately compiled boundaries.
- **Artifact:** a generated binary, library, archive, or compilation output;
  not the source that describes it.
- **Capability:** permission conveyed by a path or signature, such as mutation,
  exclusive transfer, or recursive read-only access.
- **Distribution:** one published package archive, including its private
  workspace refrains.
- **EHIR:** Encore's intermediate representation and graph-memory abstract
  machine. Application code normally uses Encore rather than writing EHIR.
- **ERN:** Exclusively Reachable Nodes; the graph region eligible for a
  synchronous ownership-release transaction. See [the model](memory-model.md).
- **Frozen region:** a recursively read-only graph shared through a `frozen`
  contract, not a temporary read lock that automatically becomes writable.
- **Host / target:** machine running the compiler / machine running its output.
- **Inline value:** a complete payload; copying it copies its fields, including
  any owning node handles stored in them.
- **Instantiation / monomorphization:** producing concrete code and types for
  a generic use.
- **Lockfile:** recorded dependency selections used to restore a project.
- **Module:** a source-level namespace of declarations within a refrain.
- **Node handle:** an owning graph edge to stack or heap node storage.
  `T&` is also a node handle, not a borrow.
- **Refrain:** a named unit of Encore code available to the project's module
  resolver. `refrain::` addresses the current package.
- **Registry / index:** metadata used to resolve named package versions to
  immutable archives.
- **Sending region:** an exclusive graph transferred through a `sending`
  contract; the source can no longer be used after transfer.
- **Toolchain / sysroot:** host tools for compilation/linking / target headers
  and libraries those tools use.
- **Trait object:** a `dyn Trait` value used for runtime dispatch.
- **UTF-8 byte / scalar / grapheme:** encoded storage unit / Unicode scalar
  value / user-perceived text element. Their counts can differ.
