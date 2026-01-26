# nix-store

> Manipulate or query the Nix store.
> See also: `nix store.3`.
> More information: <https://nix.dev/manual/nix/stable/command-ref/nix-store.html>.

- Collect garbage, such as removing unused paths:

`nix-store --gc`

- Hard-link identical files together to reduce space usage:

`nix-store --optimise`

- Delete a specific store path (must be unused):

`nix-store --delete /nix/store/{{checksum-package-version.ext}}`

- Show all dependencies of a store path (package), in a tree format:

`nix-store {{[-q|--query]}} --tree /nix/store/{{checksum-package-version.ext}}`

- Show direct runtime dependencies of a store path:

`nix-store -q --references /nix/store/{{checksum-package-version.ext}}`

- Show all transitive dependencies (full closure) of a store path:

`nix-store -q --requisites /nix/store/{{checksum-package-version.ext}}`

- Find dependencies matching a pattern in a package's closure:

`nix-store -q --requisites $(which {{package-name}}) | grep {{pattern}}`

- Calculate the total size of a certain store path with all the dependencies:

`du {{[-cLsh|--total --dereference --summarize --human-readable]}} $(nix-store {{[-q|--query]}} --references /nix/store/{{checksum-package-version.ext}})`

- Show all dependents of a particular store path:

`nix-store {{[-q|--query]}} --referrers /nix/store/{{checksum-package-version.ext}}`

- Show why a dependency is included in your profile (uses newer nix command):

`nix why-depends ~/.nix-profile /nix/store/{{checksum-package-version.ext}}`

- List all packages in current Home Manager profile:

`nix-store -q --requisites ~/.nix-profile | sort`
