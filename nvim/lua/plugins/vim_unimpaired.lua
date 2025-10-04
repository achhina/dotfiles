return {
	-- Bracket mappings for common operations
	-- Note: which-key will show overlap warnings for these mappings:
	-- - [y/]y (operator) overlaps with [yy/]yy (encode/decode C string line)
	-- - [x/]x (operator) overlaps with [xx/]xx (encode/decode XML line)
	-- - [u/]u (operator) overlaps with [uu/]uu (encode/decode URL line)
	-- - [C/]C (treesitter comment nav) overlaps with [CC/]CC (encode/decode string line)
	-- These are expected - single letter waits for motion, double letter acts on line
	"tpope/vim-unimpaired",
}
