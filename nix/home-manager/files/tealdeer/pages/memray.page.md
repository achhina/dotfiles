# memray

> Python memory profiler for tracking memory allocations.
> More information: <https://bloomberg.github.io/memray/>.

- Run a Python script and track memory allocations:

`memray run {{script.py}}`

- Generate an interactive flamegraph report from a memray binary dump:

`memray flamegraph {{memray-output.bin}}`

- Generate a live memory report while running a script:

`memray run --live {{script.py}}`

- Track allocations and generate a flamegraph in one step:

`memray run {{script.py}} && memray flamegraph {{memray-output.bin}}`

- Track native C/C++ allocations in addition to Python allocations:

`memray run --native {{script.py}}`

- Generate a table report showing top memory allocations:

`memray table {{memray-output.bin}}`
