#!/usr/bin/env bash
# Phase G — Neovim (kickstart.nvim via vim.pack)

phase_start "G" "Neovim"

SOURCE="$(chezmoi source-path)"

# ── Chezmoi tracking ──────────────────────────────────────────────────────────
check "~/.config/nvim/init.lua managed by chezmoi"
assert_file "$SOURCE/dot_config/nvim/init.lua"

check "nvim-pack-lock.json tracked"
assert_file "$HOME/.config/nvim/nvim-pack-lock.json"

# ── Plugin manager ────────────────────────────────────────────────────────────
check "vim.pack data dir exists"
assert_dir "$HOME/.local/share/nvim/site/pack/core"

# ── Mason LSPs ────────────────────────────────────────────────────────────────
_mason_bin="$HOME/.local/share/nvim/mason/bin"

check "Mason installed lua-language-server"
assert_file "$_mason_bin/lua-language-server"

check "Mason installed yaml-language-server"
assert_file "$_mason_bin/yaml-language-server"

check "Mason installed bash-language-server"
assert_file "$_mason_bin/bash-language-server"

check "Mason installed marksman"
assert_file "$_mason_bin/marksman"

check "Mason installed pyright"
assert_file "$_mason_bin/pyright"

check "jdtls NOT installed via Mason (Java stays in IntelliJ)"
assert_no_file "$_mason_bin/jdtls"

# ── Treesitter parsers ────────────────────────────────────────────────────────
check "Treesitter parsers installed (bash yaml json lua python)"
assert_cmd_ok "nvim --headless -c 'lua local p=require(\"nvim-treesitter\").get_installed(\"parsers\"); for _,l in ipairs({\"bash\",\"yaml\",\"json\",\"lua\",\"python\"}) do assert(vim.tbl_contains(p,l),l..\" missing\") end; print(\"ok\")' -c qa 2>&1 | grep -q 'ok'"

# ── init.lua key features ─────────────────────────────────────────────────────
check "init.lua enables Nerd Font"
assert_grep 'have_nerd_font = true' "$SOURCE/dot_config/nvim/init.lua"

check "init.lua declares yamlls server"
assert_grep 'yamlls' "$SOURCE/dot_config/nvim/init.lua"

check "init.lua declares bashls server"
assert_grep 'bashls' "$SOURCE/dot_config/nvim/init.lua"

check "init.lua declares pyright server"
assert_grep 'pyright' "$SOURCE/dot_config/nvim/init.lua"

check "init.lua includes harpoon2"
assert_grep 'harpoon' "$SOURCE/dot_config/nvim/init.lua"

check "init.lua has lazygit <leader>gg binding"
assert_grep 'leader.*gg' "$SOURCE/dot_config/nvim/init.lua"

check "chezmoi diff for nvim is clean"
assert_cmd_ok "[ -z \"\$(chezmoi diff ~/.config/nvim)\" ]"

phase_end
