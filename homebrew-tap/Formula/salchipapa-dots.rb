class SalchipapaDots < Formula
  desc "Salchipapa dotfiles installer — Fish/Zsh, Herdr/Zellij/Tmux, Kitty/WezTerm, Neovim, AI agents & CLI tools (Debian, Arch, WSL)"
  homepage "https://github.com/erickm13/Salchipapa.Dots"
  url "https://github.com/erickm13/Salchipapa.Dots/archive/refs/tags/v2.10.0.tar.gz"
  sha256 "383f6d78239e4b11d72ff54bc1c987372ff32b66aa759a267b9088bd09105d1e"
  version "v2.10.0"

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
