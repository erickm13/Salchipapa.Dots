class SalchipapaDots < Formula
  desc "Salchipapa dotfiles installer — Fish/Zsh, Herdr/Zellij/Tmux, Kitty/WezTerm, Neovim, AI agents & CLI tools (Debian, Arch, WSL)"
  homepage "https://github.com/erickm13/Salchipapa.Dots"
  url "https://github.com/erickm13/Salchipapa.Dots/archive/refs/tags/v2.8.0.tar.gz"
  sha256 "f50101006676c5a37f9542823524575486b1737708aafc5008b53c005d9b3f13"
  version "v2.8.0"

  def install
    bin.install "install.sh" => "salchipapa-dots"
    (share/"salchipapa-dots").install Dir["*"]
  end

  def caveats
    <<~EOS
      Run the installer with:
        sudo salchipapa-dots
    EOS
  end
end
